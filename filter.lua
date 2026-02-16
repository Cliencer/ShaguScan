if ShaguScan.disabled then return end

local filter = {}

filter.player = {
  func = function(unit)
    return UnitIsPlayer(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_player_name"],
  hint = ShaguScan.Loc["filter_player_hint"]
}

filter.npc = {
  func = function(unit)
    return not UnitIsPlayer(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_npc_name"],
  hint = ShaguScan.Loc["filter_npc_hint"]
}

filter.infight = {
  func = function(unit)
    return UnitAffectingCombat(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_infight_name"],
  hint = ShaguScan.Loc["filter_infight_hint"]
}

filter.dead = {
  func = function(unit)
    return UnitIsDead(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_dead_name"],
  hint = ShaguScan.Loc["filter_dead_hint"]
}


filter.alive = {
  func = function(unit)
    return not UnitIsDead(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_alive_name"],
  hint = ShaguScan.Loc["filter_alive_hint"]
}

filter.horde = {
  func = function(unit)
    return UnitFactionGroup(unit) == "Horde" and true or false
  end,
  name = ShaguScan.Loc["filter_horde_name"],
  hint = ShaguScan.Loc["filter_horde_hint"]
}

filter.alliance = {
  func = function(unit)
    return UnitFactionGroup(unit) == "Alliance" and true or false
  end,
  name = ShaguScan.Loc["filter_alliance_name"],
  hint = ShaguScan.Loc["filter_alliance_hint"]
}

filter.hardcore = {
  func = function(unit)
    return string.find((UnitPVPName(unit) or ""), "Still Alive") and true or false
  end,
  name = ShaguScan.Loc["filter_hardcore_name"],
  hint = ShaguScan.Loc["filter_hardcore_hint"]
}

filter.pve = {
  func = function(unit)
    return not UnitIsPVP(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_pve_name"],
  hint = ShaguScan.Loc["filter_pve_hint"]
}

filter.pvp = {
  func = function(unit)
    return UnitIsPVP(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_pvp_name"],
  hint = ShaguScan.Loc["filter_pvp_hint"]
}

filter.icon = {
  func = function(unit)
    return GetRaidTargetIndex(unit) and true or false
  end,
  name = ShaguScan.Loc["filter_icon_name"],
  hint = ShaguScan.Loc["filter_icon_hint"]
}

filter.normal = {
  func = function(unit)
    local elite = UnitClassification(unit)
    return elite == "normal" and true or false
  end,
  name = ShaguScan.Loc["filter_normal_name"],
  hint = ShaguScan.Loc["filter_normal_hint"]
}

filter.elite = {
  func = function(unit)
    local elite = UnitClassification(unit)
    return (elite == "elite" or elite == "rareelite") and true or false
  end,
  name = ShaguScan.Loc["filter_elite_name"],
  hint = ShaguScan.Loc["filter_elite_hint"]
}

filter.rare = {
  func = function(unit)
    local elite = UnitClassification(unit)
    return (elite == "rare" or elite == "rareelite") and true or false
  end,
  name = ShaguScan.Loc["filter_rare_name"],
  hint = ShaguScan.Loc["filter_rare_hint"]
}

filter.rareelite = {
  func = function(unit)
    local elite = UnitClassification(unit)
    return elite == "rareelite" and true or false
  end,
  name = ShaguScan.Loc["filter_rareelite_name"],
  hint = ShaguScan.Loc["filter_rareelite_hint"]
}

filter.worldboss = {
  func = function(unit)
    local elite = UnitClassification(unit)
    return elite == "worldboss" and true or false
  end,
  name = ShaguScan.Loc["filter_worldboss_name"],
  hint = ShaguScan.Loc["filter_worldboss_hint"]
}

filter.hostile = {
  func = function(unit)
    return UnitIsEnemy("player", unit) and true or false
  end,
  name = ShaguScan.Loc["filter_hostile_name"],
  hint = ShaguScan.Loc["filter_hostile_hint"]
}

filter.neutral = {
  func = function(unit)
    return not UnitIsEnemy("player", unit) and not UnitIsFriend("player", unit) and true or false
  end,
  name = ShaguScan.Loc["filter_neutral_name"],
  hint = ShaguScan.Loc["filter_neutral_hint"]
}

filter.friendly = {
  func = function(unit)
    return UnitIsFriend("player", unit) and true or false
  end,
  name = ShaguScan.Loc["filter_friendly_name"],
  hint = ShaguScan.Loc["filter_friendly_hint"]
}

filter.attack = {
  func = function(unit)
    return UnitCanAttack("player", unit) and true or false
  end,
  name = ShaguScan.Loc["filter_attack_name"],
  hint = ShaguScan.Loc["filter_attack_hint"]
}

filter.noattack = {
  func = function(unit)
    return not UnitCanAttack("player", unit) and true or false
  end,
  name = ShaguScan.Loc["filter_noattack_name"],
  hint = ShaguScan.Loc["filter_noattack_hint"]
}

filter.pet = {
  func = function(unit)
    local player = UnitIsPlayer(unit) and true or false
    local controlled = UnitPlayerControlled(unit) and true or false
    local pet = not player and controlled and true or false
    return pet and true or false
  end,
  name = ShaguScan.Loc["filter_pet_name"],
  hint = ShaguScan.Loc["filter_pet_hint"]
}

filter.nopet = {
  func = function(unit)
    local player = UnitIsPlayer(unit) and true or false
    local controlled = UnitPlayerControlled(unit) and true or false
    local pet = not player and controlled and true or false
    return not pet and true or false
  end,
  name = ShaguScan.Loc["filter_nopet_name"],
  hint = ShaguScan.Loc["filter_nopet_hint"]
}

filter.human = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Human" and true or false
  end,
  name = ShaguScan.Loc["filter_human_name"],
  hint = ShaguScan.Loc["filter_human_hint"]
}

filter.orc = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Orc" and true or false
  end,
  name = ShaguScan.Loc["filter_orc_name"],
  hint = ShaguScan.Loc["filter_orc_hint"]
}

filter.dwarf = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Dwarf" and true or false
  end,
  name = ShaguScan.Loc["filter_dwarf_name"],
  hint = ShaguScan.Loc["filter_dwarf_hint"]
}

filter.nightelf = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "NightElf" and true or false
  end,
  name = ShaguScan.Loc["filter_nightelf_name"],
  hint = ShaguScan.Loc["filter_nightelf_hint"]
}

filter.undead = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Scourge" and true or false
  end,
  name = ShaguScan.Loc["filter_undead_name"],
  hint = ShaguScan.Loc["filter_undead_hint"]
}

filter.tauren = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Tauren" and true or false
  end,
  name = ShaguScan.Loc["filter_tauren_name"],
  hint = ShaguScan.Loc["filter_tauren_hint"]
}

filter.gnome = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Gnome" and true or false
  end,
  name = ShaguScan.Loc["filter_gnome_name"],
  hint = ShaguScan.Loc["filter_gnome_hint"]
}

