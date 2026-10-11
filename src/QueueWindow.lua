local _, Z = ...
Z = Z.ZEUSModule or Z
if Z.runtimeInactive then return end
-- The queue window (Advanced: Show queue window, off by default): who ZEUS buffs next, one player
-- a line from the top down (class icon, level, name in class colour), in the default chat
-- window's font and size (in every alphabet it has), on a see-through black like the chat
-- window's. The class icons are as tall as the text.
-- Drag it to move it; drag its bottom-right corner (shown with the mouse over it, as on the chat
-- window) to resize it, and a taller window shows more of the queue. A player who needs several
-- buffs shows once. Players out of sight are grey: ZEUS tries them last. When there is no queue
-- the window says why. Its place and size are saved; Restore Defaults hides it and puts it back.
local L = Z.L
local PAD = 6
local LINE = 17 -- the text's height plus 3, set from the chat font
local BG, BG_HOVER = 0.25, 0.45 -- the chat window's see-through black, and with the mouse over it
local MIN_W, MAX_W, MAX_H = 100, 500, 800
local function minHeight() return 2 * PAD + LINE end
local DEFAULT = {point = "LEFT", x = 30, y = 60, w = 180, h = 150}
local window, status, grip
local rows, lastKey = {}, nil
local font = {} -- the chat size in use and the font object for it

local function saved()
    if type(Z.db.queueWindow) ~= "table" then Z.db.queueWindow = {} end
    return Z.db.queueWindow
end
local function save()
    local point, _, relative, x, y = window:GetPoint()
    local q = saved()
    q.point, q.relative, q.x, q.y = point, relative, x, y
    q.w, q.h = window:GetWidth(), window:GetHeight()
end
local function clamp(v, low, high, fallback)
    v = tonumber(v) or fallback
    return math.max(low, math.min(high, v))
end
local function place()
    local q = saved()
    window:ClearAllPoints()
    if type(q.point) == "string" and type(q.x) == "number" and type(q.y) == "number" then
        window:SetPoint(q.point, UIParent, type(q.relative) == "string" and q.relative or q.point, q.x, q.y)
    else
        window:SetPoint(DEFAULT.point, UIParent, DEFAULT.point, DEFAULT.x, DEFAULT.y)
    end
    window:SetSize(clamp(q.w, MIN_W, MAX_W, DEFAULT.w), clamp(q.h, minHeight(), MAX_H, DEFAULT.h))
end
-- The default chat window's text size (the player can change it), 14 when the game can't say.
local function chatSize()
    local size
    local chat = ChatFrame1
    if type(chat) == "table" and type(chat.GetFont) == "function" then size = select(2, chat:GetFont()) end
    size = tonumber(size)
    if not size or size <= 0 then size = 14 end
    return size
end
-- The chat font at that size, with every alphabet the game's chat font carries (Latin, Korean,
-- both Chinese scripts, Cyrillic), so a name in any of them shows instead of boxes. Setting one
-- font file would keep only the first. At the chat font's own size that is ChatFontNormal
-- itself; at another size a font family with the same members, scaled, made once per size.
local ALPHABETS = {"roman", "korean", "simplifiedchinese", "traditionalchinese", "russian"}
local families = {}
local function fontFor(size)
    local base = ChatFontNormal
    if type(base) ~= "table" or type(base.GetFont) ~= "function" then return nil end
    local baseSize = tonumber((select(2, base:GetFont())))
    if not baseSize or baseSize <= 0 or math.abs(size - baseSize) < 0.5 then return base end
    local key = math.floor(size + 0.5)
    if families[key] ~= nil then return families[key] or base end
    families[key] = false
    if type(CreateFontFamily) ~= "function" or type(base.GetFontObjectForAlphabet) ~= "function" then return base end
    local members = {}
    for _, alphabet in ipairs(ALPHABETS) do
        local ok, member = pcall(base.GetFontObjectForAlphabet, base, alphabet)
        if ok and type(member) == "table" and type(member.GetFont) == "function" then
            local file, height, flags = member:GetFont()
            height = tonumber(height) or baseSize
            if type(file) == "string" and file ~= "" then
                members[#members + 1] = {alphabet = alphabet, file = file,
                    height = height * size / baseSize, flags = type(flags) == "string" and flags or ""}
            end
        end
    end
    if #members == 0 then return base end
    local ok, family = pcall(CreateFontFamily, "ZEUSQueueFont" .. key, members)
    if not ok or type(family) ~= "table" then return base end
    families[key] = family
    return family
end
-- One line: the class icon (an atlas the size of the text), level and name in class colour. A
-- player out of sight is grey, icon and all.
local function line(c)
    local size = math.floor(font.size + 0.5)
    local grey = c.los == 1
    local icon = ""
    if type(c.class) == "string" then
        icon = ("|A:classicon-%s:%d:%d%s|a "):format(c.class:lower(), size, size, grey and ":0:0:128:128:128" or "")
    end
    local level = type(c.level) == "number" and c.level > 0 and tostring(c.level) or "??"
    if grey then return icon .. "|cff808080" .. level .. " " .. c.name .. "|r" end
    local color = c.class and type(RAID_CLASS_COLORS) == "table" and RAID_CLASS_COLORS[c.class]
    local name = c.name
    if type(color) == "table" and type(color.colorStr) == "string" then name = "|c" .. color.colorStr .. name .. "|r" end
    return icon .. level .. " " .. name
