nova.require "logger"

CONFIG = {
  show_enemy_cth = true,
  show_rushing_alert = true,
  warn_flaming_movement = true,
  warn_toxic_movement = true,
  ea_trait_to_reattach = nil,
}
-- Helper function to create generic setting
local function create_setting(name, id, desc, active_option)
  return {
    name = name,
    id = id,
    desc = desc,
    activate_option = active_option,
  }
end

-- Helper function to create settings
local function create_boolean_setting(name, id, desc, config_key, new_value)
  return create_setting(name, id, desc, function(self, ea_trait, entity, terminal)
    CONFIG[config_key] = new_value
    LOGGER:debug(string.format("CONFIG.%s = %s", config_key, tostring(CONFIG[config_key])))
    terminal:show(ea_trait, entity, EA_SETTINGS)
  end)
end

-- Helper function for the cancel option
local function create_cancel_option(id)
  return {
    name = "Return",
    id = id,
    desc = "Safely stop configuration and return to main configuration screen",
    cancel = true,
    activate_option = function(self, ea_trait, entity, terminal)
      terminal:show(ea_trait, entity, EA_SETTINGS)
    end,
  }
end

-- Define settings using the helper functions
local EA_SETTINGS_INFO_SCREEN = {
  create_boolean_setting('{RDisable} Info Alert for Enemy danger', "show_cth_no",
    "Disable the info notification PDA with the odds to be hit.",
    "show_enemy_cth", false),
  create_boolean_setting('{YEnable} Info Alert for Enemy danger', "show_cth_yes",
    "Enable the info notification PDA with the odds to be hit.",
    "show_enemy_cth", true),
  create_cancel_option("enemy_info_cancel"),
}

local EA_SETTINGS_RUSHING_ALERT = {
  create_boolean_setting('{RDisable} Rushing Alert', "show_rushing_no",
    "Disable the rushed into enemy alert.",
    "show_rushing_alert", false),
  create_boolean_setting('{YEnable} Rushing Alert', "show_rushing_yes",
    "Enable the rushed into enemy alert.",
    "show_rushing_alert", true),
  create_cancel_option("enemy_rushing_cancel"),
}

local EA_SETTINGS_FLAMING_ALERT = {
  create_boolean_setting('{RDisable} warn before moving to flaming tiles', "warn_flaming_no",
    "Disable the confirmation dialog before moving onto flaming tiles.",
    "warn_flaming_movement", false),
  create_boolean_setting('{YEnable} warn before moving to flaming tiles', "warn_flaming_yes",
    "Enable the confirmation dialog before moving onto flaming tiles.",
    "warn_flaming_movement", true),
  create_cancel_option("flaming_tile_cancel"),
}

local EA_SETTINGS_TOXIC_ALERT = {
  create_boolean_setting('{RDisable} warn before moving into toxic clouds', "warn_toxic_no",
    "Disable the confirmation dialog before moving into toxic clouds.",
    "warn_toxic_movement", false),
  create_boolean_setting('{YEnable} warn before moving into toxic clouds', "warn_toxic_yes",
    "Enable the confirmation dialog before moving into toxic clouds.",
    "warn_toxic_movement", true),
  create_cancel_option("toxic_cloud_cancel"),
}

local EA_SETTINGS_DETACH_SKILL = {
  create_setting('{RDisable} Configuration via trait, use only terminals',
    "detach_trait",
    "Remove trait from player, configuration only via terminal",
    function(self, ea_trait, entity, terminal)
      LOGGER:debug("Detach configuration trait")
      local player = world:get_player()
      local trait = player:child("trait_enemy_alerter")
      if trait then
        CONFIG.ea_trait_to_reattach = trait
        world:detach(trait)
      end
      terminal:show(ea_trait, entity, EA_SETTINGS)
    end),
  create_setting('{YEnable} Configuration via trait',
    "attach_trait",
    "Add trait back to player",
    function(self, ea_trait, entity, terminal)
      LOGGER:debug("Attach configuration trait")
      local player = world:get_player()
      if player:child("trait_enemy_alerter") == nil then
        player:attach(CONFIG.ea_trait_to_reattach)
      end
      terminal:show(ea_trait, entity, EA_SETTINGS)
    end),
  create_cancel_option("enemy_rushing_cancel"),
}

-- Helper function to create a setting entry
local function create_setting_entry(name, id, desc, settings_group)
  return {
    name = name,
    id = id,
    desc = desc,
    activate_option = function(self, ea_trait, entity)
      EA_TERMINAL:show(ea_trait, entity, settings_group)
    end,
  }
end

