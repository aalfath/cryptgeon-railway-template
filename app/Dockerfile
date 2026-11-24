# Cryptgeon 2.9.3, official image pinned by version and digest (multi-arch index).
FROM cupcakearmy/cryptgeon:2.9.3@sha256:0344b34ba5375b9cb5bc6740fd35d075d2a581ddb0fcd30e0494c62ba3408e87

COPY start.sh /app/start.sh
RUN chmod 755 /app/start.sh

ENV PORT=8000
EXPOSE 8000
ENTRYPOINT ["/app/start.sh"]
