# Use a lightweight Linux distribution as the base image
FROM bellsoft/liberica-openjdk-alpine-musl:17 AS builder

# Set the working directory in the container
WORKDIR /app

# Copy the Maven wrapper files
COPY mvnw .
COPY .mvn .mvn

# Copy the project descriptor files
COPY pom.xml .

# Download the project dependencies
RUN ./mvnw dependency:go-offline -B

# Copy the application source code
COPY src src

# Build the application
RUN ./mvnw package -DskipTests

# Use a lightweight Linux distribution as the base
FROM bellsoft/liberica-openjre-alpine-musl:17

# Set the working directory in the container
WORKDIR /app

# Copy the built JAR file from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose the port that the Spring Boot application uses (if necessary)
EXPOSE 8080

# Set the command to run the Spring Boot application
CMD ["java", "-jar", "app.jar"]