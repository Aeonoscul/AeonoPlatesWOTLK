local addonName, ns = ...
local addon = ns.addon

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local hasMediaWidgets = LibStub("AceGUISharedMediaWidgets-1.0", true) ~= nil
local function mediaWidget(kind)
    return hasMediaWidgets and kind or nil
end

local anchors = {
    TOP = "Top (TOP)",
    BOTTOM = "Bottom (BOTTOM)",
    LEFT = "Left (LEFT)",
    RIGHT = "Right (RIGHT)",
    CENTER = "Center (CENTER)",
    TOPLEFT = "Top-Left (TOPLEFT)",
    TOPRIGHT = "Top-Right (TOPRIGHT)",
    BOTTOMLEFT = "Bottom-Left (BOTTOMLEFT)",
    BOTTOMRIGHT = "Bottom-Right (BOTTOMRIGHT)"
}

local fontFlags = {
    [""] = "None",
    ["OUTLINE"] = "Outline",
    ["THICKOUTLINE"] = "Thick Outline",
    ["MONOCHROME"] = "Monochrome",
    ["MONOCHROME, OUTLINE"] = "Monochrome + Outline",
    ["MONOCHROME, THICKOUTLINE"] = "Monochrome + Thick Outline"
}

local function apply()
    addon:RefreshConfig()
    addon:ReskinAll()
end

local function getValue(key)
    return function()
        return addon.db.profile[key]
    end
end

local function setValue(key)
    return function(_, value)
        addon.db.profile[key] = value
        apply()
    end
end

local function getColor(key)
    return function()
        local c = addon.db.profile[key]
        if type(c) ~= "table" then
            return 1, 1, 1
        end
        return c.r or 1, c.g or 1, c.b or 1
    end
end

local function setColor(key)
    return function(_, r, g, b)
        addon.db.profile[key] = {
            r = r,
            g = g,
            b = b
        }
        apply()
    end
end

local function getColorAlpha(key)
    return function()
        local c = addon.db.profile[key]
        if type(c) ~= "table" then
            return 1, 1, 1, 1
        end
        return c.r or 1, c.g or 1, c.b or 1, c.a or 1
    end
end

local function setColorAlpha(key)
    return function(_, r, g, b, a)
        addon.db.profile[key] = {
            r = r,
            g = g,
            b = b,
            a = a
        }
        apply()
    end
end

local function mediaValues(mediatype)
    return function()
        local list = LSM:List(mediatype)
        if not list then
            return {}
        end
        local t = {}
        for _, key in ipairs(list) do
            t[key] = key
        end
        return t
    end
end

local function mediaValuesMerged(...)
    local types = {...}
    return function()
        local t = {}
        for _, mediatype in ipairs(types) do
            local list = LSM:List(mediatype)
            if list then
                for _, key in ipairs(list) do
                    t[key] = key
                end
            end
        end
        return t
    end
end

local function spacer(order)
    return {
        type = "description",
        name = " ",
        order = order,
        width = "full"
    }
end

