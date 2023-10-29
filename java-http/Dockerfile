FROM --platform=linux/amd64 ubuntu:20.04 AS builder

WORKDIR /app

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

RUN apt-get update
RUN apt-get install -y wget
RUN wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb
RUN dpkg -i jdk-17_linux-x64_bin.deb
RUN rm jdk-17_linux-x64_bin.deb

ENV JAVA_HOME /usr/lib/jvm/jdk-17-oracle-x64

RUN MAVEN_OPTS="-Xms512m -Xmx4g -XX:CompileThreshold=175 -XX:+DisableExplicitGC" ./mvnw dependency:go-offline -B

COPY src src

RUN ./mvnw package -DskipTests

FROM ubuntu:20.04

WORKDIR /app
 
COPY --from=builder /usr/lib/jvm/jdk-17 /usr/lib/jvm/jdk-17

ENV JAVA_HOME /usr/lib/jvm/jdk-17
ENV PATH $JAVA_HOME/bin:$PATH

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
