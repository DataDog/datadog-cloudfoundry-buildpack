# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

#!/usr/bin/env ruby

require 'yaml'

NODE_AGENT_TAGS_FILE = "/home/vcap/app/.datadog/node_agent_tags.txt"
DD_TAGS_FILE = "/home/vcap/app/.datadog/.dd_tags.txt"

def sanitize(tags_env_var, delimiter)
  tags_list = tags_env_var.gsub(",\"", ";\"").split(delimiter)
  tags_list.keep_if { |element| !element.include?(";") }
  tags_list = tags_list.map { |tag| tag.gsub(" ", "_") }
  return tags_list.uniq
end

def read_yaml_file(file_path)
  yaml_file = File.read(file_path)
  return YAML.load(yaml_file)
end

def write_yaml_file(file_path, data)
  File.write(file_path, YAML.dump(data))
end

def get_tags()
  dd_tags = ENV['DD_TAGS'] || File.file?(DD_TAGS_FILE) ? File.read(DD_TAGS_FILE).strip : nil
  dd_node_agent_tags = File.file?(NODE_AGENT_TAGS_FILE) ? File.read(NODE_AGENT_TAGS_FILE).strip : nil

  tags = []

  if !dd_tags.nil?
    tags += sanitize(dd_tags, ",")
  end

  if !dd_node_agent_tags.nil?
    tags += sanitize(dd_node_agent_tags, ",")
  end

  return tags.uniq
end

def main
  tags = get_tags()

  if !tags.empty?
    file_path = '/home/vcap/app/.datadog/dist/datadog.yaml'

    puts "updating datadog.yaml with the tags: '#{tags}'"

    data = read_yaml_file(file_path)

    data['tags'] = tags
    data['dogstatsd_tags'] = tags

    write_yaml_file(file_path, data)
  end
end

main