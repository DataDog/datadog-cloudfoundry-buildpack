# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

from __future__ import print_function

import os
import json
import subprocess

LOGS_CONFIG_DIR = os.environ['LOGS_CONFIG_DIR']
LOGS_CONFIG = os.environ['LOGS_CONFIG']

tags = []
# TODO: check if this is causing duplicate tags and should only use the used-provided DD_TAGS instead
new_tags = subprocess.check_output(['python', '/home/vcap/app/.datadog/scripts/get_tags.py', 'node-agent-tags'])
new_tags = new_tags.decode("UTF-8")

config = {}
config["logs"] = json.loads(LOGS_CONFIG)
config["logs"][0]["tags"] = json.loads(new_tags)
config = json.dumps(config)
path = LOGS_CONFIG_DIR + "/logs.yaml"

with open(path, 'w') as f:
  print("writing {} to {}".format(config, path))
  f.write(config)
  f.write("\n")
