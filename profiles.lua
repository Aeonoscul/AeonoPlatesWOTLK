local addonName, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

ns.defaults = {
    profile = {
        HPcolorEnemyClasses = true,
        HPcolorFriendlyClasses = true,
        HPcolorFriendlyPlayer = {
            r = 0.066,
            g = 0.047,
            b = 1.0
        },
        HPcolorFriendlyNPC = {
            r = 0.109,
            g = 0.839,
            b = 0.0
        },
        HPcolorEnemy = {
            r = 1.0,
            g = 0.066,
            b = 0.0
        },
        HPcolorNeutral = {
            r = 0.972,
            g = 1.0,
            b = 0.0
        },
        HPwidth = 160,
        HPheight = 20,
        normTex = "Midnight Healthbar",
        HPbgTex = "Midnight Healthbar",
        HPbgColor = {
            r = 0.113,
            g = 0.113,
            b = 0.113,
            a = 0.71
        },

        HPborderShow = true,
        glowTex = "Ferous 8",
        border = 12,
        borderInset = -2,
        borderColor = {
            r = 0.584,
            g = 0.619,
            b = 0.615
        },

        HPtextShow = true,
        HPtextShorten = true,
        HPtextFont = "Friz Quadrata TT",
        HPtextSize = 12,
        HPtextFlags = "OUTLINE",
        HPtextShadow = false,
        HPtextShadowX = 1,
        HPtextShadowY = -1,
        HPtextShadowColor = {
            r = 0,
            g = 0,
            b = 0,
            a = 1
        },
        HPtextPoint = "RIGHT",
        HPtextRelativePoint = "RIGHT",
        HPtextX = -30,
        HPtextY = 0,

        HPpctShow = true,
        HPpctFont = "Friz Quadrata TT",
        HPpctSize = 12,
        HPpctFlags = "OUTLINE",
        HPpctShadow = false,
        HPpctShadowX = 1,
        HPpctShadowY = -1,
        HPpctShadowColor = {
            r = 0,
            g = 0,
            b = 0,
            a = 1
        },
        HPpctPoint = "RIGHT",
        HPpctRelativePoint = "RIGHT",
        HPpctX = 0,
        HPpctY = 0,

        font = "Friz Quadrata TT",
        NameFontSize = 12,
        NameFlags = "OUTLINE",
        NameWidth = 95,
        NameColor = {
            r = 0.964,
            g = 0.929,
            b = 1
        },
        NameShadow = false,
        NameShadowX = 1,
        NameShadowY = -1,
        NameShadowColor = {
            r = 0,
            g = 0,
            b = 0,
            a = 1
        },
        Npoint = "LEFT",
        NrelativePoint = "LEFT",
        Nx = 2,
        Ny = 0,

        LvLFont = "Friz Quadrata TT",
        LvLFontSize = 14,
        LvLFlags = "OUTLINE",
        LvLShadow = false,
        LvLShadowX = 1,
        LvLShadowY = -1,
        LvLShadowColor = {
            r = 0,
            g = 0,
            b = 0,
            a = 1
        },
        LvLpoint = "LEFT",
        LvLrelativePoint = "RIGHT",
        LvLx = 2,
        LvLy = 0,

        raidIconSize = 35,
        raidIconPoint = "LEFT",
        raidIconRelativePoint = "RIGHT",
        raidIconX = 5,
        raidIconY = 0,

        classifySize = 36,
        classifyPoint = "RIGHT",
        classifyRelativePoint = "LEFT",
        classifyX = 0,
        classifyY = 0,

        CBwidth = 138,
        CBheight = 14,
        CBbarTex = "Midnight Cast",
        CBbgTex = "Midnight Cast",
        CBcolorBorder = {
            r = 0.16,
            g = 0.16,
            b = 0.16,
            a = 0.59
        },
        CBpoint = "TOP",
        CBrelativePoint = "BOTTOM",
        CBx = 6,
        CBy = -1,
        CBcolorCast = {
            r = 1.0,
            g = 0.86,
            b = 0.0,
            a = 1
        },
        CBcolorNoInterrupt = {
            r = 0.65,
            g = 0.65,
            b = 0.65,
            a = 1
        },
        CBcolorSuccess = {
            r = 0.0,
            g = 1.0,
            b = 0.0,
            a = 1
        },
        CBcolorFailed = {
            r = 1.0,
            g = 0.0,
            b = 0.0,
            a = 1
        },
        CBholdSuccess = 0.25,
        CBholdFailed = 0.25,
        CBfadeTime = 0.4,

        CBborderShow = false,
        CBborderTex = "Blizzard Tooltip",
        CBborderSize = 5,
        CBborderInset = -1,
        CBborderColor = {
            r = 0,
            g = 0,
            b = 0
        },

        CBshowIcon = true,
        CBiconCropped = true,
        CBiconSize = 12,
        CBiconPoint = "RIGHT",
        CBiconRelativePoint = "LEFT",
        CBiconX = 0,
        CBiconY = 0,

        CBiconBorderShow = false,
        CBiconBorderTex = "Blizzard Tooltip",
        CBiconBorderSize = 5,
        CBiconBorderInset = -1,
        CBiconBorderColor = {
            r = 0,
            g = 0,
            b = 0
        },

        CBshowName = true,
        CBnameFont = "Friz Quadrata TT",
        CBnameFontSize = 10,
        CBnameFlags = "OUTLINE",
        CBnameShadow = false,
        CBnameShadowX = 1,
        CBnameShadowY = -1,
        CBnameShadowColor = {
            r = 0,
            g = 0,
            b = 0,
            a = 1
        },
        CBnameColor = {
            r = 1,
            g = 1,
            b = 1
        },
        CBnameTruncate = 90,
        CBnamePoint = "LEFT",
        CBnameRelativePoint = "LEFT",
        CBnameX = 3,
        CBnameY = 0,

        stackingEnabled = true,
        stackingFreezeMouseover = true,
        stackingXSpace = 150,
        stackingYSpace = 25,
        stackingSpeed = 5,
        stackingUpdateRate = 0.01,

        highlightTex = "Blizzard Tooltip",
        highlightColor = {
            r = 1,
            g = 1,
            b = 1,
            a = 0.75
        },
        highlightBlend = "ADD",
        highlightInset = -2,

        ClickboxWidth = 110,
        ClickboxHeight = 15,
        minimap = {
            hide = false,
            minimapPos = 125.36,
            radius = 80
        }
    }
}

