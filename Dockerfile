# Base image 
FROM ghcr.io/charmbracelet/vhs

# Install editor and jq
RUN apt-get update \
    && apt-get install -y --no-install-recommends nano jq \
    && rm -rf /var/lib/apt/lists/*

# Set default editor
ENV EDITOR=nano

# Set working dir
WORKDIR /vhs

# Link scratchpad script
RUN ["ln", "-sf", "/vhs/scratchpad.sh", "/usr/local/bin/scratchpad"]

# Unset vhs' entrypoint
ENTRYPOINT []

# Default to bash
CMD ["bash"]
