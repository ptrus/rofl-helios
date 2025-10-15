FROM ubuntu:24.04

# Install required dependencies
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download and install Helios binary
RUN ARCH="$(uname -m)" && \
    if [ "$ARCH" = "x86_64" ]; then \
        HELIOS_URL="https://github.com/a16z/helios/releases/latest/download/helios_linux_amd64.tar.gz"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        HELIOS_URL="https://github.com/a16z/helios/releases/latest/download/helios_linux_arm64.tar.gz"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -fsSL "$HELIOS_URL" -o helios.tar.gz && \
    tar -xzf helios.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/helios && \
    rm helios.tar.gz

# Create startup script
RUN echo '#!/bin/bash\n\
if [ -z "$INFURA_API_KEY" ]; then\n\
  echo "Error: INFURA_API_KEY environment variable is not set"\n\
  exit 1\n\
fi\n\
\n\
exec /usr/local/bin/helios ethereum \\\n\
  --network mainnet \\\n\
  --rpc-bind-ip 0.0.0.0 \\\n\
  --rpc-port 1337 \\\n\
  --execution-rpc https://mainnet.infura.io/v3/$INFURA_API_KEY\n\
' > /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

# Expose Helios RPC port
EXPOSE 1337

# Run startup script
CMD ["/usr/local/bin/start.sh"]
