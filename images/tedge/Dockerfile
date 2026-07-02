ARG TEST_IMAGE=ghcr.io/thin-edge/tedge-demo-main-systemd:latest
FROM ${TEST_IMAGE}

# Install the Modbus Plugin from the prebuilt package (produced by `just build`
# and provided in the dist/ directory / the dist-packages CI artifact).
COPY dist/*.deb /tmp/
RUN apt-get update \
    && apt-get install -y --no-install-recommends /tmp/*.deb \
    && rm -f /tmp/*.deb \
    && rm -rf /var/lib/apt/lists/*

# Add configuration plugin config
COPY images/tedge/config/tedge-configuration-plugin.toml /etc/tedge/plugins/tedge-configuration-plugin.toml
COPY images/tedge/config/tedge-log-plugin.toml /etc/tedge/plugins/tedge-log-plugin.toml
