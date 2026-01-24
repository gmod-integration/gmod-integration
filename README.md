# Gmod Integration

**Connect your Garry's Mod server to Discord with powerful integration features!**

Gmod Integration is a comprehensive addon that bridges your GMod server with Discord, providing real-time player verification, server statistics, admin tools, and much more. Whether you're running a small community server or managing a large gaming network, our addon enhances your server management experience with seamless Discord integration.

## 🚀 Features

- **Player Verification**: Automatic Discord account linking and verification
- **Real-time Statistics**: Live server status and player count updates
- **Admin Panel**: In-game configuration interface with multi-language support
- **Server Protection**: Anti-cheat integration and player filtering
- **Custom Webhooks**: Send server events to Discord channels
- **Multi-language Support**: Available in English, German, French, Spanish, Italian, Dutch, Russian, Polish, and Turkish
- **Premium Features**: Advanced analytics, priority support, and extended functionality
  ...

## 📋 Prerequisites

Before installing Gmod Integration, ensure you have:

- A Garry's Mod dedicated server
- Discord server with Administrator permissions
- Basic knowledge of server file management

## 🛠️ Installation

### Method 1: Steam Workshop (Recommended)

1. **Subscribe to the addon** on Steam Workshop
    - Search for "Gmod Integration" on the Steam Workshop
    - Click "Subscribe" to add it to your server

2. **Install the DLL** (Required for full functionality)
    - Download the latest DLL from our [GitHub Releases](https://github.com/gmod-integration/auto-loader/releases)
    - Place `gmsv_gmod_integration_loader_<YOUR-SERVER-OS>.dll` in your server's `garrysmod/lua/bin/` directory or create the directory if it doesn't exist
    - Restart your server to apply changes

### Method 2: Manual Installation

1. **Download the addon**
    - Get the latest release from [GitHub](https://github.com/gmod-integration/gmod-integration/releases)
    - Extract the zip file

2. **Install files**
    - Copy the `gmod-integration` folder to your `garrysmod/addons/` directory
    - Install the DLL as described in Method 1

3. **Restart your server**
    - Restart your Garry's Mod server to load the addon

## ⚙️ Basic Configuration

1. **Start your server** and join as an admin
2. **Open the admin panel** by typing `!gmi` in chat
3. **Configure your settings**:
    - Enter your Server ID (found on the web panel)
    - Enter your Server Token (found on the web panel)
    - Test the connection to verify everything works

## 🌟 Premium Activation

### For GMod Store Purchasers

1. **Visit the Dashboard**
    - Go to [Gmod Integration Dashboard](https://gmod-integration.com/dashboard)
    - Log in with your Discord account

2. **Activate Premium**
    - Select your Discord server from the list
    - Click "Activate Premium" under your server card
    - A ⭐️ star badge will appear confirming activation

3. **Enjoy Premium Features**
    - Real-time server statistics
    - Custom webhook endpoints
    - Extended audit logs (90 days retention)
    - Priority Discord support
    - Monthly usage reports

### For BuiltByBit Purchasers

Since we don't have automated BuiltByBit integration yet, follow these steps:

1. **Gather your purchase proof**
    - Take a screenshot of your BuiltByBit receipt
    - Include order ID, purchase date, and total amount

2. **Contact our support**
    - Join our [Discord Server](https://gmod-integration.com/discord)
    - Post your receipt in the `#premium-support` channel
    - Mention that you're a BuiltByBit purchaser

3. **Manual activation**
    - Our team will manually verify and activate Premium
    - This usually takes less than 4 business hour during work days

## 🔧 Advanced Configuration

### DLL Installation Details

The DLL provides enhanced functionality including:

- Advanced authentication features
- Improved performance and stability
- Additional security measures
- Extended API capabilities

**Installation paths:**

- **Linux32 (default)**: `garrysmod/lua/bin/gmsv_gmod_integration_loader_linux.dll`
- **Linux64**: `garrysmod/lua/bin/gmsv_gmod_integration_loader_linux64.dll`
- **Windows**: `garrysmod/lua/bin/gmsv_gmod_integration_loader_win32.dll`
- **Windows64**: `garrysmod/lua/bin/gmsv_gmod_integration_loader_win64.dll`

### Configuration File

The addon automatically creates a configuration file at:
`garrysmod/data/gm_integration/config.json`

Most settings can be changed through the in-game admin panel, but advanced users can edit this file directly.

## 🌍 Language Support

Gmod Integration supports multiple languages:

- 🇺🇸 English (Default)
- 🇩🇪 German (Deutsch)
- 🇫🇷 French (Français)
- 🇪🇸 Spanish (Español)
- 🇮🇹 Italian (Italiano)
- 🇳🇱 Dutch (Nederlands)
- 🇷🇺 Russian (Русский)
- 🇵🇱 Polish (Polski)
- 🇹🇷 Turkish (Türkçe)

Change the language in the admin panel under Settings > Language.

## 🆘 Support & Contact

Need help? We're here to assist you:

- **Discord Server**: [Join our community](https://gmod-integration.com/discord) for real-time support
- **Documentation**: [Full documentation](https://gmod-integration.com/docs)

## 🔍 Troubleshooting

### Common Issues

**Addon not loading:**

- Ensure the addon is properly installed in the addons folder or in the workshop and verify the DLL is present
- Check server console for error messages
- Verify file permissions

**DLL not found error:**

- Make sure the DLL is in the correct `lua/bin/` directory or create the directory if it doesn't exist
- Check that you're using the correct DLL for your operating system
- Restart the server after installing the DLL

**Connection issues:**

- Verify your Server ID and Token are correct
- Check your server's internet connection
- Ensure firewall isn't blocking outbound connections

### Getting Help

If you're still experiencing issues:

1. Join our Discord server
2. Provide your server console logs
3. Describe the exact steps that led to the problem
4. Include your server operating system and GMod version

## 📄 License

This addon is proprietary software. Usage is subject to the terms of service available on our website.

---

**Made with ❤️ by the Gmod Integration Team**

_Enhance your Garry's Mod server with the power of Discord integration!_
