package com.example.javahttp;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import java.util.Random;


@RestController
public class ArrayController {
    @PostMapping("/foo")
    public int helloWorld(@RequestBody int[] numbers) {
        for(int i=0; i<3; i++){
            Random r = new Random();

            int pos = r.nextInt(numbers.length);

            System.out.println(numbers[pos]); 
        }

        return -1;
    }
}
