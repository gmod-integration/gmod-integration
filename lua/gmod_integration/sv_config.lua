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

// Websocket
/*
    This is a premium feature, you can buy premium on our website: https://gmod-integration.com/premium
    Websocket allow you to made a real-time connection between your server and our servers.
    And so use the real-time features of our addon (like the chat syncronization, role syncronization, ...)
*/
gmInte.config.websocket = false // If true, the addon will use the websocket instead of the http requests

// Chat
gmInte.config.chatTriggerAll = false // If true, the addon will sync all the messages in the chat
gmInte.config.chatTrigger = {
/* Example:
    ["/example "] = {
        ["prefix"] = "[Example] ", // The prefix of the message
        ["show_rank"] = false, // If true, the addon will show the rank of the player in the prefix
        ["anonymous"] = false, // If true, the addon will not show the name and the avatar of the player in the message
        ["channel"] = "admin_sync_chat" // If set, the addon will use a custom channel to sync the message (use in multi chat syncronization)
    },
    ["/admin_chat "] = {
        ["prefix"] = "[Admin Chat]",
        ["show_rank"] = true,
        ["channel"] = "discord_channel_id_admin_chat"
    },
*/
    ["// "] = {
        ["prefix"] = "",
        ["show_rank"] = false,
        ["anonymous"] = false,
        ["custom_id"] = "admin_sync_chat"
    },
    ["/ano "] = {
        ["anonymous"] = true,
    },
} // Trigger to sync the messages in a discord channel (the key is the trigger and the value is the replacement)

// Other
gmInte.config.forcePlayerLink = false // If true, the addon will force the players to link their discord account to their steam account before playing
gmInte.config.supportLink = "" // The link of your support (shown when a player do not have the requiments to join the server)

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