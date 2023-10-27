FROM --platform=linux/amd64 ubuntu:20.04 AS builder

# Set the working directory in the container
WORKDIR /app

# Copy the Maven wrapper files
COPY mvnw .
COPY .mvn .mvn

# Copy the project descriptor files
COPY pom.xml .

# Atualize os pacotes do sistema
RUN apt-get update

# Instale o OpenJDK 17
RUN apt-get install -y openjdk-17-jdk

# # Defina a variável de ambiente JAVA_HOME
RUN export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Download the project dependencies
RUN MAVEN_OPTS="-Xms256m -Xmx1g -XX:CompileThreshold=175 -XX:+UseG1GC" ./mvnw dependency:go-offline -B

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