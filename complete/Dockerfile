FROM maven:3.9-amazoncorretto-17-al2023 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -DskipTests -q

FROM gcr.io/distroless/java17-debian12:nonroot
WORKDIR /app
COPY --from=build /app/target/rest-service-complete-0.0.1-SNAPSHOT.jar app.jar
ENV SERVER_PORT=777
EXPOSE 777
ENTRYPOINT ["java", "-jar", "app.jar"]
