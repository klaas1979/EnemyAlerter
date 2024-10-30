STOP_ALERT = {
  analyzer = nil,
  title = "",
  used_weapon = false,
  command = nil,
  last_action_time = 0,
  player_rushing = false,
  rushed_cooldown_rounds = 0,

  show = function(self)
    self:create_long_title()

    ui:alert {
      id = 2,
      title = self.title,
      teletype = 0,
      content = "Stop rushing enemies in sight!",
      size = ivec2(40, -1),
      position = ivec2(-1, -1),
      modal = true,
    }
  end,

  create_long_title = function(self)
    self.title = string.format("{R%i} %s", self.analyzer:visible_enemies(), "Enemies")
    self.size_x = self.title:len() + 2
  end,

  set_last_command = function(self, command, target)
    self.used_weapon = false
    self.command = command
    if command == COMMAND_USE and target and target.weapon then
      self.used_weapon = true
    end
  end,

  last_command = function(self)
    return self:get_command_name(self.command)
  end,

  get_command_name = function(self, action_id)
    local result = "unknown command=" .. action_id
    if action_id == COMMAND_ACTIVATE then
      result = "activate"
    elseif action_id == COMMAND_DROP then
      result = "drop"
    elseif action_id == COMMAND_MOVE_E then
      result = "move_e"
    elseif action_id == COMMAND_MOVE_N then
      result = "move_n"
    elseif action_id == COMMAND_MOVE_S then
      result = "move_s"
    elseif action_id == COMMAND_MOVE_W then
      result = "move_w"
    elseif action_id == COMMAND_PICKUP then
      result = "pickup"
    elseif action_id == COMMAND_REARM then
      result = "rearm"
    elseif action_id == COMMAND_RELOAD then
      result = "reload"
    elseif action_id == COMMAND_USE then
      result = "use"
    elseif action_id == COMMAND_WAIT then
      result = "wait"
    end
    return result
  end,

  last_command_moved = function(self)
    if self.command and self.command >= COMMAND_MOVE and self.command <= COMMAND_MOVE_F then
      return true
    else
      return false
    end
  end,

  calculate_rushing = function(self)
    local current_time = ui:get_time_ms()
    local duration = current_time - self.last_action_time
    self.last_action_time = current_time
    if duration < 500 and self.rushed_cooldown_rounds <= 0 then
      self.player_rushing = true
    else
      self.player_rushing = false
      self.rushed_cooldown_rounds = self.rushed_cooldown_rounds - 1
    end
  end,

  reset_rushed_cooldown = function(self)
    self.rushed_cooldown_rounds = 15
  end,

  stop_command = function(self)
    if self.player_rushing and (self:rushed_into_enemies() or self:many_new_enemies()) then
      return true
    else
      return false
    end
  end,

  rushed_into_enemies = function(self)
    if self.analyzer:prev_visible_enemies() == 0 and self.analyzer:visible_enemies() > 0 and self:last_command_moved() then
      return true
    else
      return false
    end
  end,

  many_new_enemies = function(self)
    if self.analyzer:visible_enemies() > (self.analyzer:prev_visible_enemies() + 3) then
      return true
    else
      return false
    end
  end,
}
