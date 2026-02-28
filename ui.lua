if ShaguScan.disabled then return end

local utils = ShaguScan.utils
local filter = ShaguScan.filter
local settings = ShaguScan.settings
local r1, r2 = pcall(UnitXP, "nop", "nop")
local unitxp = r1 == true and r2 == true
local ui = CreateFrame("Frame", nil, UIParent)

ui.border = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

ui.background = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true,
  tileSize = 16,
  edgeSize = 8,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

ui.frames = {}

-- Bar 对象池，用于复用
ui.barPool = {}
ui.barPoolSize = 0 -- 手动跟踪池大小
ui.activeBars = {}

local function fmtDistance(distance, decimals)
  if not distance or tonumber(distance) == nil then return "" end

  if not decimals then
    decimals = 1
  end

  return string.format("%." .. decimals .. "f", distance)
end

ui.CreateRoot = function(parent, caption)
  local frame = CreateFrame("Frame", "ShaguScan" .. caption, parent)
  frame.id = caption

  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetMovable(true)

  frame:SetScript("OnDragStart", function()
    this.lock = true
    this:StartMoving()
  end)

  frame:SetScript("OnDragStop", function()
    -- load current window config
    local config = ShaguScan_db.config[this.id]

    -- convert to best anchor depending on position
    local new_anchor = utils.GetBestAnchor(this)
    local anchor, x, y = utils.ConvertFrameAnchor(this, new_anchor)
    this:ClearAllPoints()
    this:SetPoint(anchor, UIParent, anchor, x, y)

    -- save new position
    local anchor, _, _, x, y = this:GetPoint()
    config.anchor, config.x, config.y = anchor, x, y

    -- stop drag
    this:StopMovingOrSizing()
    this.lock = false
  end)

  -- assign/initialize elements
  frame.CreateBar = ui.CreateBar
  frame.ReleaseBar = ui.ReleaseBar
  frame.frames = {}

  -- create title text
  frame.caption = frame:CreateFontString(nil, "HIGH", "GameFontWhite")
  frame.caption:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
  frame.caption:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -2)
  frame.caption:SetTextColor(1, 1, 1, 1)
  frame.caption:SetText(caption)

  -- create option button
  frame.settings = CreateFrame("Button", nil, frame)
  frame.settings:SetPoint("RIGHT", frame.caption, "LEFT", -2, 0)
  frame.settings:SetWidth(8)
  frame.settings:SetHeight(8)

  frame.settings:SetScript("OnEnter", function()
    frame.settings.tex:SetAlpha(1)
  end)

  frame.settings:SetScript("OnLeave", function()
    frame.settings.tex:SetAlpha(.5)
  end)

  frame.settings.tex = frame.settings:CreateTexture(nil, 'OVERLAY')
  frame.settings.tex:SetTexture("Interface\\AddOns\\ShaguScan\\img\\config")
  frame.settings.tex:SetAllPoints()
  frame.settings.tex:SetAlpha(.5)

  frame.settings:SetScript("OnClick", function()
    settings.OpenConfig(this:GetParent().id)
  end)

  return frame
end

ui.BarEnter = function()
  this.border:SetBackdropBorderColor(1, 1, 1, 1)
  this.hover = true

  GameTooltip_SetDefaultAnchor(GameTooltip, this)
  GameTooltip:SetUnit(this.guid)
  GameTooltip:Show()
end

ui.BarLeave = function()
  this.hover = false
  GameTooltip:Hide()
end

ui.BarUpdate = function()
  -- animate combat text
  CombatFeedback_OnUpdate(arg1)

  -- update statusbar values
  this.bar:SetMinMaxValues(0, UnitHealthMax(this.guid))
  this.bar:SetValue(UnitHealth(this.guid))

  -- update health bar color
  local hex, r, g, b, a = utils.GetUnitColor(this.guid)
  this.bar:SetStatusBarColor(r, g, b, a)

  -- update caption text
  local level = utils.GetLevelString(this.guid)
  local level_color = utils.GetLevelColor(this.guid)
  local name = UnitName(this.guid)
  this.text:SetText(level_color .. level .. "|r " .. name)

  -- update health bar border
  if this.hover then
    this.border:SetBackdropBorderColor(1, 1, 1, 1)
  elseif UnitAffectingCombat(this.guid) then
    this.border:SetBackdropBorderColor(.8, .2, .2, 1)
  else
    this.border:SetBackdropBorderColor(.2, .2, .2, 1)
  end

  -- show raid icon if existing
  if GetRaidTargetIndex(this.guid) then
    SetRaidTargetIconTexture(this.icon, GetRaidTargetIndex(this.guid))
    this.icon:Show()
  else
    this.icon:Hide()
  end

  -- update target indicator
  if UnitIsUnit("target", this.guid) then
    this.target_left:Show()
    this.target_right:Show()
  else
    this.target_left:Hide()
    this.target_right:Hide()
  end

  if unitxp then
    local distance = UnitXP("distanceBetween", "player", this.guid)
    this.distance:SetText(fmtDistance(distance, 1))
    if distance then
      local r, g, b
      local linearColorFrom = { 0, 1, 0 }
      local linearColorTo = { 1, 0, 0 }
      if distance < 8 then
        distance = 8
      elseif distance > 200 then
        distance = 200
      end

      local p = (distance - 8) / (200 - 8)
      r = linearColorFrom[1] + (linearColorTo[1] - linearColorFrom[1]) * p
      g = linearColorFrom[2] + (linearColorTo[2] - linearColorFrom[2]) * p
      b = linearColorFrom[3] + (linearColorTo[3] - linearColorFrom[3]) * p

      this.distance:SetTextColor(r, g, b)
    end
  end
