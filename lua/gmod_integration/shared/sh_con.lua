concommand.Add("gmi_test_error", function(ply, cmd, args)
  if !SERVER && !LocalPlayer():gmIntIsAdmin() then
    print("[Gmod Integration] Missing permissions to run this command")
    return
  end

  if #args == 0 then
    error("This is a test error")
  else
    if args[1] == "loop" then
      hook.Add("Think", "gmInte:TestError:Loop", function() error("This is a test error") end)
      timer.Simple(5, function() hook.Remove("Think", "gmInte:TestError:Loop") end)
    elseif args[1] == "crash" then
      while true do
        error("This is a crash error")
      end
    else
      error("This is a test error")
    end
  end
end)