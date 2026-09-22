local addonName, ns = ...

local AceAddon = LibStub("AceAddon-3.0")
local AeonoPlates = AceAddon:NewAddon(addonName, "AceEvent-3.0", "AceConsole-3.0")
ns.addon = AeonoPlates

local LSM = LibStub("LibSharedMedia-3.0")

local defaults = ns.defaults
local cfg = ns.cfg
ns.cfg = cfg
local media = ns.media
ns.media = media

local SyncCastBarFromUnit
local CastBar_OnUpdate

local styledFrames = setmetatable({}, {
    __mode = "k"
})
local visibleFrames = setmetatable({}, {
    __mode = "k"
})
local stackableFrames = {}

local function ApplyClassificationIcon(frame)
    local icon = frame.stateIcon
    if not icon then
        return
    end

    if icon:GetTexture() == "Interface\\Tooltips\\EliteNameplateIcon" then
        icon:SetTexture("Interface\\AddOns\\AeonoPlates\\Media\\icon\\elite.tga")
        icon:SetTexCoord(0, 1, 0, 1)
    end

    icon:ClearAllPoints()
    icon:SetPoint(cfg.classifyPoint, frame.healthBar, cfg.classifyRelativePoint, cfg.classifyX, cfg.classifyY)
    icon:SetSize(cfg.classifySize, cfg.classifySize)
end

local function ApplyNameColor(frame)
    local name = frame.name
    if not name then
        return
    end
    local c = cfg.NameColor
    if c then
        name:SetTextColor(c.r or 1, c.g or 1, c.b or 1)
    else
        name:SetTextColor(1, 1, 1)
    end
end

local function ApplyTextShadow(fs, enabled, x, y, color)
    if not fs then
        return
    end
    if enabled then
        fs:SetShadowOffset(x or 1, y or -1)
        fs:SetShadowColor(color and color.r or 0, color and color.g or 0, color and color.b or 0, color and color.a or 1)
    else
        fs:SetShadowOffset(0, 0)
        fs:SetShadowColor(0, 0, 0, 0)
    end
end

local function ShadowOutdated(fs, enabled, x, y, color)
    if not fs then
        return false
    end
    local sx, sy = fs:GetShadowOffset()
    if not enabled then
        return sx ~= 0 or sy ~= 0
    end
    if sx ~= (x or 1) or sy ~= (y or -1) then
        return true
    end
    if color then
        local cr, cg, cb, ca = fs:GetShadowColor()
        if cr ~= (color.r or 0) or cg ~= (color.g or 0) or cb ~= (color.b or 0) or ca ~= (color.a or 1) then
            return true
        end
    end
    return false
end

local classByFriendName = {}

local function NormalizeUnitName(name)
    if not name or name == "" then
        return nil
    end
    name = name:gsub("%s*%(%*%)", "")
    name = name:match("([^%-]+)") or name
    return name
end

local function UpdateFriendClassInfo()
    wipe(classByFriendName)

    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    for i = 1, numParty do
        local unit = "party" .. i
        local name = UnitName(unit)
        local _, class = UnitClass(unit)
        local key = NormalizeUnitName(name)
        if key and class then
            classByFriendName[key] = class
        end
    end

    local numRaid = GetNumRaidMembers and GetNumRaidMembers() or 0
    for i = 1, numRaid do
        local name, _, _, _, _, class = GetRaidRosterInfo(i)
        local key = NormalizeUnitName(name)
        if key and class and not classByFriendName[key] then
            classByFriendName[key] = class
        end
    end
end

local plateUnitCache = setmetatable({}, {
    __mode = "k"
})
local plateUnitCacheName = setmetatable({}, {
    __mode = "k"
})

local function GetPlateUnit(frame)
    local cachedName = plateUnitCacheName[frame]
    local currentName = frame.oldname and frame.oldname:GetText()

    if cachedName == currentName then
        local unit = plateUnitCache[frame]
        if unit == false then
            return nil
        end
        if unit and UnitExists(unit) then
            return unit
        end
    end

    plateUnitCacheName[frame] = currentName

    if not currentName or currentName == "" then
        plateUnitCache[frame] = false
        return nil
    end
    local cleanName = currentName:gsub("%s*%(%*%)", "")

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitName(unit) == cleanName then
            plateUnitCache[frame] = unit
            return unit
        end
    end

    plateUnitCache[frame] = false
    return nil
end

local function DetectPlateTypeFromColor(r, g, b)
    if r > 0.99 and g > 0.99 and b < 0.01 then
        return "neutral"
    end
    if r < 0.01 and g > 0.99 and b < 0.01 then
        return "friendly_npc"
    end
    if r < 0.01 and g < 0.01 and b > 0.99 then
        return "friendly_player"
    end
    if r > 0.99 and g < 0.01 and b < 0.01 then
        return "enemy_npc"
    end
    for _, c in pairs(RAID_CLASS_COLORS) do
        if math.abs(r - c.r) < 0.01 and math.abs(g - c.g) < 0.01 and math.abs(b - c.b) < 0.01 then
            return "enemy_player"
        end
    end
    return "enemy_player"
end

local function GetPlateType(frame)
    local unit = GetPlateUnit(frame)
    if unit then
        local isPlayer = UnitIsPlayer(unit)
        local reaction = UnitReaction and UnitReaction("player", unit)
        if reaction then
            if reaction > 4 then
                return isPlayer and "friendly_player" or "friendly_npc"
            elseif reaction == 4 then
                return "neutral"
            else
                return isPlayer and "enemy_player" or "enemy_npc"
            end
        end
        if UnitIsFriend("player", unit) then
            return isPlayer and "friendly_player" or "friendly_npc"
        elseif UnitIsEnemy("player", unit) then
            return isPlayer and "enemy_player" or "enemy_npc"
        else
            return "neutral"
        end
    end

    local hb = frame.healthBar
    if not hb then
        return nil
    end
    local r, g, b = hb:GetStatusBarColor()
    return DetectPlateTypeFromColor(r, g, b)
end

local function GetPartyClassColor(frame)
    local name = NormalizeUnitName(frame.oldname and frame.oldname:GetText())
    if not name then
        return nil
    end
    local class = classByFriendName[name]
    if not class then
        return nil
    end
    return RAID_CLASS_COLORS[class]
end

local function GetColorForType(frame, unitType)
    if unitType == "neutral" then
        return cfg.HPcolorNeutral
    end
    if unitType == "friendly_npc" then
        return cfg.HPcolorFriendlyNPC
    end
    if unitType == "friendly_player" then
        if cfg.HPcolorFriendlyClasses then
            local c = GetPartyClassColor(frame)
            if c then
                return c
            end
        end
        return cfg.HPcolorFriendlyPlayer
    end
    if unitType == "enemy_npc" then
        return cfg.HPcolorEnemy
    end
    if unitType == "enemy_player" then
        if cfg.HPcolorEnemyClasses then
            return frame._classColor
        end
        return cfg.HPcolorEnemy
    end
    return nil
end

local function ApplyHealthBarColor(frame)
    local hb = frame.healthBar
    if not hb then
        return
    end

    if not frame._hpType then
        frame._hpType = GetPlateType(frame)
    end
    if not frame._hpType then
        return
    end

    if frame._hpType == "enemy_player" and not frame._classColor then
        local cr, cg, cb = hb:GetStatusBarColor()
        for _, c in pairs(RAID_CLASS_COLORS) do
            if math.abs(cr - c.r) < 0.01 and math.abs(cg - c.g) < 0.01 and math.abs(cb - c.b) < 0.01 then
                frame._classColor = {
                    r = c.r,
                    g = c.g,
                    b = c.b
                }
                break
            end
        end
    end

    local color = GetColorForType(frame, frame._hpType)
    if not color then
        return
    end

    local cr, cg, cb = hb:GetStatusBarColor()
    if cr ~= color.r or cg ~= color.g or cb ~= color.b then
        hb:SetStatusBarColor(color.r, color.g, color.b)
    end
end

local function ResetPlateColorCache(frame)
    frame._hpType = nil
    frame._classColor = nil
    plateUnitCache[frame] = nil
    plateUnitCacheName[frame] = nil
end

local FRAME_LEVELS_PER_PLATE = 3
local FRAME_ORDER_INTERVAL = 0.15
local MOUSEOVER_POLL_INTERVAL = 0.2
local STACK_DELTA_FALLBACK = 3
local HIGHLIGHT_REANCHOR_INTERVAL = 0.5

local previousFrameOrder = {}
local worldFrameChildCount = -1
local mouseoverFrame = nil

