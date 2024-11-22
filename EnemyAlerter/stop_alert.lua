STOP_ALERT = {
  title = "",
  content = "",
  used_weapon = false,
  command = nil,
  last_action_time = 0,
  player_rushing = false,
  rushed_cooldown_rounds = 0,
  -- how many enemies must be newly visible to spawn alert
  many_new_enemies_count = 3,

  show = function(self)
    self:create_title()
    self:create_content()
    ui:alert {
      id = 2,
      title = self.title,
      teletype = 0,
      content = self.content,
      size = ivec2(35, -1),
      position = ivec2(-1, -1),
      modal = true,
    }
  end,

  create_title = function(self)
    self.title = string.format("{Y%i} %s", ANALYZER:visible_enemies(), "Enemies")
  end,

  create_content = function(self)
    self.content = "Stop rushing dangerous area!"
  end,

  set_last_command = function(self, command, target)
    LOGGER:trace("set_last_command=" .. command .. ", target=" .. tostring(target))
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
    local result = "unknown command=" .. tostring(action_id)
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
    LOGGER:trace("last_command_moved")
    if self.command and self.command >= COMMAND_MOVE and self.command <= COMMAND_MOVE_F then
      return true
    else
      return false
    end
  end,

  last_command_use = function(self)
    LOGGER:trace("last_command_use")
    if self.command and self.command == COMMAND_USE then
      return true
    else
      return false
    end
  end,

  last_command_activate = function(self)
    LOGGER:trace("last_command_activate")
    if self.command and self.command == COMMAND_ACTIVATE then
      return true
    else
      return false
    end
  end,

  calculate_rushing = function(self)
    LOGGER:trace("calculate_rushing")
    local current_time = ui:get_time_ms()
    local duration = current_time - self.last_action_time
    self.last_action_time = current_time
    if duration <= 500 and self.rushed_cooldown_rounds <= 0 then
      self.player_rushing = true
    else
      self.player_rushing = false
      self.rushed_cooldown_rounds = self.rushed_cooldown_rounds - 1
    end
  end,

  reset_rushed_cooldown = function(self)
    LOGGER:trace("reset_rushed_cooldown")
    self.rushed_cooldown_rounds = 15
  end,

  -- Returns if any stop factors like rushing are active to prevent command execution
  stop_command = function(self)
    LOGGER:trace("stop_command")
    local rushed_into_enemies = ANALYZER:prev_visible_enemies() == 0 and ANALYZER:visible_enemies() > 0 and
        self:last_command_moved()

    local many_new_enemies = ANALYZER:visible_enemies() >
        (ANALYZER:prev_visible_enemies() + self.many_new_enemies_count)

    local result = false
    if CONFIG.show_rushing_alert and self.player_rushing and (rushed_into_enemies or many_new_enemies) then
      result = true
    end
    LOGGER:trace("stop_command end, will return=" .. tostring(result))
    return result
  end,

  rushing_check = function(self)
    local result = 0
    self:calculate_rushing()
    if self:stop_command() then
      self:reset_rushed_cooldown()
      STOP_ALERT:show()
      result = -1
    end
    return result
  end,

  will_move_into = function(self, id1, id2)
    LOGGER:trace("will_move_into=" .. id1 .. " or=" .. id2)
    local result = false
    if self:last_command_moved() then
      local level = world:get_level()
      local player_pos = world:get_position(world:get_player())
      local direction = self:last_command()
      local move_coords = nil
      -- NOTE: movement is strange DOWN=NORTH following this, left=east, up=south, right=west
      -- NOTE about coord system: down right corner is 1,1 going up/south means y+1 and going left/east means x+1
      if "move_n" == direction then
        move_coords = coord(0, -1)
      elseif "move_s" == direction then
        move_coords = coord(0, 1)
      elseif "move_e" == direction then
        move_coords = coord(1, 0)
      elseif "move_w" == direction then
        move_coords = coord(-1, 0)
      else
        LOGGER:error("will_move_into move detected but no direction, impossible to happen!")
      end
      local current_id1 = level:get_entity(player_pos, id1)
      local current_id2 = level:get_entity(player_pos, id2)
      local target_pos = player_pos + move_coords
      LOGGER:trace("player_pos=" ..
      tostring(player_pos) .. ", move=" .. direction .. ", move_pos=" .. tostring(target_pos))
      local target_id1 = level:get_entity(target_pos, id1)
      local target_id2 = level:get_entity(target_pos, id2)
      local current_condition = (current_id1 or current_id2) ~= nil
      local target_condition = (target_id1 or target_id2) ~= nil
      result = current_condition == false and target_condition == true
      LOGGER:debug("result=" ..
        tostring(result) ..
        ", c=" ..
        tostring(current_condition) ..
        ", t=" ..
        tostring(target_condition) ..
        ", t_id1=" .. tostring(target_id1) .. ", t_id2=" .. tostring(target_id2) ..
        ", c_id1=" .. tostring(current_id1) .. ", c_id2=" .. tostring(current_id2))
    end
    return result
  end,

  move_into_flames_check = function(self, entity, command, time_confirm)
    local result = 0
    if CONFIG.warn_flaming_movement and STOP_ALERT:will_move_into("flames", "permaflames") then
      if time_confirm == 0 then
        ui:confirm {
          size    = ivec2(23, 8),
          content = " Move into flames? ",
          actor   = entity,
          command = command,
        }
        result = -1 -- must abort this command, wait for confirm to execute it
      else
        result = 0
        LOGGER:trace("move_into_flames_check Command confirmed=" ..
          self:last_command() .. ", time_confirm: " .. time_confirm)
      end
    end
    return result
  end,

  move_into_toxic_cloud_check = function(self, entity, command, time_confirm)
    local result = 0
    if CONFIG.warn_toxic_movement and STOP_ALERT:will_move_into("toxic_smoke", "toxic_smoke_cloud") then
      if time_confirm == 0 then
        ui:confirm {
          size    = ivec2(27, 8),
          content = " Move into toxic smoke? ",
          actor   = entity,
          command = command,
        }
        result = -1 -- must abort this command, wait for confirm to execute it
      else
        result = 0
        LOGGER:trace("move_into_toxic_cloud_check Command confirmed=" ..
          self:last_command() .. ", time_confirm: " .. time_confirm)
      end
    end
    return result
  end,

}
