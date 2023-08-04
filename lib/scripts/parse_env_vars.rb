#!/usr/bin/env ruby
# Unless explicitly stated otherwise all files in this repository are licensed under the Apache 2.0 License.
# This product includes software developed at Datadog (https://www.datadoghq.com/).
# Copyright 2022-Present Datadog, Inc.

if ARGV.length > 0
    env_file_name = ARGV[0]
    env_vars = File.readlines(env_file_name)
  
    if ARGV.length > 1
      new_env_file_name = ARGV[1]
      File.open(new_env_file_name, 'w+') do |new_env_file|
        env_vars.each do |env_var|
          env_var = env_var.strip
          next if env_var.start_with?("#")
  
          env_parts = env_var.split("=", 2)
          next if env_parts.length != 2
  
          name, value = env_parts
          if !["export DD_TAGS", "export TAGS"].include?(name)
            value = value.gsub(" ", "_")
          end
  
          # skip empty env vars
          next if value == "''"
  
          new_env_file.write("#{name}=#{value}\n")
        end
      end
    else
      puts "Destination file not specified"
    end
  else
    puts "Source file not specified"
  end
  