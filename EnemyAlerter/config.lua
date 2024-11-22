nova.require "logger"
nova.require "levelmap"
nova.require "runlog"

CONFIG = {
  show_enemy_cth = true,
  show_rushing_alert = true,
  warn_flaming_movement = true,
  warn_toxic_movement = true,
  updated = 0,
  level_enter_dialog_displayed = false,
}

-- Helper function to create generic setting
local function create_setting(name, id, desc, active_option)
  return {
    name = name,
    id = id,
    description = function() return desc end,
    activate_option = active_option,
  }
end

-- Helper function to create settings
local function create_boolean_setting(name, id, desc, config_key, new_value)
  return create_setting(name, id, desc, function(self, config, entity, terminal)
    CONFIG[config_key] = new_value
    LOGGER:debug(string.format("CONFIG.%s = %s", config_key, tostring(CONFIG[config_key])))
    terminal:show(config, entity, EA_SETTINGS)
  end)
end

-- Helper function for the cancel option
local function create_cancel_option(id)
  return {
    name = "Return",
    id = id,
    description = function() return "Safely stop configuration and return to main configuration screen" end,
    cancel = true,
    activate_option = function(self, config, entity, terminal)
      terminal:show(config, entity, EA_SETTINGS)
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
        world:destroy(trait)
      end
      terminal:show(ea_trait, entity, EA_SETTINGS)
    end),
  create_setting('{YEnable} Configuration via trait',
    "attach_trait",
    "Add trait back to player",
    function(self, ea_trait, entity, terminal)
      LOGGER:debug("Attach configuration trait")
      local player = world:get_player()
      if not player:child("trait_enemy_alerter") then
        player:attach("trait_enemy_alerter")
      end
      terminal:show(ea_trait, entity, EA_SETTINGS)
    end),
  create_cancel_option("enemy_rushing_cancel"),
}

-- Helper function to create a dynamic setting entry with description as function
local function create_dynamic_setting_entry(name, id, desc, settings_group, cancel)
  return {
    name = name,
    id = id,
    description = desc,
    cancel = cancel,
    activate_option = function(self, config, entity)
      EA_TERMINAL:show(config, entity, settings_group)
    end,
  }
end

-- Helper function to create a static setting entry with fixed description
local function create_static_setting_entry(name, id, desc, settings_group)
  return create_dynamic_setting_entry(name, id, function() return desc end, settings_group, false)
end

--[[
local logl = math.min(#cpiod_log, 15)
    local desc = ""
    for i = 1, logl do
        desc = desc .. cpiod_log[#cpiod_log - i + 1]
        if i < logl then
            desc = desc .. "\n"
        end
    end
    list.fsize = logl

    table.insert(list, {
        name = "Log",
        target = self,
        desc = desc,
        cancel = true,
    })
]]

-- Define EA_SETTINGS using the helper function
EA_SETTINGS = {
  create_dynamic_setting_entry("Map", "level_map", LEVELMAP.create_map, nil, true),

  create_dynamic_setting_entry("Log", "action_log", CPIOD_LOG.description, nil, true),

  --[[ Test for trait usage from menu, did not work
  {
    name = "Use trait",
    id = "use_trait",
    description = function() return "Use trait" end,
    cancel = false,
    activate_option = function()
      local player = world:get_player()
      local trait = player:child("ktrait_adrenaline")
      LOGGER:debug("trait=" .. tostring(trait))
      -- ( self, entity, level, target )
      world:lua_callback(trait, "on_use", trait, player, world:get_level(), world:get_target(player))
    end,
  },
  --]]

  create_static_setting_entry("Enemy info screen", "enemy_info_config",
    "Configure the enemy info screen", EA_SETTINGS_INFO_SCREEN),

  create_static_setting_entry("Rushing Alert", "rushing_alert_config",
    "Configure the rushing into enemy alert", EA_SETTINGS_RUSHING_ALERT),

  create_static_setting_entry("Flaming tile alert", "flaming_alert_config",
    "Configure the warning before moving into flaming tiles", EA_SETTINGS_FLAMING_ALERT),

  create_static_setting_entry("Toxic cloud alert", "toxic_alert_config",
    "Configure the warning before moving into toxic clouds", EA_SETTINGS_TOXIC_ALERT),

  create_static_setting_entry("Add/Remove configuration skill", "change_skill",
    "Adds or removes the skill for configuration", EA_SETTINGS_DETACH_SKILL),

  {
    name = "Close configuration",
    id = "close_enemy_alerter_configuration",
    description = function() return "Safely stop configuration and close window" end,
    cancel = true,
    activate_option = function(self, config, entity, id)
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
    if options then
      local terminal_list = self:create_terminal_list(options, config)

      -- Display the terminal UI with the constructed list
      ui:terminal(entity, config, terminal_list)
    end
    LOGGER:trace("EA_TERMINAL:show completed")
  end,

  -- Creates the terminal list from the provided options.
  -- @param options A table of options to include in the terminal list.
  -- @param config The configuration object.
  -- @return A table representing the terminal list.
  create_terminal_list = function(self, options, config)
    local terminal_list = {
      title = 'Enemy Alerter PDA - HellOS v0.13',
      size = coord(56, 0),
      fsize = 18,
    }

    for i, option in pairs(options) do
      terminal_list[i] = {
        name = option.name,
        desc = option.description(),
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

-- Helper to call on level entry to show dialog if trait is not registered
function CONFIG.show_config_terminal_on_level_entry(self, player)
  if not CONFIG.level_enter_dialog_displayed then
    CONFIG.level_enter_dialog_displayed = true
    if not player:child("trait_enemy_alerter") then
      local config = player:child("enemy_alerter_config")
      EA_TERMINAL:show(config, player, EA_SETTINGS)
    end
  end
end

register_blueprint "enemy_alerter_config" {
  flags = { EF_NOPICKUP },
  callbacks = {
    on_activate = [=[
            function(self, player, level, param, id)
                EA_TERMINAL:activate_option(self, player, id)
            end
        ]=],
  },
}

CONFIG.on_enter_level = function(self, reenter)
  self.level_enter_dialog_displayed = false
  if reenter then return end
  local level = world:get_level()
  for e in level:entities() do
    if world:get_id(e) == "terminal" then
      e:attach("enemy_alerter_terminal") -- attach configuration option
    end
  end
end

register_blueprint "trait_enemy_alerter" {
  blueprint = "trait",
  text = {
    name = "EnemyAlerter PDA",
    desc = "Helper PDA with map, log and enemy alerts",
    full = "Helper PDA with map, log and enemy alerts",
    abbr = "EA PDA",
  },
  skill = {
    cooldown = 0,
    cost = 0,
  },
  attributes = {
  },
  callbacks = {
    on_use = [=[
            function(self, entity)
                local config = entity:child("enemy_alerter_config")
                EA_TERMINAL:show(config, entity, EA_SETTINGS)
            end
        ]=],
  },
}

register_blueprint "event_pda_update"
{
  flags = { EF_NOPICKUP },
  text = {
    entry    = "Download map to PDA",
    complete = "PDA map downloaded",
    desc     = "Download the map to PDA to display current location"
  },
  data = {
    terminal = {
      priority = 9,
    },
  },
  callbacks = {
    on_activate = [=[
    function( self, who, level )
      local parent  = ecs:parent( self )
      CONFIG.updated = 1 -- Map is downloaded
      ui:set_hint( "{R".."Map downloaded".."}", 1001, 0 )
      world:destroy( self )
      ui:activate_terminal( who, parent )
    end
    ]=], --Changes updated to 1 when the option is selected on a terminal.
  }
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
      priority = 100,
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
