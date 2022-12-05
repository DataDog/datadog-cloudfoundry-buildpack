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

if LOGS_CONFIG_DIR is None:
  print("ERROR: `LOGS_CONFIG_DIR` must be set in order to collect logs. For more info, see: https://github.com/DataDog/datadog-cloudfoundry-buildpack#log-collection")
  exit(1)

if LOGS_CONFIG is not None:
  config["logs"] = json.loads(LOGS_CONFIG)

  if DD_TAGS is not None:
    config["logs"][0]["tags"] = DD_TAGS
  else:
    print("Could not find DD_TAGS env var")

else:
  print("ERROR: `LOGS_CONFIG` must be set in order to collect logs. For more info, see: https://github.com/DataDog/datadog-cloudfoundry-buildpack#log-collection")
  exit(1)

config = json.dumps(config)

path = LOGS_CONFIG_DIR + "/logs.yaml"
try:
  if not os.path.exists(LOGS_CONFIG_DIR):
    os.makedirs(LOGS_CONFIG_DIR)
  with open(path, 'w+') as f:
    print("writing {} to {}".format(config, path))
    f.write(config)
    f.write("\n")
except Exception as e:
  print("Could not write to log file: {}".format(str(e)))