end

ui.BarClick = function()
  TargetUnit(this.guid)
end

ui.BarEvent = function()
  if arg1 ~= this.guid then return end
  CombatFeedback_OnCombatEvent(arg2, arg3, arg4, arg5)
end

-- 从池中获取或创建新的 bar
ui.CreateBar = function(parent, guid)
  local frame

  -- 尝试从对象池中获取可用的 bar
  if ui.barPoolSize > 0 then
    frame = ui.barPool[ui.barPoolSize]
    ui.barPool[ui.barPoolSize] = nil
    ui.barPoolSize = ui.barPoolSize - 1

    -- 重置 parent 和 guid
    frame:SetParent(parent)
    frame.guid = guid
    -- 重新注册事件（因为 SetParent 可能会影响事件）
    frame:RegisterEvent("UNIT_COMBAT")
  else
    -- 池中没有可用的，创建新的
    frame = CreateFrame("Button", nil, parent)
    frame.guid = guid

    -- assign required events and scripts
    frame:RegisterEvent("UNIT_COMBAT")
    frame:SetScript("OnEvent", ui.BarEvent)
    frame:SetScript("OnClick", ui.BarClick)
    frame:SetScript("OnEnter", ui.BarEnter)
    frame:SetScript("OnLeave", ui.BarLeave)
    frame:SetScript("OnUpdate", ui.BarUpdate)

    -- create health bar
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(1, .8, .2, 1)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(20)
    bar:SetAllPoints()
    frame.bar = bar

    -- create caption text
    local text = frame.bar:CreateFontString(nil, "HIGH", "GameFontWhite")
    text:SetPoint("TOPLEFT", bar, "TOPLEFT", 2, -2)
    text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 2)
    text:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
    text:SetJustifyH("LEFT")
    frame.text = text

    -- create combat feedback text
    local feedback = bar:CreateFontString(guid .. "feedback" .. GetTime(), "OVERLAY", "NumberFontNormalHuge")
    feedback:SetAlpha(.8)
    feedback:SetFont(DAMAGE_TEXT_FONT, 12, "OUTLINE")
    feedback:SetParent(bar)
    feedback:ClearAllPoints()
    feedback:SetPoint("CENTER", bar, "CENTER", 0, 0)

    frame.feedbackFontHeight = 14
    frame.feedbackStartTime = GetTime()
    frame.feedbackText = feedback

    -- create raid icon textures
    local icon = bar:CreateTexture(nil, "OVERLAY")
    icon:SetWidth(16)
    icon:SetHeight(16)
    icon:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    icon:Hide()
    frame.icon = icon

    -- create target indicator
    local target_left = bar:CreateTexture(nil, "OVERLAY")
    target_left:SetWidth(8)
    target_left:SetHeight(8)
    target_left:SetPoint("LEFT", frame, "LEFT", -4, 0)
    target_left:SetTexture("Interface\\AddOns\\ShaguScan\\img\\target-left")
    target_left:Hide()
    frame.target_left = target_left

    local target_right = bar:CreateTexture(nil, "OVERLAY")
    target_right:SetWidth(8)
    target_right:SetHeight(8)
    target_right:SetPoint("RIGHT", frame, "RIGHT", 4, 0)
    target_right:SetTexture("Interface\\AddOns\\ShaguScan\\img\\target-right")
    target_right:Hide()
    frame.target_right = target_right

    local distance = bar:CreateFontString(guid .. "distance" .. GetTime(), "OVERLAY", "GameFontWhite")
    distance:SetPoint("TOPLEFT", bar, "TOPRIGHT", 2, -2)
    distance:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", 2, 2)
    distance:SetWidth(50)
    distance:SetFont(STANDARD_TEXT_FONT, 9, "THINOUTLINE")
    distance:SetJustifyH("LEFT")
    if not unitxp then distance:Hide() end
    frame.distance = distance

    -- create frame backdrops
    if pfUI and pfUI.uf then
      pfUI.api.CreateBackdrop(frame)
      frame.border = frame.backdrop
    else
      frame:SetBackdrop(ui.background)
      frame:SetBackdropColor(0, 0, 0, 1)

      local border = CreateFrame("Frame", nil, frame.bar)
      border:SetBackdrop(ui.border)
      border:SetBackdropColor(.2, .2, .2, 1)
      border:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", -2, 2)
      border:SetPoint("BOTTOMRIGHT", frame.bar, "BOTTOMRIGHT", 2, -2)
      frame.border = border
    end
  end

  -- 重置状态
  frame.hover = false
  frame.pos = nil
  frame.sizes = nil

  -- 记录到活跃 bars 表中
  ui.activeBars[frame] = true

  return frame
