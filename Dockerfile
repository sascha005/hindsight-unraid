FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install hindsight server + client
RUN pip install --no-cache-dir hindsight-client==0.6.2 hindsight-embed==0.6.2

# Prepare directories
RUN mkdir -p /opt/hindsight /opt/hindsight-data/home/.hindsight \
    && useradd -m -d /opt/hindsight-data/home hindsight \
    && chown -R hindsight:hindsight /opt/hindsight-data

ENV HOME=/opt/hindsight-data/home
ENV HINDSIGHT_DATA_DIR=/opt/hindsight-data

COPY entrypoint.sh /opt/hindsight/entrypoint.sh
RUN chmod +x /opt/hindsight/entrypoint.sh

USER hindsight
WORKDIR /opt/hindsight-data

EXPOSE 8888

ENTRYPOINT ["/opt/hindsight/entrypoint.sh"]
