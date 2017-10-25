import os
import json

vcap_application = json.loads(os.environ['VCAP_APPLICATION'])

vcap_variables = ["application_id", "application_name", "instance_index", "space_name"]

tags = []

for vcap_var_name in vcap_variables:
    vcap_var = vcap_application.get(vcap_var_name)
    if vcap_var:
        tags.append("{0}:{1}".format(vcap_var_name, vcap_var))

uris = vcap_application.get('uris')
if uris:
    for uri in uris:
        tags.append("uri:{0}".format(uri))

print json.dumps(tags)