end
-- The names to show, or nil and the reason there are none.
local function names()
    if InCombatLockdown() then return nil, L.STATUS_COMBAT end
    if Z.GamepadUI() then return nil, L.PAUSED_GAMEPAD end
    if not Z.IsEnabled() then return nil, L.QUEUE_OFF end
    if not Z.FriendsEnabled() then return nil, L.QUEUE_NO_PLATES end
    if #Z.active == 0 then return nil, L.QUEUE_NO_BUFFS end
    local out, seen = {}, {}
    -- Out of mana for all of it: the queue stays, under a line that says why nothing happens.
    if Z.OutOfMana and Z.OutOfMana() then out[1] = "|cff5599ff" .. L.QUEUE_OOM .. "|r" end
    for _, c in ipairs(Z.lastScan or {}) do
        if c.guid and c.name and not seen[c.guid] then
            seen[c.guid] = true
            out[#out + 1] = line(c)
        end
    end
    if #out == 0 or (#out == 1 and Z.OutOfMana and Z.OutOfMana()) then return nil, L.QUEUE_EMPTY end
    return out
end
-- How many names fit in the window's height.
local function fits()
    return math.max(1, math.floor((window:GetHeight() - 2 * PAD) / LINE + 0.001))
end
local function useFont(text)
    if font.object then text:SetFontObject(font.object) end
    text:SetShadowOffset(1, -1) -- the chat font's shadow, which a new family lacks
    text:SetShadowColor(0, 0, 0, 1)
end
local function position(r, i)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", PAD, -PAD - (i - 1) * LINE)
    r:SetPoint("TOPRIGHT", -PAD, -PAD - (i - 1) * LINE)
    r:SetHeight(LINE)
end
local function row(i)
    if not rows[i] then
        local r = window:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
        r:SetJustifyH("LEFT")
        if r.SetWordWrap then r:SetWordWrap(false) end
        useFont(r)
        position(r, i)
        rows[i] = r
    end
    return rows[i]
end
local function bounds()
    if window.SetResizeBounds then window:SetResizeBounds(MIN_W, minHeight(), MAX_W, MAX_H)
    elseif window.SetMinResize then window:SetMinResize(MIN_W, minHeight()) window:SetMaxResize(MAX_W, MAX_H) end
end
-- Follows the chat window's font: a new size changes the line height and the icons.
local function followChat()
    local size = chatSize()
    if size == font.size then return false end
    font.size, font.object = size, fontFor(size)
    LINE = math.ceil(size) + 3
    for i, r in ipairs(rows) do useFont(r) position(r, i) end
    useFont(status)
    bounds()
    return true
end
local function render(force)
    if followChat() then force = true end
    local list, reason = names()
    local fit = fits()
    local key = fit .. "\n" .. (list and table.concat(list, "\n", 1, math.min(#list, fit)) or reason)
    if key == lastKey and not force then return end
    lastKey = key
    local shown = list and math.min(#list, fit) or 0
    for i = 1, shown do
        local r = row(i)
        r:SetText(list[i])
        r:Show()
    end
    for i = shown + 1, #rows do rows[i]:Hide() end
    status:SetText(reason or "")
    status:SetShown(list == nil)
end
local function hover(on)
    window.bg:SetColorTexture(0, 0, 0, on and BG_HOVER or BG)
    grip:SetShown(on)
end
local function leave()
    if not (window.IsMouseOver and window:IsMouseOver()) then hover(false) end
end
local function create()
    window = CreateFrame("Frame", "ZEUSQueueWindow", UIParent)
    window:SetFrameStrata("LOW")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:SetResizable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() save() end)
    window:SetScript("OnSizeChanged", function() render(true) end)
    window:SetScript("OnEnter", function() hover(true) end)
    window:SetScript("OnLeave", leave)
    window.bg = window:CreateTexture(nil, "BACKGROUND")
    window.bg:SetAllPoints(window)
    status = window:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
    status:SetPoint("TOPLEFT", PAD, -PAD)
    status:SetPoint("TOPRIGHT", -PAD, -PAD)
    status:SetJustifyH("LEFT")
    status:SetTextColor(0.6, 0.6, 0.6)
    grip = CreateFrame("Button", nil, window)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", 0, 0)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() window:StopMovingOrSizing() save() render(true) end)
    grip:SetScript("OnLeave", leave)
    window.grip, window.status, window.rows = grip, status, rows
    followChat()
    bounds()
    hover(false)
    Z.queueWindow = window
end

-- Shows or hides the window as the setting says, in its saved place.
function Z.ApplyQueueWindow()
    if Z.db.showQueue ~= true then
        if window then window:Hide() end
        return
    end
    if not window then create() end
    place()
    window:Show()
    render(true)
end
-- The Advanced box.
function Z.SetQueueWindowShown(on)
    Z.db.showQueue = on and true or false
    Z.ApplyQueueWindow()
    if Z.queueCheck then Z.queueCheck:SetChecked(Z.db.showQueue) end
end
-- After every queue rebuild and status change (UI.lua's Z.UpdateStatus).
function Z.UpdateQueueWindow()
    if window and window:IsShown() then render() end
end
