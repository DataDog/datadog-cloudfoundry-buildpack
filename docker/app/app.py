from flask import Flask
from datadog import statsd
import logging

import os

# This is a small example application
# It uses tracing and dogstatsd on a sample flask application

log = logging.getLogger("app")

app = Flask(__name__)

# The app has two routes, a basic endpoint and an exception endpoint
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

# This is meant to be run directly, instead of executed through flask run
if __name__ == '__main__':
    # It grabs the host and port from the environment
    port = 5001
    host = '0.0.0.0'
    if os.environ.get('HOST'):
        host = os.environ.get('HOST')
    if os.environ.get('PORT'):
        port = os.environ.get('PORT')
    app.run(debug=True, host=host, port=port)
