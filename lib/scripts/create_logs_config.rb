# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

require 'json'

logs_config_dir = ENV['LOGS_CONFIG_DIR']
logs_config = ENV['LOGS_CONFIG']
dd_tags = ENV['DD_TAGS']

config = {}

if logs_config_dir.nil?
  puts "ERROR: `LOGS_CONFIG_DIR` must be set in order to collect logs. For more info, see: https://github.com/DataDog/datadog-cloudfoundry-buildpack#log-collection"
  exit(1)
end

if !logs_config.nil?
  config["logs"] = JSON.parse(logs_config)
  if !dd_tags.nil?
    config["logs"][0]["tags"] = dd_tags
  else
    puts "Could not find DD_TAGS env var"
  end
else
  puts "ERROR: `LOGS_CONFIG` must be set in order to collect logs. For more info, see: https://github.com/DataDog/datadog-cloudfoundry-buildpack#log-collection"
  exit(1)
end

config = config.to_json

path = "#{logs_config_dir}/logs.yaml"

begin
  Dir.mkdir(logs_config_dir) unless File.exists?(logs_config_dir)
  File.open(path, 'w') do |f|
    puts "writing #{config} to #{path}"
    f.write(config)
    f.write("\n")
  end
rescue Exception => e
  puts "Could not write to log file #{e.backtrace}"
end