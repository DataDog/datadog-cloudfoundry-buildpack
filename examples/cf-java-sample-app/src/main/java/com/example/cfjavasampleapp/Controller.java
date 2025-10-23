package com.example.cfjavasampleapp;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import com.timgroup.statsd.StatsDClient;

@RestController
public class Controller {
    private static final Logger logger = LogManager.getLogger(Controller.class);
    private static StatsDClient dogStatsDClient = DogStatsdClient.getDogStatsDClient();

    @GetMapping("/")
    public String index() {
        logger.info("Got a Request!!");

        dogStatsDClient.increment("pcf.testing.custom_metrics.incr", new String[] { "boo:baz", "pcf" });
        dogStatsDClient.decrement("pcf.testing.custom_metrics.decr", new String[] { "foo:bar", "pcf" });

        return "Hello World";
    }
}
