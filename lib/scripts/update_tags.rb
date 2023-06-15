# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

#!/usr/bin/env ruby

# env vars
DATADOG_DIR = ENV.fetch("DATADOG_DIR", "/home/vcap/app/.datadog")
DD_TAGS = ENV.fetch("DD_TAGS", "")
DD_NODE_AGENT_TAGS = ENV.fetch("DD_NODE_AGENT_TAGS", "")
DD_UPDATE_SCRIPT_WARMUP = ENV.fetch("DD_UPDATE_SCRIPT_WARMUP", "180")

# file paths
version_file = File.join(DATADOG_DIR, "VERSION")
timestamp_file = File.join(DATADOG_DIR, "startup_time")
node_agent_tags_file = File.join(DATADOG_DIR, "node_agent_tags.txt")

# read startup time set by the buildpack supply script
timestamp = File.exists?(timestamp_file) ? File.read(timestamp_file).strip.to_i : 0

# storing all tags on this variable
tags = []

def sanitize(tags_env_var, separator)
    tags_list = tags_env_var.gsub(",\"", ";\"").split(separator)
    tags_list.keep_if { |element| !element.include?(";") }
    tags_list.keep_if { |element| !element.include?("app_instance_guid") }
    tags_list = tags_list.map { |tag| tag.gsub(" ", "_") }
    return tags_list.uniq
end

if ! DD_NODE_AGENT_TAGS.empty?
    tags.concat(sanitize(DD_NODE_AGENT_TAGS, ","))
end

if ! DD_TAGS.empty?
    tags.concat(sanitize(DD_TAGS, " "))
end

if File.exists?(version_file)
    tags.push("buildpack_version:" + File.read(version_file).strip)
end

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
