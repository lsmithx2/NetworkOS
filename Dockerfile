FROM ubuntu:22.04

LABEL maintainer="NetworkOS Project"
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1280x720

# 1. Install LXDE, VNC, NoVNC, and Networking tools
RUN apt-get update && apt-get install -y \
    lxde tigervnc-standalone-server novnc websockify \
    wget curl gpg git python3 sudo net-tools iputils-ping \
    nmap wireshark tcpdump iperf3 mtr dnsutils firefox \
    && apt-get clean

# 2. Install Google Chrome with sandbox fix
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-archive-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable && \
    sed -i 's|HERE/chrome\"|HERE/chrome\" --no-sandbox --disable-dev-shm-usage|g' /opt/google/chrome/google-chrome

# 3. Install WineHQ
RUN dpkg --add-architecture i386 && mkdir -pm755 /etc/apt/keyrings && \
    wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
    apt-get update && apt-get install --install-recommends -y winehq-stable

# 4. Set vnc.html as Default + AUTO-RESIZE logic
# This creates an index.html that redirects to vnc.html with the scaling parameter enabled
RUN echo '<html><!-- Developed by LSmithx2 --><head><title>NetworkOS VNC</title><meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale"></head></html>' > /usr/share/novnc/index.html

# 5. Startup Script (Created inside the image)
RUN echo '#!/bin/bash\n\
rm -rf /tmp/.X11-unix /tmp/.X*-lock\n\
vncserver -SecurityTypes None -geometry $VNC_RESOLUTION $DISPLAY\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 8080' > /entrypoint.sh && \
chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
