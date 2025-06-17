list.Set("DesktopWindows", "GmodIntegration:DesktopWindows:SendScreen", {
  icon = "gmod_integration/logo_context_screen.png",
  title = "Screenshot",
  width = 960,
  height = 700,
  onewindow = true,
  init = function(icon, window)
      window:Close()
      gmInte.contextScreenshot()
  end
})