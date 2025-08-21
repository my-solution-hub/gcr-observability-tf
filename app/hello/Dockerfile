FROM openjdk:17-jre-slim

# Install OpenTelemetry Java agent
RUN apt-get update && apt-get install -y wget && \
    wget -O /opt/opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy application JAR
COPY target/hello-app-1.0.0.jar /app/hello-app.jar

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 8080

# Run application with OpenTelemetry agent
CMD ["java", "-javaagent:/opt/opentelemetry-javaagent.jar", "-jar", "hello-app.jar"]
