local AceAddon = LibStub("AceAddon-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local AceHook = LibStub("AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local ADDON_NAME, AeonoPlates = AceAddon:NewAddon("AeonoPlates", "AceEvent-3.0", "AceHook-3.0")

-- LDB data source (minimap icon)
local ldb = LDB:NewDataObject("AeonoPlates", {
    type = "data source",
    text = "AeonoPlates",
    icon = "Interface\\Icons\\INV_Gauntlets_11"
})

ldb.OnClick = function(self, button)
    if button == "LeftButton" then
        ToggleCharacter("SpellBookFrame")
    elseif button == "RightButton" then
        if not AeonoPlates.optionsFrame or not AeonoPlates.optionsFrame:IsShown() then
            AceConfigDialog:Open("AeonoPlates")
        else
            AeonoPlates.optionsFrame:Hide()
        end
    end
end

-- Default configuration (AceDB-3.0)
local defaults = {
    profile = {
        bars = {
            hpHeight = 15,
            hpWidth = 155,
            cbHeight = 10,
            cbFontSize = 10,
            border = 3
        },
        icons = {
            rHeight = 15,
            rPoint = "RIGHT",
            rRelativePoint = "LEFT",
            rx = 0,
            ry = -4
        },
        level = {
            fontSize = 14,
            point = "RIGHT",
            relativePoint = "LEFT",
            x = -2,
            y = 0
        },
        name = {
            fontSize = 14,
            point = "BOTTOM",
            relativePoint = "TOP",
            x = 0,
            y = 3
        },
        colors = {
            hostile = { r = 0.69, g = 0.31, b = 0.31 },
            friendly = { r = 0.33, g = 0.59, b = 0.33 },
            friendlyPlayer = { r = 0.31, g = 0.45, b = 0.63 },
            neutral = { r = 0.65, g = 0.63, b = 0.35 }
        },
        media = {
            font = "Fonts\\FRIZQT__.TTF",
            normTex = "Interface\\Buttons\\WHITE8x8",
            glowTex = "Interface\\Buttons\\WHITE8x8",
            back = "Interface\\Buttons\\WHITE8x8",
            statusbar = "Aeono Default",
            background = "Aeono Default",
            border = "Aeono Default"
        }
    }
}

-- Media cache (resolved LSM textures/fonts)
local media = {}

local function UpdateMediaCache(self)
    local m = self.db.profile.media
    media.font = LSM:Fetch("font", m.font)
    media.normTex = LSM:Fetch("statusbar", m.normTex) or m.normTex
    media.glowTex = LSM:Fetch("statusbar", m.glowTex) or m.glowTex
    media.back = LSM:Fetch("background", m.back) or m.back
    media.statusbar = LSM:Fetch("statusbar", m.statusbar) or m.statusbar
    media.background = LSM:Fetch("background", m.background) or m.background
    media.border = LSM:Fetch("border", m.border) or m.border
end

-- OnInitialize
function AeonoPlates:OnInitialize()
    self.db = AceDB:New("AeonoPlatesDB", defaults, "AeonoPlates-Default")

    -- Register SharedMedia defaults
    LSM:Register("statusbar", "Aeono Default", "Interface\\Buttons\\WHITE8x8")
    LSM:Register("background", "Aeono Default", "Interface\\Buttons\\WHITE8x8")
    LSM:Register("border", "Aeono Default", "Interface\\Buttons\\WHITE8x8")

    -- Resolve media cache
    UpdateMediaCache(self)

    -- Register GUI
    self:RegisterGUI()

    -- Register LDB icon
    LibDBIcon:Register("AeonoPlates", ldb, self.db.profile)

    -- Start monitoring
    self:RegisterEvents()
end

-- OnEnable
function AeonoPlates:OnEnable()
    -- Register nameplate scanning event
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit)
        local namePlate = NamePlateManager:GetNamePlateForUnit(unit)
        if namePlate then
            self:SkinObjects(namePlate)
        end
    end)
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
end

-- Nameplate tracking
local trackedFrames = {}

local function OnNamePlateRemoved(self)
    trackedFrames[self] = nil
