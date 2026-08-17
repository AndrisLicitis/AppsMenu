# AppsMenu

A lightweight macOS application launcher and menu for quickly accessing your installed apps.

AppsMenu provides a simple way to organize and launch macOS applications, with user-defined categories and a native macOS app icon.

## ✨ Features

* 🚀 Quickly access installed macOS applications
* 📂 Organize applications into custom categories
* 💾 Category settings are stored in `UserDefaults`
* 🔄 Settings survive reinstallations
* 🎨 Native macOS application icon
* 🔐 Local ad-hoc code signing during installation
* 🔎 Refreshes macOS Launch Services after installation
* 🧩 Simple installation and uninstall scripts
* 🛠️ Open source under the GNU GPL v3.0 license

## 📸 Preview

![AppsMenu](AppIcon-preview.png)

## 📦 Installation

### Requirements

* macOS
* Swift / Apple's command-line development tools

### Install

Download or clone the repository:

```bash
git clone https://github.com/AndrisLicitis/AppsMenu.git
cd AppsMenu
```

Make the scripts executable:

```bash
chmod +x install.sh uninstall.sh
```

Run the installer:

```bash
./install.sh
```

The installer builds `AppsMenu.app`, installs it to `/Applications`, applies a local ad-hoc signature and refreshes macOS Launch Services.

### Uninstall

From the project directory, run:

```bash
./uninstall.sh
```

## 🧑‍💻 Development

The main application source code is located in:

```text
Sources/
└── AppsMenu.swift
```

The project is intentionally lightweight so that it can be easily understood, modified and improved.

If you have an idea for a new feature, bug fix or performance improvement, feel free to open an Issue or submit a Pull Request.

## 🤝 Contributing

Contributions are welcome!

You can contribute by:

* 🐛 Reporting bugs
* 💡 Suggesting new features
* ⚡ Improving performance
* 🎨 Improving the user interface
* 🧹 Cleaning up or improving the code
* 🧪 Adding tests
* 🔧 Submitting Pull Requests

### Pull Request workflow

1. Fork the repository.
2. Create a new branch for your changes.
3. Make and test your changes.
4. Commit your changes.
5. Open a Pull Request.

Please keep changes focused and explain what your contribution improves.

## 🗺️ Roadmap

Possible future improvements include:

* Better application search
* Keyboard shortcuts
* Favorites
* Drag-and-drop category management
* Improved application discovery
* More customization options
* Improved macOS integration
* Performance improvements
* Additional UI improvements

The roadmap is open to community ideas.

## 📄 License

AppsMenu is licensed under the **GNU General Public License v3.0**.

See the [`LICENSE`](LICENSE) file for the full license text.

## ⭐ Support the Project

If you find AppsMenu useful, consider giving the repository a ⭐ on GitHub.

Bug reports, ideas and Pull Requests are also very welcome.

---

**AppsMenu** — a simple, lightweight way to organize and launch your macOS apps.
