require 'sinatra'
require 'ddtrace'

Datadog.configure do |c|
  c.tracing.instrument :sinatra
end

get '/' do
  puts "Hello, World!"
  'Hello, World!'
end

