package com.example.javagrpc;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import io.micrometer.core.instrument.Counter;

public class ArrayController extends ArrayServiceGrpc.ArrayServiceImplBase {

    @Override
    public void search(com.example.javagrpc.ArrayDefinition.Array request,
                       io.grpc.stub.StreamObserver<com.example.javagrpc.ArrayDefinition.Num> responseObserver){

        int[] numbers = request.getArrayList().stream().mapToInt(Integer::intValue).toArray();

        for(int i=0; i< numbers.length; i++){
            System.out.println(numbers[i]);
        }

        responseObserver.onNext(com.example.javagrpc.ArrayDefinition.Num.newBuilder().setNum(-1).build());
        responseObserver.onCompleted();
    }
}
