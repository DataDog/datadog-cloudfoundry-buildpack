# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

from __future__ import print_function

import os
import json

LOGS_CONFIG_DIR = os.environ.get('LOGS_CONFIG_DIR')
LOGS_CONFIG = os.environ.get('LOGS_CONFIG')
DD_TAGS = os.environ.get('DD_TAGS')


config = {}

if LOGS_CONFIG:
  config["logs"] = json.loads(LOGS_CONFIG)

  if DD_TAGS:
    config["logs"][0]["tags"] = DD_TAGS

config = json.dumps(config)

path = LOGS_CONFIG_DIR + "/logs.yaml"

with open(path, 'w') as f:
  print("writing {} to {}".format(config, path))
  f.write(config)
  f.write("\n")
