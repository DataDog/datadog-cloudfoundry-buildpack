#!/usr/bin/env ruby
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

#!/usr/bin/env ruby

require 'json'

node_agent_tags = "/home/vcap/app/.datadog/node_agent_tags.txt"

logs_config_dir = ENV['LOGS_CONFIG_DIR']
logs_config = ENV['LOGS_CONFIG']
dd_tags = ENV['DD_TAGS']
dd_node_agent_tags = ENV['DD_NODE_AGENT_TAGS'] || (File.file?(node_agent_tags) ? File.read(node_agent_tags) : "")

def sanitize(tags_env_var, separator)
  tags_list = tags_env_var.gsub(",\"", ";\"").split(separator)
  tags_list.keep_if { |element| !element.include?(";") }
  tags_list = tags_list.map { |tag| tag.gsub(" ", "_") }
  return tags_list.uniq
end

config = {}

if logs_config_dir.nil?
  puts "ERROR: `LOGS_CONFIG_DIR` must be set in order to collect logs. For more info, see: https://github.com/DataDog/datadog-cloudfoundry-buildpack#log-collection"
  exit(1)
end

if !logs_config.nil?
  config["logs"] = JSON.parse(logs_config)

  tags_list = []

  if !dd_tags.nil?
    tags_list += sanitize(dd_tags, " ")
  else
    puts "Could not find DD_TAGS env var"
  end

  if !dd_node_agent_tags.nil?
    tags_list += sanitize(dd_node_agent_tags, ",")
  else
    puts "Could not find DD_NODE_AGENT_TAGS env var"
  end

  if !tags_list.empty?
    tags_list = tags_list.uniq
    config["logs"].each { |conf| conf["tags"] = tags_list }
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
