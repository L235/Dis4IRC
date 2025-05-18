FROM eclipse-temurin:21-jdk-alpine AS build

# Install required tools
RUN apk add --no-cache git bash curl unzip

# Copy project files
COPY . /app
WORKDIR /app

# Make Gradle wrapper executable and build the fat jar
RUN chmod +x ./gradlew && ./gradlew shadowJar

# ---- Runtime image ----
FROM eclipse-temurin:21-jre-alpine

# Create app directory
RUN mkdir -p /data
WORKDIR /data

# Copy built jar from the build stage
COPY --from=build /app/build/libs/Dis4IRC-*.jar /opt/dis4irc/app.jar

# Set memory limits
ENV JAVA_OPTS="-Xmx512m"

# Run the app
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /opt/dis4irc/app.jar"]
