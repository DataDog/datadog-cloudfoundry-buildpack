const tracer = require('dd-trace').init();
var http = require("http");
var StatsD = require('hot-shots');
var dogstatsd = new StatsD();


http.createServer(function (request, response) {
    console.log('Hello world!');
    response.writeHead(200, {'Content-Type': 'text/plain'});

    response.end('Hello World!\n');
    dogstatsd.increment('pcf.testing.custom_metrics.incr', ['foo', 'bar'])
    dogstatsd.decrement('pcf.testing.custom_metrics.decr', ['foo', 'bar'])
 }).listen(8080);

