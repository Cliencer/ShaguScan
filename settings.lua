if ShaguScan.disabled then return end

local utils = ShaguScan.utils

local settings = {}

SLASH_SHAGUSCAN1, SLASH_SHAGUSCAN2, SLASH_SHAGUSCAN3 = "/scan", "/sscan", "/shaguscan"

SlashCmdList["SHAGUSCAN"] = function(input)
  local caption = input and input ~= '' and input or "Scanner"
  settings.OpenConfig(caption)
end

settings.backdrop = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

settings.textborder = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true,
  tileSize = 16,
  edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

settings.CreateLabel = function(parent, text)
  local label = parent:CreateFontString(nil, 'HIGH', 'GameFontWhite')
  label:SetFont(STANDARD_TEXT_FONT, 9)
  label:SetText(text)
  label:SetHeight(18)
  return label
end

settings.CreateTextBox = function(parent, text)
  local textbox = CreateFrame("EditBox", nil, parent)
  textbox.ShowTooltip = settings.ShowTooltip

  textbox:SetTextColor(1, .8, .2, 1)
  textbox:SetJustifyH("RIGHT")
  textbox:SetTextInsets(5, 5, 5, 5)
  textbox:SetBackdrop(settings.textborder)
  textbox:SetBackdropColor(.1, .1, .1, 1)
  textbox:SetBackdropBorderColor(.2, .2, .2, 1)

  textbox:SetHeight(18)

  textbox:SetFontObject(GameFontNormal)
  textbox:SetFont(STANDARD_TEXT_FONT, 9)
  textbox:SetAutoFocus(false)
  textbox:SetText((text or ""))

  textbox:SetScript("OnEscapePressed", function(self)
    this:ClearFocus()
  end)
  textbox:SetScript("OnTextChanged", function(self)
    if this:GetParent().onchange then
      this:GetParent().onchange()
    end
  end)
  return textbox
end

settings.CreateCheckBox = function(parent)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")

  checkbox:SetBackdrop(settings.textborder)
  checkbox:SetHeight(18)
  checkbox:SetWidth(18)
  checkbox:SetScript("OnClick", function(self)
    this:GetParent().onchange()
  end)

  return checkbox
end

settings.ShowTooltip = function(parent, strings)
  GameTooltip:SetOwner(parent, "ANCHOR_RIGHT")
  for id, entry in pairs(strings) do
    if type(entry) == "table" then
      GameTooltip:AddDoubleLine(entry[1], entry[2])
    else
      GameTooltip:AddLine(entry)
    end
  end
  GameTooltip:Show()
end

settings.CreateScrollFrame = function(name, parent)
  local f = CreateFrame("ScrollFrame", name, parent)

  -- create slider
  f.slider = CreateFrame("Slider", nil, f)
  f.slider:SetOrientation('VERTICAL')
  f.slider:SetPoint("TOPLEFT", f, "TOPRIGHT", -7, 0)
  f.slider:SetPoint("BOTTOMRIGHT", 0, 0)
  f.slider:SetThumbTexture("Interface\\BUTTONS\\WHITE8X8")
  f.slider.thumb = f.slider:GetThumbTexture()
  f.slider.thumb:SetHeight(50)
  f.slider.thumb:SetTexture(.3, 1, .8, .5)

  local selfevent = false
  f.slider:SetScript("OnValueChanged", function()
    if selfevent then return end
    selfevent = true
    f:SetVerticalScroll(this:GetValue())
    f.UpdateScrollState()
    selfevent = false
  end)

  f.UpdateScrollState = function()
    f.slider:SetMinMaxValues(0, f:GetVerticalScrollRange())
    f.slider:SetValue(f:GetVerticalScroll())

    local m = f:GetHeight() + f:GetVerticalScrollRange()
    local v = f:GetHeight()
    local ratio = v / m

    if ratio < 1 then
      local size = math.floor(v * ratio)
      f.slider.thumb:SetHeight(size)
      f.slider:Show()
    else
      f.slider:Hide()
    end
  end

  f.Scroll = function(self, step)
    local step = step or 0

    local current = f:GetVerticalScroll()
    local max = f:GetVerticalScrollRange()
    local new = current - step

    if new >= max then
      f:SetVerticalScroll(max)
    elseif new <= 0 then
      f:SetVerticalScroll(0)
    else
      f:SetVerticalScroll(new)
    end

    f:UpdateScrollState()
  end

  f:EnableMouseWheel(1)
  f:SetScript("OnMouseWheel", function()
    this:Scroll(arg1 * 10)
  end)

  return f
end