filter.troll = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Troll" and true or false
  end,
  name = ShaguScan.Loc["filter_troll_name"],
  hint = ShaguScan.Loc["filter_troll_hint"]
}

filter.goblin = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "Goblin" and true or false
  end,
  name = ShaguScan.Loc["filter_goblin_name"],
  hint = ShaguScan.Loc["filter_goblin_hint"]
}

filter.highelf = {
  func = function(unit)
    local _, race = UnitRace(unit)
    return race == "BloodElf" and true or false
  end,
  name = ShaguScan.Loc["filter_highelf_name"],
  hint = ShaguScan.Loc["filter_highelf_hint"]
}

filter.warlock = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "WARLOCK" and true or false
  end,
  name = ShaguScan.Loc["filter_warlock_name"],
  hint = ShaguScan.Loc["filter_warlock_hint"]
}

filter.warrior = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "WARRIOR" and true or false
  end,
  name = ShaguScan.Loc["filter_warrior_name"],
  hint = ShaguScan.Loc["filter_warrior_hint"]
}

filter.hunter = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "HUNTER" and true or false
  end,
  name = ShaguScan.Loc["filter_hunter_name"],
  hint = ShaguScan.Loc["filter_hunter_hint"]
}

filter.mage = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "MAGE" and true or false
  end,
  name = ShaguScan.Loc["filter_mage_name"],
  hint = ShaguScan.Loc["filter_mage_hint"]
}