local regionIndex = {
    highlightTexture = 6
}

local function Noop()
end

local function CreateBorderFrame(parentFrame, anchorTarget, frameLevelOffset)
    local bf = CreateFrame("Frame", nil, parentFrame)
    bf:SetFrameLevel(parentFrame:GetFrameLevel() + (frameLevelOffset or 1))
    bf._anchorTarget = anchorTarget
    bf._applied = {}
    return bf
end

local function UpdateBorderFrame(bf, anchorTarget, tex, size, inset, colorR, colorG, colorB)
    if not bf then
        return
    end
    local a = bf._applied

    if a.tex ~= tex or a.size ~= size or a.inset ~= inset then
        a.tex, a.size, a.inset = tex, size, inset

        bf:ClearAllPoints()
        bf:SetPoint("TOPLEFT", anchorTarget, "TOPLEFT", inset, -inset)
        bf:SetPoint("BOTTOMRIGHT", anchorTarget, "BOTTOMRIGHT", -inset, inset)

        bf:SetBackdrop({
            edgeFile = tex,
            edgeSize = size,
            insets = {
                left = 0,
                right = 0,
                top = 0,
                bottom = 0
            }
        })
    end

    bf:SetBackdropBorderColor(colorR or 1, colorG or 1, colorB or 1, 1)
    bf:Show()

    a.colorR, a.colorG, a.colorB = colorR, colorG, colorB
end

local function HideBorderFrame(bf)
    if bf then
        bf:Hide()
    end
end

local function BorderFrameIsShown(bf)
    return bf and bf:IsShown() and true or false
end

local function GetJustifyFromAnchor(anchor)
    if not anchor then
        return "CENTER"
    end
    if anchor:find("LEFT", 1, true) then
        return "LEFT"
    end
    if anchor:find("RIGHT", 1, true) then
        return "RIGHT"
    end
    return "CENTER"
end

local function GetHighlightRegion(frame)
    if not frame then
        return
    end
    if frame.extended and frame.extended.regions then
        if frame.extended.regions.highlight then
            return frame.extended.regions.highlight
        end
        if frame.extended.regions.highlightTexture then
            return frame.extended.regions.highlightTexture
        end
    elseif frame.aloftData and frame.aloftData.highlightRegion then
        return frame.aloftData.highlightRegion
    elseif frame.highlight then
        return frame.highlight
    end
    local byIndex = select(regionIndex.highlightTexture, frame:GetRegions())
    if byIndex then
        return byIndex
    end
    for region in frame:GetRegions() do
        if region.GetTexture then
            local tex = region:GetTexture()
            if tex and type(tex) == "string" and tex:find("Highlight", 1, true) then
                return region
            end
        end
    end
end

local function ApplyHighlight(frame)
    local hl = frame.highlight
    if not hl then
        return
    end
    local hb = frame.healthBar
    if hb then
        hl:ClearAllPoints()
        hl:SetPoint("TOPLEFT", hb, "TOPLEFT", 0, 0)
        hl:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 0, 0)
    end
    hl:SetDrawLayer("OVERLAY", 7)
    hl:SetTexture(media.highlightTex)
    hl:SetTexCoord(0, 1, 0, 1)
    local c = cfg.highlightColor
    if c then
        hl:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 0.35)
    else
        hl:SetVertexColor(1, 1, 1, 0.35)
    end
    hl:SetBlendMode(cfg.highlightBlend or "ADD")
end

local function GetCastBarWidth()
    if cfg.CBwidth and cfg.CBwidth > 0 then
        return cfg.CBwidth
    end
    return cfg.HPwidth - cfg.CBheight
end

AeonoPlates.RefreshConfig = ns.RefreshConfig

local function GetCastIconTexCoord()
    if cfg.CBiconCropped then
        return 0.1, 0.9, 0.1, 0.9
    end
    return 0, 1, 0, 1
end

local function ApplyCastBarColor(cb)
    if not cb then
        return
    end
    local c = cb._noInterrupt and cfg.CBcolorNoInterrupt or cfg.CBcolorCast
    if c then
        cb:SetStatusBarColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end
end

local function ActivateCastBarOnUpdate(cb)
    if not cb._updateActive then
        cb._updateActive = true
        cb:SetScript("OnUpdate", CastBar_OnUpdate)
    end
end

local function DeactivateCastBarOnUpdate(cb)
    if cb._updateActive then
        cb._updateActive = nil
        cb:SetScript("OnUpdate", nil)
    end
end

SyncCastBarFromUnit = function(cb, unit)
    if not cb or not unit then
        return
    end
    local name, _, _, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    local isChannel = false
    if not name then
        name, _, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        isChannel = true
    end
    if not name then
        return
    end

    local nowMs = GetTime() * 1000
    local maxTime = endTime - startTime
    if maxTime <= 0 then
        return
    end

    cb._casting = (not isChannel) or nil
    cb._channeling = isChannel or nil
    cb._fadeOut = nil
    cb._holdUntil = nil
    cb._max = maxTime / 1000
    cb._noInterrupt = notInterruptible and true or nil
    cb._duration = isChannel and ((endTime - nowMs) / 1000) or ((nowMs - startTime) / 1000)

    if cb._duration < 0 then
        cb._duration = 0
    end
    if cb._duration > cb._max then
        cb._duration = cb._max
    end

    cb:SetMinMaxValues(0, cb._max)
    cb:SetValue(cb._duration)
    cb:SetAlpha(1)
    ApplyCastBarColor(cb)
    if cb.Icon and texture and cfg.CBshowIcon then
        cb.Icon:SetTexture(texture)
    end
    if cb.name and cfg.CBshowName then
        cb.name:SetText(name)
    end
    ActivateCastBarOnUpdate(cb)
    cb:Show()
end

local function ResetCastBar(cb)
    if not cb then
        return
    end
    cb._casting = nil
    cb._channeling = nil
    cb._fadeOut = nil
    cb._holdUntil = nil
    cb._duration = nil
    cb._max = nil
    cb._noInterrupt = nil
    cb:SetAlpha(1)
    cb:Hide()
    if cb.name then
        cb.name:SetText("")
    end
    if cb.Icon then
        cb.Icon:SetTexture(nil)
    end
    DeactivateCastBarOnUpdate(cb)
end

local function PlateMatchesUnit(frame, unit)
    if not frame or not frame.oldname or not frame.healthBar then
        return false
    end
    if not frame:IsShown() then
        return false
    end
    if unit == "target" then
        return UnitExists("target") and frame:GetAlpha() > 0.99
    end
    if not UnitExists(unit) then
        return false
    end
    if frame._unit then
        if frame._unit ~= unit then
            return false
        end
    else
        local unitName = UnitName(unit)
        if not unitName then
            return false
        end
        local plateName = frame.oldname:GetText() or ""
        plateName = string.gsub(plateName, "%s%(%*%)", "")
        if plateName ~= unitName then
            return false
        end
        local unitHP = UnitHealth(unit) or 0
        local plateHP = frame.healthBar:GetValue() or 0
        if math.abs(plateHP - unitHP) >= 0.5 then
            return false
        end
        frame._unit = unit
    end
    if unit == "mouseover" then
        local hl = frame.highlight
        if not (hl and hl:IsShown()) then
            return false
        end
    end
    return true
end

