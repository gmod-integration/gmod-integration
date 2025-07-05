# Dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 1) Install 32-bit libs & utilities
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      unzip \
      lib32gcc-s1 \
      lib32stdc++6 \
      dos2unix \
 && rm -rf /var/lib/apt/lists/*

# 2) Manually install SteamCMD into /steamcmd
RUN mkdir -p /steamcmd \
 && cd /steamcmd \
 && wget -qO- https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
      | tar zxvf - \
 && chmod +x steamcmd.sh

# 3) Set working dir and copy your entrypoint
WORKDIR /app
COPY entrypoint.sh .

# 4) Convert line endings & make executable
RUN dos2unix entrypoint.sh \
 && chmod +x entrypoint.sh

# 5) Invoke via bash so we don’t get exec-format errors
ENTRYPOINT ["bash", "/app/entrypoint.sh"]
