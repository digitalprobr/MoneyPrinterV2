FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    MOZ_HEADLESS=1 \
    PATH="/opt/venv/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        build-essential \
        ffmpeg \
        fonts-liberation \
        golang-go \
        imagemagick \
        libasound2t64 \
        libdbus-glib-1-2 \
        libgbm1 \
        libgtk-3-0 \
        libnss3 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        libxt6 \
        python3 \
        python3-dev \
        python3-venv \
        libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) firefox_platform="linux64" ;; \
        arm64) firefox_platform="linux64-aarch64" ;; \
        *) echo "Unsupported target architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://download.mozilla.org/?product=firefox-latest&os=${firefox_platform}&lang=en-US" -o /tmp/firefox.tar.xz; \
    tar -xJf /tmp/firefox.tar.xz -C /opt; \
    ln -s /opt/firefox/firefox /usr/local/bin/firefox; \
    rm /tmp/firefox.tar.xz

WORKDIR /app
COPY requirements.txt ./requirements.txt
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install -r requirements.txt

RUN useradd --create-home --uid 1000 --shell /usr/sbin/nologin app \
    && mkdir -p /app/.mp /app/Songs /data/firefox-profile \
    && chown -R app:app /app /data/firefox-profile

COPY --chown=app:app . /app
USER app

CMD ["python", "-u", "src/main.py"]
