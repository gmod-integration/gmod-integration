/*
    Informations:
        This file is prioritized over the configuration file in data/gmod-integration/config.json until the id are set.
        We don't recommend to use a static version of our addon, you should use the workshop version instead.

    Add Server:
        1. Go to our dashboard and Login with Discord: https://gmod-integration.com/login
        2. Go to the "Servers" page: https://gmod-integration.com/servers
        3. Click on "Add Server"
        4. Fill the form and click on "Add Server"
        5. Copy the ID and Token of your server and paste them in this file
        6. Everything is ready, you can now restart your server

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

// Chat
gmInte.config.chatTriggerAll = false // If true, the addon will sync all the messages in the chat
gmInte.config.chatTrigger = {
    ["// "] = true,
} // If chatTriggerAll is false, the addon will sync the messages that start with one of the following triggers

// Other
gmInte.config.forcePlayerLink = false // If true, the addon will force the players to link their discord account to their steam account before playing

//
// Syncronization
//

// General
gmInte.config.syncChat = false // If true, the addon will sync the chat gmod with a selected channel on discord (need to be enabled on the dashboard)
gmInte.config.syncPlayerStat = true // If true, the addon will sync the player stats (kills, deaths, playtime, ...)

// Punishment
gmInte.config.syncBan = true // If true, the addon will sync gmod bans with discord bans (and vice versa)
gmInte.config.syncTimeout = false // If true, the addon will sync gmod timeouts with discord timeouts (and vice versa)
gmInte.config.syncKick = false // If true, the addon will sync gmod kicks with discord kicks (and vice versa)

//
// Player Filter
//

// Trust Factor
gmInte.config.minimalTrust = 30 // The minimal trust factor of an user to be able to join the server (0 to 100)
gmInte.config.filterOnTrust = true // If true, the addon will filter the players according to their trust factor

// Ban
gmInte.config.filterOnBan = true // If true, the addon will filter the players according to their ban status

//
// Other
//

// Debug
gmInte.config.debug = false // If true, the addon will print debug informations in the console