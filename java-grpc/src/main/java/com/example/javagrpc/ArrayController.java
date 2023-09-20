package com.example.javagrpc;

import io.micrometer.core.instrument.Metrics;

import java.util.concurrent.TimeUnit;

public class ArrayController extends ArrayServiceGrpc.ArrayServiceImplBase {

    @Override
    public void search(com.example.javagrpc.ArrayDefinition.Array request,
                       io.grpc.stub.StreamObserver<com.example.javagrpc.ArrayDefinition.Num> responseObserver){
        long start = System.nanoTime();
        int[] numbers = request.getArrayList().stream().mapToInt(Integer::intValue).toArray();

        for(int i=0; i< numbers.length; i++){
             System.out.println(numbers[i]);
        }

        Metrics.counter("request_counter").increment();
        Metrics.timer(
                "request_timer",
                "c", Double.toString(Metrics.counter("request_counter").count())
        ).record(System.nanoTime() - start, TimeUnit.NANOSECONDS);

        responseObserver.onNext(com.example.javagrpc.ArrayDefinition.Num.newBuilder().setNum(-1).build());
        responseObserver.onCompleted();
    }
}
