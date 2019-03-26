from flask import Flask
from datadog import statsd

app = Flask(__name__)

@app.route("/")
def hello():
    statsd.increment('request.number', 1, tags=["test", "foo:bar", "my:app"])

    return "Hello World!"

@app.route("/error")
def hello():
    statsd.increment('request.error.number', 1, tags=["test", "foo:bar", "my:app"])

    raise Exception()
