-- RetzerCrosshair
-- Ring + screen-edge lines on the cursor. Configurable via /ch.

local _, NS = ...

RetzerCrosshairDB = RetzerCrosshairDB or {}

local db

local SCHEMA = {
    settings = {
        _meta = { label = "General", order = 1 },
        { key = "color",           default = { r = 1, g = 0.1, b = 0.1, a = 0.85 }, label = "Color" },
        { key = "ringSize",        default = 20,       label = "Ring Radius",    min = 4,   max = 120, step = 1 },
        { key = "lineWidth",       default = 4,        label = "Line Width",     min = 0.5, max = 8,   step = 0.5 },
        { key = "mode",            default = "combat",  label = "Show",          choices = { "combat", "always" } },
        { key = "hideOnMouselook", default = true,     label = "Hide on Mouselook" },
    },
}

NS.SCHEMA = SCHEMA

local RING_SEGMENTS = 48

----------------------------------------------------------------
-- Saved variables init
----------------------------------------------------------------

local function InitDB()
    db = RetzerCrosshairDB
    for sectionKey, entries in pairs(SCHEMA) do
        if not db[sectionKey] then db[sectionKey] = {} end
        for _, entry in ipairs(entries) do
            if entry.key and db[sectionKey][entry.key] == nil then
                local d = entry.default
                if type(d) == "table" then
                    db[sectionKey][entry.key] = {}
                    for k, v in pairs(d) do db[sectionKey][entry.key][k] = v end
                else
                    db[sectionKey][entry.key] = d
                end
            end
        end
    end
end

----------------------------------------------------------------
-- Frame setup
-- Outer frame: shown when crosshair is active, drives OnUpdate.
-- Visual frame: child that hides during mouselook, owns all lines.
----------------------------------------------------------------

local frame = CreateFrame("Frame", "RetzerCrosshairFrame", UIParent)
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("TOOLTIP")
frame:Hide()

local visual = CreateFrame("Frame", nil, frame)
visual:SetAllPoints(frame)

local ringLines = {}
for i = 1, RING_SEGMENTS do
    ringLines[i] = visual:CreateLine()
end

local lineTop    = visual:CreateLine()
local lineBottom = visual:CreateLine()
local lineLeft   = visual:CreateLine()
local lineRight  = visual:CreateLine()

----------------------------------------------------------------
-- Apply config to all lines
----------------------------------------------------------------

local function ApplyColor()
    local c = db.settings.color
    for i = 1, RING_SEGMENTS do
        ringLines[i]:SetColorTexture(c.r, c.g, c.b, c.a)
    end
    lineTop:SetColorTexture(c.r, c.g, c.b, c.a)
    lineBottom:SetColorTexture(c.r, c.g, c.b, c.a)
    lineLeft:SetColorTexture(c.r, c.g, c.b, c.a)
    lineRight:SetColorTexture(c.r, c.g, c.b, c.a)
end

local function ApplyThickness()
    local w = db.settings.lineWidth
    for i = 1, RING_SEGMENTS do
        ringLines[i]:SetThickness(w)
    end
    lineTop:SetThickness(w)
    lineBottom:SetThickness(w)
    lineLeft:SetThickness(w)
    lineRight:SetThickness(w)
end

----------------------------------------------------------------
-- Per-frame update: track cursor and reposition everything
----------------------------------------------------------------

local TWO_PI = math.pi * 2

frame:SetScript("OnUpdate", function()
    if db.settings.hideOnMouselook and IsMouselooking() then
        visual:Hide()
        return
    end
    visual:Show()

    local cx, cy = GetCursorPosition()
    if not cx then return end

    local scale = UIParent:GetEffectiveScale()
    cx = cx / scale
    cy = cy / scale

    local r  = db.settings.ringSize
    local sw = UIParent:GetWidth()
    local sh = UIParent:GetHeight()

    -- Ring: approximate circle with line segments
    -- Extend each segment slightly past its endpoints to prevent gaps from flat line caps
    local overlap = TWO_PI / RING_SEGMENTS * 0.5
    for i = 1, RING_SEGMENTS do
        local a1 = (i - 1) / RING_SEGMENTS * TWO_PI - overlap
        local a2 = i       / RING_SEGMENTS * TWO_PI + overlap
        ringLines[i]:SetStartPoint("BOTTOMLEFT", UIParent, cx + math.cos(a1) * r, cy + math.sin(a1) * r)
        ringLines[i]:SetEndPoint(  "BOTTOMLEFT", UIParent, cx + math.cos(a2) * r, cy + math.sin(a2) * r)
    end

    -- Lines from ring edge to screen edges
    lineTop:SetStartPoint(   "BOTTOMLEFT", UIParent, cx,     cy + r)
    lineTop:SetEndPoint(     "BOTTOMLEFT", UIParent, cx,     sh)

    lineBottom:SetStartPoint("BOTTOMLEFT", UIParent, cx,     cy - r)
    lineBottom:SetEndPoint(  "BOTTOMLEFT", UIParent, cx,     0)

    lineLeft:SetStartPoint(  "BOTTOMLEFT", UIParent, cx - r, cy)
    lineLeft:SetEndPoint(    "BOTTOMLEFT", UIParent, 0,      cy)

    lineRight:SetStartPoint( "BOTTOMLEFT", UIParent, cx + r, cy)
    lineRight:SetEndPoint(   "BOTTOMLEFT", UIParent, sw,     cy)
end)

----------------------------------------------------------------
-- Show/hide based on mode and combat state
----------------------------------------------------------------

local inCombat = false

local function UpdateVisibility()
    local mode = db.settings.mode
    if mode == "always" or (mode == "combat" and inCombat) then
        frame:Show()
    else
        frame:Hide()
    end
end

NS.ApplyAll = function() ApplyColor(); ApplyThickness(); UpdateVisibility() end

----------------------------------------------------------------
-- Events
----------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "RetzerCrosshair" then return end
        InitDB()
        NS.db = db
        ApplyColor()
        ApplyThickness()
        inCombat = InCombatLockdown() == 1
        UpdateVisibility()

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        UpdateVisibility()

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        UpdateVisibility()
    end
end)

----------------------------------------------------------------
-- Slash command: /rch — open settings UI
----------------------------------------------------------------

SLASH_CURSORCROSSHAIR1 = "/rch"

SlashCmdList["CURSORCROSSHAIR"] = function()
    if NS.ToggleOptions then NS.ToggleOptions() end
end
