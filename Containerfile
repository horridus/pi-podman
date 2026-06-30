FROM node:22-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    mariadb-client \
    procps \
    iputils-ping \
    dnsutils \
    python3 \
    python3-pip \
    poppler-utils \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-ita \
    python3-dotenv \
    && rm -rf /var/lib/apt/lists/*

# Install Astral CLI
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Installa pi coding agent globalmente
RUN npm install -g @earendil-works/pi-coding-agent

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
