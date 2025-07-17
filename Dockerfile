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

# App directory (also holds runtime config)
WORKDIR /opt/dis4irc

# Copy the built JAR from the build stage
COPY --from=build /app/build/libs/Dis4IRC-*.jar ./app.jar

# Java options
ENV JAVA_OPTS="-Xmx256m -XX:+UseSerialGC"

# On container start:
# 1) decode CONFIG_B64 → ./config.hocon
# 2) run Dis4IRC with that config (app expected to read ./config.hocon)
ENTRYPOINT ["sh","-c", "\
  echo \"$CONFIG_B64\" | base64 -d > config.hocon && \
  exec java $JAVA_OPTS -jar ./app.jar \
"]
