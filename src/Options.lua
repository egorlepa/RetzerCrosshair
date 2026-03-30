-- RetzerCrosshair settings UI
-- Opened by /ch with no arguments.

local _, NS = ...

local RUI = LibStub("RetzerUI-1.0")

local optionsFrame

local function ToggleOptions()
    if InCombatLockdown() then
        print("|cff88ccffRetzerCrosshair:|r Cannot open settings in combat (/rch)")
        return
    end
    if not optionsFrame then
        optionsFrame = RUI:BuildOptionsFrame({
            title     = "RetzerCrosshair",
            name      = "RetzerCrosshairOptionsFrame",
            schema    = NS.SCHEMA,
            db        = NS.db,
            onChanged = NS.ApplyAll,
            frameW    = 600,
            frameH    = 280,
        })
    end
    if optionsFrame:IsShown() then
        optionsFrame:Hide()
    else
        optionsFrame:Show()
    end
end

NS.ToggleOptions = ToggleOptions
