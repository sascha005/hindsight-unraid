FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install hindsight client libraries + api binary + uv
RUN pip install --no-cache-dir \
    hindsight-client==0.6.2 \
    hindsight-embed==0.6.2 \
    hindsight-api==0.6.2 \
    uv

# Prepare directories (will be owned by root, entrypoint handles chown)
RUN mkdir -p /opt/hindsight /opt/hindsight-data/home/.hindsight \
    && useradd -m -d /opt/hindsight-data/home hindsight || true

ENV HOME=/opt/hindsight-data/home
ENV HINDSIGHT_DATA_DIR=/opt/hindsight-data

COPY entrypoint.sh /opt/hindsight/entrypoint.sh
RUN chmod +x /opt/hindsight/entrypoint.sh

WORKDIR /opt/hindsight-data

EXPOSE 8888

ENTRYPOINT ["/opt/hindsight/entrypoint.sh"]