end

-- Update media cache when settings change
function AeonoPlates:UpdateMedia()
    UpdateMediaCache(self)
    self:RefreshAll()
end

-- Refresh all existing nameplates
function AeonoPlates:RefreshAll()
    for i = 1, NamePlateManager:GetMaxNamePlates() do
        local namePlate = NamePlateManager:GetNamePlateAtIndex(i)
        if namePlate and namePlate.UnitFrame then
            self:SkinObjects(namePlate)
        end
    end
end
------------------------------------------------------------------------
-- Castbar event handler
------------------------------------------------------------------------
local function Castbar_OnEvent(self, event, ...)
    local unit = ...
    if (unit ~= nil and unit ~= "player") then
        return
    end

    local frame = self:GetParent()
    local name = string.gsub(select(7, frame:GetRegions()):GetText(), "%s%(%*%)", "")
    if not (name == UnitName(unit) and frame:GetChildren():GetValue() == UnitHealth(unit)) then
        return
    end

    if (event == "UNIT_SPELLCAST_START") then
        local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
        if (not name or (not self.showTradeSkills and isTradeSkill)) then
            self:Hide()
            return
        end

        self:SetStatusBarColor(1.0, 0.7, 0.0)
        self.duration = GetTime() - (startTime / 1000)
        self.max = (endTime - startTime) / 1000

        self:SetValue(0)
        self:SetMinMaxValues(0, self.max)
        self:SetAlpha(1.0)

        if (self.Icon) then
            self.Icon:SetTexture(texture)
        end

        self:SetAlpha(1.0)
        self.holdTime = 0
        self.casting = 1
        self.castID = castID
        self.delay = 0
        self.channeling = nil
        self.fadeOut = nil

        if (self.Shield) then
            if (self.showShield and notInterruptible) then
                self.Shield:Show()
                if (self.Border) then
                    self.Border:Hide()
                end
            else
                self.Shield:Hide()
                if (self.Border) then
                    self.Border:Show()
                end
            end
        end

        self:Show()

    elseif (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP") then
        if ((self.casting and event == "UNIT_SPELLCAST_STOP" and select(4, ...) == self.castID) or (self.channeling and event == "UNIT_SPELLCAST_CHANNEL_STOP")) then
            self:SetValue(self.max)

            if (event == "UNIT_SPELLCAST_STOP") then
                self.casting = nil
                self:SetStatusBarColor(0.0, 1.0, 0.0)
            else
                self.channeling = nil
            end

            self.flash = 1
            self.fadeOut = 1
            self.holdTime = 0
        end

    elseif (event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED") then
        if (self:IsShown() and (self.casting and select(4, ...) == self.castID) and not self.fadeOut) then
            self:SetValue(self.max)
            self:SetStatusBarColor(1.0, 0.0, 0.0)

            self.casting = nil
            self.channeling = nil
            self.fadeOut = 1
            self.holdTime = GetTime() + CASTING_BAR_HOLD_TIME
        end

    elseif (event == "UNIT_SPELLCAST_DELAYED") then
        local castbar = self
        if (castbar:IsShown()) then
            local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
            if (not name or (not self.showTradeSkills and isTradeSkill)) then
                self:Hide()
                return
            end

            local duration = GetTime() - (startTime / 1000)
            if (duration < 0) then duration = 0 end
            castbar.delay = castbar.delay + castbar.duration - duration
            castbar.duration = duration

            castbar:SetValue(duration)

            if (not castbar.casting) then
                castbar:SetStatusBarColor(1.0, 0.7, 0.0)
                castbar.casting = 1
                castbar.channeling = nil
                castbar.fadeOut = 0
            end
        end

    elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
        local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
        if (not name or (not self.showTradeSkills and isTradeSkill)) then
            self:Hide()
            return
        end

        self:SetStatusBarColor(0.0, 1.0, 0.0)
        self.duration = ((endTime / 1000) - GetTime())
        self.max = (endTime - startTime) / 1000
        self.delay = 0
        self:SetMinMaxValues(0, self.max)
        self:SetValue(self.duration)

        if (self.Icon) then
            self.Icon:SetTexture(texture)
        end

        self:SetAlpha(1.0)
        self.holdTime = 0
        self.casting = nil
        self.channeling = 1
        self.fadeOut = nil

        if (self.Shield) then
            if (self.showShield and notInterruptible) then
                self.Shield:Show()
                if (self.Border) then
                    self.Border:Hide()
                end
            else
                self.Shield:Hide()
                if (self.Border) then
                    self.Border:Show()
                end
            end
        end

        self:Show()

    elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
        local castbar = self
        if (castbar:IsShown()) then
            local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)
            if (not name or (not self.showTradeSkills and isTradeSkill)) then
                self:Hide()
                return
            end

            local duration = ((endTime / 1000) - GetTime())
            castbar.delay = castbar.delay + castbar.duration - duration
            castbar.duration = duration
            castbar.max = (endTime - startTime) / 1000

            castbar:SetMinMaxValues(0, castbar.max)
            castbar:SetValue(duration)
        end

    elseif (event == "UNIT_SPELLCAST_INTERRUPTIBLE") then
        if (self.Shield) then
            self.Shield:Hide()
            if (self.Border) then
                self.Border:Show()
            end
        end

    elseif (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then
        if (self.Shield) then
            self.Shield:Show()
            if (self.Border) then
                self.Border:Hide()
            end
        end
    end
end

------------------------------------------------------------------------
-- Castbar OnUpdate
------------------------------------------------------------------------
local function Castbar_OnUpdate(self, elapsed)
    if (self.casting) then
        local duration = self.duration + elapsed
        if (duration >= self.max) then
            self:SetValue(self.max)
            self:SetStatusBarColor(0.0, 1.0, 0.0)
            self.holdTime = 0
            self.fadeOut = 0
            self.casting = nil
            return
        end

        self.duration = duration
        self:SetValue(duration)

    elseif (self.channeling) then
        local duration = self.duration - elapsed
        if (duration <= 0) then
            self:SetStatusBarColor(0.0, 1.0, 0.0)
            self.fadeOut = 0
            self.channeling = nil
            self.holdTime = 0
            return
        end
        self.duration = duration
        self:SetValue(duration)

    elseif (GetTime() < self.holdTime) then
        return

    elseif (self.fadeOut) then
        local alpha = self:GetAlpha() - CASTING_BAR_ALPHA_STEP
        if (alpha > 0.05) then
            self:SetAlpha(alpha)
        else
            self.fadeOut = nil
            self:Hide()
        end
    end
end

------------------------------------------------------------------------
-- Update cast time text
------------------------------------------------------------------------
local function UpdateCastTime(self, curValue)
    local minValue, maxValue = self:GetMinMaxValues()
    if self.channeling then
        local casttime = string.format("%.1f", curValue)
        local castcur = string.format("\n%.1f", maxValue)
        self.time:SetText(casttime .. castcur)
    else
        local casttime = string.format("%.1f", (maxValue - curValue))
        local castcur = string.format("\n%.1f", maxValue)
        self.time:SetText(casttime .. castcur)
    end
end

------------------------------------------------------------------------
-- Healthbar OnUpdate
------------------------------------------------------------------------
local function Healthbar_OnUpdate(self)
    local cfg = self.frame.db.profile
    local colors = cfg.colors

    local r, g, b = self:GetStatusBarColor()
    if g + b == 0 then
        self.r, self.g, self.b = colors.hostile.r, colors.hostile.g, colors.hostile.b
        self:SetStatusBarColor(colors.hostile.r, colors.hostile.g, colors.hostile.b)
    elseif r + b == 0 then
        self.r, self.g, self.b = colors.friendly.r, colors.friendly.g, colors.friendly.b
        self:SetStatusBarColor(colors.friendly.r, colors.friendly.g, colors.friendly.b)
    elseif r + g == 0 then
        self.r, self.g, self.b = colors.friendlyPlayer.r, colors.friendlyPlayer.g, colors.friendlyPlayer.b
        self:SetStatusBarColor(colors.friendlyPlayer.r, colors.friendlyPlayer.g, colors.friendlyPlayer.b)
    elseif 2 - (r + g) < 0.05 and b == 0 then
        self.r, self.g, self.b = colors.neutral.r, colors.neutral.g, colors.neutral.b
        self:SetStatusBarColor(colors.neutral.r, colors.neutral.g, colors.neutral.b)
    else
        self.r, self.g, self.b = r, g, b
    end

    local frame = self:GetParent()
    if not frame.oldglow:IsShown() then
        self.hpBorder:SetBackdropBorderColor(0, 0, 0)
    else
        local r, g, b = frame.oldglow:GetVertexColor()
        if g + b == 0 then
            self.hpBorder:SetBackdropBorderColor(1, 0, 0)
        else
            self.hpBorder:SetBackdropBorderColor(1, 1, 0)
        end
    end
    self:SetStatusBarColor(self.r, self.g, self.b)

    self:ClearAllPoints()
    self:SetPoint("CENTER", self:GetParent(), 0, 10)
    self:SetHeight(cfg.bars.hpHeight)
    self:SetWidth(cfg.bars.hpWidth)

    self.hpBackground:SetVertexColor(self.r * 0.25, self.g * 0.25, self.b * 0.25)

    local nameString = frame.oldname:GetText()
    if string.len(nameString) < cfg.bars.hpWidth / 5 then
        frame.name:SetText(nameString)
    else
        frame.name:SetFormattedText("%s...", nameString:sub(1, cfg.bars.hpWidth / 5))
    end

    frame.level:ClearAllPoints()
    frame.level:SetPoint(cfg.level.point, frame.healthBar, cfg.level.relativePoint, cfg.level.x, cfg.level.y)
    if frame.boss:IsShown() then
        frame.level:SetText("BOSS")
        frame.level:SetTextColor(0.8, 0.05, 0)
        frame.level:Show()
    end
    frame.highlight:SetAllPoints(self)

    self:Hide()
    self:Show()
end

------------------------------------------------------------------------
-- OnHide for nameplate
------------------------------------------------------------------------
local function OnHide(self)
    self.highlight:Hide()
end
------------------------------------------------------------------------
-- SkinObjects - main nameplate skinning function
------------------------------------------------------------------------
function AeonoPlates:SkinObjects(frame)
    local cfg = self.db.profile
    local bars = cfg.bars
    local icons = cfg.icons
    local levelCfg = cfg.level
    local nameCfg = cfg.name

    frame.healthBar, frame.castBar = frame:GetChildren()
    local healthBar, castBar = frame.healthBar, frame.castBar
    local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()

    -- Name region
    frame.oldname = nameTextRegion
    nameTextRegion:Hide()
    nameTextRegion.Show = function() end

    frame.name = frame:CreateFontString()
    frame.name:SetPoint(nameCfg.point, healthBar, nameCfg.relativePoint, nameCfg.x, nameCfg.y)
    frame.name:SetFont(media.font, nameCfg.fontSize, "OUTLINE")
    frame.name:SetTextColor(0.84, 0.75, 0.65)
    frame.name:SetShadowOffset(1, -1)

    -- Level region
    frame.level = levelTextRegion
    levelTextRegion:SetFont(media.font, levelCfg.fontSize, "OUTLINE")
    levelTextRegion:SetShadowOffset(1, -1)
    frame.boss = bossIconRegion

    -- Health bar
    healthBar:SetStatusBarTexture(media.normTex)

    healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
    healthBar.hpBackground:SetAllPoints(healthBar)
    healthBar.hpBackground:SetTexture(media.back)
    healthBar.hpBackground:SetVertexColor(0.15, 0.15, 0.15)

    healthBar.hpBorder = CreateFrame("Frame", nil, healthBar)
    healthBar.hpBorder:SetFrameLevel(healthBar:GetFrameLevel() - 1 > 0 and healthBar:GetFrameLevel() - 1 or 0)
    healthBar.hpBorder:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -bars.border, bars.border)
    healthBar.hpBorder:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", bars.border, -bars.border)
    healthBar.hpBorder:SetBackdrop({
        edgeFile = media.glowTex,
        edgeSize = bars.border,
        insets = { left = bars.border, right = bars.border, top = bars.border, bottom = bars.border }
    })
    healthBar.hpBorder:SetBackdropColor(0, 0, 0)
    healthBar.hpBorder:SetBackdropBorderColor(0, 0, 0)

    healthBar.frame = self
    healthBar:SetScript("OnUpdate", Healthbar_OnUpdate)

    -- Highlight
    highlightRegion:SetTexture(media.normTex)
    highlightRegion:SetVertexColor(0.25, 0.25, 0.25)
    frame.highlight = highlightRegion

    -- Custom castbar
    local castbar = CreateFrame("StatusBar", nil, frame)
    castbar:SetHeight(bars.cbHeight)
    castbar:SetWidth(bars.hpWidth - (bars.cbHeight + 8))
    castbar:SetStatusBarTexture(media.normTex)
    castbar:GetStatusBarTexture():SetHorizTile(false)
    castbar:GetStatusBarTexture():SetVertTile(false)
    castbar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, -8)

    castbar.showTradeSkills = true
    castbar.showShield = true
    castbar.casting = true
    castbar.channeling = true
    castbar.holdTime = 0

    castbar.Border = castbar:CreateTexture(nil, "BACKGROUND")
    castbar.Border:SetSize(castbarOverlay:GetSize())
    castbar.Border:SetAllPoints(castbar)
    castbar.Border:SetTexture(media.back)
    castbar.Border:SetVertexColor(0, 0, 0, 0.8)

    castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
    castbar.Icon:SetSize(spellIconRegion:GetSize())
    castbar.Icon:SetPoint("RIGHT", castbar, "LEFT", -2, 0)
    castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    castbar.time = castbar:CreateFontString(nil, "ARTWORK")
    castbar.time:SetPoint("RIGHT", castbar.Icon, "LEFT", -4, 0)
    castbar.time:SetFont(media.font, bars.cbFontSize, "OUTLINE")
    castbar.time:SetTextColor(0.84, 0.75, 0.65)
    castbar.time:SetShadowOffset(1, -1)

    castbar:Hide()

    castbar:RegisterEvent("UNIT_SPELLCAST_START")
    castbar:RegisterEvent("UNIT_SPELLCAST_FAILED")
    castbar:RegisterEvent("UNIT_SPELLCAST_STOP")
    castbar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    castbar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    castbar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    castbar:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
    castbar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    castbar:SetScript("OnEvent", Castbar_OnEvent)
    castbar:SetScript("OnUpdate", Castbar_OnUpdate)
    castbar:HookScript("OnValueChanged", UpdateCastTime)

    -- Store old regions
    frame.oldglow = glowRegion

    -- Track this frame
    trackedFrames[frame] = true
    frame:HookScript("OnHide", OnNamePlateRemoved)

    -- Hide original regions
    frame:SetScript("OnHide", OnHide)

    glowRegion:SetTexture(nil)
    overlayRegion:SetTexture(nil)
    shieldedRegion:SetTexture(nil)
    castbarOverlay:SetTexture(nil)
    stateIconRegion:SetTexture(nil)
    bossIconRegion:SetTexture(nil)