local function IsAppearanceOutdated(frame, healthBar)
    local castbar = frame.customCastBar
    local w, h = healthBar:GetSize()
    if w ~= cfg.HPwidth or h ~= cfg.HPheight then
        return true
    end

    local p, _, rp, x, y = healthBar:GetPoint()
    if p ~= "CENTER" or rp ~= "CENTER" or x ~= 0 or y ~= -10 then
        return true
    end

    local nFont, nSize, nFlags = frame.name:GetFont()
    local np, _, nrp, nx, ny = frame.name:GetPoint()
    if nFont ~= media.font or nSize ~= cfg.NameFontSize or nFlags ~= (cfg.NameFlags or "OUTLINE") or np ~= cfg.Npoint or
        nrp ~= cfg.NrelativePoint or nx ~= cfg.Nx or ny ~= cfg.Ny then
        return true
    end
    if frame.name:GetWidth() ~= (cfg.NameWidth or 0) then
        return true
    end
    if frame.name:GetJustifyH() ~= GetJustifyFromAnchor(cfg.Npoint) then
        return true
    end
    if ShadowOutdated(frame.name, cfg.NameShadow, cfg.NameShadowX, cfg.NameShadowY, cfg.NameShadowColor) then
        return true
    end

    local lFont, lSize, lFlags = frame.level:GetFont()
    if lFont ~= media.levelFont or lSize ~= cfg.LvLFontSize or lFlags ~= (cfg.LvLFlags or "OUTLINE") then
        return true
    end
    if ShadowOutdated(frame.level, cfg.LvLShadow, cfg.LvLShadowX, cfg.LvLShadowY, cfg.LvLShadowColor) then
        return true
    end

    if frame.healthText then
        local hFont, hSize, hFlags = frame.healthText:GetFont()
        if hFont ~= media.healthFont or hSize ~= cfg.HPtextSize or hFlags ~= (cfg.HPtextFlags or "") then
            return true
        end
        if cfg.HPtextShow ~= frame.healthText:IsShown() then
            return true
        end
        if ShadowOutdated(frame.healthText, cfg.HPtextShadow, cfg.HPtextShadowX, cfg.HPtextShadowY,
            cfg.HPtextShadowColor) then
            return true
        end
    end

    if frame.healthPct then
        local pFont, pSize, pFlags = frame.healthPct:GetFont()
        if pFont ~= media.healthPctFont or pSize ~= cfg.HPpctSize or pFlags ~= (cfg.HPpctFlags or "") then
            return true
        end
        if cfg.HPpctShow ~= frame.healthPct:IsShown() then
            return true
        end
        if ShadowOutdated(frame.healthPct, cfg.HPpctShadow, cfg.HPpctShadowX, cfg.HPpctShadowY, cfg.HPpctShadowColor) then
            return true
        end
    end

    if castbar then
        if castbar:GetHeight() ~= cfg.CBheight or castbar:GetWidth() ~= GetCastBarWidth() then
            return true
        end
        local cp, _, crp, cx, cy = castbar:GetPoint()
        if cp ~= cfg.CBpoint or crp ~= cfg.CBrelativePoint or cx ~= cfg.CBx or cy ~= cfg.CBy then
            return true
        end
        if cfg.CBborderShow then
            if castbar.borderFrame and castbar.borderApplied then
                local ba = castbar.borderApplied
                if ba.edge ~= cfg.CBborderSize or ba.inset ~= cfg.CBborderInset or
                    not BorderFrameIsShown(castbar.borderFrame) or ba.tex ~= media.cbBorderTex or ba.colorR ~=
                    cfg.CBborderColor.r or ba.colorG ~= cfg.CBborderColor.g or ba.colorB ~= cfg.CBborderColor.b then
                    return true
                end
            else
                return true
            end
        elseif castbar.borderFrame and BorderFrameIsShown(castbar.borderFrame) then
            return true
        end
        if cfg.CBshowIcon then
            if not castbar.Icon then
                return true
            end
            local ip, _, irp, ix, iy = castbar.Icon:GetPoint()
            if ip ~= cfg.CBiconPoint or irp ~= cfg.CBiconRelativePoint or ix ~= cfg.CBiconX or iy ~= cfg.CBiconY then
                return true
            end
            local tl, tr, tt, tb = castbar.Icon:GetTexCoord()
            local etl, etr, ett, etb = GetCastIconTexCoord()
            if tl ~= etl or tr ~= etr or tt ~= ett or tb ~= etb then
                return true
            end
        elseif castbar.Icon then
            return true
        end
        if cfg.CBiconBorderShow and cfg.CBshowIcon then
            if castbar.iconBorderFrame and castbar.iconBorderApplied then
                local iba = castbar.iconBorderApplied
                if iba.edge ~= cfg.CBiconBorderSize or iba.inset ~= cfg.CBiconBorderInset or
                    not BorderFrameIsShown(castbar.iconBorderFrame) or iba.tex ~= media.iconBorderTex or iba.colorR ~=
                    cfg.CBiconBorderColor.r or iba.colorG ~= cfg.CBiconBorderColor.g or iba.colorB ~=
                    cfg.CBiconBorderColor.b then
                    return true
                end
            else
                return true
            end
        elseif castbar.iconBorderFrame and BorderFrameIsShown(castbar.iconBorderFrame) then
            return true
        end
        if castbar.name then
            local nf, ns_, flags = castbar.name:GetFont()
            if nf ~= media.nameFont or ns_ ~= cfg.CBnameFontSize or flags ~= (cfg.CBnameFlags or "") then
                return true
            end
            local cnp, _, cnrp, cnx, cny = castbar.name:GetPoint()
            if cnp ~= cfg.CBnamePoint or cnrp ~= cfg.CBnameRelativePoint or cnx ~= cfg.CBnameX or cny ~= cfg.CBnameY then
                return true
            end
            if castbar.name:GetJustifyH() ~= GetJustifyFromAnchor(cfg.CBnamePoint) then
                return true
            end
            if ShadowOutdated(castbar.name, cfg.CBnameShadow, cfg.CBnameShadowX, cfg.CBnameShadowY,
                cfg.CBnameShadowColor) then
                return true
            end
        end
    end

    if cfg.HPborderShow then
        if healthBar.hpBorder and healthBar.hpBorderApplied then
            local a = healthBar.hpBorderApplied
            if a.edge ~= cfg.border or a.inset ~= cfg.borderInset or not BorderFrameIsShown(healthBar.hpBorder) or a.tex ~=
                media.glowTex or a.colorR ~= cfg.borderColor.r or a.colorG ~= cfg.borderColor.g or a.colorB ~=
                cfg.borderColor.b then
                return true
            end
        else
            return true
        end
    elseif healthBar.hpBorder and BorderFrameIsShown(healthBar.hpBorder) then
        return true
    end

    local tex = healthBar:GetStatusBarTexture()
    if not tex or tex:GetTexture() ~= media.normTex then
        return true
    end

    if healthBar.hpBackground then
        if healthBar.hpBackground:GetTexture() ~= media.hpBgTex then
            return true
        end
        local br, bg, bb = healthBar.hpBackground:GetVertexColor()
        local c = cfg.HPbgColor
        if br ~= (c.r or 0.15) or bg ~= (c.g or 0.15) or bb ~= (c.b or 0.15) then
            return true
        end
    end

    return false
end

local function ApplyHealthBarLayout(frame)
    local hb = frame.healthBar
    if not hb then
        return
    end
    hb:ClearAllPoints()
    hb:SetPoint("CENTER", frame, 0, -10)
    hb:SetHeight(cfg.HPheight)
    hb:SetWidth(cfg.HPwidth)

    frame.level:ClearAllPoints()
    frame.level:SetPoint(cfg.LvLpoint, hb, cfg.LvLrelativePoint, cfg.LvLx, cfg.LvLy)

    if frame.raidIcon then
        frame.raidIcon:SetSize(cfg.raidIconSize, cfg.raidIconSize)
        frame.raidIcon:ClearAllPoints()
        frame.raidIcon:SetPoint(cfg.raidIconPoint, hb, cfg.raidIconRelativePoint, cfg.raidIconX, cfg.raidIconY)
    end
    if frame.healthText then
        frame.healthText:ClearAllPoints()
        frame.healthText:SetPoint(cfg.HPtextPoint, hb, cfg.HPtextRelativePoint, cfg.HPtextX, cfg.HPtextY)
    end
    if frame.healthPct then
        frame.healthPct:ClearAllPoints()
        frame.healthPct:SetPoint(cfg.HPpctPoint, hb, cfg.HPpctRelativePoint, cfg.HPpctX, cfg.HPpctY)
    end
end

local function FormatHealthValue(v)
    if v <= 0 then
        return ""
    end
    if not cfg.HPtextShorten then
        if v < 1 then
            return string.format("%.1f", v)
        end
        return tostring(math.floor(v))
    end
    if v < 1 then
        return string.format("%.1f", v)
    end
    if v >= 100000000 then
        return string.format("%.0fm", v / 1000000)
    elseif v >= 10000000 then
        return string.format("%.1fm", v / 1000000)
    elseif v >= 1000000 then
        return string.format("%.2fm", v / 1000000)
    elseif v >= 100000 then
        return string.format("%.0fk", v / 1000)
    elseif v >= 10000 then
        return string.format("%.1fk", v / 1000)
    else
        return tostring(math.floor(v))
    end
end