-- Define EA_SETTINGS using the helper function
EA_SETTINGS = {
  create_setting_entry("Enemy info screen", "enemy_info_config",
    "Configure the enemy info screen", EA_SETTINGS_INFO_SCREEN),

  create_setting_entry("Rushing Alert", "rushing_alert_config",
    "Configure the rushing into enemy alert", EA_SETTINGS_RUSHING_ALERT),

  create_setting_entry("Flaming tile alert", "flaming_alert_config",
    "Configure the warning before moving into flaming tiles", EA_SETTINGS_FLAMING_ALERT),

  create_setting_entry("Toxic cloud alert", "toxic_alert_config",
    "Configure the warning before moving into toxic clouds", EA_SETTINGS_TOXIC_ALERT),

  create_setting_entry("Add/Remove configuration skill", "change_skill",
    "Adds or removes the skill for configuration", EA_SETTINGS_DETACH_SKILL),

  {
    name = "Close configuration",
    id = "close_enemy_alerter_configuration",
    desc = "Safely stop configuration and close window",
    cancel = true,
    activate_option = function(self, ea_trait, entity, id)
      LOGGER:debug("Close configuration")
    end,
  },
}

-- Centralized table to hold all settings references
-- new config options need to be added to this table
local ALL_SETTINGS = {
  EA_SETTINGS,
  EA_SETTINGS_INFO_SCREEN,
  EA_SETTINGS_RUSHING_ALERT,
  EA_SETTINGS_FLAMING_ALERT,
  EA_SETTINGS_TOXIC_ALERT,
  EA_SETTINGS_DETACH_SKILL,
}

EA_TERMINAL = {
  -- Displays the terminal interface with the provided options.
  -- @param self The terminal instance.
  -- @param config The configuration object.
  -- @param entity The entity to which the terminal is attached.
  -- @param options A table of options to display in the terminal.
  show = function(self, config, entity, options)
    LOGGER:trace(string.format("EA_TERMINAL:show called with config: %s, entity: %s, options: %s",
      tostring(config), tostring(entity), tostring(options)))

    local terminal_list = self:create_terminal_list(options, config)

    -- Display the terminal UI with the constructed list
    ui:terminal(entity, config, terminal_list)
    LOGGER:trace("EA_TERMINAL:show completed")
  end,

  -- Creates the terminal list from the provided options.
  -- @param options A table of options to include in the terminal list.
  -- @param config The configuration object.
  -- @return A table representing the terminal list.
  create_terminal_list = function(self, options, config)
    local terminal_list = {
      title = 'Configure Enemy Alerter - HellOS 0.9',
      size = coord(50, 0),
      fsize = 4,
    }

    for i, option in pairs(options) do
      terminal_list[i] = {
        name = option.name,
        desc = option.desc,
        id = option.id,
        target = config,
        cancel = option.cancel or false,
      }
    end

    return terminal_list
  end,

  -- Activates the option corresponding to the provided ID.
  -- @param self The terminal instance.
  -- @param config The configuration object.
  -- @param entity The entity to which the terminal is attached.
  -- @param id The ID of the option to activate.
  activate_option = function(self, config, entity, id)
    LOGGER:trace(string.format("EA_TERMINAL:activate_option called with id: %s", tostring(id)))

    -- Iterate over all available settings and activate the matching option
    for _, settings in pairs(ALL_SETTINGS) do
      self:activate_option_list(config, entity, id, settings)
    end
  end,

  -- Activates the option from a specific settings list if the ID matches.
  -- @param self The terminal instance.
  -- @param config The configuration object.
  -- @param entity The entity to which the terminal is attached.
  -- @param id The ID of the option to activate.
  -- @param settings The list of settings to check against.
  activate_option_list = function(self, config, entity, id, settings)
    LOGGER:trace(string.format("EA_TERMINAL:activate_option_list called with id: %s", tostring(id)))

    for _, option in pairs(settings) do
      if id == world:hash(option.id) and option.activate_option then
        option:activate_option(config, entity, self) -- Pass terminal instance here
        return
      end
    end
  end,
}

register_blueprint "enemy_alerter_config" {
  flags = { EF_NOPICKUP },
  callbacks = {
    on_activate = [=[
            function(self, player, level, param, id)
                LOGGER:trace("enemy_alerter_config > on_activate")
                EA_TERMINAL:activate_option(self, player, id)
            end
        ]=],
  },
}

register_blueprint "trait_enemy_alerter" {
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
  attributes = {},
  callbacks = {
    on_use = [=[
            function(self, entity)
                local config = world:get_player():child("enemy_alerter_config")
                EA_TERMINAL:show(config, entity, EA_SETTINGS)
            end
        ]=],
  },
}

register_blueprint "enemy_alerter_terminal" {
  flags = { EF_NOPICKUP },
  text = {
    entry = "Configure Enemy Alerter",
    complete = "Configuration completed!",
    desc = "Configure Enemy Alerter settings"
  },
  data = {
    terminal = {
      priority = 9,
    },
  },
  callbacks = {
    on_activate = [=[
            function(self, who, level)
                local config = who:child("enemy_alerter_config")
                EA_TERMINAL:show(config, who, EA_SETTINGS)
            end
        ]=],
  }
}

world.register_on_entity(function(x)
  if x.data and x.data.ai and x.data.ai.group == "player" then
    x:attach("trait_enemy_alerter")
    x:attach("enemy_alerter_config")
  end
end)
