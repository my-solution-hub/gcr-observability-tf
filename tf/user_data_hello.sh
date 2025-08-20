#!/bin/bash
yum update -y
yum install -y java-17-amazon-corretto-devel git

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create application directory
mkdir -p /opt/hello-app
cd /opt/hello-app

# Create Spring Boot application
cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    <groupId>com.example</groupId>
    <artifactId>hello-app</artifactId>
    <version>1.0.0</version>
    <properties>
        <java.version>17</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

mkdir -p src/main/java/com/example/hello
cat > src/main/java/com/example/hello/HelloApplication.java << 'EOF'
package com.example.hello;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.web.client.RestTemplate;
import org.springframework.context.annotation.Bean;
import java.time.Duration;

@SpringBootApplication
@RestController
public class HelloApplication {

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    public static void main(String[] args) {
        SpringApplication.run(HelloApplication.class, args);
    }

    @GetMapping("/")
    public String home() {
        return "<h1>Hello Service</h1><p><a href='/api/data'>Get Data</a></p>";
    }

    @GetMapping("/api/data")
    public String getData() {
        String cacheKey = "world_data";
        String cachedData = redisTemplate.opsForValue().get(cacheKey);
        
        if (cachedData != null) {
            return "From Redis: " + cachedData;
        }
        
        try {
            RestTemplate restTemplate = new RestTemplate();
            String worldData = restTemplate.getForObject("${world_endpoint}/api/data", String.class);
            redisTemplate.opsForValue().set(cacheKey, worldData, Duration.ofMinutes(5));
            return "From World Service: " + worldData;
        } catch (Exception e) {
            return "Error calling world service: " + e.getMessage();
        }
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
EOF

cat > src/main/resources/application.properties << 'EOF'
server.port=8080
spring.data.redis.host=${redis_endpoint}
spring.data.redis.port=6379
management.endpoints.web.exposure.include=health,info
EOF

# Install Maven
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
tar xzf apache-maven-3.9.5-bin.tar.gz
ln -s apache-maven-3.9.5 maven
export PATH=/opt/maven/bin:$PATH

# Build and run the application
cd /opt/hello-app
/opt/maven/bin/mvn clean package -DskipTests

# Create systemd service
cat > /etc/systemd/system/hello-app.service << 'EOF'
[Unit]
Description=Hello Spring Boot Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/hello-app
ExecStart=/usr/bin/java -jar /opt/hello-app/target/hello-app-1.0.0.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hello-app
systemctl start hello-app