ns.cfg = ns.cfg or {}
ns.media = ns.media or {}

function ns.RefreshConfig(addon)
    local cfg = ns.cfg
    local media = ns.media
    local p = addon.db.profile

    cfg.HPcolorEnemyClasses = p.HPcolorEnemyClasses
    cfg.HPcolorFriendlyClasses = p.HPcolorFriendlyClasses
    cfg.HPcolorFriendlyPlayer = p.HPcolorFriendlyPlayer
    cfg.HPcolorFriendlyNPC = p.HPcolorFriendlyNPC
    cfg.HPcolorEnemy = p.HPcolorEnemy
    cfg.HPcolorNeutral = p.HPcolorNeutral
    cfg.HPwidth = p.HPwidth
    cfg.HPheight = p.HPheight
    cfg.HPbgTex = p.HPbgTex
    cfg.HPbgColor = p.HPbgColor

    cfg.HPborderShow = p.HPborderShow
    cfg.border = p.border
    cfg.borderInset = p.borderInset
    cfg.borderColor = p.borderColor

    cfg.HPtextShow = p.HPtextShow
    cfg.HPtextShorten = p.HPtextShorten
    cfg.HPtextFont = p.HPtextFont
    cfg.HPtextSize = p.HPtextSize
    cfg.HPtextFlags = p.HPtextFlags
    cfg.HPtextShadow = p.HPtextShadow
    cfg.HPtextShadowX = p.HPtextShadowX
    cfg.HPtextShadowY = p.HPtextShadowY
    cfg.HPtextShadowColor = p.HPtextShadowColor
    cfg.HPtextPoint = p.HPtextPoint
    cfg.HPtextRelativePoint = p.HPtextRelativePoint
    cfg.HPtextX = p.HPtextX
    cfg.HPtextY = p.HPtextY

    cfg.HPpctShow = p.HPpctShow
    cfg.HPpctFont = p.HPpctFont
    cfg.HPpctSize = p.HPpctSize
    cfg.HPpctFlags = p.HPpctFlags
    cfg.HPpctShadow = p.HPpctShadow
    cfg.HPpctShadowX = p.HPpctShadowX
    cfg.HPpctShadowY = p.HPpctShadowY
    cfg.HPpctShadowColor = p.HPpctShadowColor
    cfg.HPpctPoint = p.HPpctPoint
    cfg.HPpctRelativePoint = p.HPpctRelativePoint
    cfg.HPpctX = p.HPpctX
    cfg.HPpctY = p.HPpctY

    cfg.NameFontSize = p.NameFontSize
    cfg.NameFlags = p.NameFlags
    cfg.NameWidth = p.NameWidth
    cfg.NameColor = p.NameColor
    cfg.NameShadow = p.NameShadow
    cfg.NameShadowX = p.NameShadowX
    cfg.NameShadowY = p.NameShadowY
    cfg.NameShadowColor = p.NameShadowColor
    cfg.Npoint = p.Npoint
    cfg.NrelativePoint = p.NrelativePoint
    cfg.Nx = p.Nx
    cfg.Ny = p.Ny

    cfg.LvLFontSize = p.LvLFontSize
    cfg.LvLFlags = p.LvLFlags
    cfg.LvLFont = p.LvLFont
    cfg.LvLShadow = p.LvLShadow
    cfg.LvLShadowX = p.LvLShadowX
    cfg.LvLShadowY = p.LvLShadowY
    cfg.LvLShadowColor = p.LvLShadowColor
    cfg.LvLpoint = p.LvLpoint
    cfg.LvLrelativePoint = p.LvLrelativePoint
    cfg.LvLx = p.LvLx
    cfg.LvLy = p.LvLy

    cfg.raidIconSize = p.raidIconSize
    cfg.raidIconPoint = p.raidIconPoint
    cfg.raidIconRelativePoint = p.raidIconRelativePoint
    cfg.raidIconX = p.raidIconX
    cfg.raidIconY = p.raidIconY

    cfg.classifySize = p.classifySize
    cfg.classifyPoint = p.classifyPoint
    cfg.classifyRelativePoint = p.classifyRelativePoint
    cfg.classifyX = p.classifyX
    cfg.classifyY = p.classifyY

    cfg.CBheight = p.CBheight
    cfg.CBwidth = p.CBwidth
    cfg.CBpoint = p.CBpoint
    cfg.CBrelativePoint = p.CBrelativePoint
    cfg.CBx = p.CBx
    cfg.CBy = p.CBy
    cfg.CBbarTex = p.CBbarTex
    cfg.CBbgTex = p.CBbgTex
    cfg.CBcolorCast = p.CBcolorCast
    cfg.CBcolorNoInterrupt = p.CBcolorNoInterrupt
    cfg.CBcolorSuccess = p.CBcolorSuccess
    cfg.CBcolorFailed = p.CBcolorFailed
    cfg.CBcolorBorder = p.CBcolorBorder
    cfg.CBholdSuccess = p.CBholdSuccess
    cfg.CBholdFailed = p.CBholdFailed
    cfg.CBfadeTime = p.CBfadeTime

    cfg.CBborderShow = p.CBborderShow
    cfg.CBborderTex = p.CBborderTex
    cfg.CBborderSize = p.CBborderSize
    cfg.CBborderInset = p.CBborderInset
    cfg.CBborderColor = p.CBborderColor

    cfg.CBshowIcon = p.CBshowIcon
    cfg.CBiconSize = p.CBiconSize
    cfg.CBiconCropped = p.CBiconCropped
    cfg.CBiconPoint = p.CBiconPoint
    cfg.CBiconRelativePoint = p.CBiconRelativePoint
    cfg.CBiconX = p.CBiconX
    cfg.CBiconY = p.CBiconY
    cfg.CBiconBorderShow = p.CBiconBorderShow
    cfg.CBiconBorderTex = p.CBiconBorderTex
    cfg.CBiconBorderSize = p.CBiconBorderSize
    cfg.CBiconBorderInset = p.CBiconBorderInset
    cfg.CBiconBorderColor = p.CBiconBorderColor

    cfg.CBshowName = p.CBshowName
    cfg.CBnameFont = p.CBnameFont
    cfg.CBnameFontSize = p.CBnameFontSize
    cfg.CBnameFlags = p.CBnameFlags
    cfg.CBnameColor = p.CBnameColor
    cfg.CBnameTruncate = p.CBnameTruncate
    cfg.CBnameShadow = p.CBnameShadow
    cfg.CBnameShadowX = p.CBnameShadowX
    cfg.CBnameShadowY = p.CBnameShadowY
    cfg.CBnameShadowColor = p.CBnameShadowColor
    cfg.CBnamePoint = p.CBnamePoint
    cfg.CBnameRelativePoint = p.CBnameRelativePoint
    cfg.CBnameX = p.CBnameX
    cfg.CBnameY = p.CBnameY

    cfg.stackingEnabled = p.stackingEnabled
    cfg.stackingFreezeMouseover = p.stackingFreezeMouseover
    cfg.stackingXSpace = p.stackingXSpace
    cfg.stackingYSpace = p.stackingYSpace
    cfg.stackingSpeed = p.stackingSpeed
    cfg.stackingUpdateRate = p.stackingUpdateRate

    cfg.highlightColor = p.highlightColor
    cfg.highlightBlend = p.highlightBlend
    cfg.highlightInset = p.highlightInset

    local function resolveMedia(mediatype, key, fallback)
        if type(key) ~= "string" or key == "" then
            return fallback
        end
        if LSM:IsValid(mediatype, key) then
            return LSM:Fetch(mediatype, key)
        end
        if key:match("[\\/]") then
            return key
        end
        return fallback
    end

    local function resolveBgMedia(key, fallback)
        if type(key) ~= "string" or key == "" then
            return fallback
        end
        if LSM:IsValid("statusbar", key) then
            return LSM:Fetch("statusbar", key)
        end
        if LSM:IsValid("background", key) then
            return LSM:Fetch("background", key)
        end
        if LSM:IsValid("border", key) then
            return LSM:Fetch("border", key)
        end
        if key:match("[\\/]") then
            return key
        end
        return fallback
    end

    media.font = resolveMedia("font", p.font, "Fonts\\FRIZQT__.TTF")
    media.normTex = resolveMedia("statusbar", p.normTex, "Interface\\Buttons\\WHITE8x8")
    media.glowTex = resolveMedia("border", p.glowTex, "Interface\\Buttons\\WHITE8x8")
    media.nameFont = resolveMedia("font", p.CBnameFont or p.font, "Fonts\\FRIZQT__.TTF")
    media.cbBarTex = resolveMedia("statusbar", p.CBbarTex, media.normTex)
    media.cbBgTex = resolveBgMedia(p.CBbgTex, media.normTex)
    media.cbBorderTex = resolveMedia("border", p.CBborderTex, "Interface\\Buttons\\WHITE8x8")
    media.iconBorderTex = resolveMedia("border", p.CBiconBorderTex, "Interface\\Buttons\\WHITE8x8")
    media.hpBgTex = resolveBgMedia(p.HPbgTex, media.normTex)
    media.levelFont = resolveMedia("font", p.LvLFont or p.font, "Fonts\\FRIZQT__.TTF")
    media.healthFont = resolveMedia("font", p.HPtextFont or p.font, "Fonts\\FRIZQT__.TTF")
    media.healthPctFont = resolveMedia("font", p.HPpctFont or p.font, "Fonts\\FRIZQT__.TTF")
    media.highlightTex = resolveBgMedia(p.highlightTex, "Interface\\Buttons\\WHITE8x8")

    SetCVar("ShowClassColorInNameplate", 1)
end