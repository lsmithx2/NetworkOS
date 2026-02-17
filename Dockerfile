FROM ubuntu:22.04

LABEL maintainer="NetworkOS Project"

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1024x768
ENV NOVNC_PORT=8080

# Optional noVNC basic auth (set NOVNC_PASSWORD at runtime to enable)
ENV NOVNC_USER=admin
ENV NOVNC_PASSWORD=""

# Wine defaults (you can override at runtime)
ENV WINEDEBUG=-all

# Angry IP Scanner version (GitHub release .deb)
ARG IPSCAN_VERSION=3.9.3

# 0) Enable 32-bit architecture for Wine (needed for many Windows apps)
RUN dpkg --add-architecture i386

# 1) Desktop + VNC/noVNC + browsers + network toolkit + ping + wine
# Fixes:
# - enable Universe (masscan often lives there)
# - preseed wireshark prompt (even if not on desktop, package can prompt)
# - add nginx + htpasswd tooling for noVNC password protection (reliable across distros)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends software-properties-common debconf-utils ca-certificates curl gnupg; \
    add-apt-repository -y universe; \
    echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      # Desktop
      lxde-core lxterminal dbus dbus-x11 x11-xserver-utils \
      # VNC/noVNC
      tigervnc-standalone-server novnc websockify \
      # noVNC auth front-end (WebSocket-safe)
      nginx-light apache2-utils \
      # Base utilities
      wget curl gpg git python3 sudo ca-certificates \
      # Ping / ICMP utilities
      iputils-ping iputils-tracepath \
      # Networking tools (expanded)
      iproute2 traceroute mtr dnsutils \
      nmap masscan arp-scan netdiscover fping \
      tcpdump tshark tcpflow wireshark \
      iperf3 ethtool ipcalc net-tools lsof whois \
      netcat-openbsd socat \
      # Angry IP Scanner dependency (Java)
      openjdk-17-jre \
      # Wine (Windows apps) + common runtime deps
      wine64 wine32 winetricks cabextract fonts-wine winbind \
      # Wine GUI/runtime deps that often fix "wine not working" in containers
      libgl1 libgl1-mesa-dri libasound2 libasound2-plugins libpulse0 \
      fonts-dejavu-core fonts-dejavu-extra \
      # Browser(s)
      firefox \
      # Chrome runtime deps that often matter in minimal images
      fonts-liberation libatk-bridge2.0-0 libatk1.0-0 libcups2 \
      libdrm2 libgbm1 libgtk-3-0 libnss3 libxss1 libxcomposite1 libxrandr2 \
      libxdamage1 libxkbcommon0 xdg-utils; \
    rm -rf /var/lib/apt/lists/*

# 1b) Install Angry IP Scanner from GitHub release (.deb)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    curl -fsSL -o /tmp/ipscan.deb \
      "https://github.com/angryip/ipscan/releases/download/${IPSCAN_VERSION}/ipscan_${IPSCAN_VERSION}_amd64.deb"; \
    dpkg -i /tmp/ipscan.deb || apt-get -f install -y; \
    rm -f /tmp/ipscan.deb; \
    rm -rf /var/lib/apt/lists/*

# 2) Install Google Chrome
RUN set -eux; \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor > /usr/share/keyrings/google-archive-keyring.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-archive-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    rm -rf /var/lib/apt/lists/*; \
    sed -i 's|HERE/chrome"|HERE/chrome" --no-sandbox --disable-dev-shm-usage --disable-gpu|g' \
      /opt/google/chrome/google-chrome

# 3) Desktop Icons
# - Removed Wireshark from desktop
# - Added Angry IP Scanner to desktop
RUN mkdir -p /root/Desktop && \
    cat > /root/Desktop/angry-ip-scanner.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Angry IP Scanner
Exec=ipscan
Icon=ipscan
Categories=Network;
Terminal=false
EOF
RUN chmod +x /root/Desktop/angry-ip-scanner.desktop

# 3b) Update LXDE menu (ensure new apps show up)
RUN update-desktop-database /usr/share/applications || true

# 4) noVNC default landing page (autoconnect + scaling)
RUN echo '<html><head><meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale"></head></html>' \
  > /usr/share/novnc/index.html

# 5) Wallpaper (SAFE: include file in build context)
COPY vista.jpg /usr/share/backgrounds/vista.jpg

RUN mkdir -p /root/.config/pcmanfm/LXDE && \
    cat > /root/.config/pcmanfm/LXDE/desktop-items-0.conf <<'EOF'
[*]
wallpaper_mode=stretch
wallpaper=/usr/share/backgrounds/vista.jpg
desktop_bg=#000000
show_documents=0
show_trash=1
show_mounts=1
EOF

# 6) Entrypoint:
# - fixes LXDE "No session for pid" by launching LXDE under dbus-launch
# - initializes Wine prefix once
# - implements reliable noVNC password protection using nginx basic auth (WebSocket-safe)
RUN cat > /entrypoint.sh <<'EOF'
#!/usr/bin/env bash
set -e

echo "[INFO] Starting container entrypoint..."

DISP_NUM="${DISPLAY#:}"
VNC_PORT="$((5900 + DISP_NUM))"

# External port (published)
NOVNC_PORT="${NOVNC_PORT:-8080}"

# Internal port for websockify when auth is enabled
NOVNC_INTERNAL_PORT=6080

rm -rf /tmp/.X11-unix /tmp/.X*-lock || true
touch /root/.Xauthority || true

# Provide a runtime dir (prevents session/logind related errors in containers)
export XDG_RUNTIME_DIR="/tmp/runtime-root"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Create VNC xstartup that launches LXDE under a DBus session
mkdir -p /root/.vnc
cat > /root/.vnc/xstartup <<'XEOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export XDG_RUNTIME_DIR="/tmp/runtime-root"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

exec dbus-launch --exit-with-session startlxde
XEOF
chmod +x /root/.vnc/xstartup

# Start VNC server
vncserver "${DISPLAY}" \
  -SecurityTypes None \
  -geometry "${VNC_RESOLUTION}" \
  -xstartup /root/.vnc/xstartup

echo "[INFO] VNC up on localhost:${VNC_PORT} (display ${DISPLAY})"

# Initialize Wine on first boot (needs DISPLAY/X available)
if [ ! -d /root/.wine ]; then
  echo "[INFO] Initializing Wine prefix..."
  (export DISPLAY="${DISPLAY}"; wineboot --init >/tmp/wineboot.log 2>&1 || true) &
fi

# Start noVNC
# If NOVNC_PASSWORD is set, use nginx basic auth in front of websockify
if [ -n "${NOVNC_PASSWORD:-}" ]; then
  echo "[INFO] noVNC auth enabled via nginx basic auth"

  # Start websockify bound to localhost only
  websockify \
    --web /usr/share/novnc/ \
    --wrap-mode ignore \
    "127.0.0.1:${NOVNC_INTERNAL_PORT}" \
    "127.0.0.1:${VNC_PORT}" &

  # Create htpasswd file
  mkdir -p /etc/nginx
  htpasswd -bc /etc/nginx/.htpasswd "${NOVNC_USER:-admin}" "${NOVNC_PASSWORD}"

  # Nginx config with websocket support + basic auth
  cat > /etc/nginx/conf.d/novnc.conf <<NGINXCONF
server {
  listen ${NOVNC_PORT};
  server_name _;

  auth_basic "NetworkOS";
  auth_basic_user_file /etc/nginx/.htpasswd;

  location / {
    proxy_pass http://127.0.0.1:${NOVNC_INTERNAL_PORT};
    proxy_http_version 1.1;

    # WebSocket headers
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";

    # Forwarded headers
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
NGINXCONF

  nginx -t
  exec nginx -g "daemon off;"
else
  echo "[INFO] noVNC auth disabled (direct websockify)"

  exec websockify \
    --web /usr/share/novnc/ \
    --wrap-mode ignore \
    "0.0.0.0:${NOVNC_PORT}" \
    "localhost:${VNC_PORT}"
fi
EOF
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
