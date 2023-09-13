package com.example.javagrpc;

import io.grpc.*;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class GrpcServerRequestInterceptor implements ServerInterceptor {

    private final Counter customCounter;

    @Autowired
    public GrpcServerRequestInterceptor(MeterRegistry registry) {
        System.out.println("Criei intercepter");
        this.customCounter = Counter
                .builder("request_counter")
                .description("Contador de requisições")
                .register(registry);
    }

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            ServerCall<ReqT, RespT> serverCall, Metadata metadata, ServerCallHandler<ReqT, RespT> next) {


        System.out.println("gRPC request intercepted");
        System.out.println(customCounter.count());
        System.out.println(customCounter.toString());

        customCounter.increment();


        return next.startCall(serverCall, metadata);
    }
}