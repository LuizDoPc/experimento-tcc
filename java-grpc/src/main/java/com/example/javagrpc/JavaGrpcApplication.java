package com.example.javagrpc;

import io.grpc.Server;
import io.grpc.ServerBuilder;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.IOException;

@SpringBootApplication
public class JavaGrpcApplication {

    public static void main(String[] args) throws IOException, InterruptedException {
        SpringApplication.run(JavaGrpcApplication.class, args);

        int port = 50059;

        Server server = ServerBuilder.forPort(port)
                .addService(new ArrayController())
                .build();

        System.out.println("Starting gRPC server on port " + port);

        server.start();
        server.awaitTermination();
    }
}
