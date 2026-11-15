<h1 align="center">
  <br>
  DynamicBar
  <br>
</h1>


<p align="center">
  <a title="Crowdin" target="_blank" href="https://crowdin.com/project/dynamicbar"><img src="https://badges.crowdin.net/dynamicbar/localized.svg"></a>
  <img src="https://github.com/DynamicBar/DynamicBar/actions/workflows/cicd.yml/badge.svg" alt="DynamicBar Build & Test" style="margin-right: 10px;" />
  <a href="https://discord.gg/c8JXA7qrPm">
    <img src="https://dcbadge.limes.pink/api/server/https://discord.gg/c8JXA7qrPm?style=flat" alt="Discord Badge" />
  </a>
  <a href="https://www.ko-fi.com/alexander5015">
    <img src="https://srv-cdn.himpfen.io/badges/kofi/kofi-flat.svg" alt="Ko-Fi" />
  </a>
</p>

Say hello to **DynamicBar**, the coolest way to make your MacBook’s notch the star of the show! Say goodbye to ordinary status bars: with DynamicBar, your notch transforms into a dynamic music control center, complete with a vibrant visualizer and all the essential music controls you need. But that’s just the start! DynamicBar also offers calendar integration, a handy file shelf with AirDrop support, a complete MacOS HUD replacement and more!

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d5f69c1-6e7b-4bc2-a6f1-bb9e27cf88a8" alt="Demo GIF" />
</p>

<!--https://github.com/user-attachments/assets/19b87973-4b3a-4853-b532-7e82d1d6b040-->
---
<!--## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#-roadmap)
- [Building from Source](#building-from-source)
- [Contributing](#-contributing)
- [Join our Discord Server](#join-our-discord-server)
- [Star History](#star-history)
- [Buy us a coffee!](#buy-us-a-coffee)
- [Acknowledgments](#-acknowledgments)-->

## Installation

1. Download the latest **`DynamicBar.dmg`** from [Releases](https://github.com/techashutosh03/DynamicBar/releases/latest).
2. Open `DynamicBar.dmg` and drag **DynamicBar** into your `/Applications` folder.
3. Because this is a 100% free open-source project without a paid Apple Developer account, run this single command in Terminal before opening the app for the first time:

```bash
xattr -dr com.apple.quarantine "/Applications/DynamicBar.app"
```
4. Launch **DynamicBar** from your Applications folder!

## Usage

- Launch the app, and voilà—your notch is now the coolest part of your screen.
- Hover over the notch to see it expand and reveal all its secrets.
- Use the controls to manage your music like a rockstar.
- Click the star in your menu bar to customize your notch to your heart's content.

## 📋 Roadmap
- [x] Playback live activity 🎧
- [x] Calendar integration 📆
- [x] Reminders integration ☑️
- [x] Mirror 📷
- [x] Charging indicator and current percentage 🔋
- [x] Customizable gesture control 👆🏻
- [x] Shelf functionality with AirDrop 📚
- [x] Notch sizing customization, finetuning on different display sizes 🖥️
- [x] System HUD replacements (volume, brightness, backlight) 🎚️💡⌨️
- [ ] Bluetooth Live Activity (connect/disconnect for bluetooth devices) 
- [ ] Weather integration ⛅️
- [ ] Customizable Layout options 🛠️
- [ ] Lock Screen Widgets 🔒
- [ ] Extension system 🧩
- [ ] Notifications (under consideration) 🔔
<!-- - [ ] Clipboard history manager 📌 `Extension` -->
<!-- - [ ] Download indicator of different browsers (Safari, Chromium browsers, Firefox) 🌍 `Extension`-->
<!-- - [ ] Customizable function buttons 🎛️ -->
<!-- - [ ] App switcher 🪄 -->

<!-- ## 🧩 Extensions
> [!NOTE]
> We’re hard at work on some awesome extensions! Stay tuned, and we’ll keep you updated as soon as they’re released. -->

## Building from Source

### Prerequisites

- **macOS 15.6 or later**
- **Xcode 26 or later**

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/techashutosh03/DynamicBar.git
   cd DynamicBar
   ```

2. **Open the Project in Xcode**:
   ```bash
   open DynamicBar.xcodeproj
   ```

3. **Build and Run**:
    - Click the "Run" button or press `Cmd + R`. Watch the magic unfold!

## 🤝 Contributing

We’re all about good vibes and awesome contributions! Read [CONTRIBUTING.md](CONTRIBUTING.md) to learn how you can join the fun!

## Join our Discord Server

<a href="https://discord.gg/GvYcYpAKTu" target="_blank"><img src="https://iili.io/28m3GHv.png" alt="Join Discord Server!" style="height: 60px !important;width: 217px !important;" ></a>

## Star History
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/DynamicBar/org-star-chart-updater/main/projects/DynamicBar/chart-dark.svg">
   <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/DynamicBar/org-star-chart-updater/main/projects/DynamicBar/chart-light.svg">
   <img src="https://raw.githubusercontent.com/DynamicBar/org-star-chart-updater/main/projects/DynamicBar/chart-light.svg" alt="DynamicBar GitHub star history">
 </picture>

## Support us on Ko-fi!
<!-- <a href="https://www.buymeacoffee.com/jfxh67wvfxq" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-red.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a> -->
<a href="https://www.ko-fi.com/alexander5015" target="_blank"><img src="https://github.com/user-attachments/assets//a76175ef-7e93-475a-8b67-4922ba5964c2" alt="Support us on Ko-fi" style="height: 70px !important;width: 346px !important;" ></a>

## 🎉 Acknowledgments

We would like to express our gratitude to the authors and maintainers of the open-source projects that made this possible. 

## Notable Projects
- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** –  An open-source project that allowed us to use the Now Playing source in macOS 15.4+
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** – An open-source project that has been instrumental in developing the first version of the "Shelf" feature in DynamicBar.

For a full list of licenses and attributions, please see the [Third-Party Licenses](./THIRD_PARTY_LICENSES.md) file.

### Icon credits: [@maxtron95](https://github.com/maxtron95)
### Website credits: [@himanshhhhuv](https://github.com/himanshhhhuv)

- **SwiftUI**: For making us look like coding wizards.
- **You**: For being awesome and checking out **DynamicBar**!

