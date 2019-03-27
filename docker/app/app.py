from flask import Flask
from datadog import statsd
import logging

import os

# This is a small example application
# It uses tracing and dogstatsd on a sample flask application

log = logging.getLogger("app")

app = Flask(__name__)

@app.route("/")
def hello():
    statsd.increment('request.number', 1, tags=["test", "foo:bar", "my:app"])
    log.info("Got a request at hello")
    return "Hello World!"

@app.route("/error")
def error():
    statsd.increment('request.error.number', 1, tags=["test", "foo:bar", "my:app"])
    log.info("Got a request at error")
    raise Exception()

if __name__ == '__main__':
    port = 5001
    host = '0.0.0.0'
    if os.environ.get('HOST'):
        host = os.environ.get('HOST')
    if os.environ.get('PORT'):
        port = os.environ.get('PORT')
    app.run(debug=True, host=host, port=port)
