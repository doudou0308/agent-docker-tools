FROM public.ecr.aws/docker/library/debian:13-slim@sha256:ab3b3c8c5159eebfca4376430132d53c4d425f869c765ecbe47177a030da575d

ARG PIP_INDEX_URL=https://pypi.org/simple

ENV GHIDRA_HOME=/opt/tools/ghidra \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    ADT_IN_CONTAINER=1

RUN set -eu; \
    apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update; \
    DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=3 install -y --no-install-recommends \
        binutils ca-certificates curl file gdb openjdk-21-jdk-headless python3-venv unzip xxd; \
    rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    workdir=$(mktemp -d); \
    cd "$workdir"; \
    release=https://github.com/bethington/ghidra-mcp/releases/download/v7.0.0; \
    wheel=ghidra_mcp_bridge-7.0.0-py3-none-any.whl; \
    curl -fLSs --retry 3 -o ghidra.zip \
        https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip; \
    curl -fLSs --retry 3 -o mcp.zip "$release/GhidraMCP-7.0.0.zip"; \
    curl -fLSs --retry 3 -o "$wheel" "$release/$wheel"; \
    printf '%s\n' \
        'ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db  ghidra.zip' \
        'd133c4c869a0d9f605c1c9426bf5d9064772a6947ccecde0f42fbbffecf1d812  mcp.zip' \
        "a75050061d0d1514d4b11e6288ea7575c09ab6125a1394c33fe349fb7658bbae  $wheel" \
        | sha256sum --check --strict; \
    mkdir -p /opt/tools /opt/tools/ghidra-mcp; \
    unzip -q ghidra.zip -d /opt/tools; \
    mv /opt/tools/ghidra_12.1.4_PUBLIC "$GHIDRA_HOME"; \
    unzip -q "$GHIDRA_HOME"/Extensions/Ghidra/*_Jython.zip -d "$GHIDRA_HOME/Ghidra/Extensions"; \
    unzip -q mcp.zip -d /opt/tools/ghidra-mcp; \
    ln -s GhidraMCP/lib/GhidraMCP-7.0.0.jar /opt/tools/ghidra-mcp/GhidraMCP.jar; \
    python3 -m venv /opt/tools/ghidra-mcp/venv; \
    /opt/tools/ghidra-mcp/venv/bin/pip install --no-cache-dir --index-url "$PIP_INDEX_URL" 'mcp==1.28.1' "./$wheel"; \
    rm -rf "$workdir"

COPY LICENSE /usr/share/doc/agent-docker-tools/copyright
COPY docker/licenses/ghidra-mcp.LICENSE /usr/share/doc/ghidra-mcp/copyright
COPY docker/licenses/ghidra-mcp.NOTICE /usr/share/doc/ghidra-mcp/NOTICE
COPY docker/entrypoint.sh /opt/entrypoint.sh
COPY docker/stop-children.sh /opt/stop-children.sh
COPY docker/healthcheck.py /opt/tools/ghidra-mcp/healthcheck.py
RUN sed -i 's/\r$//' /opt/entrypoint.sh /opt/stop-children.sh && chmod 0755 /opt/entrypoint.sh

WORKDIR /root
EXPOSE 8766/tcp
HEALTHCHECK --interval=15s --timeout=8s --start-period=120s --retries=3 \
    CMD ["/opt/tools/ghidra-mcp/venv/bin/python", "/opt/tools/ghidra-mcp/healthcheck.py"]
ENTRYPOINT ["/opt/entrypoint.sh"]
