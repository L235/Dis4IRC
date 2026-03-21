# Railway Deployment

This fork deploys Dis4IRC on [Railway](https://railway.com/) with auto-deploy from GitHub.

## Architecture

- **Deploy source**: GitHub repo `L235/Dis4IRC`, `master` branch
- **Deploy method**: Auto-deploy on push to master
- **Config delivery**: The `config.hocon` file is stored as a base64-encoded Railway environment variable (`CONFIG_B64`), decoded at container startup

## Dockerfile

The Dockerfile is a two-stage build:

1. **Build stage**: Uses `eclipse-temurin:21-jdk-alpine` to run `gradlew shadowJar`
2. **Runtime stage**: Uses `eclipse-temurin:21-jre-alpine`, decodes `CONFIG_B64` into `config.hocon`, then runs the jar

### JVM flags

Set via `JAVA_OPTS` in the Dockerfile:

- `-Xmx256m` — heap limit
- `-XX:+UseSerialGC` — low-overhead GC for small containers
- `-Djava.net.preferIPv4Stack=true` — **required**: Railway containers lack IPv6, and Libera Chat's DNS returns AAAA records that cause connection failures

## SASL Authentication

Libera Chat requires SASL authentication from cloud provider IPs (including Railway). Without SASL, the server disconnects the bot ~7 seconds after connecting.

SASL is configured via two fields in `config.hocon` under the `irc` section:

```hocon
irc {
    sasl-account=YourNickServAccount
    sasl-password=YourNickServPassword
    # ... other fields
}
```

These are read at startup and registered as SASL PLAIN with KICL before the IRC connection is established. This is distinct from NickServ identification via `init-commands-list`, which happens post-connect and is too late for networks that require SASL.

## Updating the config

1. Decode the current config:
   ```bash
   railway variables --json | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('CONFIG_B64',''))" | base64 -d > config.hocon
   ```
2. Edit `config.hocon`
3. Re-encode and upload:
   ```bash
   railway variables --set "CONFIG_B64=$(base64 -i config.hocon | tr -d '\n')"
   ```

Config changes take effect on the next deployment. To apply without a code change, use `railway redeploy`.

## Long message handling

The upstream paste service (paste.gg) is dead. This fork replaces it with inline truncation: messages exceeding `max-message-length` (default 450) or `max-new-lines` (default 4) are stripped of code fences, collapsed to a single line, and truncated with `...`.
