package com.example.javahttp;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ArrayController {
    @PostMapping("/foo")
    public int helloWorld(@RequestBody int[] numbers) {
        for(int i=0; i<numbers.length; i++){
            System.out.println(i);
        }
        return -1;
    }
}
