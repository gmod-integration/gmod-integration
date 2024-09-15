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

local report_bug_title = language.GetPhrase("gmod_integration.report_bug.title")
report_bug_title = report_bug_title == "gmod_integration.report_bug.title" && "Report Bug" || report_bug_title
list.Set("DesktopWindows", "GmodIntegration:DesktopWindows:ReportBug", {
    icon = "gmod_integration/logo_context_report.png",
    title = report_bug_title,
    width = 960,
    height = 700,
    onewindow = true,
    init = function(icon, window)
        window:Close()
        gmInte.openReportBug()
    end
})

list.Set("DesktopWindows", "GmodIntegration:DesktopWindows:SendScreen", {
    icon = "gmod_integration/logo_context_screen.png",
    title = "Dsc Screen",
    width = 960,
    height = 700,
    onewindow = true,
    init = function(icon, window)
        window:Close()
        gmInte.contextScreenshot()
    end
})