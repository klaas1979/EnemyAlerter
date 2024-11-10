nova.require "logger"

CONFIG = {
  show_enemy_cth = true,
  show_rushing_alert = true,
  warn_flaming_movement = true,
  ea_trait_to_reattach = nil,
}

EA_SETTINGS_INFO_SCREEN = {
  {
    name = '{RDisable} Info Alert for Enemy danger',
    id = "show_cth_no",
    desc = "Disable the info notification PDA with the odds to be hit.",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("CONFIG.show_enemy_cth = false")
      CONFIG.show_enemy_cth = false
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = '{YEnable} Info Alert for Enemy danger',
    id = "show_cth_yes",
    desc = "Enable the info notification PDA with the odds to be hit.",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("CONFIG.show_enemy_cth = true")
      CONFIG.show_enemy_cth = true
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = "Return",
    id = "enemy_info_cancel",
    desc = "Safely stop configuration",
    cancel = true,
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end,
  },
}
EA_SETTINGS_RUSHING_ALERT = {
  {
    name = '{RDisable} Rushing Alert',
    id = "show_rushing_no",
    desc = "Disable the rushed into enemy alert.",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("CONFIG.show_rushing_alert = false")
      CONFIG.show_rushing_alert = false
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = '{YEnable} Rushing Alert',
    id = "show_rushing_yes",
    desc = "Enable the rushed into enemy alert.",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("CONFIG.show_rushing_alert = true")
      CONFIG.show_rushing_alert = true
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = "Return",
    id = "enemy_rushing_cancel",
    desc = "Safely stop configuration",
    cancel = true,
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end,
  },
}
EA_SETTINGS_FLAMING_ALERT = {
  {
    name = '{RDisable} warn before moving to flaming tiles',
    id = "warn_flaming_no",
    desc = "Disable the confirmation dialog before moving onto flaming tiles.",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("CONFIG.warn_flaming_movement = false")
      CONFIG.warn_flaming_movement = false
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = '{YEnable} warn before moving to flaming tiles',
    id = "warn_flaming_yes",
    desc = "Enable the confirmation dialog before moving onto flaming tiles.",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("CONFIG.warn_flaming_movement = true")
      CONFIG.warn_flaming_movement = true
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = "Return",
    id = "flaming_tile_cancel",
    desc = "Safely stop configuration",
    cancel = true,
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end,
  },
}

EA_SETTINGS_DETACH_SKILL = {
  {
    name = '{RDisable} Configuration via skill, use only terminals',
    id = "detach_skill",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("Detach configuration skill")
      local player = world:get_player()
      local trait = player:child("trait_enemy_alerter")
      if trait then
        CONFIG.ea_trait_to_reattach = trait
        world:detach(trait)
      end
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = '{YEnable} Configuration via skill',
    id = "attach_skill",
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("CONFIG.show_rushing_alert = true")
      local player = world:get_player()
      if player:child("trait_enemy_alerter") == nil then player:attach(CONFIG.ea_trait_to_reattach) end
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end
  },
  {
    name = "Return",
    id = "enemy_rushing_cancel",
    desc = "Safely stop configuration",
    cancel = true,
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS)
    end,
  },
}

EA_SETTINGS = {
  -- Configuration for Enemy info Chance to hit display
  {
    name = "Enemy info screen",
    id = "enemy_info_config",
    desc = "Configure the enemy info screen",
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS_INFO_SCREEN)
    end,
  },
  -- Configuration for stop alert on rushing
  {
    name = "Rushing Alert",
    id = "rushing_alert_config",
    desc = "Configure the rushing into enemy alert",
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS_RUSHING_ALERT)
    end,
  },
  -- Configuration for move into flaming tiles alert
  {
    name = "Flaming tile alert",
    id = "flaming_alert_config",
    desc = "Configure the warning before moving into flaming tiles",
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS_FLAMING_ALERT)
    end,
  },
  -- Configuration for removing skill to only configure via terminals
  {
    name = "Add/Remove configuration skill",
    id = "change_skill",
    desc = "Adds or removes the skill for configuration",
    activate_option = function(self, ea_trait, entity, id)
      EA_TERMINAL:show(ea_trait, entity, EA_SETTINGS_DETACH_SKILL)
    end,
  },
  {
    name = "Return",
    id = "enemy_cancel",
    desc = "Safely stop configuration",
    cancel = true,
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("Close configuration")
    end,
  },
}

EA_TERMINAL = {
  show = function(self, config, entity, options)
    LOGGER:trace("EA_TERMINAL:show(" ..
      tostring(self) .. ", " .. tostring(config) .. ", " .. tostring(entity) .. ", " .. tostring(options) .. ")")
    local terminal_list = {
      title = 'Configure Enemy Alerter - HellOS 0.9',
      size  = coord(50, 0),
    }
    for i, option in pairs(options) do
      terminal_list[i] = {
        name = option.name,
        desc = option.desc,
        id = option.id,
        target = config,
        cancel = option
            .cancel or false
      }
    end
    terminal_list.fsize = 4

    ui:terminal(entity, config, terminal_list)
    LOGGER:trace("EA_TERMINAL:show end")
  end,

  activate_option = function(self, config, entity, id)
    LOGGER:trace("EA_TERMINAL:activate_option")
    self:activate_option_list(config, entity, id, EA_SETTINGS)
    self:activate_option_list(config, entity, id, EA_SETTINGS_INFO_SCREEN)
    self:activate_option_list(config, entity, id, EA_SETTINGS_RUSHING_ALERT)
    self:activate_option_list(config, entity, id, EA_SETTINGS_FLAMING_ALERT)
    self:activate_option_list(config, entity, id, EA_SETTINGS_DETACH_SKILL)
  end,

  activate_option_list = function(self, config, entity, id, settings)
    LOGGER:trace("EA_TERMINAL:activate_option")
    for _, option in pairs(settings) do
      if id == world:hash(option.id) and option.activate_option then
        option:activate_option(config, entity, id)
        return
      end
    end
  end,
}

register_blueprint "enemy_alerter_config" {
  flags = { EF_NOPICKUP },
  callbacks = {
    on_activate = [=[
        function( self, player, level, param, id )
          LOGGER:trace("enemy_alerter_config > on_activatve")
          EA_TERMINAL:activate_option(self, player, id)
        end
    ]=],
  },
}

register_blueprint "trait_enemy_alerter"
{
  blueprint = "trait",
  text = {
    name = "EnemyAlerter",
    desc = "Configure Enemy Alerter to your needs",
    full = "Configure Enemy Alerter to your needs",
    abbr = "EA",
  },
  skill = {
    cooldown = 0,
    cost = 0,
  },
  attributes = {
  },
  callbacks = {
    on_use = [=[
        function ( self, entity )
          local config = world:get_player():child("enemy_alerter_config")
          EA_TERMINAL:show(config, entity, EA_SETTINGS)
        end
    ]=],
  },
}

register_blueprint "enemy_alerter_terminal"
{
  flags = { EF_NOPICKUP },
  text = {
    entry    = "Configure Enemy Alerter",
    complete = "Configuration completed!",
    desc     = "Configure Enemy Alerter settings"
  },
  data = {
    terminal = {
      priority = 9,
    },
  },
  callbacks = {
    on_activate = [=[
		function( self, who, level )
			local config = who:child("enemy_alerter_config")
      EA_TERMINAL:show(config, who, EA_SETTINGS)
		end
		]=]
  }
}

world.register_on_entity(function(x)
  if x.data and x.data.ai and x.data.ai.group == "player" then
    x:attach("trait_enemy_alerter")
    x:attach("enemy_alerter_config")
  end
end)
