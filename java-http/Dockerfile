# Use a lightweight Linux distribution as the base image
FROM adoptopenjdk:11-jdk-hotspot AS builder

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