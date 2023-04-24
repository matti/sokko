FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/matti/sokko"

COPY --from=jpillora/chisel:1.8.1 /app/bin /usr/local/bin/chisel
COPY --from=ghcr.io/matti/k8s-leader:107fcdcac60c8b5440f3837046649424be722ad2 /* /usr/local/bin

WORKDIR /app
COPY app .

ENTRYPOINT [ "/app/entrypoint.sh" ]
