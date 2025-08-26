package com.example.hello.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ApiController {

    private static final Logger logger = LoggerFactory.getLogger(ApiController.class);

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Value("${world.service.url:http://localhost:5000}")
    private String worldServiceUrl;

    @GetMapping("/data")
    public String getData(@RequestParam(value = "cache_key", defaultValue = "world_data") String cacheKey) {
        logger.info("API data request received with cache_key: {}", cacheKey);
        
        try {
            // Check Redis cache first
            String cachedData = redisTemplate.opsForValue().get(cacheKey);
            
            if (cachedData != null) {
                logger.info("Cache hit - returning cached data for key: {}", cacheKey);
                return "From Redis Cache: " + cachedData;
            }
            
            logger.info("Cache miss - calling world service at: {}", worldServiceUrl);
            // If not in cache, call World service
            RestTemplate restTemplate = new RestTemplate();
            String worldData = restTemplate.getForObject(worldServiceUrl + "/api/data", String.class);
            
            // Cache the result for 5 minutes
            redisTemplate.opsForValue().set(cacheKey, worldData, Duration.ofMinutes(5));
            logger.info("Data cached successfully for 5 minutes with key: {}", cacheKey);
            
            return "From World Service (cached): " + worldData;
            
        } catch (Exception e) {
            logger.error("Error processing data request: {}", e.getMessage());
            return "Error: " + e.getMessage();
        }
    }

    @GetMapping("/hello")
    public Map<String, Object> apiHello() {
        logger.info("API Hello endpoint called");
        Map<String, Object> response = new HashMap<>();
        response.put("service", "hello-service");
        response.put("message", "Hello from Spring Boot!");
        response.put("timestamp", java.time.Instant.now().toString());
        return response;
    }

    @GetMapping("/world")
    public Map<String, Object> apiWorld() {
        logger.info("API World endpoint called - proxying to world service");
        try {
            String cacheKey = "world_data";
            String cachedData = redisTemplate.opsForValue().get(cacheKey);
            
            if (cachedData != null) {
                logger.info("Cache hit for world data");
                Map<String, Object> response = new HashMap<>();
                response.put("data", cachedData);
                response.put("source", "redis_cache");
                response.put("service", "hello-service");
                return response;
            }
            
            logger.info("Cache miss - calling world service");
            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<Map> worldResponse = restTemplate.getForEntity(
                worldServiceUrl + "/api/data", Map.class);
            
            if (worldResponse.getStatusCode().is2xxSuccessful()) {
                Map<String, Object> worldData = worldResponse.getBody();
                redisTemplate.opsForValue().set(cacheKey, worldData.toString(), Duration.ofMinutes(5));
                
                Map<String, Object> response = new HashMap<>();
                response.put("data", worldData);
                response.put("source", "world_service");
                response.put("service", "hello-service");
                return response;
            } else {
                throw new RuntimeException("World service returned: " + worldResponse.getStatusCode());
            }
        } catch (Exception e) {
            logger.error("Error calling world service: {}", e.getMessage());
            Map<String, Object> response = new HashMap<>();
            response.put("error", e.getMessage());
            response.put("service", "hello-service");
            return response;
        }
    }

    @PostMapping("/traces")
    public ResponseEntity<String> proxyTraces(@RequestBody String traces) {
        // Proxy web traces to OTEL collector
        try {
            RestTemplate restTemplate = new RestTemplate();
            String collectorUrl = "http://otel-collector:4318/v1/traces";
            
            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.set("Content-Type", "application/json");
            
            org.springframework.http.HttpEntity<String> entity = new org.springframework.http.HttpEntity<>(traces, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(collectorUrl, entity, String.class);
            
            return ResponseEntity.ok("Traces forwarded");
        } catch (Exception e) {
            logger.error("Error forwarding traces: {}", e.getMessage());
            return ResponseEntity.status(500).body("Error forwarding traces");
        }
    }
}
