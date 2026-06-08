# ============================================================
# CHYing Agent — Docker Environment
# Base: Kali Linux Rolling with security research tools
# ============================================================

FROM kalilinux/kali-rolling:latest
LABEL maintainer="your-name <your-email>"
LABEL description="CHYing Agent — AI-powered CTF/Auto-Pentest Docker Environment"

# ============================================================
# Build Arguments & Environment
# ============================================================
ARG http_proxy=http://host.docker.internal:7897
ARG https_proxy=http://host.docker.internal:7897

ENV http_proxy=$http_proxy
ENV https_proxy=$https_proxy
ENV no_proxy=localhost,127.0.0.1
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-21
ENV GHIDRA_HOME=/opt/tools/ghidra
ENV CHYING_IN_CONTAINER=1

# ============================================================
# Stage 1: Base System & Development Tools
# ============================================================
RUN set -eux; \
    rm -f /etc/apt/sources.list.d/*.sources; \
    if [ -n "${http_proxy:-}" ]; then \
        echo "Acquire::http::Proxy \"$http_proxy\";" > /etc/apt/apt.conf.d/99proxy; \
        echo "Acquire::https::Proxy \"$https_proxy\";" >> /etc/apt/apt.conf.d/99proxy; \
    fi; \
    echo "deb http://mirrors.aliyun.com/kali kali-rolling main contrib non-free non-free-firmware" > /etc/apt/sources.list; \
    apt-get update -o Acquire::Retries=10 -o Acquire::http::Timeout=60 || \
        apt-get update -o Acquire::Retries=10; \
    apt-get install -y --no-install-recommends --fix-missing \
        python3 python3-venv python3-pip python-is-python3 python3-dev \
        openjdk-21-jdk \
        build-essential gcc g++ make cmake \
        libgmp-dev libmpfr-dev libmpc-dev \
        curl git perl gnupg2 wget sudo jq unzip tree file xxd \
        libnet-ssleay-perl libio-socket-ssl-perl libcrypt-ssleay-perl libssl-dev ca-certificates \
        iputils-ping dnsutils iproute2 net-tools traceroute \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ============================================================
# Stage 2: Security Scanning Tools
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    nmap sqlmap netcat-traditional tcpdump \
    whatweb nuclei \
    smbclient smbmap python3-impacket \
    socat proxychains4 sslscan \
    hydra hashid \
    libimage-exiftool-perl cewl \
    subfinder ffuf arjun wpscan \
    commix \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* || true

# Wordlists
RUN git clone --depth=1 https://github.com/gh0stkey/Web-Fuzzing-Box.git /usr/share/wordlists/Web-Fuzzing-Box || true \
    && rm -rf /usr/share/wordlists/Web-Fuzzing-Box/.git

# ============================================================
# Stage 3: Forensics & Reversing Tools
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    binwalk foremost sleuthkit p7zip-full unrar fcrackzip \
    steghide pngcheck imagemagick sox libsox-fmt-all ffmpeg \
    tshark john hashcat hexedit \
    ruby ruby-dev qpdf poppler-utils bulk-extractor \
    gdb gdb-multiarch radare2 \
    crackmapexec evil-winrm chisel impacket-scripts \
    postgresql tmux \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* || true

# SecLists
RUN for i in 1 2 3 4 5; do \
        apt-get update -o Acquire::Retries=10 && \
        apt-get install -y --no-install-recommends seclists && \
        break || sleep 5; \
    done; \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Metasploit
RUN for i in 1 2 3 4 5; do \
        apt-get update -o Acquire::Retries=10 && \
        apt-get install -y --no-install-recommends metasploit-framework && \
        break || sleep 5; \
    done; \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* || true

RUN gem install zsteg || true

# ============================================================
# Stage 4: Python & Ruby Libraries for CTF
# ============================================================
RUN pip3 install --break-system-packages --ignore-installed \
    "mcp>=1.5.0,<2.0.0" \
    "requests>=2.28.0,<3.0.0" \
    -i https://pypi.tuna.tsinghua.edu.cn/simple/

RUN mkdir -p /opt/tools

RUN ln -sf $(ls -d /usr/lib/jvm/java-21-openjdk-* | head -1) /usr/lib/jvm/java-21

RUN pip3 install --break-system-packages --ignore-installed \
    requests aiohttp jinja2 'httpx[cli]' ratelimit beautifulsoup4 \
    websockets clairvoyance lxml pycryptodomex pycryptodome gmpy2 \
    sympy z3-solver factordb-pycli pwntools ropper volatility3 \
    scapy pillow pyzbar numpy scipy pyjwt base58 \
    -i https://pypi.tuna.tsinghua.edu.cn/simple/

RUN pip3 install --break-system-packages --ignore-installed chardet \
    -i https://pypi.tuna.tsinghua.edu.cn/simple/ || true

RUN pip3 install --break-system-packages --force-reinstall "capstone==5.0.3" \
    -i https://pypi.tuna.tsinghua.edu.cn/simple/

# ============================================================
# Stage 5: Specialized CTF Tools (Git clones)
# ============================================================
RUN git clone --depth=1 https://github.com/ticarpi/jwt_tool.git /opt/tools/jwt_tool || true \
    && rm -rf /opt/tools/jwt_tool/.git \
    && if [ -f /opt/tools/jwt_tool/jwt_tool.py ]; then chmod +x /opt/tools/jwt_tool/jwt_tool.py; fi

RUN git clone --depth=1 https://github.com/epinna/tplmap.git /opt/tools/tplmap || true \
    && rm -rf /opt/tools/tplmap/.git \
    && if [ -f /opt/tools/tplmap/tplmap.py ]; then chmod +x /opt/tools/tplmap/tplmap.py; fi

RUN git clone --depth=1 https://github.com/s0md3v/XSStrike.git /opt/tools/XSStrike || true \
    && rm -rf /opt/tools/XSStrike/.git \
    && if [ -d /opt/tools/XSStrike ]; then \
        cd /opt/tools/XSStrike && \
        pip3 install --break-system-packages -r requirements.txt || true; \
    fi

RUN git clone --depth=1 https://github.com/tarunkant/Gopherus.git /opt/tools/Gopherus || true \
    && rm -rf /opt/tools/Gopherus/.git \
    && if [ -f /opt/tools/Gopherus/gopherus.py ]; then chmod +x /opt/tools/Gopherus/gopherus.py; fi

RUN git clone --depth=1 https://github.com/ambionics/phpggc.git /opt/tools/phpggc || true \
    && rm -rf /opt/tools/phpggc/.git \
    && if [ -f /opt/tools/phpggc/phpggc ]; then chmod +x /opt/tools/phpggc/phpggc; fi

RUN git clone --depth=1 https://github.com/RsaCtfTool/RsaCtfTool.git /opt/tools/RsaCtfTool || true \
    && rm -rf /opt/tools/RsaCtfTool/.git \
    && if [ -d /opt/tools/RsaCtfTool ]; then \
        cd /opt/tools/RsaCtfTool && \
        pip3 install --break-system-packages -r requirements.txt || true; \
    fi

RUN git clone --depth=1 https://github.com/pwndbg/pwndbg.git /opt/tools/pwndbg || true \
    && if [ -d /opt/tools/pwndbg ]; then \
        cd /opt/tools/pwndbg && ./setup.sh || true; \
    fi

# Nuclei Templates
RUN git clone --depth=1 https://github.com/projectdiscovery/nuclei-templates.git /root/.local/nuclei-templates || true \
    && rm -rf /root/.local/nuclei-templates/.git

# Vulhub (lightweight: keep only config files)
RUN git clone --depth=1 https://github.com/vulhub/vulhub.git /opt/tools/vulhub || true \
    && cd /opt/tools/vulhub \
    && find . -type f \( -name "docker-compose.*" -o -name "Dockerfile" -o -name "*.sh" \
        -o -name "*.sql" -o -name "*.conf" -o -name "*.xml" -o -name "*.yml" \
        -o -name "*.yaml" -o -name "*.jar" -o -name "*.war" -o -name "*.tar" \
        -o -name "*.gz" -o -name "*.zip" -o -name "*.key" -o -name "*.pem" \
        -o -name "*.crt" -o -name "*.properties" -o -name "*.ini" -o -name "*.cfg" \
        -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" \
        -o -name "*.svg" -o -name "*.ico" -o -name "*.pdf" -o -name "*.lock" \
        -o -name ".gitignore" -o -name ".dockerignore" -o -name "*.css" \
        -o -name "LICENSE*" -o -name "Makefile" \) -delete 2>/dev/null; \
    find . -type d -empty -delete 2>/dev/null; \
    rm -rf .git

# Ruby tools
RUN gem install one_gadget || true

# Python tools
RUN pip3 install --break-system-packages ROPGadget || true

RUN rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED

# ysoserial
RUN mkdir -p /opt/tools/ysoserial && \
    wget -qO /opt/tools/ysoserial/ysoserial-all.jar \
    "https://github.com/frohoff/ysoserial/releases/download/v0.0.6/ysoserial-all.jar" || true

# JADX
ENV JADX_VERSION="1.5.5"
RUN wget -qO /tmp/jadx.zip \
    "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" && \
    mkdir -p /opt/tools/jadx && \
    unzip -q /tmp/jadx.zip -d /opt/tools/jadx && \
    chmod +x /opt/tools/jadx/bin/jadx /opt/tools/jadx/bin/jadx-gui && \
    ln -sf /opt/tools/jadx/bin/jadx /usr/local/bin/jadx && \
    rm -f /tmp/jadx.zip || true

# ProjectDiscovery tools (katana, httpx)
RUN set -x; \
    arch=$(uname -m); \
    if [ "$arch" = "x86_64" ]; then platform="linux_amd64"; \
    elif [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]; then platform="linux_arm64"; \
    else platform="linux_amd64"; fi; \
    KATANA_URL=$(curl -sL https://api.github.com/repos/projectdiscovery/katana/releases/latest \
      | grep -o '"browser_download_url": *"[^"]*"' | grep "${platform}.zip" | head -1 | cut -d'"' -f4) || true; \
    if [ -n "$KATANA_URL" ]; then \
      wget -qO /tmp/katana.zip "$KATANA_URL" && \
      unzip -q /tmp/katana.zip -d /tmp/katana_extracted && \
      find /tmp/katana_extracted -type f -name katana -exec mv {} /usr/local/bin/katana \; && \
      chmod +x /usr/local/bin/katana; \
      rm -rf /tmp/katana.zip /tmp/katana_extracted; \
    fi; \
    HTTPX_URL=$(curl -sL https://api.github.com/repos/projectdiscovery/httpx/releases/latest \
      | grep -o '"browser_download_url": *"[^"]*"' | grep "${platform}.zip" | head -1 | cut -d'"' -f4) || true; \
    if [ -n "$HTTPX_URL" ]; then \
      wget -qO /tmp/httpx.zip "$HTTPX_URL" && \
      unzip -q /tmp/httpx.zip -d /tmp/httpx_extracted && \
      find /tmp/httpx_extracted -type f -name httpx -exec mv {} /usr/local/bin/httpx \; && \
      chmod +x /usr/local/bin/httpx; \
      rm -rf /tmp/httpx.zip /tmp/httpx_extracted; \
    fi; \
    echo "Done installing ProjectDiscovery tools"

# ============================================================
# Stage 6: Ghidra & GhidraMCP (download from GitHub releases)
# ============================================================
# Ghidra 12.0.3
RUN wget -qO /tmp/ghidra.zip \
    "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.0.3_build/ghidra_12.0.3_PUBLIC_20260210.zip" && \
    mkdir -p /opt/tools/ghidra && \
    unzip -qo /tmp/ghidra.zip -d /tmp/ghidra_extracted && \
    mv /tmp/ghidra_extracted/ghidra_12.0.3_PUBLIC/* /opt/tools/ghidra/ && \
    rm -rf /tmp/ghidra.zip /tmp/ghidra_extracted || \
    echo "WARNING: Ghidra download failed. You can manually download and COPY it."

# GhidraMCP (bethington/ghidra-mcp headless server)
# Build from source or download pre-built release
RUN git clone --depth=1 --branch main \
    https://github.com/bethington/ghidra-mcp.git /tmp/ghidra-mcp-src && \
    mkdir -p /opt/tools/ghidra-mcp && \
    if [ -f /tmp/ghidra-mcp-src/GhidraMCP.jar ]; then \
        cp /tmp/ghidra-mcp-src/GhidraMCP.jar /opt/tools/ghidra-mcp/; \
    fi; \
    if [ -d /tmp/ghidra-mcp-src/lib ]; then \
        cp -r /tmp/ghidra-mcp-src/lib /opt/tools/ghidra-mcp/; \
    fi; \
    if [ -f /tmp/ghidra-mcp-src/bridge_mcp_ghidra.py ]; then \
        cp /tmp/ghidra-mcp-src/bridge_mcp_ghidra.py /opt/tools/ghidra-mcp/; \
    fi; \
    if [ -f /tmp/ghidra-mcp-src/requirements.txt ]; then \
        cp /tmp/ghidra-mcp-src/requirements.txt /opt/tools/ghidra-mcp/; \
    fi; \
    if [ -d /tmp/ghidra-mcp-src/ghidra_scripts ]; then \
        cp -r /tmp/ghidra-mcp-src/ghidra_scripts /opt/tools/ghidra-mcp/; \
    fi; \
    cp -r /tmp/ghidra-mcp-src/docker /opt/tools/ghidra-mcp/ 2>/dev/null || true; \
    for f in AGENTS.md CHANGELOG.md CLAUDE.md CONTRIBUTING.md LICENSE README.md; do \
        [ -f "/tmp/ghidra-mcp-src/$f" ] && cp "/tmp/ghidra-mcp-src/$f" /opt/tools/ghidra-mcp/; \
    done; \
    rm -rf /tmp/ghidra-mcp-src || true; \
    # Install Python bridge dependencies
    if [ -f /opt/tools/ghidra-mcp/requirements.txt ]; then \
        pip3 install --break-system-packages -r /opt/tools/ghidra-mcp/requirements.txt || true; \
    fi

# ============================================================
# Stage 7: Utility Wrappers & Final Cleanup
# ============================================================
RUN echo '#!/bin/bash\npython3 /opt/tools/jwt_tool/jwt_tool.py "$@"' > /usr/local/bin/jwt-tool && chmod +x /usr/local/bin/jwt-tool || true && \
    echo '#!/bin/bash\npython3 /opt/tools/tplmap/tplmap.py "$@"' > /usr/local/bin/tplmap && chmod +x /usr/local/bin/tplmap || true && \
    echo '#!/bin/bash\npython3 /opt/tools/XSStrike/xsstrike.py "$@"' > /usr/local/bin/xsstrike && chmod +x /usr/local/bin/xsstrike || true && \
    echo '#!/bin/bash\npython3 /opt/tools/Gopherus/gopherus.py "$@"' > /usr/local/bin/gopherus && chmod +x /usr/local/bin/gopherus || true && \
    echo '#!/bin/bash\n/opt/tools/phpggc/phpggc "$@"' > /usr/local/bin/phpggc && chmod +x /usr/local/bin/phpggc || true && \
    echo '#!/bin/bash\npython3 /opt/tools/RsaCtfTool/RsaCtfTool.py "$@"' > /usr/local/bin/rsactftool && chmod +x /usr/local/bin/rsactftool || true && \
    echo '#!/bin/bash\njava -jar /opt/tools/ysoserial/ysoserial-all.jar "$@"' > /usr/local/bin/ysoserial && chmod +x /usr/local/bin/ysoserial || true

# Cleanup build dependencies to reduce image size
RUN apt-get purge -y --auto-remove \
    build-essential gcc g++ cmake python3-dev \
    libgmp-dev libmpfr-dev libmpc-dev libssl-dev ruby-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ============================================================
# Stage 8: Entrypoint & Runtime Config
# ============================================================
WORKDIR /root

COPY docker/entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

EXPOSE 8089/tcp 8766/tcp

ENTRYPOINT ["/opt/entrypoint.sh"]
