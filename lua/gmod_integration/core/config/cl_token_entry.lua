-- The saved credential never reaches this control. Only a new, explicitly entered value is sent.
function gmInte.configureTokenEntry(input, configured, save, delay)
    input:SetText("")
    input:SetPlaceholderText(configured &&
        gmInte.getTranslation("admin.server_token_configured", "Token configured. Enter a replacement.") ||
        gmInte.getTranslation("admin.server_token_placeholder", "Paste your server token here."))
    local revision = 0
    input.OnChange = function(self)
        revision = revision + 1
        local currentRevision = revision
        local value = self:GetValue()
        if value == "" then return end
        timer.Simple(delay || 0.5, function()
            if !IsValid(self) || currentRevision != revision || self:GetValue() != value then return end
            save(value)
        end)
    end
end
