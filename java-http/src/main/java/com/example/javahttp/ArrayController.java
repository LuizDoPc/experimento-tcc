package com.example.javahttp;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ArrayController {

    private final Counter requestCounter;

    public ArrayController(MeterRegistry registry){
        this.requestCounter = Counter
                .builder("request_counter")
                .description("Contador de requisições")
                .register(registry);
    }

    @PostMapping("/foo")
    public int helloWorld(@RequestBody int[] numbers) {
        for(int i=0; i<numbers.length; i++){
            System.out.println(i);
        }

        requestCounter.increment();
        return -1;
    }
}