settings.CreateScrollChild = function(name, parent)
  local f = CreateFrame("Frame", name, parent)

  -- dummy values required
  f:SetWidth(1)
  f:SetHeight(1)
  f:SetAllPoints(parent)

  parent:SetScrollChild(f)

  f:SetScript("OnUpdate", function()
    this:GetParent():UpdateScrollState()
  end)

  return f
end

settings.OpenConfig = function(caption)
  -- Toggle Existing Dialog
  local existing = getglobal("ShaguScanConfigDialog" .. caption)
  if existing then
    if existing:IsShown() then existing:Hide() else existing:Show() end
    return
  end

  -- Create defconfig if new config
  if not ShaguScan_db.config[caption] then
    ShaguScan_db.config[caption] = {
      filter = "npc,infight,alive",
      scale = 1,
      anchor = "CENTER",
      x = 0,
      y = 0,
      width = 75,
      height = 12,
      spacing = 4,
      maxrow = 20
    }
  end

  -- Main Dialog
  local dialog = CreateFrame("Frame", "ShaguScanConfigDialog" .. caption, UIParent)
  table.insert(UISpecialFrames, "ShaguScanConfigDialog" .. caption)

  -- Save Shortcuts
  local config = ShaguScan_db.config[caption]
  local caption = caption

  dialog:SetFrameStrata("DIALOG")
  dialog:SetPoint("CENTER", 0, 0)
  dialog:SetWidth(264)
  dialog:SetHeight(264)

  dialog:EnableMouse(true)
  dialog:RegisterForDrag("LeftButton")
  dialog:SetMovable(true)
  dialog:SetScript("OnDragStart", function() this:StartMoving() end)
  dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  dialog:SetBackdrop(settings.backdrop)
  dialog:SetBackdropColor(.2, .2, .2, 1)
  dialog:SetBackdropBorderColor(.2, .2, .2, 1)

  -- Assign functions to dialog
  dialog.CreateTextBox = settings.CreateTextBox
  dialog.CreateLabel = settings.CreateLabel

  -- Save & Reload
  dialog.save = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.save:SetWidth(96)
  dialog.save:SetHeight(18)
  dialog.save:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 8)
  dialog.save:SetText(ShaguScan.Loc["Save"])
  dialog.save:SetScript("OnClick", function()
    local new_caption = dialog.caption:GetText()

    local filter = dialog.filter:GetText()
    local width = dialog.width:GetText()
    local height = dialog.height:GetText()
    local spacing = dialog.spacing:GetText()
    local maxrow = dialog.maxrow:GetText()
    local anchor = dialog.anchor:GetText()
    local scale = dialog.scale:GetText()
    local x = dialog.x:GetText()
    local y = dialog.y:GetText()

    -- build new config
    local new_config = {
      filter = filter,
      width = tonumber(width) or config.width,
      height = tonumber(height) or config.height,
      spacing = tonumber(spacing) or config.spacing,
      maxrow = tonumber(maxrow) or config.maxrow,
      anchor = utils.IsValidAnchor(anchor) and anchor or config.anchor,
      scale = tonumber(scale) or config.scale,
      x = tonumber(x) or config.x,
      y = tonumber(y) or config.y,
    }

    ShaguScan_db.config[caption] = nil
    ShaguScan_db.config[new_caption] = new_config
    this:GetParent():Hide()
  end)

  -- Delete
  dialog.delete = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
  dialog.delete:SetWidth(96)
  dialog.delete:SetHeight(18)
  dialog.delete:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.delete:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 8, 8)
  dialog.delete:SetText(ShaguScan.Loc["Delete"])
  dialog.delete:SetScript("OnClick", function()
    ShaguScan_db.config[caption] = nil
    this:GetParent():Hide()
  end)

  dialog.close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
  dialog.close:SetWidth(20)
  dialog.close:SetHeight(20)
  dialog.close:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", 0, 0)
  dialog.close:SetScript("OnClick", function()
    this:GetParent():Hide()
  end)

  -- Caption (Title)
  dialog.caption = dialog:CreateTextBox(caption)
  dialog.caption:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -18)
  dialog.caption:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -8, -18)
  dialog.caption:SetFont(STANDARD_TEXT_FONT, 10)
  dialog.caption:SetJustifyH("CENTER")
  dialog.caption:SetHeight(20)

  -- Backdrop
  local backdrop = CreateFrame("Frame", nil, dialog)
  backdrop:SetBackdrop(settings.backdrop)
  backdrop:SetBackdropBorderColor(.2, .2, .2, 1)
  backdrop:SetBackdropColor(.2, .2, .2, 1)

  backdrop:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -40)
  backdrop:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 28)

  backdrop.CreateTextBox = settings.CreateTextBox
  backdrop.CreateLabel = settings.CreateLabel

  backdrop.pos = 8

  -- Filter
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Filter:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.filter = backdrop:CreateTextBox(config.filter)

  dialog.filter:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.filter:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.filter:SetScript("OnMouseUp", function()
    dialog.filter:ClearFocus()
    settings.OpenFilter(dialog.caption:GetText())
  end)
  dialog.filter:SetScript("OnMouseDown", function()
    dialog.filter:ClearFocus()
  end)
  dialog.filter:SetScript("OnEnter", function()
    dialog.filter:ShowTooltip({
      ShaguScan.Loc["Unit Filters"],
      ShaguScan.Loc["Click to open filter browser."],
    })
  end)

  dialog.filter:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Spacer
  backdrop.pos = backdrop.pos + 9

  -- Width
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Width:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.width = backdrop:CreateTextBox(config.width)
  dialog.width:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.width:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.width:SetScript("OnEnter", function()
    dialog.width:ShowTooltip({
      ShaguScan.Loc["Health Bar Width"],
      ShaguScan.Loc["An Integer Value in Pixels"]
    })
  end)

  dialog.width:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18

  -- Height
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Height:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.height = backdrop:CreateTextBox(config.height)
  dialog.height:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.height:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.height:SetScript("OnEnter", function()
    dialog.height:ShowTooltip({
      ShaguScan.Loc["Health Bar Height"],
      ShaguScan.Loc["An Integer Value in Pixels"]
    })
  end)

  dialog.height:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Spacing
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Spacing:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.spacing = backdrop:CreateTextBox(config.spacing)
  dialog.spacing:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.spacing:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.spacing:SetScript("OnEnter", function()
    dialog.spacing:ShowTooltip({
      ShaguScan.Loc["Spacing Between Health Bars"],
      ShaguScan.Loc["An Integer Value in Pixels"]
    })
  end)

  dialog.spacing:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Max per Row
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Max-Row:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.maxrow = backdrop:CreateTextBox(config.maxrow)
  dialog.maxrow:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.maxrow:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.maxrow:SetScript("OnEnter", function()
    dialog.maxrow:ShowTooltip({
      ShaguScan.Loc["Maximum Entries Per Column"],
      ShaguScan.Loc["A new column will be created once exceeded"]
    })
  end)

  dialog.maxrow:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Spacer
  backdrop.pos = backdrop.pos + 9

  -- Anchor
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Anchor:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.anchor = backdrop:CreateTextBox(config.anchor)
  dialog.anchor:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.anchor:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.anchor:SetScript("OnEnter", function()
    dialog.anchor:ShowTooltip({
      ShaguScan.Loc["Window Anchor"],
      ShaguScan.Loc["The Anchor From Where Positions Are Calculated."],
      " ",
      { "TOP",         "TOPLEFT" },
      { "TOPRIGHT",    "CENTER" },
      { "LEFT",        "RIGHT" },
      { "BOTTOM",      "BOTTOMLEFT" },
      { "BOTTOMRIGHT", "" }
    })
  end)

  dialog.anchor:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Scale
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Scale:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.scale = backdrop:CreateTextBox(utils.round(config.scale, 2))
  dialog.scale:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.scale:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.scale:SetScript("OnEnter", function()
    dialog.scale:ShowTooltip({
      ShaguScan.Loc["Window Scale"],
      ShaguScan.Loc["A floating point number, 1 equals 100%"]
    })
  end)

  dialog.scale:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Position-X
  local caption = backdrop:CreateLabel(ShaguScan.Loc["X-Position:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.x = backdrop:CreateTextBox(utils.round(config.x, 2))
  dialog.x:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.x:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.x:SetScript("OnEnter", function()
    dialog.x:ShowTooltip({
      ShaguScan.Loc["X-Position of Window"],
      ShaguScan.Loc["A Number in Pixels"]
    })
  end)

  dialog.x:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  backdrop.pos = backdrop.pos + 18

  -- Position-Y
  local caption = backdrop:CreateLabel(ShaguScan.Loc["Y-Position:"])
  caption:SetPoint("TOPLEFT", backdrop, 10, -backdrop.pos)

  dialog.y = backdrop:CreateTextBox(utils.round(config.y, 2))
  dialog.y:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 60, -backdrop.pos)
  dialog.y:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -8, -backdrop.pos)
  dialog.y:SetScript("OnEnter", function()
    dialog.y:ShowTooltip({
      ShaguScan.Loc["Y-Position of Window"],
      ShaguScan.Loc["A Number in Pixels"]
    })
  end)

  dialog.y:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  backdrop.pos = backdrop.pos + 18
