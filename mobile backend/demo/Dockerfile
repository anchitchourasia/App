# ─── Stage 1: Build the JAR using Maven ───────────────
FROM maven:3.9.6-eclipse-temurin-17 AS build

# ✅ Accept proxy build args
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

WORKDIR /app

# Copy pom.xml first (Docker cache optimization)
COPY pom.xml .

# Download dependencies separately so they get cached
RUN mvn dependency:go-offline -B

# Now copy source code
COPY src ./src

# Build the JAR — skip tests (Jenkins already runs them separately)
RUN mvn clean package -DskipTests


# ─── Stage 2: Run the JAR (lightweight image) ─────────
FROM eclipse-temurin:17-jre-alpine

# ✅ Accept proxy build args
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

WORKDIR /app

# Copy only the built JAR from Stage 1
COPY --from=build /app/target/demo-0.0.1-SNAPSHOT.jar app.jar

# Expose Spring Boot default port
EXPOSE 8080

# Run
ENTRYPOINT ["java", "-jar", "app.jar"]