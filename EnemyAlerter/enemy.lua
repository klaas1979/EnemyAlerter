nova.require "logger"

ENEMY = {
  level = nil,
  player = nil,
  player_position = nil,
  player_evasion = 0,
  player_cover_mod = 0,

  initialize = function(self)
    self.level = world:get_level()
    self.player = world:get_player()
    self.player_position = world:get_position(self.player)
    self.player_evasion = self.player:attribute("evasion")
    self.player_cover_mod = self.player:attribute("cover_mod")
  end,

  create_data = function(self)
    return {
      id = nil,
      weapon_damage = 0,
      damage = 0, -- calculated=weapon_damage * damage_mult
      shots = 0,
      is_shotgun = false,
      distance = nil,
      min_distance = 0,
      opt_distance = 1,
      max_distance = 1,
      weapon_accuracy = 0,
      damage_mult = 0,

      cover = 0,
      accuracy = 100,
      chance_to_hit = 100,

      ---@diagnostic disable-next-line: redefined-local
      set_weapon = function(self, weapon)
        if weapon then
          if weapon.weapon.group == world:hash("shotguns") then
            self.is_shotgun = true
          end
          local wa = weapon.attributes
          if wa then
            if wa.damage then
              self.weapon_damage = wa.damage
            end
            if wa.shots then
              self.shots = wa.shots
            end

            self.opt_distance = wa.opt_distance
            self.max_distance = wa.max_distance
            if wa.accuracy then
              self.weapon_accuracy = wa.accuracy
            end
          end
        end
      end,

      ---@diagnostic disable-next-line: redefined-local
      weapon_chance_to_hit = function(self)
        local result = 1.0
        if self.min_distance and self.distance < self.min_distance then
          result = (self.min_distance - self.distance) / self.min_distance
        elseif self.max_distance and self.distance > self.max_distance then
          result = 0.0
        elseif self.opt_distance and self.max_distance and self.distance > self.opt_distance then
          local steps = (self.max_distance - self.opt_distance)
          result = (steps - (self.distance - self.opt_distance)) / steps
        elseif self.opt_distance and self.distance <= self.opt_distance then
          result = 1.0
        elseif self.distance > 1.5 then
          result = 0.0
        end
        return result
      end,

      ---@diagnostic disable-next-line: redefined-local
      tostring = function(self)
        return string.format(
          "wpn_dxs=%ix%i dmg_mult=%.2f calc_dmg=%i cth=%.f%% dst=%.1f rng=%i/%i/%i, cov=%.2f, shotgun=%s",
          self.weapon_damage or 0, self.shots or 1, self.damage_mult or 1, self.damage or 0,
          self.chance_to_hit or 100, self.distance or 1, self.min_distance or 0, self.opt_distance or 1,
          self.max_distance or 1, self.cover or 0, tostring(self.is_shotgun))
      end,
    }
  end,

  analyze = function(self, enemy)
    local enemy_data = self:create_data()
    enemy_data.id = tostring(enemy)
    local weapon = enemy:get_weapon()
    enemy_data:set_weapon(weapon)
    enemy_data.distance = self.level:distance(self.player, enemy)
    local enemy_position = world:get_position(enemy)
    enemy_data.cover = self.level:get_max_cover(enemy_position, self.player_position)
    if enemy.attributes.accuracy then
      enemy_data.accuracy = 100 + enemy.attributes.accuracy
    end
    enemy_data.damage_mult = enemy.attributes.damage_mult or 1
    enemy_data.damage = math.floor((enemy_data.weapon_damage * enemy_data.damage_mult) + 0.5) -- round number
    if enemy_data.is_shotgun then
      self:shotgun_damage(enemy_data)
    else
      self:chance_to_hit(enemy_data)
    end
    return enemy_data
  end,

  chance_to_hit = function(self, enemy_data)
    local wcth = enemy_data:weapon_chance_to_hit()
    local final_accuracy = wcth * enemy_data.accuracy

    -- cover and hunker
    final_accuracy = final_accuracy * (100 - enemy_data.cover) / 100
    final_accuracy = final_accuracy * (100 - enemy_data.cover * self.player_cover_mod) / 100

    -- evasion bonus dodge
    final_accuracy = final_accuracy * (100 - self.player_evasion) / 100
    final_accuracy = final_accuracy + enemy_data.weapon_accuracy

    LOGGER:debug("wcth=" ..
      wcth ..
      ", eacc=" ..
      enemy_data.accuracy ..
      ", p_cover=" ..
      enemy_data.cover .. ", p_cover_mod=" .. self.player_cover_mod .. ", p_evasion=" .. self.player_evasion
      .. ", e_weap_acc=" .. tostring(enemy_data.weapon_accuracy))
    enemy_data.chance_to_hit = final_accuracy
  end,

  shotgun_damage = function(self, enemy_data)
    -- for shotgun damage do NOT include dodge nor cover
    LOGGER:trace("Shotgun dmg=" ..
      enemy_data:weapon_chance_to_hit() .. "*" .. enemy_data.damage)
    -- as of testing the accuracy of enemy is NOT taken into account, only the distance accuracy calculation as modifier!!
    -- as of testing it seems that the calcuation is rounded down
    enemy_data.damage = math.floor(enemy_data:weapon_chance_to_hit() * enemy_data.damage)
    LOGGER:debug("Shotgun dmg=" .. enemy_data.damage)
  end,
}
