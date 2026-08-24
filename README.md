# ⚡ DNS Switcher

[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue.svg)](https://github.com/Mr-Meshky/dns-switcher)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%2F%20Zsh%20%2F%20Fish-green.svg)](https://github.com/Mr-Meshky/dns-switcher)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/Mr-Meshky/dns-switcher)

A fast, interactive, and CLI-ready DNS manager for **Linux** 🐧 and **macOS** . Easily switch between curated Iranian anti-sanction DNS servers, fast global DNS, and ad-blocking providers, or benchmark and test latency on the fly.

[🇮🇷 راهنمای فارسی در انتهای صفحه](#راهنمای-فارسی)

---

## ✨ Features

- 🎯 **Interactive TUI Menu**: Keyboard navigation (`↑`/`↓` or `j`/`k`, `Enter`, `q`).
- ⚡ **Non-Interactive CLI Mode**: Set, clear, or inspect DNS directly with commands like `change-dns set 403`.
- 🇮🇷 **Rich Anti-Sanction Providers**: Curated collection including Shecan, 403, Electro, Radar Game, Begzar, Shelter, Level15, Hostiran, Vanilla, and Pishrun.
- 🌍 **Global & Security Providers**: Cloudflare, Google, Quad9, Control D, OpenDNS, and AdGuard (Ad-blocking & Family safety).
- 📶 **Auto Interface Detection**: Dynamically detects the active network service/interface on macOS (Wi-Fi, Ethernet, Hotspot) and Linux.
- 🚀 **Live Latency / Ping Tester**: Measure ping times to all DNS servers with color-coded latency indicators.
- 🧪 **Anti-Sanction Benchmark**: Tests resolution against blocked/sanctioned domains (Docker Hub, OpenAI, Android Developers, Figma, Gradle).
- 🧹 **Automatic DNS Cache Flush**: Flushes OS-level DNS cache instantly upon switching.
- 💾 **Persistent Custom DNS**: Add and remove custom DNS profiles directly from the menu or CLI.

---

## 📦 Installation

### Option 1: Quick Install (Git Clone)

```bash
git clone https://github.com/Mr-Meshky/dns-switcher.git
cd dns-switcher
chmod +x install.sh
./install.sh
```

After installation, reload your shell:
```bash
source ~/.zshrc   # for zsh
# or
source ~/.bashrc  # for bash
```

---

## 🚀 Usage

### 1. Interactive Menu (With Instant Hotkeys)
Simply run:
```bash
change-dns
# or
dns-switcher
```
Inside the menu, you can use `↑`/`↓` and `Enter`, or press **single hotkeys** instantly:
- `1` to `9` : Instantly set the corresponding DNS provider (e.g. `1` for Shecan, `2` for 403, `3` for Electro)
- `0` : Instantly reset DNS to default (DHCP)
- `p` : Run live ping test to all servers
- `t` : Run anti-sanction benchmark
- `f` : Flush DNS cache
- `q` : Exit

### 2. Fast CLI Commands (Instant Switch)

```bash
# Ultra-fast numeric shortcuts
change-dns 1              # Set Shecan
change-dns 2              # Set 403 Online
change-dns 3              # Set Electro
change-dns 0              # Reset to default (DHCP)

# Direct provider name
change-dns 403
change-dns shecan
change-dns electro
change-dns cloudflare

# Direct custom IP
change-dns set 1.1.1.1 1.0.0.1

# Tools & Utilities
change-dns ping           # Test latency to all servers
change-dns test           # Test anti-sanction resolution benchmark
change-dns status         # View current active DNS & interface
change-dns list           # List all available DNS profiles
change-dns flush          # Flush local DNS cache
change-dns clear          # Reset DNS to default (DHCP)
```

---

## 🌐 Supported DNS Providers

### 🛡️ Anti-Sanction & Developer (Iran)
| Provider | Primary IP | Secondary IP | Purpose |
| :--- | :--- | :--- | :--- |
| **Shecan (شکن)** | `178.22.122.100` | `185.51.200.2` | General & Dev anti-sanction |
| **403 Online (سامانه ۴۰۳)** | `10.202.10.202` | `10.202.10.102` | Developers, AI & IT tools |
| **Electro (الکترو)** | `78.157.42.100` | `78.157.42.101` | Gaming & Developer anti-sanction |
| **Radar Game (رادار بازی)** | `10.202.10.10` | `10.202.10.11` | Gaming low latency |
| **Begzar (بگذر)** | `185.55.226.26` | `185.55.225.25` | Anti-sanction bypass |
| **Shelter (شلتر)** | `185.86.136.241` | `185.86.136.242` | Developer anti-sanction |
| **Level 15 (لول ۱۵)** | `185.105.238.167` | `185.105.239.167` | Gaming & anti-sanction |
| **Hostiran (هاست‌ایران)** | `172.29.0.100` | `172.29.2.100` | Developer tools |
| **Vanilla DNS** | `10.202.10.100` | `10.202.10.101` | Anti-sanction bypass |
| **Pishrun (پیشران)** | `5.202.100.100` | `5.202.100.101` | AI & Dev tools |

### 🌍 Global & Privacy
| Provider | Primary IP | Secondary IP | Purpose |
| :--- | :--- | :--- | :--- |
| **Cloudflare** | `1.1.1.1` | `1.0.0.1` | Fast & privacy-focused |
| **Google Public DNS** | `8.8.8.8` | `8.8.4.4` | High reliability |
| **Quad9** | `9.9.9.9` | `149.112.112.112` | Security & malware protection |
| **Control D** | `76.76.2.0` | `76.76.10.0` | Next-gen high speed |
| **OpenDNS (Cisco)** | `208.67.222.222` | `208.67.220.220` | Security & stability |

### 🚫 AdBlock & Family Safety
| Provider | Primary IP | Secondary IP | Purpose |
| :--- | :--- | :--- | :--- |
| **AdGuard DNS** | `94.140.14.14` | `94.140.15.15` | Blocks ads & trackers |
| **AdGuard Family** | `94.140.14.15` | `94.140.15.16` | Blocks ads + adult content |

---

<h2 id="راهنمای-فارسی">🇮🇷 راهنمای فارسی</h2>

ابزار **DNS Switcher** یک اسکریپت حرفه‌ای و سبک برای سیستم‌عامل‌های **لینوکس** و **مک** است که به شما امکان می‌دهد سریعاً بین DNSهای ضدتحریم ایرانی، سرورهای جهانی و مسدودکننده تبلیغات جابجا شوید.

### نحوه نصب:
```bash
git clone https://github.com/Mr-Meshky/dns-switcher.git
cd dns-switcher
chmod +x install.sh
./install.sh
```

### دستورات پرکاربرد:
- `change-dns` : باز کردن منوی تعاملی و گرافیکی ترمینال
- `change-dns set 403` : تنظیم سریع روی سامانه ۴۰۳
- `change-dns set shecan` : تنظیم سریع روی شکن
- `change-dns set electro` : تنظیم سریع روی الکترو
- `change-dns clear` : ریست DNS به حالت اولیه (DHCP)
- `change-dns ping` : اندازه‌گیری تاخیر و پینگ به تمامی DNSها
- `change-dns test` : بنچمارک و تست باز کردن سرویس‌های تحریمی مثل داکر، هوش مصنوعی، فیگما و اندروید
- `change-dns status` : نمایش وضعیت و DNS فعال سیستم

---

## 👤 Author

Developed by **[MrMeshky](https://mrmeshky.ir)** with ❤️.
Contribute and star the project on [GitHub](https://github.com/Mr-Meshky/dns-switcher)!
