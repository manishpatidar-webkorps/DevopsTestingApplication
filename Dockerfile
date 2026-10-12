# Stage 1: Build and extract layers
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build

# Copy build configuration files first to cache dependency downloads
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the fat JAR
COPY src ./src
RUN mvn clean package -DskipTests

# Extract the JAR into layers using Spring Boot's tools mode
RUN java -Djarmode=tools -jar target/*.jar extract --layers --destination extracted

# Stage 2: Final minimal runtime environment
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Create a non-privileged system user and group for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy individual layers from the builder stage
COPY --from=builder /build/extracted/dependencies/ ./
COPY --from=builder /build/extracted/spring-boot-loader/ ./
COPY --from=builder /build/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/extracted/application/ ./

# Switch execution context away from root to the secure user
USER appuser

EXPOSE 8081

# Launch using the optimized Spring Boot JarLauncher instead of a raw fat JAR
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
