# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

import sys

if len(sys.argv) > 1:
    env_file_name = sys.argv[1]
    with open(env_file_name, 'r') as env_file:
        env_vars = env_file.readlines()

    if len(sys.argv) > 2:
        new_env_file_name = sys.argv[2]
        with open(new_env_file_name, 'w') as new_env_file:
            for env_var in env_vars:
                env_var = env_var.strip()
                if env_var.startswith("#"):
                    continue
                env_var = env_var.replace(" ", "_")
                new_env_file.write("export {}\n".format(env_var))
    else:
        print("Destination file not specified")
else:
    print("Source file not specified")