/*
    Informations:
        This file is prioritized over the configuration file in data/gmod-integration/config.json if id and token are set in this file.
        We don't recommend to use a static version of our addon, you should use the workshop version instead.

    Add Server:
        0. Add the bot to your guild if it's not already done: https://gmod-integration.com/invite
        1. Go to our dashboard and Login with Discord: https://gmod-integration.com/login you should be redirected to the dashboard
        2. Add the bot to your guild and click on "Add to Guild" or select your guild if it's already added
        3. Go to the "Servers" page and click on "Create Server"
        4. Copy the ID and Token of your server and paste them in this file
        5 Everything is ready, you can now restart your server

    To go further, you can check the documentation: https://docs.gmod-integration.com
*/
// API Connection
gmInte.config.id = "" // Server ID
gmInte.config.token = "" // Server Token
gmInte.config.websocketFQDN = "ws.gmod-integration.com" // The FQDN of the websocket server
gmInte.config.apiFQDN = "api.gmod-integration.com" // The FQDN of the API server
// Punishment
gmInte.config.syncBan = true // If true, the addon will sync gmod bans with discord bans (and vice versa)
gmInte.config.syncTimeout = false // If true, the addon will sync gmod timeouts with discord timeouts (and vice versa)
gmInte.config.syncKick = false // If true, the addon will sync gmod kicks with discord kicks (and vice versa)
// Ban
gmInte.config.filterOnBan = true // If true, the addon will filter the players according to their ban status
// Materials
gmInte.config.redownloadMaterials = false // If true, the addon will redownload the materials of the addon (useful if you have a problem with the materials)
// Debug & Development
gmInte.config.debug = false // If true, the addon will show debug informations in the console
// Security
gmInte.config.forcePlayerLink = false // If true, the addon will force the players to link their discord account to their steam account before playing
gmInte.config.verifyOnJoin = false // If true, the addon will verify the players when they join the server or on player ready
gmInte.config.verifyOnReadyKickTime = 600 // The time in seconds before kicking a player that is not verified (0 to disable)
gmInte.config.verifyFamilySharing = false // If true, the addon will verify the family sharing of the players
gmInte.config.clientBranch = "any" // The branch of the addon that the clients should use (none, dev, prerelease, x86-64)
// Other
gmInte.config.supportLink = "" // The link of your support (shown when a player do not have the requiments to join the server)
gmInte.config.maintenance = false // If true, the addon will only allow the players with the "gmod-integration.maintenance" permission to join the server
gmInte.config.language = "en" // The language of the addon (en, fr, de, es, it, tr, ru)
gmInte.config.logTimestamp = "%H:%M:%S" // The timestamp format of the logs
gmInte.config.dllBranch = "main" // The download branch of gmod integration via dll (Use at your own risk, this is not recommended for production servers)
gmInte.config.adminRank = {
    // How can edit the configuration of the addon / bypass the maintenance mode
    ["superadmin"] = true,
}