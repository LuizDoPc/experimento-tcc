package com.example.javagrpc;

import java.util.Random;

import org.springframework.beans.factory.annotation.Value;

public class ArrayController extends ArrayServiceGrpc.ArrayServiceImplBase {

    @Override
    public void search(com.example.javagrpc.ArrayDefinition.Array request,
                       io.grpc.stub.StreamObserver<com.example.javagrpc.ArrayDefinition.Num> responseObserver){
        int[] numbers = request.getArrayList().stream().mapToInt(Integer::intValue).toArray();

        for(int i=0; i<3; i++){
            Random r = new Random();

            int pos = r.nextInt(numbers.length);

            System.out.println(numbers[pos]); 
        }

        responseObserver.onNext(com.example.javagrpc.ArrayDefinition.Num.newBuilder().setNum(-1).build());
        responseObserver.onCompleted();
    }
}
