local function testConError(ply, cmd, args)
  if ply && !ply:gmIntIsAdmin() then
    if SERVER then return end
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
end

concommand.Add("gmod_integration_test_error", testConError)
concommand.Add("gmi_test_error", testConError)