# GAMIT/GLOBK 10.71 Docker Image
# Requires MIT license - Apply at http://geoweb.mit.edu/gg/license.php

FROM ubuntu:24.04

LABEL maintainer="geumjin99"
LABEL description="GAMIT/GLOBK 10.71 GPS/GNSS Processing Software"
LABEL version="10.71"

# Build arguments for MIT credentials
ARG GG_USER=guest
ARG GG_PASSWORD

# Check password is provided
RUN if [ -z "$GG_PASSWORD" ]; then \
      echo "ERROR: GG_PASSWORD is required. Use --build-arg GG_PASSWORD=your_password"; \
      exit 1; \
    fi

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV gg=/opt/gg
ENV HELP_DIR=${gg}/help
ENV PATH="${gg}/com:${gg}/kf/globk:${gg}/kf/glred:${gg}/kf/glfor:${gg}/kf/glinit:${gg}/gamit/utils:${PATH}"

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gfortran \
    gcc \
    make \
    tcsh \
    csh \
    curl \
    libx11-dev \
    libxt-dev \
    libxaw7-dev \
    libncurses-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create gg directory
WORKDIR /opt/gg

# Download GAMIT source files
RUN curl -u ${GG_USER}:${GG_PASSWORD} -O ftp://chandler.mit.edu/updates/source/gamit.10.71.tar.gz \
    && curl -u ${GG_USER}:${GG_PASSWORD} -O ftp://chandler.mit.edu/updates/source/kf.10.71.tar.gz \
    && curl -u ${GG_USER}:${GG_PASSWORD} -O ftp://chandler.mit.edu/updates/source/libraries.10.71.tar.gz \
    && curl -u ${GG_USER}:${GG_PASSWORD} -O ftp://chandler.mit.edu/updates/source/com.10.71.tar.gz \
    && curl -u ${GG_USER}:${GG_PASSWORD} -O ftp://chandler.mit.edu/updates/source/help.10.71.tar.gz \
    && curl -u ${GG_USER}:${GG_PASSWORD} -O ftp://chandler.mit.edu/updates/source/tables.10.71.tar.gz

# Extract all archives
RUN for f in *.tar.gz; do tar -xzf $f; done && rm -f *.tar.gz

# Download and apply incremental updates
RUN LATEST_UPDATE=$(curl -s -u ${GG_USER}:${GG_PASSWORD} ftp://chandler.mit.edu/updates/source/ | grep "incremental_updates" | grep ".tar.gz" | tail -1 | awk '{print $NF}') \
    && curl -u ${GG_USER}:${GG_PASSWORD} -O ftp://chandler.mit.edu/updates/source/${LATEST_UPDATE} \
    && tar -xzf ${LATEST_UPDATE} && rm -f ${LATEST_UPDATE}

# Copy build script
COPY install_gamit.sh /opt/gg/
RUN chmod +x /opt/gg/install_gamit.sh

# Build GAMIT/GLOBK
RUN /opt/gg/install_gamit.sh

# Create data directory
RUN mkdir -p /data
WORKDIR /data

# Default command
CMD ["/bin/bash"]
