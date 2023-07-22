#!/usr/bin/env ruby
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.


DATADOG_DIR = ENV.fetch("DATADOG_DIR", "/home/vcap/app/.datadog")
DD_UPDATE_SCRIPT_WARMUP = ENV.fetch("DD_UPDATE_SCRIPT_WARMUP", "180")
NODE_AGENT_TAGS_FILE = File.join(DATADOG_DIR, "/node_agent_tags.txt")
DD_TAGS_FILE = File.join(DATADOG_DIR, "/.dd_tags.txt")

def sanitize(tags_env_var, separator)
    tags_list = tags_env_var.gsub(",\"", ";\"").split(separator)
    tags_list.keep_if { |element| !element.include?(";") }
    tags_list.keep_if { |element| !element.include?("app_instance_guid") }
    tags_list = tags_list.map { |tag| tag.gsub(" ", "_").strip }
    return tags_list.uniq
end

def get_tags()
    dd_tags = ENV['DD_TAGS'] ||File.file?(DD_TAGS_FILE) ? File.read(DD_TAGS_FILE) : nil
    dd_node_agent_tags = ENV['DD_NODE_AGENT_TAGS'] || (File.file?(NODE_AGENT_TAGS_FILE) ? File.read(NODE_AGENT_TAGS_FILE) : nil)

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
    timestamp_file = File.join(DATADOG_DIR, "startup_time")
    node_agent_tags_file = File.join(DATADOG_DIR, "node_agent_tags.txt")

    # read startup time set by the buildpack supply script
    timestamp = File.exists?(timestamp_file) ? File.read(timestamp_file).strip.to_i : 0

    # storing all tags on this variable
    tags = get_tags()

    # if the script is executed during the warmup period, merge incoming tags with the existing tags
    # otherwise, override existing tags
    if Time.now.to_i - timestamp <= DD_UPDATE_SCRIPT_WARMUP.to_i
        if File.exists?(node_agent_tags_file)
            node_tags = File.read(node_agent_tags_file).split(',')
            tags.concat(node_tags)
        end
    end

    # remove duplicates
    tags = tags.uniq

    # export tags
    File.write(node_agent_tags_file, tags.join(","))
end

main
