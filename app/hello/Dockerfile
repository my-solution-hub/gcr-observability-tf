FROM amazoncorretto:17-alpine

# Install OpenTelemetry Java agent
RUN apk add --no-cache wget && \
    wget -O /opt/opentelemetry-javaagent.jar https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Copy application JAR
COPY target/hello-app-1.0.0.jar /app/hello-app.jar

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 8080

# Run application with OpenTelemetry agent
CMD ["java", "-javaagent:/opt/opentelemetry-javaagent.jar", "-jar", "hello-app.jar"]
