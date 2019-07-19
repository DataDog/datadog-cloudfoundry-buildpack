from __future__ import print_function

import os
import json

vcap_app_string = os.environ.get('VCAP_APPLICATION', '{}')

vcap_application = json.loads(vcap_app_string)

vcap_variables = ["application_id", "name", "instance_index", "space_name"]

tags = []

for vcap_var_name in vcap_variables:
    vcap_var = vcap_application.get(vcap_var_name)
    if vcap_var:
        key = vcap_var_name
        if vcap_var_name == 'name':
            key = 'application_name'
        tags.append("{0}:{1}".format(key, vcap_var))

uris = vcap_application.get('uris')
if uris:
    for uri in uris:
        tags.append("uri:{0}".format(uri))

user_tags = os.environ.get('TAGS', None)
user_tags = user_tags.replace(" ", ",")
if user_tags:
    try:
        user_tags = user_tags.split(',')
        tags.extend(user_tags)
    except Exception as e:
        print("there was an issue parsing the tags in TAGS: {}".format(e))

user_tags = os.environ.get('DD_TAGS', None)
# The separator that the agent understands for DD_TAGS is space, not comma
# To be consistent, allow using spaces as separator, but keep backward compatibility
user_tags = user_tags.replace(" ", ",")
if user_tags:
    try:
        user_tags = user_tags.split(',')
        tags.extend(user_tags)
    except Exception as e:
        print("there was an issue parsing the tags in DD_TAGS: {}".format(e))

print(" ".join(tags))
