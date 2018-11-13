import os

LOGS_CONFIG_DIR = os.environ['LOGS_CONFIG_DIR']
LOGS_CONFIG = os.environ['LOGS_CONFIG']

config = "{\"logs\":" + LOGS_CONFIG + "}" 
path = LOGS_CONFIG_DIR + "/logs.yaml"

file = open(path, 'w')

print "writing {} to {}".format(config, path)
file.write(config)
file.write("\n")
