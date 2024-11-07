nova.require "logger"

INFO_ALERT = {
  id = 7903,
  analyzer = nil,
  rounds_shown = 0,
  size_x = 0,

  clear = function(self)
    ui:alert_clear(self.id)
  end,

  show = function(self)
    self:clear()
    self.title = ""
    self.content = ""

    if self.analyzer:will_level_up() == false and self.analyzer:visible_enemies() > 0 then
      local result = self:create_content_odds()
      if self.rounds_shown <= 3 then
        self:create_long_title()
        self:add_damage_lines(result, self.add_dmg_line_long)
      else
        self:create_short_title()
        self:add_damage_lines(result, self.add_dmg_line_short)
      end
      self:set_shown_alert()
      ui:alert {
        id = self.id,
        title = self.title,
        teletype = 0,
        content = self.content,
        size = ivec2(self.size_x, -1),
        position = ivec2(1, 20),
        modal = false,
      }
    end
  end,

  create_long_title = function(self)
    self.title = string.format("{R%i} %s", self.analyzer:visible_enemies(), "Enemies")
    self.size_x = self.title:len() + 2
  end,

  create_long_content_enemies = function(self)
    for i, e in pairs(self.analyzer.enemies) do
      local line
      if e.shots > 1 then
        line = string.format("%ix%i (%.f%%)", e.damage, e.shots, e.chance_to_hit)
      else
        line = string.format("%i (%.f%%)", e.damage, e.chance_to_hit)
      end
      self:calculate_size_x(line)
      if i > 1 then self.content = self.content .. "\n" end
      self.content = self.content .. line
    end
  end,

  create_content_odds = function(self)
    local health = self.analyzer.health_current
    local result = {}
    local has_odd = false
    for i, dmg_odd in pairs(self.analyzer.damage_odds) do
      LOGGER:trace("create_content_odds for=" .. dmg_odd.odd .. "%=" .. dmg_odd.damage)
      if dmg_odd.odd >= 1 and dmg_odd.damage >= health then result.die = dmg_odd end
      if dmg_odd.damage >= (health * 3 / 4) and dmg_odd.damage < health then
        result.health75 = dmg_odd
        has_odd = true
      end
      if dmg_odd.odd >= 1 and dmg_odd.damage >= (health * 1 / 2) and dmg_odd.damage < (health * 3 / 4) then
        result.health50 = dmg_odd
        has_odd = true
      end
      if dmg_odd.odd >= 1 and dmg_odd.damage >= (health * 1 / 4) and dmg_odd.damage < (health * 1 / 2) then
        result.health25 = dmg_odd
        has_odd = true
      end
      if dmg_odd.odd >= 1 and dmg_odd.damage >= (health * 1 / 10) and dmg_odd.damage < (health * 1 / 4) then
        result.health10 = dmg_odd
        has_odd = true
      end
    end
    if has_odd == false then
            if #self.analyzer.damage_odds > 0 then
                LOGGER:trace("adding odd=" ..
                self.analyzer.damage_odds[1].odd .. "%=" .. self.analyzer.damage_odds[1].damage)
                result.other = self.analyzer.damage_odds[1]
            else
                LOGGER:trace("no odds adding empty one")
                result.other = { odd = 0, damage = 0 }
            end
        else
    end
    return result
  end,

  add_damage_lines = function(self, result, format_function)
    if result.die then
      format_function(self, result.die.odd, result.die.damage, "DIE", "R")
    end
    if result.health75 then
      format_function(self, result.health75.odd, result.health75.damage,
        "3/4", "Y")
    end
    if result.health50 then
      format_function(self, result.health50.odd, result.health50.damage,
        "1/2", "Y")
    end
    if result.health25 then
      format_function(self, result.health25.odd, result.health25.damage,
        "1/4")
    end
    if result.health10 then
      format_function(self, result.health10.odd, result.health10.damage,
        "/10")
    end
    if result.other then
      format_function(self, result.other.odd, result.other.damage,
        "Atk")
    end
  end,
  add_dmg_line_long = function(self, odd, damage, text, color)
    local line = ""
    if text and color then
      line = string.format("{%s%s} %.f%% %i", color, text, odd, damage)
    elseif text then
      line = string.format("%s %.f%% %i", text, odd, damage)
    else
      line = string.format("%.f%% %i", odd, damage)
    end
    self:calculate_size_x(line)
    if string.len(self.content) > 0 then self.content = self.content .. "\n" end
    self.content = self.content .. line
  end,

  add_dmg_line_short = function(self, odd, damage, text, color)
    local line = ""
    if text and color then
      line = string.format("{%s%s} %.f%%", color, text, odd)
    elseif text then
      line = string.format("%s %.f%%", text, odd)
    else
      line = string.format("%.f%%", odd)
    end
    self:calculate_size_x(line)
    if string.len(self.content) > 0 then self.content = self.content .. "\n" end
    self.content = self.content .. line
  end,

  create_short_title = function(self)
    self.title = string.format("{R%i} %s", self.analyzer:visible_enemies(), "En.")
    self.size_x = self.title:len() + 3
  end,

  create_short_content_enemies = function(self)
    for i, e in pairs(self.analyzer.enemies) do
      local line
      if e.shots > 1 then
        line = string.format("%ix%i %.f%%", e.damage, e.shots, e.chance_to_hit)
      else
        line = string.format("%i %.f%%", e.damage, e.chance_to_hit)
      end
      self:calculate_size_x(line)
      if i > 1 then self.content = self.content .. "\n" end
      self.content = self.content .. line
    end
  end,

  calculate_size_x = function(self, line)
    self.size_x = math.max(line:len() + 4, self.size_x)
  end,

  set_shown_alert = function(self)
    local now = self.analyzer:visible_enemies()
    local last = self.analyzer:prev_visible_enemies()
    if now > last then
      self.rounds_shown = 0
    elseif now > 0 then
      self.rounds_shown = self.rounds_shown + 1
    end
  end
}