local function RefreshHealthText(frame)
    local ht = frame.healthText
    if not ht then
        return
    end
    if not cfg.HPtextShow then
        if ht:IsShown() then
            ht:Hide()
        end
        return
    end
    local hb = frame.healthBar
    if not hb then
        return
    end

    local val = hb:GetValue() or 0
    local _, max = hb:GetMinMaxValues()
    if not max or max <= 0 or val <= 0 then
        if ht._lastText ~= "" then
            ht._lastText = ""
            ht:SetText("")
        end
        if ht:IsShown() then
            ht:Hide()
        end
        return
    end
    local text = FormatHealthValue(val)
    if ht._lastText ~= text then
        ht._lastText = text
        ht:SetText(text)
    end
    if not ht:IsShown() then
        ht:Show()
    end
end

local function RefreshHealthPercent(frame)
    local hp = frame.healthPct
    if not hp then
        return
    end
    if not cfg.HPpctShow then
        if hp:IsShown() then
            hp:Hide()
        end
        return
    end
    local hb = frame.healthBar
    if not hb then
        return
    end

    local val = hb:GetValue() or 0
    local _, max = hb:GetMinMaxValues()
    if not max or max <= 0 or val <= 0 then
        if hp._lastText ~= "" then
            hp._lastText = ""
            hp:SetText("")
        end
        if hp:IsShown() then
            hp:Hide()
        end
        return
    end
    local pct = val / max * 100
    if pct > 100 then
        pct = 100
    end
    if pct < 0 then
        pct = 0
    end
    local text = string.format("%d%%", math.floor(pct + 0.5))
    if hp._lastText ~= text then
        hp._lastText = text
        hp:SetText(text)
    end
    if not hp:IsShown() then
        hp:Show()
    end
end

local function HealthBar_OnValueChanged(self, value)
    local frame = self.ownerFrame
    if not frame then
        return
    end
    RefreshHealthText(frame)
    RefreshHealthPercent(frame)
    ApplyHealthBarColor(frame)
end

function AeonoPlates:ReskinFrame(frame)
    local healthBar = frame.healthBar
    if not healthBar then
        return
    end

    if frame.highlight then
        ApplyHighlight(frame)
    end

    ApplyHealthBarColor(frame)

    if not IsAppearanceOutdated(frame, healthBar) then
        ApplyNameColor(frame)
        ApplyClassificationIcon(frame)
        return
    end

    ApplyHealthBarLayout(frame)

    frame.name:ClearAllPoints()
    frame.name:SetPoint(cfg.Npoint, healthBar, cfg.NrelativePoint, cfg.Nx, cfg.Ny)
    frame.name:SetFont(media.font, cfg.NameFontSize, cfg.NameFlags or "OUTLINE")
    frame.name:SetJustifyH(GetJustifyFromAnchor(cfg.Npoint))
    ApplyTextShadow(frame.name, cfg.NameShadow, cfg.NameShadowX, cfg.NameShadowY, cfg.NameShadowColor)
    if cfg.NameWidth and cfg.NameWidth > 0 then
        frame.name:SetWidth(cfg.NameWidth)
        frame.name:SetWordWrap(false)
    else
        frame.name:SetWidth(0)
        frame.name:SetWordWrap(true)
    end

    frame.level:SetFont(media.levelFont, cfg.LvLFontSize, cfg.LvLFlags or "OUTLINE")
    ApplyTextShadow(frame.level, cfg.LvLShadow, cfg.LvLShadowX, cfg.LvLShadowY, cfg.LvLShadowColor)

    if frame.healthText then
        frame.healthText:SetFont(media.healthFont, cfg.HPtextSize, cfg.HPtextFlags or "")
        ApplyTextShadow(frame.healthText, cfg.HPtextShadow, cfg.HPtextShadowX, cfg.HPtextShadowY, cfg.HPtextShadowColor)
        RefreshHealthText(frame)
    end
    if frame.healthPct then
        frame.healthPct:SetFont(media.healthPctFont, cfg.HPpctSize, cfg.HPpctFlags or "")
        ApplyTextShadow(frame.healthPct, cfg.HPpctShadow, cfg.HPpctShadowX, cfg.HPpctShadowY, cfg.HPpctShadowColor)
        RefreshHealthPercent(frame)
    end

    healthBar:SetStatusBarTexture(media.normTex)

    if healthBar.hpBackground then
        healthBar.hpBackground:SetTexture(media.hpBgTex)
        local c = cfg.HPbgColor
        healthBar.hpBackground:SetVertexColor(c.r or 0.15, c.g or 0.15, c.b or 0.15, c.a or 0.7)
    end

    if cfg.HPborderShow then
        if not healthBar.hpBorder then
            healthBar.hpBorder = CreateBorderFrame(healthBar, healthBar, 1)
        end
        UpdateBorderFrame(healthBar.hpBorder, healthBar, media.glowTex, cfg.border, cfg.borderInset, cfg.borderColor.r,
            cfg.borderColor.g, cfg.borderColor.b)
        healthBar.hpBorderApplied = {
            edge = cfg.border,
            inset = cfg.borderInset,
            tex = media.glowTex,
            colorR = cfg.borderColor.r,
            colorG = cfg.borderColor.g,
            colorB = cfg.borderColor.b
        }
    elseif healthBar.hpBorder then
        HideBorderFrame(healthBar.hpBorder)
        healthBar.hpBorderApplied = nil
    end

    local castbar = frame.customCastBar
    if castbar then
        castbar:SetHeight(cfg.CBheight)
        castbar:SetWidth(GetCastBarWidth())
        castbar:SetStatusBarTexture(media.cbBarTex)
        castbar:ClearAllPoints()
        castbar:SetPoint(cfg.CBpoint, healthBar, cfg.CBrelativePoint, cfg.CBx, cfg.CBy)

        if castbar.Border then
            castbar.Border:SetTexture(media.cbBgTex)
            if cfg.CBcolorBorder then
                castbar.Border:SetVertexColor(cfg.CBcolorBorder.r, cfg.CBcolorBorder.g, cfg.CBcolorBorder.b,
                    cfg.CBcolorBorder.a or 1)
            end
        end

        if cfg.CBborderShow then
            if not castbar.borderFrame then
                castbar.borderFrame = CreateBorderFrame(castbar, castbar, 1)
            end
            UpdateBorderFrame(castbar.borderFrame, castbar, media.cbBorderTex, cfg.CBborderSize, cfg.CBborderInset,
                cfg.CBborderColor.r, cfg.CBborderColor.g, cfg.CBborderColor.b)
            castbar.borderApplied = {
                edge = cfg.CBborderSize,
                inset = cfg.CBborderInset,
                tex = media.cbBorderTex,
                colorR = cfg.CBborderColor.r,
                colorG = cfg.CBborderColor.g,
                colorB = cfg.CBborderColor.b
            }
        elseif castbar.borderFrame then
            HideBorderFrame(castbar.borderFrame)
            castbar.borderApplied = nil
        end

        if cfg.CBshowIcon then
            local icon = castbar.Icon
            if not icon then
                icon = castbar:CreateTexture(nil, "ARTWORK")
                castbar.Icon = icon
            end
            local iconSize = (cfg.CBiconSize and cfg.CBiconSize > 0) and cfg.CBiconSize or 16
            icon:SetSize(iconSize, iconSize)
            icon:ClearAllPoints()
            icon:SetPoint(cfg.CBiconPoint, castbar, cfg.CBiconRelativePoint, cfg.CBiconX, cfg.CBiconY)
            icon:SetTexCoord(GetCastIconTexCoord())
            icon:Show()
        elseif castbar.Icon then
            castbar.Icon:Hide()
        end

        if cfg.CBiconBorderShow and cfg.CBshowIcon and castbar.Icon then
            if not castbar.iconBorderFrame then
                castbar.iconBorderFrame = CreateBorderFrame(castbar, castbar.Icon, 2)
            else
                castbar.iconBorderFrame._anchorTarget = castbar.Icon
            end
            UpdateBorderFrame(castbar.iconBorderFrame, castbar.Icon, media.iconBorderTex, cfg.CBiconBorderSize,
                cfg.CBiconBorderInset, cfg.CBiconBorderColor.r, cfg.CBiconBorderColor.g, cfg.CBiconBorderColor.b)
            castbar.iconBorderApplied = {
                edge = cfg.CBiconBorderSize,
                inset = cfg.CBiconBorderInset,
                tex = media.iconBorderTex,
                colorR = cfg.CBiconBorderColor.r,
                colorG = cfg.CBiconBorderColor.g,
                colorB = cfg.CBiconBorderColor.b
            }
        elseif castbar.iconBorderFrame then
            HideBorderFrame(castbar.iconBorderFrame)
            castbar.iconBorderApplied = nil
        end

        if castbar.name then
            castbar.name:SetFont(media.nameFont, cfg.CBnameFontSize, cfg.CBnameFlags or "")
            castbar.name:ClearAllPoints()
            castbar.name:SetPoint(cfg.CBnamePoint, castbar, cfg.CBnameRelativePoint, cfg.CBnameX, cfg.CBnameY)
            castbar.name:SetJustifyH(GetJustifyFromAnchor(cfg.CBnamePoint))
            ApplyTextShadow(castbar.name, cfg.CBnameShadow, cfg.CBnameShadowX, cfg.CBnameShadowY, cfg.CBnameShadowColor)
            local nc = cfg.CBnameColor
            if nc then
                castbar.name:SetTextColor(nc.r or 1, nc.g or 1, nc.b or 1)
            end
            if cfg.CBnameTruncate and cfg.CBnameTruncate > 0 then
                castbar.name:SetWidth(cfg.CBnameTruncate)
                castbar.name:SetWordWrap(false)
            else
                castbar.name:SetWidth(0)
                castbar.name:SetWordWrap(true)
            end
            if not cfg.CBshowName then
                castbar.name:Hide()
            end
        end
    end

    ApplyNameColor(frame)
    ApplyClassificationIcon(frame)
