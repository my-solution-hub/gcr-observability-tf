package com.example.hello;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.web.client.RestTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.http.ResponseEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.time.Duration;

@SpringBootApplication
@RestController
public class HelloApplication {

    private static final Logger logger = LoggerFactory.getLogger(HelloApplication.class);

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Value("${world.service.url:http://localhost:5000}")
    private String worldServiceUrl;

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    public static void main(String[] args) {
        logger.info("Starting Hello Service application");
        SpringApplication.run(HelloApplication.class, args);
    }

    @GetMapping("/")
    public String home() {
        logger.info("Home page requested");
        return """
            <html>
            <head>
                <title>Hello Service - Observability Demo</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 40px; }
                    button { padding: 10px 20px; margin: 10px; background: #007cba; color: white; border: none; border-radius: 4px; cursor: pointer; }
                    button:hover { background: #005a87; }
                    #result { margin-top: 20px; padding: 15px; background: #f5f5f5; border-radius: 4px; min-height: 50px; }
                </style>
            </head>
            <body>
                <h1>Hello Service - Observability Demo</h1>
                <p>This service demonstrates caching with Redis and microservice communication.</p>
                
                <button onclick="fetchData()">Get Data from World Service</button>
                <button onclick="checkHealth()">Check Health</button>
                
                <div id="result">Click a button to see results...</div>
                
                <script>
                    async function fetchData() {
                        document.getElementById('result').innerHTML = 'Loading...';
                        try {
                            const response = await fetch('/api/data');
                            const data = await response.text();
                            document.getElementById('result').innerHTML = '<strong>Data:</strong> ' + data;
                        } catch (error) {
                            document.getElementById('result').innerHTML = '<strong>Error:</strong> ' + error.message;
                        }
                    }
                    
                    async function checkHealth() {
                        document.getElementById('result').innerHTML = 'Checking health...';
                        try {
                            const response = await fetch('/health');
                            const data = await response.text();
                            document.getElementById('result').innerHTML = '<strong>Health Status:</strong> ' + data;
                        } catch (error) {
                            document.getElementById('result').innerHTML = '<strong>Error:</strong> ' + error.message;
                        }
                    }
                </script>
            </body>
            </html>
            """;
    }

    @GetMapping("/api/data")
    public String getData() {
        logger.info("API data request received");
        String cacheKey = "world_data";
        
        try {
            // Check Redis cache first
            String cachedData = redisTemplate.opsForValue().get(cacheKey);
            
            if (cachedData != null) {
                logger.info("Cache hit - returning cached data");
                return "From Redis Cache: " + cachedData;
            }
            
            logger.info("Cache miss - calling world service at: {}", worldServiceUrl);
            // If not in cache, call World service
            RestTemplate restTemplate = new RestTemplate();
            String worldData = restTemplate.getForObject(worldServiceUrl + "/api/data", String.class);
            
            // Cache the result for 5 minutes
            redisTemplate.opsForValue().set(cacheKey, worldData, Duration.ofMinutes(5));
            logger.info("Data cached successfully for 5 minutes");
            
            return "From World Service (cached): " + worldData;
            
        } catch (Exception e) {
            logger.error("Error processing data request: {}", e.getMessage());
            return "Error: " + e.getMessage();
        }
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        logger.debug("Health check requested");
        return ResponseEntity.ok("OK");
    }
}
