ARG PIXI_VERSION=0.61.0
# Pin base image by tag + digest to improve
# supply-chain integrity and reproducability.
# Auto-update pinned images with Docker Scout Policy + remediation PRs
ARG BASE_IMAGE=ubuntu:24.04@sha256:c35e29c9450151419d9448b0fd75374fec4fff364a27f176fb458d472dfc9e54

# Build with Ubuntu LTS
FROM --platform=$TARGETPLATFORM ubuntu:24.04@sha256:c35e29c9450151419d9448b0fd75374fec4fff364a27f176fb458d472dfc9e54 AS builder

# Specify PIXI_VERSION ARG again to make it available in this stage
ARG PIXI_VERSION
RUN apt-get update && apt-get install -y curl

# Download architecture-specific Pixi tarball and checksum to
# verify integrity before installing Pixi.
# Adapt to binary if preferred.
RUN set -eux; \
    ARCH="$(uname -m)"; \
    PIXI_TAR="pixi-${ARCH}-unknown-linux-musl.tar.gz"; \
    PIXI_URL="https://github.com/prefix-dev/pixi/releases/download/v${PIXI_VERSION}/${PIXI_TAR}"; \
    curl -Lso /${PIXI_TAR} "$PIXI_URL"; \
    curl -Lso /${PIXI_TAR}.sha256 "${PIXI_URL}.sha256"; \
    grep -q ' ' /${PIXI_TAR}.sha256 || sed -i "s|\$|  /${PIXI_TAR}|" /${PIXI_TAR}.sha256; \
    sha256sum -c /${PIXI_TAR}.sha256; \
    tar -xzf /${PIXI_TAR} -C /usr/local/bin; \
    chmod +x /usr/local/bin/pixi

RUN /usr/local/bin/pixi --version

FROM --platform=$TARGETPLATFORM $BASE_IMAGE
COPY --from=builder --chown=root:root --chmod=0555 /usr/local/bin/pixi /usr/local/bin/pixi
RUN printf '\neval "$(pixi completion --shell bash)"\n' >> /root/.bashrc
ENV PATH="/root/.pixi/bin:${PATH}"
