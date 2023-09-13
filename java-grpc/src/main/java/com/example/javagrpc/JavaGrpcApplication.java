package com.example.javagrpc;

import io.grpc.BindableService;
import io.grpc.Server;
import io.grpc.ServerBuilder;
import io.grpc.ServerInterceptors;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.cumulative.CumulativeCounter;
import io.micrometer.prometheus.PrometheusConfig;
import io.micrometer.prometheus.PrometheusMeterRegistry;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.IOException;

@SpringBootApplication
public class JavaGrpcApplication {

    public static void main(String[] args) throws IOException, InterruptedException {
        SpringApplication.run(JavaGrpcApplication.class, args);

        int port = 50051;

        MeterRegistry registry = new PrometheusMeterRegistry(PrometheusConfig.DEFAULT);

        Server server = ServerBuilder.forPort(port)
                .addService(ServerInterceptors.intercept((BindableService) new ArrayController(), new GrpcServerRequestInterceptor(registry)))
                .build();

        System.out.println("Starting gRPC server on port " + port);

        server.start();
        server.awaitTermination();
    }
}
