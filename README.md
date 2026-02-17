# 🌐 NetworkOS

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![LXDE](https://img.shields.io/badge/Desktop-LXDE-blue?style=for-the-badge)
![noVNC](https://img.shields.io/badge/noVNC-Browser%20Access-green?style=for-the-badge)
![Wine](https://img.shields.io/badge/Wine-Windows%20Support-purple?style=for-the-badge)

---

## 🚀 Overview

**NetworkOS** is a browser-accessible Linux desktop (LXDE) built for:

- 🌐 Network analysis  
- 🔐 Security testing  
- 🖥 Sysadmin operations  
- 🧪 Lab environments  
- 🪟 Running Windows tools via Wine  

Everything runs inside a Docker container and is accessed via **noVNC** in your browser.

---

# 📦 Features

## 🖥 Desktop Environment
- LXDE lightweight GUI
- Browser access via noVNC
- Custom wallpaper support
- Angry IP Scanner desktop shortcut
- Auto-scaling display

---

## 🌐 Network Toolkit

### Discovery & Scanning
- `nmap`
- `masscan`
- `arp-scan`
- `netdiscover`
- `fping`
- **Angry IP Scanner (GUI)**

### Packet Analysis
- Wireshark (installed)
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

### Utilities
- `netcat`
- `socat`
- `ethtool`
- `ipcalc`
- `net-tools`
- `lsof`

---

# 🪟 Wine & Windows Application Support

Wine is fully configured with GUI management tools.

## Installed Wine Tools

- **Winecfg** (Wine configuration)
- **Wine File Manager**
- **Winetricks (GUI)**
- **Q4Wine (Wine environment manager)**
- **PlayOnLinux (installation wizard)**

These tools allow users to:

- Install Windows applications via GUI
- Manage separate Wine prefixes
- Install .NET / DirectX runtimes
- Configure DLL overrides
- Switch Windows versions

---

## Running Windows Applications

### Install via GUI
Use:
- PlayOnLinux
- Q4Wine
- Winetricks GUI

### Manual install
```bash
wine installer.exe
```

### Launch application
```bash
wine program.exe
```

Wine prefix is stored at:

```
/root/.wine
```

Persist `/root` to retain installations.

---

# 🔐 noVNC Password Protection

NetworkOS uses **nginx-based Basic Authentication** in front of noVNC.

To enable:

```bash
docker run -d \
  -p 8080:8080 \
  -e NOVNC_USER=admin \
  -e NOVNC_PASSWORD=SuperSecret123 \
  --name networkos \
  networkos
```

You will see a browser login prompt.

If `NOVNC_PASSWORD` is not set, authentication is disabled.

---

# 🚀 Quick Start

## Build

```bash
docker build -t networkos .
```

## Run

```bash
docker run -d \
  -p 8080:8080 \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --name networkos \
  networkos
```

Open:

```
http://localhost:8080
```

---

# 💾 Persistence

To persist desktop data, Wine installs, browsers, etc:

```bash
docker run -d \
  -p 8080:8080 \
  -v $(pwd)/networkos_data:/root \
  -e NOVNC_PASSWORD=mypass \
  --name networkos \
  networkos
```

---

# 🐳 Required Docker Capabilities

Some tools require extra privileges:

```bash
--cap-add NET_ADMIN
--cap-add NET_RAW
```

To scan host LAN (Linux only):

```bash
--network host
```

---

# ☸ Kubernetes / Northflank / Cloud Deployments

This image is resource-heavy.

### Minimum recommended resources:

- 4GB RAM minimum
- 6–8GB recommended
- 2 vCPU minimum

If you see pods marked:

```
Evicted
```

It is typically due to memory pressure.

### Suggested resource limits:

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

# ⚠ Performance Notes

High memory consumers:

- Chrome
- Firefox
- Wine
- Java (Angry IP Scanner)
- Wireshark GUI

For production, consider a lighter variant without:

- Chrome
- Wine
- Wireshark GUI

---

# 🔒 Security Notes

- VNC runs internally without password.
- nginx protects noVNC when `NOVNC_PASSWORD` is set.
- Always use HTTPS when exposing publicly.
- Recommended:
  - Reverse proxy
  - VPN
  - IP allowlisting
  - Cloudflare Zero Trust

---

# 🧪 Use Cases

- Network lab environment
- Remote troubleshooting desktop
- Windows-only vendor tools via Wine
- Security training lab
- Temporary forensic workstation

---

# 🌍 Access

After running:

```
http://your-server-ip:8080
```

Login prompt appears if password is enabled.

---

# 📜 License

MIT License (or your preferred license)
