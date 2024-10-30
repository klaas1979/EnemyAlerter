INFO_ALERT = {
  analyzer = nil,
  rounds_shown = 0,
  size_x = 0,
  long_title = "",
  long_content = "",

  show = function(self)
    ui:alert_clear(1)
    self.title = ""
    self.content = ""

    if self.analyzer:visible_enemies() > 0 then
      if self.rounds_shown <= 3 then
        self:create_long_title()
        self:create_long_content()
      else
        self:create_short_title()
        self:create_short_content()
      end
      self:set_shown_alert()
      ui:alert {
        id = 1,
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

  create_long_content = function(self)
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

  create_short_title = function(self)
    self.title = string.format("{R%i} %s", self.analyzer:visible_enemies(), "En.")
    self.size_x = self.title:len() + 3
  end,

  create_short_content = function(self)
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
    self.size_x = math.max(line:len(), self.size_x)
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
