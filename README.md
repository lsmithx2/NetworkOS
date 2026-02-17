# 🌐 NetworkOS

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![LXDE](https://img.shields.io/badge/Desktop-LXDE-blue?style=for-the-badge)
![noVNC](https://img.shields.io/badge/noVNC-Browser%20Access-green?style=for-the-badge)
![Wine](https://img.shields.io/badge/Wine-Windows%20Support-purple?style=for-the-badge)

---

## 🚀 Overview

**NetworkOS** is a browser-accessible Linux desktop (LXDE) designed for:

- 🌐 Network analysis  
- 🔐 Security testing  
- 🖥 Sysadmin tasks  
- 🧪 Lab environments  
- 🪟 Running Windows tools via Wine  

Everything runs inside a Docker container and is accessible via **noVNC** in your browser.

---

# 📦 Features

## 🖥 Desktop Environment
- LXDE lightweight GUI
- Browser access via noVNC
- Custom wallpaper support
- Angry IP Scanner shortcut on desktop
- Auto-scaling display

## 🌐 Network Toolkit

### Discovery & Scanning
- `nmap`
- `masscan`
- `arp-scan`
- `netdiscover`
- `fping`
- Angry IP Scanner (GUI)

### Packet Analysis
- `Wireshark`
- `tcpdump`
- `tshark`
- `tcpflow`

### Connectivity & Diagnostics
- `ping`
- `tracepath`
- `traceroute`
- `mtr`
- `iperf3`
- `dnsutils`
- `whois`

### Network Utilities
- `netcat`
- `socat`
- `ethtool`
- `ipcalc`
- `net-tools`
- `lsof`

---

# 🌍 Browsers

- Firefox
- Google Chrome

---

# 🪟 Windows Application Support

- Wine (64-bit + 32-bit)
- Winetricks
- Suitable for many legacy Windows networking tools

---

# 🚀 Quick Start

## 🔨 Build

```bash
docker build -t networkos .
```

---

## ▶ Run (Basic)

```bash
docker run -d \
  -p 8080:8080 \
  --name networkos-lab \
  networkos
```

Open:

```
http://localhost:8080
```

---

# 🔐 Enable Password Protection (Recommended)

```bash
docker run -d \
  -p 8080:8080 \
  -e NOVNC_USER=admin \
  -e NOVNC_PASSWORD=SuperSecret123 \
  --name networkos-lab \
  networkos
```

If `NOVNC_PASSWORD` is not set, noVNC runs without authentication.

⚠ If exposing publicly, use HTTPS via reverse proxy and IP restrictions.

---

# 💾 Persistence

```bash
docker run -d \
  -p 8080:8080 \
  -v $(pwd)/networkos_data:/root \
  -e NOVNC_PASSWORD=mypass \
  --name networkos-lab \
  networkos
```

This preserves:
- Desktop files
- Wine installs
- Browser data
- User configs

---

# 🐳 Recommended Docker Flags

Some tools require extra capabilities:

```bash
docker run -d \
  -p 8080:8080 \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  networkos
```

To scan the host LAN (Linux only):

```bash
docker run -d \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  networkos
```

---

# ☸ Kubernetes / Northflank / Cloud Notes

This image is **heavy** (full desktop + Chrome + Firefox + Wine + Java).

### Recommended minimum resources:

- **4GB RAM minimum**
- **6–8GB recommended**
- 2 vCPU minimum

If you see pods marked:

```
Evicted
```

It is almost always due to:

- Memory pressure (OOM)
- Node disk pressure
- Resource limits too low

### Recommended Kubernetes memory request/limit:

```yaml
resources:
  requests:
    memory: "4Gi"
    cpu: "1000m"
  limits:
    memory: "8Gi"
    cpu: "2000m"
```

---

# 🏥 Optional Healthcheck

Recommended addition to Dockerfile:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080 || exit 1
```

---

# ⚠ Performance Considerations

Running a full GUI desktop inside Kubernetes is resource-intensive.

High RAM consumers:
- Chrome
- Firefox
- Wine
- Java (Angry IP Scanner)
- Wireshark GUI

---

# 🪟 Running Windows Tools

```bash
wine mytool.exe
```

Wine data lives in:

```
/root/.wine
```

Persist `/root` to keep installations.

---

# 🔒 Security Notes

- VNC server runs without internal password.
- noVNC can be protected with `NOVNC_PASSWORD`.
- For internet exposure:
  - Use HTTPS reverse proxy
  - IP allowlisting
  - VPN-only access
  - Cloudflare Zero Trust

---

# 🎯 Use Cases

- Network penetration testing lab
- Remote Wireshark workstation
- Vendor Windows utilities via Wine
- Training environments
- Temporary troubleshooting desktop

---

# 🌍 Access

After running:

```
http://your-server-ip:8080
```

Login prompt appears if `NOVNC_PASSWORD` is set.

---

# 📜 License

MIT License

---
