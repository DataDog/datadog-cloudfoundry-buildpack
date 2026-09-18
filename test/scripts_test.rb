# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

# Unit tests for the buildpack's runtime Ruby scripts.
#
# These scripts run at app start under the buildpack's embedded Ruby (see
# scripts/prepare.sh for the pinned version). They exercise the real drift
# paths that have broken silently on Ruby version bumps: deprecated File APIs
# and YAML.load alias handling. Run them on the same Ruby the buildpack ships.

require 'minitest/autorun'
require 'tmpdir'
require 'json'
require 'open3'

SCRIPTS_DIR = File.expand_path('../lib/scripts', __dir__)

def run_ruby(*args, env: {})
  Open3.capture2e(env, RbConfig.ruby, *args)
end

class DeprecatedApiScanTest < Minitest::Test
  # File.exists?/Dir.exists? were removed in Ruby 3.2. Guard against anyone
  # reintroducing them anywhere in the runtime scripts.
  def test_no_deprecated_file_predicates
    offenders = Dir[File.join(SCRIPTS_DIR, '*.rb')].select do |path|
      File.read(path).match?(/\b(?:File|Dir)\.exists\?/)
    end
    assert_empty offenders,
      "deprecated File.exists?/Dir.exists? found (removed in Ruby 3.2): #{offenders.join(', ')}"
  end
end

class UpdateDatadogConfigTest < Minitest::Test
  SCRIPT = File.join(SCRIPTS_DIR, 'update_datadog_config.rb')

  # datadog.yaml uses YAML anchors (tags: &1 / dogstatsd_tags: *1). Since Psych
  # 4 (Ruby 3.1) YAML.load rejects aliases unless aliases: true. This must parse.
  def test_read_yaml_file_resolves_aliases
    Dir.mktmpdir do |dir|
      yaml_path = File.join(dir, 'datadog.yaml')
      File.write(yaml_path, "tags: &1\n- env:test\ndogstatsd_tags: *1\n")

      out, status = run_ruby('-r', SCRIPT, '-e',
        'd = read_yaml_file(ARGV[0]); print(d["tags"] == d["dogstatsd_tags"] && d["tags"] == ["env:test"])',
        yaml_path)

      assert status.success?, "script crashed parsing anchored YAML:\n#{out}"
      assert_equal 'true', out, "aliases not resolved to the same value:\n#{out}"
    end
  end
end

class UpdateTagsTest < Minitest::Test
  SCRIPT = File.join(SCRIPTS_DIR, 'update_tags.rb')

  # Runs the script end to end. Exercises File.exist?(startup_time) and
  # File.exist?(node_agent_tags.txt); a deprecated-API drift crashes it here.
  def test_merges_existing_node_agent_tags_within_warmup
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'startup_time'), Time.now.to_i.to_s)
      File.write(File.join(dir, 'node_agent_tags.txt'), 'existing:tag')

      out, status = run_ruby(SCRIPT,
        env: { 'DATADOG_DIR' => dir, 'DD_NODE_AGENT_TAGS' => 'incoming:tag' })

      assert status.success?, "update_tags.rb crashed:\n#{out}"
      written = File.read(File.join(dir, 'node_agent_tags.txt')).split(',')
      assert_includes written, 'incoming:tag'
      assert_includes written, 'existing:tag'
    end
  end
end

class CreateLogsConfigTest < Minitest::Test
  SCRIPT = File.join(SCRIPTS_DIR, 'create_logs_config.rb')

  # Points LOGS_CONFIG_DIR at a missing dir so the Dir.mkdir unless
  # File.exist?(dir) branch runs; a deprecated-API drift crashes it here.
  def test_writes_logs_config_and_creates_missing_dir
    Dir.mktmpdir do |base|
      logs_dir = File.join(base, 'logs') # single missing level; Dir.mkdir is not recursive

      out, status = run_ruby(SCRIPT, env: {
        'LOGS_CONFIG_DIR' => logs_dir,
        'LOGS_CONFIG' => JSON.dump([{ 'type' => 'file', 'port' => '10514' }]),
        'DD_TAGS' => 'env:test',
        'DD_NODE_AGENT_TAGS' => 'app_id:abc',
      })

      assert status.success?, "create_logs_config.rb crashed:\n#{out}"
      logs_yaml = File.join(logs_dir, 'logs.yaml')
      assert File.exist?(logs_yaml), "logs.yaml not written:\n#{out}"
      config = JSON.parse(File.read(logs_yaml))
      assert_equal 10514, config['logs'].first['port']
      assert_includes config['logs'].first['tags'], 'env:test'
    end
  end
end
