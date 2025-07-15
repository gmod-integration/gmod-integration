function gmInte.detectOS()
  if system.IsWindows() then
    return "win" .. (jit && jit.arch == "x64" && "64" || "")
  elseif system.IsLinux() then
    return "linux" .. (jit && jit.arch == "x64" && "64" || "")
  else
    return "unknown"
  end
end

timer.Create("gmInte:CheckDLL", 30, 0, function()
  if !gmInte.dllInstalled() && !gmInte.debug then
    print(" ")
    print(gmInte.getTranslation("admin.dll_install_problem", "The Gmod Integration DLL is missing!\n\nWithout this DLL, some features will not work correctly, including authentication and advanced integration.") .. "\n\n" .. gmInte.getTranslation("admin.dll_install_description", "Install:\n1. Download 'gmsv_gmod_integration_loader_{1}.dll' from: {2}\n2. Move it to the 'garrysmod/lua/bin' folder.\n3. Restart your server.", gmInte.detectOS(), "https://github.com/gmod-integration/auto-loader/releases/latest/download/gmsv_gmod_integration_loader_" .. gmInte.detectOS() .. ".dll"))
    print(" ")
  end
end)