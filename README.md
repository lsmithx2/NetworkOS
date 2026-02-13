# 🌐 NetworkOS

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E9433F?style=for-the-badge&logo=ubuntu&logoColor=white)

**NetworkOS** is a custom, browser-accessible Linux desktop environment (LXDE) built for network analysis, security testing, and sysadmin tasks.



[Image of a network topology diagram]


## 🚀 One-Command Launch

You don't need to install a VNC client. NetworkOS runs entirely in your web browser.

### 1. Build
```bash
docker build -t networkos .

### Run
```bash
docker run -d -p 8080:8080 --name networkos-lab networkos
