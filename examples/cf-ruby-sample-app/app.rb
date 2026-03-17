require 'sinatra'
require 'datadog'
require 'datadog/statsd'

Datadog.configure do |c|
  c.profiling.enabled = true
  c.tracing.instrument :sinatra
end

statsd = Datadog::Statsd.new('127.0.0.1', 8125)

get '/' do
  puts "Hello, World!"
  statsd.increment('pcf.testing.custom_metrics.incr', tags: ['ruby:foo', 'pcf'])
  statsd.decrement('pcf.testing.custom_metrics.decr', tags: ['foo:ruby', 'pcf'])
  'Hello, World!'
end