end
------------------------------------------------------------------------
-- RegisterGUI - AceConfig options panel
------------------------------------------------------------------------
function AeonoPlates:RegisterGUI()
    local options = {
        type = "group",
        name = "AeonoPlates",
        get = function(info)
            return self.db.profile[info.arg1][info.arg2]
        end,
        set = function(info, value)
            self.db.profile[info.arg1][info.arg2] = value
            self:UpdateMedia()
        end,
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    heading = {
                        type = "description",
                        name = "AeonoPlates - Custom Nameplates for WotLK 3.3.5a",
                        order = 1
                    },
                    minimap = {
                        type = "toggle",
                        name = "Show Minimap Icon",
                        order = 2,
                        get = function()
                            return LibDBIcon:IsVisible("AeonoPlates")
                        end,
                        set = function(_, v)
                            if v then
                                LibDBIcon:Show("AeonoPlates")
                            else
                                LibDBIcon:Hide("AeonoPlates")
                            end
                        end
                    }
                }
            },
            bars = {
                type = "group",
                name = "Bars",
                order = 2,
                args = {
                    hpHeight = {
                        type = "range",
                        name = "HP Bar Height",
                        min = 5, max = 30, step = 1,
                        order = 1,
                        arg1 = "bars",
                        arg2 = "hpHeight"
                    },
                    hpWidth = {
                        type = "range",
                        name = "HP Bar Width",
                        min = 50, max = 300, step = 1,
                        order = 2,
                        arg1 = "bars",
                        arg2 = "hpWidth"
                    },
                    cbHeight = {
                        type = "range",
                        name = "Castbar Height",
                        min = 5, max = 20, step = 1,
                        order = 3,
                        arg1 = "bars",
                        arg2 = "cbHeight"
                    },
                    cbFontSize = {
                        type = "range",
                        name = "Castbar Font Size",
                        min = 6, max = 20, step = 1,
                        order = 4,
                        arg1 = "bars",
                        arg2 = "cbFontSize"
                    },
                    border = {
                        type = "range",
                        name = "Border Size",
                        min = 0, max = 10, step = 1,
                        order = 5,
                        arg1 = "bars",
                        arg2 = "border"
                    }
                }
            },
            nameplate = {
                type = "group",
                name = "Nameplate",
                order = 3,
                args = {
                    section = {
                        type = "description",
                        name = "Name text and level positioning",
                        order = 1
                    },
                    nameFontSize = {
                        type = "range",
                        name = "Name Font Size",
                        min = 8, max = 24, step = 1,
                        order = 2,
                        arg1 = "name",
                        arg2 = "fontSize"
                    },
                    namePoint = {
                        type = "select",
                        name = "Name Anchor Point",
                        values = { ["TOP"] = "TOP", ["BOTTOM"] = "BOTTOM", ["LEFT"] = "LEFT", ["RIGHT"] = "RIGHT", ["CENTER"] = "CENTER" },
                        order = 3,
                        arg1 = "name",
                        arg2 = "point"
                    },
                    nameRelativePoint = {
                        type = "select",
                        name = "Name Relative To",
                        values = { ["TOP"] = "TOP", ["BOTTOM"] = "BOTTOM", ["LEFT"] = "LEFT", ["RIGHT"] = "RIGHT", ["CENTER"] = "CENTER" },
                        order = 4,
                        arg1 = "name",
                        arg2 = "relativePoint"
                    },
                    nameX = {
                        type = "range",
                        name = "Name X Offset",
                        min = -50, max = 50, step = 1,
                        order = 5,
                        arg1 = "name",
                        arg2 = "x"
                    },
                    nameY = {
                        type = "range",
                        name = "Name Y Offset",
                        min = -50, max = 50, step = 1,
                        order = 6,
                        arg1 = "name",
                        arg2 = "y"
                    },
                    levelFontSize = {
                        type = "range",
                        name = "Level Font Size",
                        min = 8, max = 24, step = 1,
                        order = 7,
                        arg1 = "level",
                        arg2 = "fontSize"
                    },
                    levelPoint = {
                        type = "select",
                        name = "Level Anchor Point",
                        values = { ["TOP"] = "TOP", ["BOTTOM"] = "BOTTOM", ["LEFT"] = "LEFT", ["RIGHT"] = "RIGHT", ["CENTER"] = "CENTER" },
                        order = 8,
                        arg1 = "level",
                        arg2 = "point"
                    },
                    levelRelativePoint = {
                        type = "select",
                        name = "Level Relative To",
                        values = { ["TOP"] = "TOP", ["BOTTOM"] = "BOTTOM", ["LEFT"] = "LEFT", ["RIGHT"] = "RIGHT", ["CENTER"] = "CENTER" },
                        order = 9,
                        arg1 = "level",
                        arg2 = "relativePoint"
                    },
                    levelX = {
                        type = "range",
                        name = "Level X Offset",
                        min = -50, max = 50, step = 1,
                        order = 10,
                        arg1 = "level",
                        arg2 = "x"
                    },
                    levelY = {
                        type = "range",
                        name = "Level Y Offset",
                        min = -50, max = 50, step = 1,
                        order = 11,
                        arg1 = "level",
                        arg2 = "y"
                    }
                }
            },
            colors = {
                type = "group",
                name = "Colors",
                order = 4,
                args = {
                    hostile = {
                        type = "color",
                        name = "Hostile Unit Color",
                        hasAlpha = false,
                        order = 1,
                        arg1 = "colors",
                        arg2 = "hostile"
                    },
                    friendly = {
                        type = "color",
                        name = "Friendly Unit Color",
                        hasAlpha = false,
                        order = 2,
                        arg1 = "colors",
                        arg2 = "friendly"
                    },
                    friendlyPlayer = {
                        type = "color",
                        name = "Friendly Player Color",
                        hasAlpha = false,
                        order = 3,
                        arg1 = "colors",
                        arg2 = "friendlyPlayer"
                    },
                    neutral = {
                        type = "color",
                        name = "Neutral Unit Color",
                        hasAlpha = false,
                        order = 4,
                        arg1 = "colors",
                        arg2 = "neutral"
                    }
                }
            },
            media = {
                type = "group",
                name = "Media",
                order = 5,
                args = {
                    heading = {
                        type = "description",
                        name = "SharedMedia textures and fonts",
                        order = 1
                    },
                    statusbar = {
                        type = "select",
                        name = "Statusbar Texture",
                        dialogWidth = "medium",
                        values = LSM:HashTable("statusbar"),
                        order = 2,
                        arg1 = "media",
                        arg2 = "statusbar",
                        get = function(info)
                            return self.db.profile.media.statusbar
                        end,
                        set = function(info, v)
                            self.db.profile.media.statusbar = v
                            UpdateMediaCache(self)
                            self:RefreshAll()
                        end
                    },
                    background = {
                        type = "select",
                        name = "Background Texture",
                        dialogWidth = "medium",
                        values = LSM:HashTable("background"),
                        order = 3,
                        arg1 = "media",
                        arg2 = "background",
                        get = function(info)
                            return self.db.profile.media.background
                        end,
                        set = function(info, v)
                            self.db.profile.media.background = v
                            UpdateMediaCache(self)
                            self:RefreshAll()
                        end
                    },
                    border = {
                        type = "select",
                        name = "Border Texture",
                        dialogWidth = "medium",
                        values = LSM:HashTable("border"),
                        order = 4,
                        arg1 = "media",
                        arg2 = "border",
                        get = function(info)
                            return self.db.profile.media.border
                        end,
                        set = function(info, v)
                            self.db.profile.media.border = v
                            UpdateMediaCache(self)
                            self:RefreshAll()
                        end
                    },
                    font = {
                        type = "select",
                        name = "Font",
                        dialogWidth = "medium",
                        values = LSM:HashTable("font"),
                        order = 5,
                        arg1 = "media",
                        arg2 = "font",
                        get = function(info)
                            return self.db.profile.media.font
                        end,
                        set = function(info, v)
                            self.db.profile.media.font = v
                            UpdateMediaCache(self)
                            self:RefreshAll()
                        end
                    }
                }
            },
            about = {
                type = "group",
                name = "About",
                order = 6,
                args = {
                    text = {
                        type = "description",
                        name = "AeonoPlates v2.0\nCustom nameplates for WoW 3.3.5a (WotLK)\nAuthor: Aeonoscul",
                        width = "default",
                        order = 1
                    }
                }
            }
        }
    }

    -- Register with AceConfig registry
    AceConfig:RegisterOptionsDialog("AeonoPlates", options, {
        title = "AeonoPlates",
        type = "group"
    })

    -- Register slash command
    SLASH_AEONOPALATES1 = "/aeonoplates"
    SLASH_AEONOPALATES2 = "/ap"
    SlashCmdList["AEONOPALATES"] = function()
        if AeonoPlates.optionsFrame and AeonoPlates.optionsFrame:IsShown() then
            AeonoPlates.optionsFrame:Hide()
        else
            AceConfigDialog:Open("AeonoPlates")
        end
    end
end
