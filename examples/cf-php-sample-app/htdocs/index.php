<?php
require __DIR__ . '/../vendor/autoload.php';

use Slim\Factory\AppFactory;
use DataDog\DogStatsd;

$statsd = new DogStatsd(['host' => '127.0.0.1', 'port' => 8125]);

$app = AppFactory::create();

$app->get('/', function ($request, $response) use ($statsd) {
    error_log('HELLO WORLD!');
    $statsd->increment('pcf.testing.custom_metrics.incr', 1, ['boo:baz', 'pcf']);
    $statsd->decrement('pcf.testing.custom_metrics.decr', 1, ['foo:bar', 'pcf']);
    $response->getBody()->write('Hello World from PHP!');
    return $response;
});

$app->run();
