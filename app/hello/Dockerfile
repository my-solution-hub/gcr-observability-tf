# Frontend build stage with China npm mirror
FROM node:18-alpine AS frontend-build
WORKDIR /app
# Use Taobao npm registry for China
RUN npm config set registry https://registry.npmmirror.com
COPY package.json webpack.config.js ./
COPY src/main/resources/static/js/otel-init.js ./src/main/resources/static/js/
RUN npm install && npm run build

# Java build stage  
FROM maven:3.8.4-openjdk-17-slim AS java-build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
COPY --from=frontend-build /app/src/main/resources/static/js/otel-bundle.js ./src/main/resources/static/js/
RUN mvn clean package -DskipTests

# Runtime stage
FROM amazoncorretto:17-alpine
COPY agent/aws-opentelemetry-agent.jar /opt/opentelemetry-javaagent.jar
COPY --from=java-build /app/target/hello-app-1.0.0.jar /app/hello-app.jar
WORKDIR /app
EXPOSE 8080
CMD ["java", "-javaagent:/opt/opentelemetry-javaagent.jar", "-jar", "hello-app.jar"]
