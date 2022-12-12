# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

#!/usr/bin/env ruby

require 'yaml'

# env vars
DATADOG_DIR = ENV.fetch('DATADOG_DIR', '/home/vcap/app/.datadog')
DD_TAGS = ENV.fetch('DD_TAGS', '')
DD_NODE_AGENT_TAGS = ENV.fetch('DD_NODE_AGENT_TAGS', '')


datadog_config_filepath = File.join(DATADOG_DIR, 'dist/datadog.yaml')


file = File.open(datadog_config_filepath, 'r')
yaml_data = YAML.load(file)

tags = DD_TAGS.split(',') + DD_NODE_AGENT_TAGS.split(',')
yaml_data['tags'] = tags.uniq

File.write(datadog_config_filepath, yaml_data.to_yaml)
