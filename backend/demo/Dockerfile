# ─── Stage 1: Build the JAR ───────────────────────────
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

# Copy pom.xml and source code
COPY pom.xml .
COPY src ./src

# Build the JAR, skip tests (tests run in Jenkins separately)
RUN mvn clean package -DskipTests

# ─── Stage 2: Run the JAR ─────────────────────────────
FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Copy only the built JAR from Stage 1
COPY --from=build /app/target/*.jar app.jar

# Expose the port your Spring Boot app runs on
EXPOSE 8080

# Run the app
ENTRYPOINT ["java", "-jar", "app.jar"]