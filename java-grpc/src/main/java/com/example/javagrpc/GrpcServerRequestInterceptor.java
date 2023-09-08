package com.example.javagrpc;

import io.grpc.*;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class GrpcServerRequestInterceptor implements ServerInterceptor {

    private final Counter customCounter;

    public GrpcServerRequestInterceptor(MeterRegistry meterRegistry) {
        this.customCounter = Counter
                .builder("request_counter")
                .description("Contador de requisições")
                .register(meterRegistry);
    }

    @Override
    public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
            ServerCall<ReqT, RespT> serverCall, Metadata metadata, ServerCallHandler<ReqT, RespT> next) {


        System.out.println("gRPC request intercepted");

        customCounter.increment();


        return next.startCall(serverCall, metadata);
    }
}