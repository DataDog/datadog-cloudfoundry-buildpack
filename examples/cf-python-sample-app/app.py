from ddtrace import patch_all; patch_all(flask=True, requests=True, logging=True)
from ddtrace import tracer
from ddtrace.profiling import Profiler
from flask import Flask
from datadog import initialize, statsd
import logging
import os


prof = Profiler()
prof.start()

options = {
    'statsd_host':'127.0.0.1',
    'statsd_port':8125
}

initialize(**options)

FORMAT = ('%(asctime)s %(levelname)s [%(name)s] [%(filename)s:%(lineno)d] '
          '[dd.service=%(dd.service)s dd.env=%(dd.env)s dd.version=%(dd.version)s dd.trace_id=%(dd.trace_id)s dd.span_id=%(dd.span_id)s] '
          '- %(message)s')
logging.basicConfig(format=FORMAT)
log = logging.getLogger(__name__)
log.level = logging.INFO

app = Flask(__name__)

@app.route('/')
def hello_world():
    log.info("HELLO WORLD!")
    statsd.increment('pcf.testing.custom_metrics.incr', tags=["boo:baz", "pcf"])
    statsd.decrement('pcf.testing.custom_metrics.decr', tags=["foo:bar", "pcf"])
    return 'Hello World from Python!'

if __name__ == '__main__':
    log.info("RUNNING FLASK SERVER")
    port = int(os.getenv('PORT', 8080))
    app.run(debug=True, host='0.0.0.0', port=port)

