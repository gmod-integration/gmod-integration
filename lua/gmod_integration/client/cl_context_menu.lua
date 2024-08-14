list.Set("DesktopWindows", "GmodIntegration:DesktopWindows", {
    icon = "gmod_integration/logo_context.png",
    title = "GM Integration",
    width = 960,
    height = 700,
    onewindow = true,
    init = function(icon, window)
        window:Close()
        gmInte.openAdminConfig()
    end
})

list.Set("DesktopWindows", "GmodIntegration:DesktopWindows:ReportBug", {
    icon = "gmod_integration/logo_context_report.png",
    title = language.GetPhrase("gmod_integration.report_bug.title", "Report Bug"),
    width = 960,
    height = 700,
    onewindow = true,
    init = function(icon, window)
        window:Close()
        gmInte.openReportBug()
    end
})