filter.priest = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "PRIEST" and true or false
  end,
  name = ShaguScan.Loc["filter_priest_name"],
  hint = ShaguScan.Loc["filter_priest_hint"]
}

filter.druid = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "DRUID" and true or false
  end,
  name = ShaguScan.Loc["filter_druid_name"],
  hint = ShaguScan.Loc["filter_druid_hint"]
}

filter.paladin = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "PALADIN" and true or false
  end,
  name = ShaguScan.Loc["filter_paladin_name"],
  hint = ShaguScan.Loc["filter_paladin_hint"]
}

filter.shaman = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "SHAMAN" and true or false
  end,
  name = ShaguScan.Loc["filter_shaman_name"],
  hint = ShaguScan.Loc["filter_shaman_hint"]
}

filter.rogue = {
  func = function(unit)
    local _, class = UnitClass(unit)
    local player = UnitIsPlayer(unit)

    return player and class == "ROGUE" and true or false
  end,
  name = ShaguScan.Loc["filter_rogue_name"],
  hint = ShaguScan.Loc["filter_rogue_hint"]
}

filter.aggro = {
  func = function(unit)
    return UnitExists(unit .. "target") and UnitIsUnit(unit .. "target", "player") and true or false
  end,
  name = ShaguScan.Loc["filter_aggro_name"],
  hint = ShaguScan.Loc["filter_aggro_hint"]
}

filter.noaggro = {
  func = function(unit)
    return not UnitExists(unit .. "target") or not UnitIsUnit(unit .. "target", "player") and true or false
  end,
  name = ShaguScan.Loc["filter_noaggro_name"],
  hint = ShaguScan.Loc["filter_noaggro_hint"]
}

filter.pfquest = {
  func = function(unit)
    return pfQuest and pfMap and UnitName(unit) and pfMap.tooltips[UnitName(unit)] and true or false
  end,
  name = ShaguScan.Loc["filter_pfquest_name"],
  hint = ShaguScan.Loc["filter_pfquest_hint"]
}

filter.range = {
  func = function(unit)
    return CheckInteractDistance(unit, 4) and true or false
  end,
  name = ShaguScan.Loc["filter_range_name"],
  hint = ShaguScan.Loc["filter_range_hint"]
}

filter.level = {
  func = function(unit, args)
    local level = tonumber(args)
    return level and UnitLevel(unit) == level and true or false
  end,
  name = ShaguScan.Loc["filter_level_name"],
  hint = ShaguScan.Loc["filter_level_hint"],
  needArg = true,
}

filter.minlevel = {
  func = function(unit, args)
    local level = tonumber(args)
    return level and UnitLevel(unit) >= level and true or false
  end,
  name = ShaguScan.Loc["filter_minlevel_name"],
  hint = ShaguScan.Loc["filter_minlevel_hint"],
  needArg = true,
}

filter.maxlevel = {
  func = function(unit, args)
    local level = tonumber(args)
    return level and UnitLevel(unit) <= level and true or false
  end,
  name = ShaguScan.Loc["filter_maxlevel_name"],
  hint = ShaguScan.Loc["filter_maxlevel_hint"],
  needArg = true,
}

filter.name = {
  func = function(unit, name)
    name = strlower(name or "")
    unit = strlower(UnitName(unit) or "")
    return string.find(unit, name) and true or false
  end,
  name = ShaguScan.Loc["filter_name_name"],
  hint = ShaguScan.Loc["filter_name_hint"],
  needArg = true,
}

ShaguScan.filter = filter
