local oldPrint = print
function print(...)
    local msg = table.concat({...}, " ")
    if gmInte.enableConsoleLiveExporter then
      gmInte.websocket:send("console_live_exporter", {
          data = msg
      }, nil, true)
    end
    oldPrint(...)
end