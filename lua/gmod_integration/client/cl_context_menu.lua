list.Set("DesktopWindows", "GmodIntegration:DesktopWindows", {
	icon = "gmod_integration/logo_context.png",
    title = "GM Integration",
	width		= 960,
	height		= 700,
	onewindow	= true,
    init = function(icon, window)
        window:Close()
        gmInte.openAdminConfig()
    end
    }
)