local options = {
    name = "AeonoPlates",
    handler = addon,
    type = "group",
    args = {

        healthBar = {
            type = "group",
            name = "Health Bar",
            order = 1,
            childGroups = "tab",
            args = {

                appearance = {
                    type = "group",
                    name = "Appearance",
                    order = 1,
                    args = {
                        classColorEnemies = {
                            type = "toggle",
                            name = "Class Color Enemies",
                            desc = "Color hostile players by their class (Blizzard standard option).",
                            order = 1,
                            get = getValue("HPcolorEnemyClasses"),
                            set = setValue("HPcolorEnemyClasses")
                        },
                        classColorFriends = {
                            type = "toggle",
                            name = "Class Color Allies",
                            desc = "Color friendly players in party/raid by their class.",
                            order = 2,
                            get = getValue("HPcolorFriendlyClasses"),
                            set = setValue("HPcolorFriendlyClasses")
                        },
                        friendlyPlayerColor = {
                            type = "color",
                            name = "Friendly Player (outside group)",
                            hasAlpha = false,
                            order = 31,
                            get = getColor("HPcolorFriendlyPlayer"),
                            set = setColor("HPcolorFriendlyPlayer")
                        },
                        friendlyNPCColor = {
                            type = "color",
                            name = "Friendly NPC",
                            hasAlpha = false,
                            order = 32,
                            get = getColor("HPcolorFriendlyNPC"),
                            set = setColor("HPcolorFriendlyNPC")
                        },
                        enemyNPCColor = {
                            type = "color",
                            name = "Enemy",
                            hasAlpha = false,
                            order = 33,
                            get = getColor("HPcolorEnemy"),
                            set = setColor("HPcolorEnemy")
                        },
                        neutralColor = {
                            type = "color",
                            name = "Neutral",
                            hasAlpha = false,
                            order = 34,
                            get = getColor("HPcolorNeutral"),
                            set = setColor("HPcolorNeutral")
                        },
                        spacer1 = spacer(3),

                        width = {
                            type = "range",
                            name = "Bar Width",
                            desc = "Health bar width in pixels.",
                            min = 100,
                            max = 300,
                            step = 1,
                            order = 10,
                            get = getValue("HPwidth"),
                            set = setValue("HPwidth")
                        },
                        height = {
                            type = "range",
                            name = "Bar Height",
                            desc = "Health bar height in pixels.",
                            min = 8,
                            max = 40,
                            step = 1,
                            order = 11,
                            get = getValue("HPheight"),
                            set = setValue("HPheight")
                        },

                        spacer2 = spacer(12),

                        barTexture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Statusbar"),
                            name = "Bar Texture",
                            desc = "Statusbar texture for health bar (LibSharedMedia).",
                            values = mediaValues("statusbar"),
                            order = 20,
                            get = getValue("normTex"),
                            set = setValue("normTex")
                        },
                        bgTexture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Statusbar"),
                            name = "Background Texture",
                            desc = "Background texture under health bar.",
                            values = mediaValuesMerged("statusbar"),
                            order = 21,
                            get = getValue("HPbgTex"),
                            set = setValue("HPbgTex")
                        },
                        bgColor = {
                            type = "color",
                            name = "Background Color",
                            desc = "Color of the background texture under health bar.",
                            hasAlpha = true,
                            order = 22,
                            get = getColorAlpha("HPbgColor"),
                            set = setColorAlpha("HPbgColor")
                        }
                    }
                },

                border = {
                    type = "group",
                    name = "Border",
                    order = 2,
                    args = {
                        show = {
                            type = "toggle",
                            name = "Show Border",
                            order = 1,
                            get = getValue("HPborderShow"),
                            set = setValue("HPborderShow")
                        },
                        spacer1 = spacer(2),

                        texture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Border"),
                            name = "Border Texture",
                            values = mediaValues("border"),
                            order = 10,
                            get = getValue("glowTex"),
                            set = setValue("glowTex")
                        },
                        thickness = {
                            type = "range",
                            name = "Border Thickness",
                            min = 1,
                            max = 12,
                            step = 1,
                            order = 11,
                            get = getValue("border"),
                            set = setValue("border")
                        },
                        inset = {
                            type = "range",
                            name = "Border Inset",
                            desc = "Offset of the border inward (negative = outward).",
                            min = -12,
                            max = 12,
                            step = 1,
                            order = 12,
                            get = getValue("borderInset"),
                            set = setValue("borderInset")
                        },
                        color = {
                            type = "color",
                            name = "Border Color",
                            hasAlpha = false,
                            order = 13,
                            get = getColor("borderColor"),
                            set = setColor("borderColor")
                        }
                    }
                },

                highlight = {
                    type = "group",
                    name = "Mouseover Highlight",
                    order = 2.5,
                    args = {
                        texture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Background"),
                            name = "Texture",
                            desc = "Highlight texture. Registered as background in LibSharedMedia.",
                            values = mediaValues("background"),
                            order = 2,
                            get = getValue("highlightTex"),
                            set = setValue("highlightTex")
                        },
                        color = {
                            type = "color",
                            name = "Color",
                            hasAlpha = true,
                            order = 3,
                            get = getColorAlpha("highlightColor"),
                            set = setColorAlpha("highlightColor")
                        },
                        blend = {
                            type = "select",
                            name = "Blend Mode",
                            desc = "ADD - additive blending (glow), BLEND - normal, DISABLE - no blending.",
                            values = {
                                ["ADD"] = "ADD",
                                ["BLEND"] = "BLEND",
                                ["DISABLE"] = "DISABLE"
                            },
                            order = 4,
                            get = getValue("highlightBlend"),
                            set = setValue("highlightBlend")
                        },
                        inset = {
                            type = "range",
                            name = "Inset",
                            desc = "Negative value - highlight extends beyond health bar; positive - shrinks inward.",
                            min = -20,
                            max = 20,
                            step = 1,
                            order = 5,
                            get = getValue("highlightInset"),
                            set = setValue("highlightInset")
                        }
                    }
                },

                text = {
                    type = "group",
                    name = "Text",
                    order = 3,
                    args = {
                        show = {
                            type = "toggle",
                            name = "Show Text",
                            order = 1,
                            get = getValue("HPtextShow"),
                            set = setValue("HPtextShow")
                        },
                        shorten = {
                            type = "toggle",
                            name = "Shorten Values",
                            desc = "24000 -> 24k, 1200000 -> 1.2m.",
                            order = 2,
                            get = getValue("HPtextShorten"),
                            set = setValue("HPtextShorten")
                        },
                        spacer1 = spacer(3),

                        font = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Font"),
                            name = "Font",
                            values = mediaValues("font"),
                            order = 10,
                            get = getValue("HPtextFont"),
                            set = setValue("HPtextFont")
                        },
                        fontSize = {
                            type = "range",
                            name = "Font Size",
                            min = 6,
                            max = 24,
                            step = 1,
                            order = 11,
                            get = getValue("HPtextSize"),
                            set = setValue("HPtextSize")
                        },
                        fontFlags = {
                            type = "select",
                            name = "Font Flags",
                            values = fontFlags,
                            order = 12,
                            get = getValue("HPtextFlags"),
                            set = setValue("HPtextFlags")
                        },
                        spacer2 = spacer(13),

                        shadow = {
                            type = "toggle",
                            name = "Shadow",
                            order = 14,
                            get = getValue("HPtextShadow"),
                            set = setValue("HPtextShadow")
                        },
                        shadowColor = {
                            type = "color",
                            name = "Shadow Color",
                            hasAlpha = true,
                            order = 15,
                            get = getColorAlpha("HPtextShadowColor"),
                            set = setColorAlpha("HPtextShadowColor")
                        },
                        shadowX = {
                            type = "range",
                            name = "Shadow Offset X",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 16,
                            get = getValue("HPtextShadowX"),
                            set = setValue("HPtextShadowX")
                        },
                        shadowY = {
                            type = "range",
                            name = "Shadow Offset Y",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 17,
                            get = getValue("HPtextShadowY"),
                            set = setValue("HPtextShadowY")
                        },
                        spacer3 = spacer(20),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 21,
                            get = getValue("HPtextPoint"),
                            set = setValue("HPtextPoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Bar Point",
                            values = anchors,
                            order = 22,
                            get = getValue("HPtextRelativePoint"),
                            set = setValue("HPtextRelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 23,
                            get = getValue("HPtextX"),
                            set = setValue("HPtextX")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 24,
                            get = getValue("HPtextY"),
                            set = setValue("HPtextY")
                        }
                    }
                },

                percent = {
                    type = "group",
                    name = "Percent",
                    order = 4,
                    args = {
                        show = {
                            type = "toggle",
                            name = "Show Percent",
                            order = 1,
                            get = getValue("HPpctShow"),
                            set = setValue("HPpctShow")
                        },
                        spacer1 = spacer(2),

                        font = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Font"),
                            name = "Font",
                            values = mediaValues("font"),
                            order = 10,
                            get = getValue("HPpctFont"),
                            set = setValue("HPpctFont")
                        },
                        fontSize = {
                            type = "range",
                            name = "Font Size",
                            min = 6,
                            max = 24,
                            step = 1,
                            order = 11,
                            get = getValue("HPpctSize"),
                            set = setValue("HPpctSize")
                        },
                        fontFlags = {
                            type = "select",
                            name = "Font Flags",
                            values = fontFlags,
                            order = 12,
                            get = getValue("HPpctFlags"),
                            set = setValue("HPpctFlags")
                        },
                        spacer2 = spacer(13),

                        shadow = {
                            type = "toggle",
                            name = "Shadow",
                            order = 14,
                            get = getValue("HPpctShadow"),
                            set = setValue("HPpctShadow")
                        },
                        shadowColor = {
                            type = "color",
                            name = "Shadow Color",
                            hasAlpha = true,
                            order = 15,
                            get = getColorAlpha("HPpctShadowColor"),
                            set = setColorAlpha("HPpctShadowColor")
                        },
                        shadowX = {
                            type = "range",
                            name = "Shadow Offset X",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 16,
                            get = getValue("HPpctShadowX"),
                            set = setValue("HPpctShadowX")
                        },
                        shadowY = {
                            type = "range",
                            name = "Shadow Offset Y",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 17,
                            get = getValue("HPpctShadowY"),
                            set = setValue("HPpctShadowY")
                        },
                        spacer3 = spacer(20),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 21,
                            get = getValue("HPpctPoint"),
                            set = setValue("HPpctPoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Bar Point",
                            values = anchors,
                            order = 22,
                            get = getValue("HPpctRelativePoint"),
                            set = setValue("HPpctRelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 23,
                            get = getValue("HPpctX"),
                            set = setValue("HPpctX")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 24,
                            get = getValue("HPpctY"),
                            set = setValue("HPpctY")
                        }
                    }
                }
            }
        },

        nameAndLevel = {
            type = "group",
            name = "Name & Level",
            order = 2,
            childGroups = "tab",
            args = {

                name = {
                    type = "group",
                    name = "Name",
                    order = 1,
                    args = {
                        font = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Font"),
                            name = "Font",
                            desc = "Font for name, level and castbar elements.",
                            values = mediaValues("font"),
                            order = 1,
                            get = getValue("font"),
                            set = setValue("font")
                        },
                        fontSize = {
                            type = "range",
                            name = "Font Size",
                            min = 6,
                            max = 24,
                            step = 1,
                            order = 2,
                            get = getValue("NameFontSize"),
                            set = setValue("NameFontSize")
                        },
                        fontFlags = {
                            type = "select",
                            name = "Font Flags",
                            values = fontFlags,
                            order = 3,
                            get = getValue("NameFlags"),
                            set = setValue("NameFlags")
                        },
                        maxWidth = {
                            type = "range",
                            name = "Width (0 = auto)",
                            desc = "Maximum width of name text; long text is truncated. 0 = auto.",
                            min = 0,
                            max = 300,
                            step = 1,
                            order = 4,
                            get = getValue("NameWidth"),
                            set = setValue("NameWidth")
                        },
                        nameColor = {
                            type = "color",
                            name = "Name Color",
                            desc = "Color of name text above the plate.",
                            hasAlpha = false,
                            order = 5,
                            get = getColor("NameColor"),
                            set = setColor("NameColor")
                        },
                        spacer1 = spacer(6),

                        shadow = {
                            type = "toggle",
                            name = "Shadow",
                            order = 7,
                            get = getValue("NameShadow"),
                            set = setValue("NameShadow")
                        },
                        shadowColor = {
                            type = "color",
                            name = "Shadow Color",
                            hasAlpha = true,
                            order = 8,
                            get = getColorAlpha("NameShadowColor"),
                            set = setColorAlpha("NameShadowColor")
                        },
                        shadowX = {
                            type = "range",
                            name = "Shadow Offset X",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 9,
                            get = getValue("NameShadowX"),
                            set = setValue("NameShadowX")
                        },
                        shadowY = {
                            type = "range",
                            name = "Shadow Offset Y",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 10,
                            get = getValue("NameShadowY"),
                            set = setValue("NameShadowY")
                        },
                        spacer2 = spacer(15),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 20,
                            get = getValue("Npoint"),
                            set = setValue("Npoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Bar Point",
                            values = anchors,
                            order = 21,
                            get = getValue("NrelativePoint"),
                            set = setValue("NrelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -50,
                            max = 50,
                            step = 1,
                            order = 22,
                            get = getValue("Nx"),
                            set = setValue("Nx")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -50,
                            max = 50,
                            step = 1,
                            order = 23,
                            get = getValue("Ny"),
                            set = setValue("Ny")
                        }
                    }
                },

                level = {
                    type = "group",
                    name = "Level",
                    order = 2,
                    args = {
                        font = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Font"),
                            name = "Font",
                            values = mediaValues("font"),
                            order = 1,
                            get = getValue("LvLFont"),
                            set = setValue("LvLFont")
                        },
                        fontSize = {
                            type = "range",
                            name = "Font Size",
                            min = 6,
                            max = 24,
                            step = 1,
                            order = 2,
                            get = getValue("LvLFontSize"),
                            set = setValue("LvLFontSize")
                        },
                        fontFlags = {
                            type = "select",
                            name = "Font Flags",
                            values = fontFlags,
                            order = 3,
                            get = getValue("LvLFlags"),
                            set = setValue("LvLFlags")
                        },
                        spacer1 = spacer(4),

                        shadow = {
                            type = "toggle",
                            name = "Shadow",
                            order = 5,
                            get = getValue("LvLShadow"),
                            set = setValue("LvLShadow")
                        },
                        shadowColor = {
                            type = "color",
                            name = "Shadow Color",
                            hasAlpha = true,
                            order = 6,
                            get = getColorAlpha("LvLShadowColor"),
                            set = setColorAlpha("LvLShadowColor")
                        },
                        shadowX = {
                            type = "range",
                            name = "Shadow Offset X",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 7,
                            get = getValue("LvLShadowX"),
                            set = setValue("LvLShadowX")
                        },
                        shadowY = {
                            type = "range",
                            name = "Shadow Offset Y",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 8,
                            get = getValue("LvLShadowY"),
                            set = setValue("LvLShadowY")
                        },
                        spacer2 = spacer(10),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 20,
                            get = getValue("LvLpoint"),
                            set = setValue("LvLpoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Bar Point",
                            values = anchors,
                            order = 21,
                            get = getValue("LvLrelativePoint"),
                            set = setValue("LvLrelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -50,
                            max = 50,
                            step = 1,
                            order = 22,
                            get = getValue("LvLx"),
                            set = setValue("LvLx")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -50,
                            max = 50,
                            step = 1,
                            order = 23,
                            get = getValue("LvLy"),
                            set = setValue("LvLy")
                        }
                    }
                }
            }
        },

        icons = {
            type = "group",
            name = "Icons",
            order = 3,
            childGroups = "tab",
            args = {
                raidIcon = {
                    type = "group",
                    name = "Raid Marker",
                    order = 1,
                    args = {
                        size = {
                            type = "range",
                            name = "Icon Size",
                            min = 10,
                            max = 50,
                            step = 1,
                            order = 1,
                            get = getValue("raidIconSize"),
                            set = setValue("raidIconSize")
                        },
                        spacer1 = spacer(10),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 20,
                            get = getValue("raidIconPoint"),
                            set = setValue("raidIconPoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Bar Point",
                            values = anchors,
                            order = 21,
                            get = getValue("raidIconRelativePoint"),
                            set = setValue("raidIconRelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 22,
                            get = getValue("raidIconX"),
                            set = setValue("raidIconX")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 23,
                            get = getValue("raidIconY"),
                            set = setValue("raidIconY")
                        }
                    }
                },
                classification = {
                    type = "group",
                    name = "Classification",
                    order = 2,
                    args = {
                        size = {
                            type = "range",
                            name = "Size",
                            min = 8,
                            max = 64,
                            step = 1,
                            order = 20,
                            get = getValue("classifySize"),
                            set = setValue("classifySize")
                        },

                        spacer1 = spacer(30),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 40,
                            get = getValue("classifyPoint"),
                            set = setValue("classifyPoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Bar Point",
                            values = anchors,
                            order = 41,
                            get = getValue("classifyRelativePoint"),
                            set = setValue("classifyRelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 42,
                            get = getValue("classifyX"),
                            set = setValue("classifyX")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 43,
                            get = getValue("classifyY"),
                            set = setValue("classifyY")
                        }
                    }
                }
            }
        },

        castBar = {
            type = "group",
            name = "Cast Bar",
            order = 4,
            childGroups = "tab",
            args = {

                bar = {
                    type = "group",
                    name = "Bar",
                    order = 1,
                    args = {
                        width = {
                            type = "range",
                            name = "Width (0 = auto)",
                            desc = "Fixed castbar width. 0 = calculate from health bar width.",
                            min = 0,
                            max = 300,
                            step = 1,
                            order = 1,
                            get = getValue("CBwidth"),
                            set = setValue("CBwidth")
                        },
                        height = {
                            type = "range",
                            name = "Height",
                            min = 4,
                            max = 20,
                            step = 1,
                            order = 2,
                            get = getValue("CBheight"),
                            set = setValue("CBheight")
                        },
                        barTexture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Statusbar"),
                            name = "Bar Texture",
                            values = mediaValues("statusbar"),
                            order = 3,
                            get = getValue("CBbarTex"),
                            set = setValue("CBbarTex")
                        },
                        bgTexture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Statusbar"),
                            name = "Background Texture",
                            values = mediaValuesMerged("statusbar"),
                            order = 4,
                            get = getValue("CBbgTex"),
                            set = setValue("CBbgTex")
                        },
                        bgColor = {
                            type = "color",
                            name = "Background Color",
                            hasAlpha = true,
                            order = 5,
                            get = getColorAlpha("CBcolorBorder"),
                            set = setColorAlpha("CBcolorBorder")
                        },

                        spacer1 = spacer(10),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 20,
                            get = getValue("CBpoint"),
                            set = setValue("CBpoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Bar Point",
                            values = anchors,
                            order = 21,
                            get = getValue("CBrelativePoint"),
                            set = setValue("CBrelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 22,
                            get = getValue("CBx"),
                            set = setValue("CBx")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 23,
                            get = getValue("CBy"),
                            set = setValue("CBy")
                        },

                        spacer2 = spacer(30),

                        colorCast = {
                            type = "color",
                            name = "Casting Color",
                            desc = "Bar color while casting.",
                            hasAlpha = true,
                            order = 40,
                            get = getColorAlpha("CBcolorCast"),
                            set = setColorAlpha("CBcolorCast")
                        },
                        colorNoInterrupt = {
                            type = "color",
                            name = "Non-interruptible Color",
                            hasAlpha = true,
                            order = 41,
                            get = getColorAlpha("CBcolorNoInterrupt"),
                            set = setColorAlpha("CBcolorNoInterrupt")
                        },
                        colorSuccess = {
                            type = "color",
                            name = "Success Color",
                            hasAlpha = true,
                            order = 42,
                            get = getColorAlpha("CBcolorSuccess"),
                            set = setColorAlpha("CBcolorSuccess")
                        },
                        colorFailed = {
                            type = "color",
                            name = "Failed Color",
                            hasAlpha = true,
                            order = 43,
                            get = getColorAlpha("CBcolorFailed"),
                            set = setColorAlpha("CBcolorFailed")
                        },

                        spacer3 = spacer(50),

                        holdSuccess = {
                            type = "range",
                            name = "Hold after Success (sec)",
                            min = 0,
                            max = 2,
                            step = 0.05,
                            order = 60,
                            get = getValue("CBholdSuccess"),
                            set = setValue("CBholdSuccess")
                        },
                        holdFailed = {
                            type = "range",
                            name = "Hold after Failed (sec)",
                            min = 0,
                            max = 2,
                            step = 0.05,
                            order = 61,
                            get = getValue("CBholdFailed"),
                            set = setValue("CBholdFailed")
                        },
                        fadeTime = {
                            type = "range",
                            name = "Fade Time (sec)",
                            min = 0.05,
                            max = 2,
                            step = 0.05,
                            order = 62,
                            get = getValue("CBfadeTime"),
                            set = setValue("CBfadeTime")
                        }
                    }
                },

                border = {
                    type = "group",
                    name = "Border",
                    order = 2,
                    args = {
                        show = {
                            type = "toggle",
                            name = "Show Border",
                            order = 1,
                            get = getValue("CBborderShow"),
                            set = setValue("CBborderShow")
                        },
                        spacer1 = spacer(2),

                        texture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Border"),
                            name = "Border Texture",
                            values = mediaValues("border"),
                            order = 10,
                            get = getValue("CBborderTex"),
                            set = setValue("CBborderTex")
                        },
                        thickness = {
                            type = "range",
                            name = "Border Thickness",
                            min = 1,
                            max = 24,
                            step = 1,
                            order = 11,
                            get = getValue("CBborderSize"),
                            set = setValue("CBborderSize")
                        },
                        inset = {
                            type = "range",
                            name = "Border Inset",
                            min = -12,
                            max = 12,
                            step = 1,
                            order = 12,
                            get = getValue("CBborderInset"),
                            set = setValue("CBborderInset")
                        },
                        color = {
                            type = "color",
                            name = "Border Color",
                            hasAlpha = false,
                            order = 13,
                            get = getColor("CBborderColor"),
                            set = setColor("CBborderColor")
                        }
                    }
                },

                icon = {
                    type = "group",
                    name = "Icon",
                    order = 3,
                    args = {
                        show = {
                            type = "toggle",
                            name = "Show Icon",
                            order = 1,
                            get = getValue("CBshowIcon"),
                            set = setValue("CBshowIcon")
                        },
                        cropped = {
                            type = "toggle",
                            name = "Crop Edges",
                            desc = "Crop the cast icon's border.",
                            order = 2,
                            get = getValue("CBiconCropped"),
                            set = setValue("CBiconCropped")
                        },
                        size = {
                            type = "range",
                            name = "Icon Size",
                            desc = "0 = use default size (16).",
                            min = 0,
                            max = 64,
                            step = 1,
                            order = 3,
                            get = getValue("CBiconSize"),
                            set = setValue("CBiconSize")
                        },
                        spacer1 = spacer(10),

                        point = {
                            type = "select",
                            name = "Icon Point",
                            values = anchors,
                            order = 20,
                            get = getValue("CBiconPoint"),
                            set = setValue("CBiconPoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Castbar Point",
                            values = anchors,
                            order = 21,
                            get = getValue("CBiconRelativePoint"),
                            set = setValue("CBiconRelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 22,
                            get = getValue("CBiconX"),
                            set = setValue("CBiconX")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 23,
                            get = getValue("CBiconY"),
                            set = setValue("CBiconY")
                        },

                        spacer2 = spacer(30),

                        borderShow = {
                            type = "toggle",
                            name = "Show Icon Border",
                            order = 40,
                            get = getValue("CBiconBorderShow"),
                            set = setValue("CBiconBorderShow")
                        },
                        borderTexture = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Border"),
                            name = "Border Texture",
                            values = mediaValues("border"),
                            order = 41,
                            get = getValue("CBiconBorderTex"),
                            set = setValue("CBiconBorderTex")
                        },
                        borderThickness = {
                            type = "range",
                            name = "Border Thickness",
                            min = 1,
                            max = 24,
                            step = 1,
                            order = 42,
                            get = getValue("CBiconBorderSize"),
                            set = setValue("CBiconBorderSize")
                        },
                        borderInset = {
                            type = "range",
                            name = "Border Inset",
                            min = -12,
                            max = 12,
                            step = 1,
                            order = 43,
                            get = getValue("CBiconBorderInset"),
                            set = setValue("CBiconBorderInset")
                        },
                        borderColor = {
                            type = "color",
                            name = "Border Color",
                            hasAlpha = false,
                            order = 44,
                            get = getColor("CBiconBorderColor"),
                            set = setColor("CBiconBorderColor")
                        }
                    }
                },

                spellName = {
                    type = "group",
                    name = "Spell Name",
                    order = 4,
                    args = {
                        show = {
                            type = "toggle",
                            name = "Show Name",
                            order = 1,
                            get = getValue("CBshowName"),
                            set = setValue("CBshowName")
                        },
                        spacer1 = spacer(2),

                        font = {
                            type = "select",
                            dialogControl = mediaWidget("LSM30_Font"),
                            name = "Font",
                            values = mediaValues("font"),
                            order = 10,
                            get = getValue("CBnameFont"),
                            set = setValue("CBnameFont")
                        },
                        fontSize = {
                            type = "range",
                            name = "Font Size",
                            min = 6,
                            max = 24,
                            step = 1,
                            order = 11,
                            get = getValue("CBnameFontSize"),
                            set = setValue("CBnameFontSize")
                        },
                        fontFlags = {
                            type = "select",
                            name = "Font Flags",
                            values = fontFlags,
                            order = 12,
                            get = getValue("CBnameFlags"),
                            set = setValue("CBnameFlags")
                        },
                        color = {
                            type = "color",
                            name = "Text Color",
                            hasAlpha = false,
                            order = 13,
                            get = getColor("CBnameColor"),
                            set = setColor("CBnameColor")
                        },
                        truncate = {
                            type = "range",
                            name = "Width (0 = auto)",
                            desc = "Maximum width of name text. 0 = no truncation.",
                            min = 0,
                            max = 300,
                            step = 1,
                            order = 14,
                            get = getValue("CBnameTruncate"),
                            set = setValue("CBnameTruncate")
                        },
                        spacer2 = spacer(15),

                        shadow = {
                            type = "toggle",
                            name = "Shadow",
                            order = 16,
                            get = getValue("CBnameShadow"),
                            set = setValue("CBnameShadow")
                        },
                        shadowColor = {
                            type = "color",
                            name = "Shadow Color",
                            hasAlpha = true,
                            order = 17,
                            get = getColorAlpha("CBnameShadowColor"),
                            set = setColorAlpha("CBnameShadowColor")
                        },
                        shadowX = {
                            type = "range",
                            name = "Shadow Offset X",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 18,
                            get = getValue("CBnameShadowX"),
                            set = setValue("CBnameShadowX")
                        },
                        shadowY = {
                            type = "range",
                            name = "Shadow Offset Y",
                            min = -5,
                            max = 5,
                            step = 0.5,
                            order = 19,
                            get = getValue("CBnameShadowY"),
                            set = setValue("CBnameShadowY")
                        },
                        spacer3 = spacer(20),

                        point = {
                            type = "select",
                            name = "Anchor Point",
                            values = anchors,
                            order = 30,
                            get = getValue("CBnamePoint"),
                            set = setValue("CBnamePoint")
                        },
                        relativePoint = {
                            type = "select",
                            name = "Castbar Point",
                            values = anchors,
                            order = 31,
                            get = getValue("CBnameRelativePoint"),
                            set = setValue("CBnameRelativePoint")
                        },
                        x = {
                            type = "range",
                            name = "X Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 32,
                            get = getValue("CBnameX"),
                            set = setValue("CBnameX")
                        },
                        y = {
                            type = "range",
                            name = "Y Offset",
                            min = -100,
                            max = 100,
                            step = 1,
                            order = 33,
                            get = getValue("CBnameY"),
                            set = setValue("CBnameY")
                        }
                    }
                }
            }
        },

        stacking = {
            type = "group",
            name = "Stacking",
            order = 5,
            args = {
                enabled = {
                    type = "toggle",
                    name = "Enable Stacking",
                    desc = "Rosen-style nameplate stacking. Enemies stop overlapping each other.",
                    order = 1,
                    get = getValue("stackingEnabled"),
                    set = setValue("stackingEnabled")
                },
                freezeMouseover = {
                    type = "toggle",
                    name = "Freeze Mouseover",
                    desc = "Stops movement of the plate under the cursor.",
                    order = 2,
                    get = getValue("stackingFreezeMouseover"),
                    set = setValue("stackingFreezeMouseover")
                },
                spacer1 = spacer(3),

                xSpace = {
                    type = "range",
                    name = "Collider Width",
                    desc = "Width of the virtual collider around the plate.",
                    min = 20,
                    max = 200,
                    step = 1,
                    order = 10,
                    get = getValue("stackingXSpace"),
                    set = setValue("stackingXSpace")
                },
                ySpace = {
                    type = "range",
                    name = "Collider Height",
                    desc = "Height of the virtual collider around the plate.",
                    min = 5,
                    max = 50,
                    step = 1,
                    order = 11,
                    get = getValue("stackingYSpace"),
                    set = setValue("stackingYSpace")
                },
                speed = {
                    type = "range",
                    name = "Stacking Speed",
                    desc = "Speed of plate rising and shifting. Higher = faster response.",
                    min = 1,
                    max = 20,
                    step = 1,
                    order = 12,
                    get = getValue("stackingSpeed"),
                    set = setValue("stackingSpeed")
                },
                updateRate = {
                    type = "range",
                    name = "Update Rate (sec)",
                    desc = "0 = every frame, 0.03 = ~30 times/sec.",
                    min = 0,
                    max = 0.1,
                    step = 0.005,
                    order = 13,
                    get = getValue("stackingUpdateRate"),
                    set = setValue("stackingUpdateRate")
                }
            }
        },

        general = {
            type = "group",
            name = "General",
            order = 6,
            childGroups = "tab",
            args = {
                minimap = {
                    type = "group",
                    name = "Minimap",
                    order = 1,
                    args = {
                        hide = {
                            type = "toggle",
                            name = "Hide Settings Icon",
                            desc = "Hide the settings button on the minimap.",
                            order = 1,
                            get = function()
                                return addon.db.profile.minimap.hide
                            end,
                            set = function(_, value)
                                addon.db.profile.minimap.hide = value
                                addon:ApplyMinimapIcon()
                            end
                        }
                    }
                }
            }
        }
    }
}

function addon:SetupOptions()
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)
    profiles.order = 99
    options.args.profiles = profiles

    AceConfig:RegisterOptionsTable("AeonoPlates", options)

    local function openOptions()
        AceConfigDialog:Open("AeonoPlates")
    end
    self:RegisterChatCommand("aeno", openOptions)
    self:RegisterChatCommand("aeonoplates", openOptions)
end