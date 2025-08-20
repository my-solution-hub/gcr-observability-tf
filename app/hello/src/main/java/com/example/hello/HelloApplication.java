package com.example.hello;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.web.client.RestTemplate;
import org.springframework.context.annotation.Bean;
import java.time.Duration;

@SpringBootApplication
@RestController
public class HelloApplication {

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Value("${world.service.url:http://localhost:5000}")
    private String worldServiceUrl;

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    public static void main(String[] args) {
        SpringApplication.run(HelloApplication.class, args);
    }

    @GetMapping("/")
    public String home() {
        return """
            <html>
            <head><title>Hello Service</title></head>
            <body>
                <h1>Hello Service - Observability Demo</h1>
                <p><a href='/api/data'>Get Data from World Service</a></p>
                <p><a href='/health'>Health Check</a></p>
                <p>This service checks Redis cache first, then calls World service if needed.</p>
            </body>
            </html>
            """;
    }

    @GetMapping("/api/data")
    public String getData() {
        String cacheKey = "world_data";
        
        try {
            // Check Redis cache first
            String cachedData = redisTemplate.opsForValue().get(cacheKey);
            
            if (cachedData != null) {
                return "From Redis Cache: " + cachedData;
            }
            
            // If not in cache, call World service
            RestTemplate restTemplate = new RestTemplate();
            String worldData = restTemplate.getForObject(worldServiceUrl + "/api/data", String.class);
            
            // Cache the result for 5 minutes
            redisTemplate.opsForValue().set(cacheKey, worldData, Duration.ofMinutes(5));
            
            return "From World Service (cached): " + worldData;
            
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
