from __future__ import print_function

import os

LOGS_CONFIG_DIR = os.environ['LOGS_CONFIG_DIR']
LOGS_CONFIG = os.environ['LOGS_CONFIG']

config = "{\"logs\":" + LOGS_CONFIG + "}"
path = LOGS_CONFIG_DIR + "/logs.yaml"

with open(path, 'w') as f:
    print("writing {} to {}".format(config, path))
    f.write(config)
    f.write("\n")
