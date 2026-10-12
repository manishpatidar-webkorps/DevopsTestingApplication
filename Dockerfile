# Stage 1: Build and extract layers
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build

# Copy build configuration files first to cache dependency downloads
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the fat JAR
COPY src ./src
RUN mvn clean package -DskipTests

# FIX: Extract into a dedicated, clean directory to prevent the "not empty" error
RUN java -Djarmode=tools -jar target/*.jar extract --layers --destination extracted

# Clean up Maven cache within this stage to ensure no dangling temporary data leaks
RUN rm -rf ~/.m2/repository

# Stage 2: Final ultra-minimal runtime environment (Distroless JRE)
FROM gcr.io/distroless/java21-debian12:latest
WORKDIR /app

# FIX: Pull layers from the nested /build/extracted/ folder
COPY --from=builder /build/extracted/dependencies/ ./
COPY --from=builder /build/extracted/spring-boot-loader/ ./
COPY --from=builder /build/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/extracted/application/ ./

EXPOSE 8081

# Optimized JVM tuning flags for VERY low RAM environments
ENTRYPOINT [ \
  "java", \
  "-XX:MaxRAMPercentage=50.0", \
  "-XX:+UseSerialGC", \
  "-Xss256k", \
  "org.springframework.boot.loader.launch.JarLauncher" \
 ]