end
settings.OpenFilter = function(caption)
  local existing = getglobal("ShaguScanConfigFilterDialog" .. caption)
  if existing then
    if existing:IsShown() then existing:Hide() else existing:Show() end
    return
  end
  local config = ShaguScan_db.config[caption]
  if not config then return end
  local configDialog = getglobal("ShaguScanConfigDialog" .. caption)
  local filter = CreateFrame("Frame", "ShaguScanConfigFilterDialog" .. caption,
    configDialog)
  filter.caption = caption
  filter:SetFrameStrata("DIALOG")
  filter:SetPoint("TOPLEFT", configDialog, "TOPRIGHT", 0, 0)
  filter:SetPoint("BOTTOMLEFT", configDialog, "BOTTOMRIGHT", 0, 0)
  filter:SetWidth(264)
  filter:SetBackdrop(settings.backdrop)
  filter:SetBackdropColor(.2, .2, .2, 1)
  filter:SetBackdropBorderColor(.2, .2, .2, 1)
  filter.scroll = settings.CreateScrollFrame(nil, filter)
  filter.scroll:SetPoint("TOPLEFT", 5, -10)
  filter.scroll:SetPoint("BOTTOMRIGHT", -5, 5)
  filter.scroll.box = settings.CreateScrollChild(nil, filter.scroll)
  filter.scroll.box:SetWidth(244)
  print(filter.scroll.box:GetWidth())
  filter.settings = {}

  local function loadData()
    local filter_texts = { utils.strsplit(',', ShaguScan_db.config[caption].filter) }
    for id, filter_text in pairs(filter_texts) do
      local name, args = utils.strsplit(':', filter_text)
      filter.settings[name].enable = true
      filter.settings[name].arg = args or true
      filter.settings[name].checkbox:SetChecked(true)
      if filter.settings[name].input then
        filter.settings[name].input:SetText(args)
      end
    end
  end

  local function saveData()
    local filter_text = ""
    for tag, set in pairs(filter.settings) do
      if set.enable then
        filter_text = filter_text .. tag
        if type(set.arg) == "string" then
          filter_text = filter_text .. ":" .. set.arg
        end
        filter_text = filter_text .. ","
      end
    end
    --ShaguScan_db.config[caption].filter = string.sub(filter_text, 1, -2)
    getglobal("ShaguScanConfigDialog" .. caption).filter:SetText(string.sub(filter_text, 1, -2))
  end

  local i = 0
  for tag, ft in pairs(ShaguScan.filter) do
    i = i + 1
    filter.settings[tag] = CreateFrame("Button", nil, filter.scroll.box)
    filter.settings[tag]:SetPoint("TOPLEFT", filter.scroll.box, "TOPLEFT", 5, -i * 24 + 5)
    filter.settings[tag]:SetPoint("BOTTOMRIGHT", filter.scroll.box, "TOPRIGHT", 5, -i * 24 - 15)
    
    filter.settings[tag].name = ft.name
    filter.settings[tag].hint = ft.hint
    filter.settings[tag].enable = false
    filter.settings[tag].arg = nil

    filter.settings[tag].tex = filter.settings[tag]:CreateTexture("BACKGROUND")
    filter.settings[tag].tex:SetAllPoints(filter.settings[tag])
    filter.settings[tag].tex:SetTexture(0, 0, 0, 0.4)

    filter.settings[tag].checkbox = settings.CreateCheckBox(filter.settings[tag])
    filter.settings[tag].checkbox:SetPoint("LEFT", 5, 0)
    filter.settings[tag].checkbox.ShowTooltip = settings.ShowTooltip

    filter.settings[tag].label = settings.CreateLabel(filter.settings[tag], ft.name)
    filter.settings[tag].label:SetPoint("LEFT", filter.settings[tag].checkbox, "RIGHT", 5, 0)
    
    filter.settings[tag].checkbox:SetScript("OnEnter", function()
      this:ShowTooltip({
        this:GetParent().hint,
      })
    end)
    filter.settings[tag].checkbox:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)


    if ft.needArg then
      filter.settings[tag].input = settings.CreateTextBox(filter.settings[tag], "")
      filter.settings[tag].input:SetWidth(120)
      filter.settings[tag].input:SetHeight(18)
      filter.settings[tag].input:SetPoint("RIGHT", filter.settings[tag], "RIGHT", -10, 0)
       filter.settings[tag].input:SetBackdropBorderColor(.8, .8, .8, 1)
    end
    filter.settings[tag].onchange = function()
      this:GetParent().enable = this:GetParent().checkbox:GetChecked()
      this:GetParent().arg = this:GetParent().input and this:GetParent().input:GetText()
      saveData()
    end
  end



  loadData()
end
ShaguScan.settings = settings
