require 'sinatra'
require 'datadog'

Datadog.configure do |c|
  c.profiling.enabled = true
  c.tracing.instrument :sinatra
end

get '/' do
  puts "Hello, World!"
  'Hello, World!'
end

