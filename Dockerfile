# Stage 1: Build and extract layers
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build

# Copy build configuration files first to cache dependency downloads
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the fat JAR
COPY src ./src
RUN mvn clean package -DskipTests

# FIX: Extract directly into the /build folder using "." to avoid nested folders
RUN java -Djarmode=tools -jar target/*.jar extract --layers --destination .

# Clean up Maven cache within this stage to ensure no dangling temporary data leaks
RUN rm -rf ~/.m2/repository

# Stage 2: Final ultra-minimal runtime environment (Distroless JRE)
# This drops base OS footprint entirely, containing only the JRE and minimal libraries
FROM gcr.io/distroless/java21-debian12:latest
WORKDIR /app

# Copy individual layers from the builder stage
COPY --from=builder /build/dependencies/ ./
COPY --from=builder /build/spring-boot-loader/ ./
COPY --from=builder /build/snapshot-dependencies/ ./
COPY --from=builder /build/application/ ./

EXPOSE 8081

# Optimized JVM tuning flags for VERY low RAM environments:
# -XX:MaxRAMPercentage: Dynamically restricts the JVM to only use 50% of the container's available RAM
# -XX:+UseSerialGC: Swaps the heavy default parallel GC with a lightweight, ultra-low memory Garbage Collector
# -Xss256k: Reduces thread stack size from 1MB to 256KB to save massive amounts of native RAM
ENTRYPOINT [ \
  "java", \
  "-XX:MaxRAMPercentage=50.0", \
  "-XX:+UseSerialGC", \
  "-Xss256k", \
  "org.springframework.boot.loader.launch.JarLauncher" \
]
