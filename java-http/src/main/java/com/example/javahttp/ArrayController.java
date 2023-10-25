package com.example.javahttp;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.TimeUnit;

@RestController
public class ArrayController {

    private final Counter requestCounter;
    private final MeterRegistry currentRegistry;
    
    @Value("${WARMUP_COUNT}")
    private int warmupCount;

    public ArrayController(MeterRegistry registry){
        this.currentRegistry = registry;

        this.requestCounter = Counter
                .builder("request_counter")
                .description("Contador de requisições")
                .register(registry);
    }

    @PostMapping("/foo")
    public int helloWorld(@RequestBody int[] numbers) {
        long start = System.nanoTime();
        Timer t = currentRegistry.timer("request_timer", "c", Double.toString(requestCounter.count()));

        for(int i=0; i<numbers.length; i++){
            System.out.println(i);
        }

        System.out.println("Warmup count: " + warmupCount);
        if(requestCounter.count() > warmupCount){
            requestCounter.increment();
            t.record(System.nanoTime() - start, TimeUnit.NANOSECONDS);
        }
        return -1;
    }
}
