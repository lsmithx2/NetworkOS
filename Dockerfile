FROM ubuntu:22.04

# Set Metadata
LABEL maintainer="LSmithx2"
LABEL version="1.0"
LABEL description="NetworkOS - Custom LXDE Desktop for Networking"

ENV DEBIAN_FRONTEND=noninteractive
# Set the hostname inside the container environment
ENV HOSTNAME=NetworkOS

# 1. Install Base, Desktop, and VNC
RUN apt-get update && apt-get install -y \
    lxde tigervnc-standalone-server novnc websockify \
    wget curl gpg git python3 sudo \
    # Networking Suite
    nmap wireshark tcpdump iperf3 mtr net-tools iputils-ping dnsutils \
    && apt-get clean

# 2. Install Browsers (Firefox & Chrome)
RUN apt-get install -y firefox && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-archive-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable && \
    sed -i 's|HERE/chrome\"|HERE/chrome\" --no-sandbox --disable-dev-shm-usage|g' /opt/google/chrome/google-chrome

# 3. Install WineHQ
RUN dpkg --add-architecture i386 && mkdir -pm755 /etc/apt/keyrings && \
    wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources && \
    apt-get update && apt-get install --install-recommends -y winehq-stable

# 4. NetworkOS Branding
# Custom Terminal Prompt: root@NetworkOS:~#
RUN echo "export PS1='\[\e[1;32m\]root@NetworkOS\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]# '" >> /root/.bashrc && \
    echo "echo '------------------------------------------'" >> /root/.bashrc && \
    echo "echo '     Welcome to NetworkOS v1.0          '" >> /root/.bashrc && \
    echo "echo '------------------------------------------'" >> /root/.bashrc

# 5. Startup Script
RUN echo "#!/bin/bash\n\
rm -rf /tmp/.X* /tmp/.X11-unix\n\
vncserver -SecurityTypes None -geometry 1280x720 :1\n\
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 8080" > /start.sh && chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
