# ─── Build Stage ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS build

# Install Git, Bash, etc
RUN apk add --no-cache git bash curl unzip

# Copy the project in and build the fat-jar
COPY . /app
WORKDIR /app
RUN chmod +x ./gradlew && ./gradlew shadowJar

# ─── Runtime Stage ───────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine

# Install base64 tool to decode our config
RUN apk add --no-cache coreutils

# Create data directory where config will live
RUN mkdir -p /data
WORKDIR /data

# Copy the built JAR from the build stage
COPY --from=build /app/build/libs/Dis4IRC-*.jar /opt/dis4irc/app.jar

# Java options
ENV JAVA_OPTS="-Xmx512m"

# On container start:
# 1) decode CONFIG_B64 → /data/config.hocon
# 2) run Dis4IRC with that config
ENTRYPOINT ["sh","-c", "\
  echo \"$CONFIG_B64\" | base64 -d > /data/config.hocon && \
  exec java $JAVA_OPTS -jar /opt/dis4irc/app.jar \
"]
