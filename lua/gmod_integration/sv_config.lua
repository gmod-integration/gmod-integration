/*
    Informations:
        This file is prioritized over the configuration file in data/gmod-integration/config.json if id and token are set in this file.
        We don't recommend to use a static version of our addon, you should use the workshop version instead.

    Add Server:
        0. Add the bot to your guild if it's not already done: https://gmod-integration.com/invite
        1. Go to our dashboard and Login with Discord: https://gmod-integration.com/login
        2. Go to the "Servers" page: https://gmod-integration.com/config/servers and click on "Create Server"
        3. Copy the ID and Token of your server and paste them in this file
        4. Everything is ready, you can now restart your server

    To go further, you can check the documentation: https://docs.gmod-integration.com

    WARNING:
        NEVER SHARE THE TOKEN OF YOUR SERVER WITH ANYONE,
        IF ANY PROBLEM OCCURS, GO TO OUR WEBSITE AND FOLLOW THE INSTRUCTIONS:
        https://gmod-integration.com/emergency
*/

//
// General
//

// API Connection
gmInte.config.id = "" // Server ID
gmInte.config.token = "" // Server Token

// Other
gmInte.config.forcePlayerLink = false // If true, the addon will force the players to link their discord account to their steam account before playing
gmInte.config.supportLink = "" // The link of your support (shown when a player do not have the requiments to join the server)

//
// Syncronization
//

// Punishment
gmInte.config.syncBan = true // If true, the addon will sync gmod bans with discord bans (and vice versa)
gmInte.config.syncTimeout = false // If true, the addon will sync gmod timeouts with discord timeouts (and vice versa)
gmInte.config.syncKick = false // If true, the addon will sync gmod kicks with discord kicks (and vice versa)

// Ban
gmInte.config.filterOnBan = true // If true, the addon will filter the players according to their ban status

//
// Materials
//

gmInte.config.redownloadMaterials = false // If true, the addon will redownload the materials of the addon (useful if you have a problem with the materials)

//
// Debug & Development
//

gmInte.config.debug = false // If true, the addon will show debug informations in the console
gmInte.config.devInstance = false // If true, the addon will use the development instance of API and Websocket