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
timestamp_file = File.join(DATADOG_DIR, "startup_time")
node_agent_tags_file = File.join(DATADOG_DIR, "node_agent_tags.txt")

# read startup time set by the buildpack supply script
timestamp = File.read(timestamp_file).strip
time = Time.parse(timestamp)

# storing all tags on this variable
tags = []

if ! DD_NODE_AGENT_TAGS.empty?
    tags.concat(DD_NODE_AGENT_TAGS.split(','))

if ! DD_TAGS.empty?
    tags.concat(DD_TAGS.split(','))

# if the script is executed during the warmup period, merge incoming tags with the existing tags
# otherwise, override existing tags
if Time.now - time <= DD_UPDATE_SCRIPT_WARMUP.to_i
    if File.exists?(node_agent_tags_file)
        node_tags = File.read(node_agent_tags_file).split(',')
        tags.concat(node_tags)
end

# remove duplicates
tags = tags.uniq

# export tags
File.write(node_agent_tags_file, tags.join(","))