end

-- 将 bar 回收到对象池中
ui.ReleaseBar = function(parent, guid)
  local frame = parent.frames[guid]
  if not frame then return end

  -- 隐藏 bar
  frame:Hide()

  -- 取消事件注册
  frame:UnregisterEvent("UNIT_COMBAT")

  -- 清除 guid 关联
  frame.guid = nil

  -- 从父框架的 frames 表中移除
  parent.frames[guid] = nil

  -- 从活跃 bars 表中移除
  ui.activeBars[frame] = nil

  -- 添加到对象池（使用 table.insert 兼容旧版本）
  ui.barPoolSize = ui.barPoolSize + 1
  ui.barPool[ui.barPoolSize] = frame
end

-- 清理所有对象池中的 bars（可选，用于内存紧张时）
ui.ClearBarPool = function()
  for i = 1, ui.barPoolSize do
    ui.barPool[i]:SetParent(nil)
    ui.barPool[i] = nil
  end
  ui.barPoolSize = 0
end

ui:SetAllPoints()
ui:SetScript("OnUpdate", function()
  if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + .5 end

  -- remove old leftover frames
  for caption, root in pairs(ui.frames) do
    if not ShaguScan_db.config[caption] then
      -- 回收所有子 bars 到对象池
      for guid, _ in pairs(root.frames) do
        root:ReleaseBar(guid)
      end
      root:Hide()
      ui.frames[caption] = nil
    end
  end

  -- create ui frames based on config values
  for caption, config in pairs(ShaguScan_db.config) do
    -- create root frame if not existing
    ui.frames[caption] = ui.frames[caption] or ui:CreateRoot(caption)
    local root = ui.frames[caption]

    -- skip if locked (due to moving)
    if root.lock then return end

    -- update position based on config
    if not root.pos or root.pos ~= config.anchor .. config.x .. config.y .. config.scale then
      root.pos = config.anchor .. config.x .. config.y .. config.scale
      root:ClearAllPoints()
      root:SetPoint(config.anchor, config.x, config.y)
      root:SetScale(config.scale)
    end

    -- update filter if required
    if not root.filter_conf or root.filter_conf ~= config.filter then
      root.filter = {}

      -- prepare all filter texts
      local filter_texts = { utils.strsplit(',', config.filter) }
      for id, filter_text in pairs(filter_texts) do
        local name, args = utils.strsplit(':', filter_text)
        root.filter[name] = args or true
      end

      -- mark current state of data
      root.filter_conf = config.filter
    end

    -- 跟踪当前应该显示的 guids
    local visibleGuids = {}

    -- run through all guids and fill with bars
    local title_size = 12 + config.spacing
    local width, height = config.width, config.height + title_size
    local x, y, count = 0, 0, 0
    for guid, time in pairs(ShaguScan.core.guids) do
      -- apply filters
      local visible = true
      if UnitIsPlayer(guid) and UnitName("player") == UnitName(guid) then visible = false end
      for name, args in pairs(root.filter) do
        if not visible then break end
        if filter[name] then
          visible = visible and filter[name].func(guid, args)
        end
      end

      -- display element if filters allow it
      if UnitExists(guid) and visible then
        count = count + 1
        visibleGuids[guid] = true

        if count > config.maxrow then
          count, x = 1, x + config.width + config.spacing
          width = math.max(x + config.width, width)
        end

        y = (count - 1) * (config.height + config.spacing) + title_size
        height = math.max(y + config.height + config.spacing, height)

        -- 尝试从对象池获取或创建新 bar
        local bar = root.frames[guid]
        if not bar then
          bar = root:CreateBar(guid)
          root.frames[guid] = bar
        end

        -- update position if required
        if not bar.pos or bar.pos ~= x .. -y then
          bar:ClearAllPoints()
          bar:SetPoint("TOPLEFT", root, "TOPLEFT", x, -y)
          bar.pos = x .. -y
        end

        -- update sizes if required
        if not bar.sizes or bar.sizes ~= config.width .. config.height then
          bar:SetWidth(config.width)
          bar:SetHeight(config.height)
          bar.sizes = config.width .. config.height
        end

        bar:Show()
      end
    end

    -- 回收不再需要的 bars（使用 ReleaseBar 代替直接隐藏和删除）
    for guid, bar in pairs(root.frames) do
      if not visibleGuids[guid] then
        root:ReleaseBar(guid)
      end
    end

    -- update window size
    root:SetWidth(width)
    root:SetHeight(height)
  end
end)

ShaguScan.ui = ui