end

local function SetStackingForFrame(frame, enabled)
    if enabled then
        if not stackableFrames[frame] then
            stackableFrames[frame] = {
                xpos = 0,
                ypos = 0,
                position = 0
            }
        end
    else
        if stackableFrames[frame] then
            stackableFrames[frame] = nil
            frame:SetClampedToScreen(false)
            frame:SetClampRectInsets(0, 0, 0, 0)
        end
    end
end

function AeonoPlates:ReskinAll()
    for frame in pairs(styledFrames) do
        self:ReskinFrame(frame)
        if frame:IsShown() then
            SetStackingForFrame(frame, cfg.stackingEnabled)
        end
    end
end

function AeonoPlates:RefreshConfigAndReskin()
    self:RefreshConfig()
    self:ReskinAll()
end

local sortBuffer = {}
local priorityBuffer = {}

local function ReorderFrameLevels()
    if not next(visibleFrames) then
        if #previousFrameOrder > 0 then
            wipe(previousFrameOrder)
        end
        return
    end
    wipe(sortBuffer)
    local hasTarget = UnitExists("target")

    for frame in pairs(visibleFrames) do
        local virtual = frame.VirtualPlate
        if virtual then
            local d = virtual:GetEffectiveDepth()
            if d > 0 then
                sortBuffer[#sortBuffer + 1] = frame
                local hl = frame.highlight
                local isMouseover = hl and hl:IsShown()
                local isTarget = hasTarget and frame:GetAlpha() > 0.99
                local prio
                if isMouseover then
                    prio = -2
                elseif isTarget then
                    prio = -1
                else
                    prio = d
                end
                priorityBuffer[frame] = prio
            end
        end
    end

    if #sortBuffer == 0 then
        if #previousFrameOrder > 0 then
            wipe(previousFrameOrder)
        end
        return
    end

    table.sort(sortBuffer, function(a, b)
        return priorityBuffer[a] > priorityBuffer[b]
    end)

    local same = (#previousFrameOrder == #sortBuffer)
    if same then
        for i = 1, #sortBuffer do
            if previousFrameOrder[i] ~= sortBuffer[i] then
                same = false;
                break
            end
        end
    end

    if same then
        for i = 1, #sortBuffer do
            priorityBuffer[sortBuffer[i]] = nil
        end
        wipe(sortBuffer)
        return
    end

    wipe(previousFrameOrder)
    for i, frame in ipairs(sortBuffer) do
        previousFrameOrder[i] = frame
        local virtual = frame.VirtualPlate
        local base = i * FRAME_LEVELS_PER_PLATE
        virtual:SetFrameLevel(base)
        local hb = frame.healthBar
        if hb then
            hb:SetFrameLevel(base)
            if hb.hpBorder then
                hb.hpBorder:SetFrameLevel(base + 1)
            end
        end
        local cb = frame.customCastBar
        if cb then
            cb:SetFrameLevel(base - 1)
            if cb.borderFrame then
                cb.borderFrame:SetFrameLevel(base)
            end
            if cb.iconBorderFrame then
                cb.iconBorderFrame:SetFrameLevel(base + 1)
            end
        end
        priorityBuffer[frame] = nil
    end
    wipe(sortBuffer)
end

local function IsMouseoverByName(frame)
    local hl = frame.highlight
    if not hl then
        return false
    end
    return hl:IsShown()
end

local function IsFriendlyFrame(frame)
    local t = frame._hpType
    if not t then
        t = GetPlateType(frame)
        frame._hpType = t
    end
    return t == "friendly_player" or t == "friendly_npc"
end

local function UpdateStacking()
    if not cfg.stackingEnabled then
        return
    end
    if not next(stackableFrames) then
        return
    end

    local xspace = cfg.stackingXSpace or 130
    local yspace = cfg.stackingYSpace or 15
    local wfWidth = WorldFrame:GetWidth()
    local stackSpeed = cfg.stackingSpeed or STACK_DELTA_FALLBACK
    local STACK_DELTA = stackSpeed

    local skipped = {}
    for frame in pairs(stackableFrames) do
        if IsFriendlyFrame(frame) then
            skipped[frame] = true
            stackableFrames[frame].position = 0
            if frame:IsClampedToScreen() then
                frame:SetClampedToScreen(false)
                frame:SetClampRectInsets(0, 0, 0, 0)
            end
        end
    end

    for frame, data in pairs(stackableFrames) do
        if not skipped[frame] and frame:IsShown() then
            local width, height = frame:GetSize()
            local _, _, _, x, y = frame:GetPoint(1)
            if x and y then
                data.xpos = x
                data.ypos = y
                if cfg.stackingFreezeMouseover and IsMouseoverByName(frame) then
                    local cx, cy = frame:GetCenter()
                    if cx and cy then
                        data.position = cy - data.ypos + height / 2
                        data.xpos = cx
                        frame:SetClampedToScreen(true)
                        frame:SetClampRectInsets(-2 * wfWidth, wfWidth - cx - width / 2, 768 - cy - height / 2, -2 * 768)
                    end
                else
                    local min = 1000
                    local reset = true
                    for other, otherData in pairs(stackableFrames) do
                        if frame ~= other and not skipped[other] then
                            local xdiff = data.xpos - otherData.xpos
                            local ydiff = data.ypos + data.position - otherData.ypos - otherData.position
                            local ydiffOrigin = data.ypos - otherData.ypos - otherData.position
                            if math.abs(xdiff) < xspace then
                                if ydiff >= 0 and math.abs(ydiff) < min then
                                    min = math.abs(ydiff)
                                end
                                if math.abs(ydiffOrigin) < yspace then
                                    reset = false
                                end
                            end
                        end
                    end
                    local oldPosition = data.position
                    local newPosition = oldPosition
                    if oldPosition >= STACK_DELTA and reset then
                        newPosition = oldPosition - math.exp(-10 / oldPosition) * stackSpeed
                    elseif min < yspace then
                        newPosition = oldPosition + math.exp(-min / yspace) * stackSpeed
                    elseif oldPosition >= STACK_DELTA and min > yspace + STACK_DELTA then
                        newPosition = oldPosition - math.exp(-yspace / min) * stackSpeed * 0.8
                    end
                    data.position = newPosition
                    frame:SetClampedToScreen(true)
                    frame:SetClampRectInsets(0.5 * width, -0.5 * width, -height, -data.ypos - newPosition + height)
                end
            end
        end
    end
end

local function OnFrameHide(self)
    visibleFrames[self] = nil
    if mouseoverFrame == self then
        mouseoverFrame = nil
    end
    if stackableFrames[self] then
        stackableFrames[self] = nil
        self:SetClampedToScreen(false)
        self:SetClampRectInsets(0, 0, 0, 0)
    end
    self._lastNameString = nil
    self._unit = nil
    ResetPlateColorCache(self)
    if self.customCastBar then
        ResetCastBar(self.customCastBar)
    end
end

local function OnFrameShow(self)
    visibleFrames[self] = true
    if cfg.stackingEnabled then
        stackableFrames[self] = {
            xpos = 0,
            ypos = 0,
            position = 0
        }
    end
    if self.customCastBar then
        ResetCastBar(self.customCastBar)
    end

    local hl = self.highlight
    local hb = self.healthBar
    if hl and hb then
        hl:Hide()
        hl:ClearAllPoints()
        hl:SetPoint("TOPLEFT", hb, "TOPLEFT", 0, 0)
        hl:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 0, 0)
        hl:SetDrawLayer("OVERLAY", 7)
    end

    if self.oldname and self.name then
        local nameString = self.oldname:GetText()
        if nameString ~= self._lastNameString then
            self._lastNameString = nameString
            self.name:SetText(nameString or "")
        end
    end

    ApplyHealthBarLayout(self)
    RefreshHealthText(self)
    RefreshHealthPercent(self)

    ResetPlateColorCache(self)
    ApplyHealthBarColor(self)
    ApplyNameColor(self)
    ApplyClassificationIcon(self)
end

local function FinishCast(cb, success, now)
    cb._casting = nil
    cb._channeling = nil
    cb._noInterrupt = nil
    if not cb._updateActive then
        ActivateCastBarOnUpdate(cb)
    end
    local c = success and cfg.CBcolorSuccess or cfg.CBcolorFailed
    if c then
        cb:SetStatusBarColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end
    if cb.name and cfg.CBshowName then
        cb.name:SetText(success and "Success" or "Failed")
    end
    cb._holdUntil = (now or GetTime()) + (success and cfg.CBholdSuccess or cfg.CBholdFailed)
    cb._fadeOut = true
end

local function CastBar_OnEvent(self, event, ...)
    local unit = ...
    if not unit or unit == "player" then
        return
    end
    local frame = self.ownerFrame
    if not frame then
        return
    end
    if not PlateMatchesUnit(frame, unit) then
        return
    end

    if event == "UNIT_SPELLCAST_START" then
        local name, _, _, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
        if not name then
            return
        end
        self._casting = true
        self._channeling = nil
        self._fadeOut = nil
        self._holdUntil = nil
        self._noInterrupt = notInterruptible and true or nil
        self._duration = GetTime() - (startTime / 1000)
        self._max = (endTime - startTime) / 1000
        self:SetMinMaxValues(0, self._max)
        self:SetValue(self._duration)
        self:SetAlpha(1)
        ApplyCastBarColor(self)
        if self.Icon and texture and cfg.CBshowIcon then
            self.Icon:SetTexture(texture)
        end
        if self.name and cfg.CBshowName then
            self.name:SetText(name)
        end
        ActivateCastBarOnUpdate(self)
        self:Show()
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local name, _, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        if not name then
            return
        end
        self._casting = nil
        self._channeling = true
        self._fadeOut = nil
        self._holdUntil = nil
        self._noInterrupt = notInterruptible and true or nil
        self._duration = (endTime / 1000) - GetTime()
        self._max = (endTime - startTime) / 1000
        self:SetMinMaxValues(0, self._max)
        self:SetValue(self._duration)
        self:SetAlpha(1)
        ApplyCastBarColor(self)
        if self.Icon and texture and cfg.CBshowIcon then
            self.Icon:SetTexture(texture)
        end
        if self.name and cfg.CBshowName then
            self.name:SetText(name)
        end
        ActivateCastBarOnUpdate(self)
        self:Show()
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if self._casting or self._channeling then
            FinishCast(self, true)
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        if self._casting or self._channeling then
            FinishCast(self, false)
        end
    elseif event == "UNIT_SPELLCAST_DELAYED" then
        if self:IsShown() and self._casting then
            local name, _, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
            if name then
                self._duration = GetTime() - (startTime / 1000)
                self._max = (endTime - startTime) / 1000
                self._noInterrupt = notInterruptible and true or nil
                self:SetMinMaxValues(0, self._max)
                self:SetValue(self._duration)
                ApplyCastBarColor(self)
            end
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        if self:IsShown() and self._channeling then
            local name, _, _, _, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
            if name then
                self._duration = (endTime / 1000) - GetTime()
                self._max = (endTime - startTime) / 1000
                self._noInterrupt = notInterruptible and true or nil
                self:SetMinMaxValues(0, self._max)
                self:SetValue(self._duration)
                ApplyCastBarColor(self)
            end
        end
    end
end

function AeonoPlates:OnSpellcastEvent(event, unit)
    if not unit or unit == "player" then
        return
    end
    for plate in pairs(visibleFrames) do
        local cb = plate.customCastBar
        if cb and PlateMatchesUnit(plate, unit) then
            CastBar_OnEvent(cb, event, unit)
            return
        end
    end
end

CastBar_OnUpdate = function(self, elapsed)
    if not self._casting and not self._channeling and not self._fadeOut then
        return
    end
    local now = GetTime()
    if self._casting then
        local d = (self._duration or 0) + elapsed
        if d >= self._max then
            self:SetValue(self._max)
            FinishCast(self, true, now)
        else
            self._duration = d
            self:SetValue(d)
        end
    elseif self._channeling then
        local d = (self._duration or 0) - elapsed
        if d <= 0 then
            self:SetValue(0)
            FinishCast(self, true, now)
        else
            self._duration = d
            self:SetValue(d)
        end
    end
    if self._fadeOut then
        if self._holdUntil and now < self._holdUntil then
            return
        end
        self._holdUntil = nil
        local alpha = self:GetAlpha() - (elapsed / (cfg.CBfadeTime or 0.2))
        if alpha > 0.05 then
            self:SetAlpha(alpha)
        else
            ResetCastBar(self)
        end
    end
end

local function SkinNameplate(frame)
    local children = {frame:GetChildren()}
    local regions = {frame:GetRegions()}

    local healthBar = children[1]
    local castBar = children[2]
    local glowRegion, overlayRegion, castBarOverlay, shieldedRegion, spellIconRegion, _, nameTextRegion,
        levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = unpack(regions)

    local virtual = CreateFrame("Frame", nil, frame)
    virtual.RealPlate = frame
    frame.VirtualPlate = virtual
    virtual:SetAllPoints(frame)

    local baseLevel = frame:GetFrameLevel()
    for i = 1, #children do
        local child = children[i]
        local offset = child:GetFrameLevel() - baseLevel
        child:SetParent(virtual)
        child:SetFrameLevel(virtual:GetFrameLevel() + offset)
    end
    if healthBar then
        healthBar.ownerFrame = frame
    end
    for i = 1, #regions do
        regions[i]:SetParent(virtual)
    end

    virtual:EnableDrawLayer("HIGHLIGHT")

    do
        local byIndex = select(regionIndex.highlightTexture, virtual:GetRegions())
        if byIndex then
            frame.highlight = byIndex
        else
            frame.highlight = GetHighlightRegion(frame)
        end
        if frame.highlight then
            ApplyHighlight(frame)
        end
    end

    frame.healthBar = healthBar
    frame.castBar = castBar

    frame.oldname = nameTextRegion
    nameTextRegion:Hide()
    nameTextRegion.Show = Noop

    frame.name = virtual:CreateFontString()
    frame.name:SetPoint(cfg.Npoint, healthBar, cfg.NrelativePoint, cfg.Nx, cfg.Ny)
    frame.name:SetFont(media.font, cfg.NameFontSize, cfg.NameFlags or "OUTLINE")
    frame.name:SetJustifyH(GetJustifyFromAnchor(cfg.Npoint))
    ApplyTextShadow(frame.name, cfg.NameShadow, cfg.NameShadowX, cfg.NameShadowY, cfg.NameShadowColor)
    if cfg.NameWidth and cfg.NameWidth > 0 then
        frame.name:SetWidth(cfg.NameWidth)
        frame.name:SetWordWrap(false)
    else
        frame.name:SetWidth(0)
        frame.name:SetWordWrap(true)
    end

    local nameString = nameTextRegion:GetText()
    frame._lastNameString = nameString
    frame.name:SetText(nameString or "")
    ApplyNameColor(frame)

    frame.level = levelTextRegion
    levelTextRegion:SetFont(media.levelFont, cfg.LvLFontSize, cfg.LvLFlags or "OUTLINE")
    ApplyTextShadow(levelTextRegion, cfg.LvLShadow, cfg.LvLShadowX, cfg.LvLShadowY, cfg.LvLShadowColor)
    frame.boss = bossIconRegion

    frame.raidIcon = raidIconRegion
    raidIconRegion:SetSize(cfg.raidIconSize, cfg.raidIconSize)
    raidIconRegion:ClearAllPoints()
    raidIconRegion:SetPoint(cfg.raidIconPoint, healthBar, cfg.raidIconRelativePoint, cfg.raidIconX, cfg.raidIconY)

    frame.healthText = healthBar:CreateFontString(nil, "OVERLAY")
    frame.healthText:SetPoint(cfg.HPtextPoint, healthBar, cfg.HPtextRelativePoint, cfg.HPtextX, cfg.HPtextY)
    frame.healthText:SetFont(media.healthFont, cfg.HPtextSize, cfg.HPtextFlags or "")
    ApplyTextShadow(frame.healthText, cfg.HPtextShadow, cfg.HPtextShadowX, cfg.HPtextShadowY, cfg.HPtextShadowColor)
    frame.healthText:SetText("")
    if not cfg.HPtextShow then
        frame.healthText:Hide()
    end

    frame.healthPct = healthBar:CreateFontString(nil, "OVERLAY")
    frame.healthPct:SetPoint(cfg.HPpctPoint, healthBar, cfg.HPpctRelativePoint, cfg.HPpctX, cfg.HPpctY)
    frame.healthPct:SetFont(media.healthPctFont, cfg.HPpctSize, cfg.HPpctFlags or "")
    ApplyTextShadow(frame.healthPct, cfg.HPpctShadow, cfg.HPpctShadowX, cfg.HPpctShadowY, cfg.HPpctShadowColor)
    frame.healthPct:SetText("")
    if not cfg.HPpctShow then
        frame.healthPct:Hide()
    end

    healthBar:SetStatusBarTexture(media.normTex)

    healthBar.hpBackground = healthBar:CreateTexture(nil, "BORDER")
    healthBar.hpBackground:SetAllPoints(healthBar)
    healthBar.hpBackground:SetTexture(media.hpBgTex)
    local bgc = cfg.HPbgColor
    healthBar.hpBackground:SetVertexColor(bgc.r or 0.15, bgc.g or 0.15, bgc.b or 0.15, bgc.a or 0.7)

    if cfg.HPborderShow then
        healthBar.hpBorder = CreateBorderFrame(healthBar, healthBar, 1)
        UpdateBorderFrame(healthBar.hpBorder, healthBar, media.glowTex, cfg.border, cfg.borderInset, cfg.borderColor.r,
            cfg.borderColor.g, cfg.borderColor.b)
        healthBar.hpBorderApplied = {
            edge = cfg.border,
            inset = cfg.borderInset,
            tex = media.glowTex,
            colorR = cfg.borderColor.r,
            colorG = cfg.borderColor.g,
            colorB = cfg.borderColor.b
        }
    end

    healthBar:HookScript("OnValueChanged", HealthBar_OnValueChanged)
    RefreshHealthText(frame)
    RefreshHealthPercent(frame)

    local castbar = CreateFrame("StatusBar", nil, virtual)
    castbar.ownerFrame = frame
    castbar:SetHeight(cfg.CBheight)
    castbar:SetWidth(GetCastBarWidth())
    castbar:SetStatusBarTexture(media.cbBarTex)
    local castTex = castbar:GetStatusBarTexture()
    if castTex then
        castTex:SetHorizTile(false)
        castTex:SetVertTile(false)
    end
    castbar:SetPoint(cfg.CBpoint, healthBar, cfg.CBrelativePoint, cfg.CBx, cfg.CBy)

    castbar.Border = castbar:CreateTexture(nil, "BACKGROUND")
    castbar.Border:SetSize(castBarOverlay:GetSize())
    castbar.Border:SetAllPoints(castbar)
    castbar.Border:SetTexture(media.cbBgTex)
    if cfg.CBcolorBorder then
        castbar.Border:SetVertexColor(cfg.CBcolorBorder.r, cfg.CBcolorBorder.g, cfg.CBcolorBorder.b,
            cfg.CBcolorBorder.a or 1)
    end

    if cfg.CBborderShow then
        castbar.borderFrame = CreateBorderFrame(castbar, castbar, 1)
        UpdateBorderFrame(castbar.borderFrame, castbar, media.cbBorderTex, cfg.CBborderSize, cfg.CBborderInset,
            cfg.CBborderColor.r, cfg.CBborderColor.g, cfg.CBborderColor.b)
        castbar.borderApplied = {
            edge = cfg.CBborderSize,
            inset = cfg.CBborderInset,
            tex = media.cbBorderTex,
            colorR = cfg.CBborderColor.r,
            colorG = cfg.CBborderColor.g,
            colorB = cfg.CBborderColor.b
        }
    end

    if cfg.CBshowIcon then
        castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")
        local iconSize = (cfg.CBiconSize and cfg.CBiconSize > 0) and cfg.CBiconSize or 16
        castbar.Icon:SetSize(iconSize, iconSize)
        castbar.Icon:SetPoint(cfg.CBiconPoint, castbar, cfg.CBiconRelativePoint, cfg.CBiconX, cfg.CBiconY)
        castbar.Icon:SetTexCoord(GetCastIconTexCoord())
    end

    if cfg.CBiconBorderShow and cfg.CBshowIcon and castbar.Icon then
        castbar.iconBorderFrame = CreateBorderFrame(castbar, castbar.Icon, 2)
        UpdateBorderFrame(castbar.iconBorderFrame, castbar.Icon, media.iconBorderTex, cfg.CBiconBorderSize,
            cfg.CBiconBorderInset, cfg.CBiconBorderColor.r, cfg.CBiconBorderColor.g, cfg.CBiconBorderColor.b)
        castbar.iconBorderApplied = {
            edge = cfg.CBiconBorderSize,
            inset = cfg.CBiconBorderInset,
            tex = media.iconBorderTex,
            colorR = cfg.CBiconBorderColor.r,
            colorG = cfg.CBiconBorderColor.g,
            colorB = cfg.CBiconBorderColor.b
        }
    end

    castbar.name = castbar:CreateFontString(nil, "ARTWORK")
    castbar.name:SetPoint(cfg.CBnamePoint, castbar, cfg.CBnameRelativePoint, cfg.CBnameX, cfg.CBnameY)
    castbar.name:SetFont(media.nameFont or media.font, cfg.CBnameFontSize, cfg.CBnameFlags or "")
    castbar.name:SetJustifyH(GetJustifyFromAnchor(cfg.CBnamePoint))
    ApplyTextShadow(castbar.name, cfg.CBnameShadow, cfg.CBnameShadowX, cfg.CBnameShadowY, cfg.CBnameShadowColor)
    if cfg.CBnameColor then
        castbar.name:SetTextColor(cfg.CBnameColor.r or 1, cfg.CBnameColor.g or 1, cfg.CBnameColor.b or 1)
    end
    if cfg.CBnameTruncate and cfg.CBnameTruncate > 0 then
        castbar.name:SetWidth(cfg.CBnameTruncate)
        castbar.name:SetWordWrap(false)
    end
    if not cfg.CBshowName then
        castbar.name:Hide()
    end

    frame.customCastBar = castbar
    castbar:Hide()
    castbar:SetAlpha(1)

    if castBar then
        castBar:SetAlpha(0)
        if spellIconRegion then
            spellIconRegion:SetSize(0.01, 0.01)
            spellIconRegion:SetAlpha(0)
        end
    end

    frame.oldglow = glowRegion
    frame:SetScript("OnHide", OnFrameHide)
    frame:SetScript("OnShow", OnFrameShow)

    styledFrames[frame] = true
    if frame:IsShown() then
        visibleFrames[frame] = true
        if cfg.stackingEnabled then
            stackableFrames[frame] = {
                xpos = 0,
                ypos = 0,
                position = 0
            }
        end
    end
    frame.stateIcon = stateIconRegion

    glowRegion:SetTexture(nil)
    overlayRegion:SetTexture(nil)
    shieldedRegion:SetTexture(nil)
    castBarOverlay:SetTexture(nil)
    bossIconRegion:SetTexture(nil)

    ApplyHealthBarLayout(frame)
    ApplyHealthBarColor(frame)
    ApplyNameColor(frame)
    ApplyClassificationIcon(frame)
end

local function HookFrames(...)
    for index = 1, select("#", ...) do
        local frame = select(index, ...)
        local region = frame:GetRegions()
        if (not styledFrames[frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" and
            region:GetTexture() == [=[Interface\TargetingFrame\UI-TargetingFrame-Flash]=]) then
            SkinNameplate(frame)
        end
    end
end

function AeonoPlates:OnMediaRegistered(event, mediatype)
    if mediatype == "font" or mediatype == "statusbar" or mediatype == "background" or mediatype == "border" then
        self:RefreshConfig()
        self:ReskinAll()
    end
end

function AeonoPlates:MigrateProfile()
    local function deepFill(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" then
                if type(target[k]) ~= "table" then
                    target[k] = {}
                end
                deepFill(target[k], v)
            elseif target[k] == nil then
                target[k] = v
            end
        end
    end
    if self.db and self.db.profile then
        deepFill(self.db.profile, ns.defaults.profile)
    end
end

local LDB = LibStub("LibDataBroker-1.1")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local minimapDataObject = LDB:NewDataObject("AeonoPlates", {
    type = "launcher",
    icon = "Interface\\Icons\\INV_Misc_Book_08",
    OnClick = function(_, button)
        if button == "LeftButton" or button == "RightButton" then
            AceConfigDialog:Open("AeonoPlates")
        end
    end,
    OnTooltipShow = function(self)
        self:AddLine("AeonoPlates")
        self:AddLine("Нажмите, чтобы открыть настройки")
    end
})

local minimapIcon

function AeonoPlates:ApplyMinimapIcon()
    if not minimapIcon then
        return
    end
    if self.db.profile.minimap.hide then
        minimapIcon:Hide("AeonoPlates")
    else
        minimapIcon:Show("AeonoPlates")
    end
end

function AeonoPlates:SetupMinimap()
    minimapIcon = LibStub("LibDBIcon-1.0")
    minimapIcon:Register("AeonoPlates", minimapDataObject, self.db.profile.minimap)
    self:ApplyMinimapIcon()
end

function AeonoPlates:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AeonoPlatesDB", ns.defaults, true)
    self:MigrateProfile()

    local mediaPath = "Interface\\AddOns\\AeonoPlates\\Media"
    LSM:Register("statusbar", "Midnight Healthbar", mediaPath .. "\\statusbar\\blizzbarfill.tga")
    LSM:Register("statusbar", "Midnight Cast", mediaPath .. "\\statusbar\\blizzcast.tga")
    LSM:Register("statusbar", "Midnight Cast Channel", mediaPath .. "\\statusbar\\blizzcastchannel.tga")
    LSM:Register("statusbar", "Midnight Cast Nonbreakable", mediaPath .. "\\statusbar\\blizzcastnonbreakable.tga")
    LSM:Register("statusbar", "Midnight Cast Background", mediaPath .. "\\statusbar\\blizzcastback.tga")
    LSM:Register("border", "Midnight Border", mediaPath .. "\\border\\blizzborder.tga")

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfigAndReskin")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfigAndReskin")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfigAndReskin")

    LSM.RegisterCallback(self, "LibSharedMedia_Registered", "OnMediaRegistered")
    self:RefreshConfig()
end

function AeonoPlates:_RefreshTargetCastBars()
    local hasTarget = UnitExists("target")
    for frame in pairs(visibleFrames) do
        local cb = frame.customCastBar
        if cb then
            local hl = frame.highlight
            local isMO = hl and hl:IsShown()
            local isT = hasTarget and frame:GetAlpha() > 0.99
            if isMO then

            elseif isT then
                local name = UnitCastingInfo("target")
                if not name then
                    name = UnitChannelInfo("target")
                end
                if name and not cb._casting and not cb._channeling then
                    SyncCastBarFromUnit(cb, "target")
                end
            end
        end
    end
end

function AeonoPlates:OnTargetChanged()
    local f = self._targetRefreshFrame
    if not f then
        f = CreateFrame("Frame")
        self._targetRefreshFrame = f
        f:SetScript("OnUpdate", function(f)
            f:Hide()
            AeonoPlates:_RefreshTargetCastBars()
        end)
    end
    f:Show()
end

function AeonoPlates:OnNameplateUnitUpdated(event, unit)
    if not unit or not unit:find("nameplate") then
        return
    end
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then
        return
    end
    local frame = plate
    if not styledFrames[frame] then
        return
    end
    if not frame.oldname or not frame.name then
        return
    end

    local nameString = frame.oldname:GetText()
    if nameString ~= frame._lastNameString then
        frame._lastNameString = nameString
        frame.name:SetText(nameString or "")
        ResetPlateColorCache(frame)
        ApplyHealthBarColor(frame)
    end
    ApplyNameColor(frame)
    ApplyClassificationIcon(frame)
end

function AeonoPlates:OnFactionChanged()
    for frame in pairs(styledFrames) do
        frame._hpType = nil
    end
    for frame in pairs(visibleFrames) do
        ApplyHealthBarColor(frame)
    end
end

function AeonoPlates:OnGroupChanged()
    UpdateFriendClassInfo()
    for frame in pairs(styledFrames) do
        frame._hpType = nil
    end
    for frame in pairs(visibleFrames) do
        ApplyHealthBarColor(frame)
    end
end

function AeonoPlates:OnEnable()
    self:SetupOptions()
    self:SetupMinimap()

    UpdateFriendClassInfo()

    worldFrameChildCount = -1
    local frameOrderAccum = 0
    local stackAccum = 0
    local mouseoverAccum = 0
    local highlightAccum = 0
    local lastStackingEnabled = cfg.stackingEnabled

    local scanner = CreateFrame("Frame")
    local childScanAccum = 0
    scanner:SetScript("OnUpdate", function(_, elapsed)
        childScanAccum = childScanAccum + elapsed
        if childScanAccum >= 0.2 then
            childScanAccum = 0
            local count = WorldFrame:GetNumChildren()
            if count ~= worldFrameChildCount then
                worldFrameChildCount = count
                HookFrames(WorldFrame:GetChildren())
            end
        end

        if lastStackingEnabled ~= cfg.stackingEnabled then
            lastStackingEnabled = cfg.stackingEnabled
            for frame in pairs(styledFrames) do
                if frame:IsShown() then
                    SetStackingForFrame(frame, cfg.stackingEnabled)
                end
            end
        end

        mouseoverAccum = mouseoverAccum + elapsed
        if mouseoverAccum >= MOUSEOVER_POLL_INTERVAL then
            mouseoverAccum = 0
            if mouseoverFrame then
                local hl = mouseoverFrame.highlight
                if hl and hl:IsShown() and mouseoverFrame:IsShown() then
                    local cb = mouseoverFrame.customCastBar
                    if cb then
                        local name = UnitCastingInfo("mouseover")
                        if not name then
                            name = UnitChannelInfo("mouseover")
                        end
                        if name and not cb._casting and not cb._channeling then
                            SyncCastBarFromUnit(cb, "mouseover")
                        end
                    end
                else
                    mouseoverFrame = nil
                end
            end
            if not mouseoverFrame then
                for frame in pairs(visibleFrames) do
                    local hl = frame.highlight
                    if hl and hl:IsShown() and frame:IsShown() then
                        mouseoverFrame = frame
                        break
                    end
                end
            end
            if mouseoverFrame then
                local cb = mouseoverFrame.customCastBar
                if cb then
                    local name = UnitCastingInfo("mouseover")
                    if not name then
                        name = UnitChannelInfo("mouseover")
                    end
                    if name and not cb._casting and not cb._channeling then
                        SyncCastBarFromUnit(cb, "mouseover")
                    end
                end
            end
        end

        highlightAccum = highlightAccum + elapsed
        if highlightAccum >= HIGHLIGHT_REANCHOR_INTERVAL then
            highlightAccum = 0
            for frame in pairs(visibleFrames) do
                local hl = frame.highlight
                local hb = frame.healthBar
                if hl and hb then
                    local hlW, hlH = hl:GetSize()
                    local hbW, hbH = hb:GetSize()
                    if hlW ~= hbW or hlH ~= hbH then
                        hl:ClearAllPoints()
                        hl:SetPoint("TOPLEFT", hb, "TOPLEFT", 0, 0)
                        hl:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 0, 0)
                        hl:SetDrawLayer("OVERLAY", 7)
                    end
                end
            end
        end

       frameOrderAccum = frameOrderAccum + elapsed
        if frameOrderAccum >= FRAME_ORDER_INTERVAL then
            frameOrderAccum = 0
            ReorderFrameLevels()
        end

        if cfg.stackingEnabled then
            local rate = cfg.stackingUpdateRate or 0
            stackAccum = stackAccum + elapsed
            if rate <= 0 or stackAccum >= rate then
                stackAccum = 0
                UpdateStacking()
            end
        end
    end)

    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnTargetChanged")
    self:RegisterEvent("UNIT_NAME_UPDATE", "OnNameplateUnitUpdated")
    self:RegisterEvent("UNIT_FACTION", "OnFactionChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnGroupChanged")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "OnGroupChanged")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "OnGroupChanged")
    self:RegisterEvent("UNIT_SPELLCAST_START", "OnSpellcastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnSpellcastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnSpellcastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnSpellcastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "OnSpellcastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnSpellcastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "OnSpellcastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnSpellcastEvent")
end