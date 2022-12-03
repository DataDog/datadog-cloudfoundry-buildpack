# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2017-Present Datadog, Inc.

from __future__ import print_function

import os
import json
import sys


vcap_app_string = os.environ.get('VCAP_APPLICATION', '{}')

vcap_application = json.loads(vcap_app_string)

vcap_variables = ["application_id", "name", "instance_index", "space_name"]

cf_instance_ip = os.environ.get("CF_INSTANCE_IP")

tags = ["cf_instance_ip:{}".format(cf_instance_ip)]
tags.append("container_id:{}".format(os.environ.get("CF_INSTANCE_GUID")))

if len(sys.argv) > 1 and sys.argv[1] == 'node-agent-tags':
    # These are always comma separated - See https://github.com/DataDog/datadog-agent/blob/main/pkg/cloudfoundry/containertagger/container_tagger.go#L133
    node_agent_tags = os.environ.get('DD_NODE_AGENT_TAGS', None)

    if node_agent_tags is not None:
        # we do this to separate commas inside json values from tags separator commas
        node_agent_tags = node_agent_tags.replace(",\"", ";\"")
        all_node_agent_tags = node_agent_tags.split(",")
        tags = tags + [tag for tag in all_node_agent_tags if ";" not in tag]


for vcap_var_name in vcap_variables:
    vcap_var = vcap_application.get(vcap_var_name)
    if vcap_var is not None:
        key = vcap_var_name
        if vcap_var_name == 'name':
            key = 'application_name'
        tags.append("{0}:{1}".format(key, vcap_var))

uris = vcap_application.get('uris')
if uris:
    for uri in uris:
        tags.append("uri:{0}".format(uri))

user_tags = os.environ.get('TAGS', None)
if user_tags:
    try:
        user_tags = user_tags.split(',')
        for tag in user_tags:
            tags.append(tag)
    except Exception as e:
        print("there was an issue parsing the tags in TAGS: {}".format(e))

user_tags = os.environ.get('DD_TAGS', None)
if user_tags:
    try:
        user_tags = user_tags.split(',')
        for tag in user_tags:
            tags.append(tag)
    except Exception as e:
        print("there was an issue parsing the tags in DD_TAGS: {}".format(e))

tags = [ tag.replace(" ", "_") for tag in tags ]
tags = list(dict.fromkeys(tags))
legacy_tags = os.environ.get('LEGACY_TAGS_FORMAT', False)
if legacy_tags:
    print(','.join(tags))
else:
    print(json.dumps(tags))
