package com.example.cfjavasampleapp;

import com.timgroup.statsd.NonBlockingStatsDClientBuilder;
import com.timgroup.statsd.StatsDClient;

public class DogStatsdClient {
    public static StatsDClient getDogStatsDClient() {

        StatsDClient client = new NonBlockingStatsDClientBuilder()
                .hostname("localhost")
                .port(8125)
                .build();

        return client;
    }

}
