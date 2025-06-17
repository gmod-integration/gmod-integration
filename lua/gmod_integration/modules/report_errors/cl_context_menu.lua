list.Set("DesktopWindows", "GmodIntegration:DesktopWindows:ReportBug", {
  icon = "gmod_integration/logo_context_report.png",
  title = "Report Bug",
  width = 960,
  height = 700,
  onewindow = true,
  init = function(icon, window)
      window:Close()
      gmInte.openReportBug()
  end
})