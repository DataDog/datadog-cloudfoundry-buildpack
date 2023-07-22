#!/usr/bin/env ruby
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

require 'json'

NODE_AGENT_TAGS_FILE = "/home/vcap/app/.datadog/node_agent_tags.txt"

def parse_tags(tags)
  begin
    delimiter = ','
    delimiter = ' ' if tags.count(' ') > tags.count(',')
    if !ENV["DD_TAGS_SEP"].nil?
      delimiter = ENV["DD_TAGS_SEP"]
    end
    return tags.split(delimiter)
  rescue Exception => e
    puts "there was an issue parsing the tags in '#{tags}': #{e.message}"
    return []
  end
end

vcap_app_string = ENV['VCAP_APPLICATION'] || '{}'

vcap_application = JSON.parse(vcap_app_string)

vcap_variables = ['application_id', 'name', 'instance_index', 'space_name']

cf_instance_ip = ENV['CF_INSTANCE_IP']

tags = []
tags << "cf_instance_ip:#{cf_instance_ip}" if cf_instance_ip

tags << "container_id:#{ENV['CF_INSTANCE_GUID']}"

node_agent_tags = ENV['DD_NODE_AGENT_TAGS']
if node_agent_tags
  # These are always comma separated
  # See https://github.com/DataDog/datadog-agent/blob/main/pkg/cloudfoundry/containertagger/container_tagger.go#L133

  # we do this to separate commas inside json values from tags separator commas
  node_agent_tags = node_agent_tags.gsub(",\"", ";\"")
  all_node_agent_tags = parse_tags(node_agent_tags)
  if !all_node_agent_tags.empty?
    tags += all_node_agent_tags.keep_if { |tag| !tag.include?(';') }
  end
end

node_agent_tags_file = File.file?(NODE_AGENT_TAGS_FILE) ? File.read(NODE_AGENT_TAGS_FILE).strip : nil
if node_agent_tags_file
  node_agent_tags = parse_tags(node_agent_tags_file)
  if !node_agent_tags.empty?
    tags += node_agent_tags
  end
end

vcap_variables.each do |vcap_var_name|
  vcap_var = vcap_application[vcap_var_name]
  next unless vcap_var

  key = vcap_var_name
  key = 'application_name' if vcap_var_name == 'name'
  tags << "#{key}:#{vcap_var}"
end

uris = vcap_application['uris']
if uris
  uris.each do |uri|
    tags << "uri:#{uri}"
  end
end

user_tags = ENV['TAGS']
if user_tags
  begin
    user_tags = parse_tags(user_tags)
    tags += user_tags
  rescue Exception => e
    puts "there was an issue parsing the tags in TAGS: #{e.message}"
  end
end

user_tags = ENV['DD_TAGS']
if user_tags
  begin
    user_tags = parse_tags(user_tags)
    tags += user_tags
  rescue Exception => e
    puts "there was an issue parsing the tags in DD_TAGS: #{e.message}"
  end
end

version_file = '/home/vcap/app/.datadog/VERSION'
if File.exist?(version_file)
  buildpack_version = File.open(version_file, 'r') { |file| file.read.strip }
  tags << "buildpack_version:#{buildpack_version.strip}"
end

tags = tags.map { |tag| tag.gsub(' ', '_') }
tags = tags.uniq

puts tags.join(',')
