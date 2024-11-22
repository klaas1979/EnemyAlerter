nova.require "analyzer"
nova.require "config"
nova.require "info_alert"
nova.require "logger"
nova.require "stop_alert"

-- set the logging level
LOGGER:set_level('trace')

LOGGER:info("Enemy Alerter loading")

--[[
NOTES: game will freeze if the INFO_ALERT is shown and a ui:terminal or another ui:alert is shown

TODOs:
- check if evasion is calculated correctly taking negative armor modifications into account
- check fiends and other demons attacks > no attack shown, but ranged attack executed
- include armor and resistances into damage calculation
- include round status effects into damage calculation and warnings
--]]

EA_MAIN = {}
EA_MAIN.on_pre_command = function(self, entity, command, target, position, time_confirm)
    LOGGER:trace("on_pre_command last=" ..
        STOP_ALERT:last_command() ..
        ", commmand=" ..
        STOP_ALERT:get_command_name(command) .. ", pos=" .. tostring(position) .. ", time_confirm=" .. time_confirm)
    -- display the configuration once for each level
    CONFIG:show_config_terminal_on_level_entry(entity)

    -- set data
    STOP_ALERT.analyzer = ANALYZER
    STOP_ALERT.config = CONFIG
    STOP_ALERT:set_last_command(command, target)

    -- clear ui:alert as it crashes the game if ui:terminal or another ui:function is called
    if STOP_ALERT:last_command_use() or STOP_ALERT:last_command_activate() then INFO_ALERT:clear() end

    -- start checks to be aborted
    local result = 0
    -- check if command needs to be prevented
    -- check rushing
    result = STOP_ALERT:rushing_check()
    if result == 0 then -- only check move into flames if not rushing
        result = STOP_ALERT:move_into_flames_check(entity, command, time_confirm)
    end
    if result == 0 then -- only check move into toxic if not rushing and no flames
        result = STOP_ALERT:move_into_toxic_cloud_check(entity, command, time_confirm)
    end
    if result == -1 then              -- stop the command and play some audio about it
        LOGGER:info("Stopped command " .. STOP_ALERT:last_command() .. ", ms: " .. ui:get_time_ms())
        world:play_voice("vo_refuse") -- refuse the action verbally
    end
    LOGGER:trace("on_pre_command returns=" .. result)
    return result
end

register_blueprint "enemy_alerter" {
    flags = { EF_NOPICKUP },
    callbacks = {
        on_action = [=[
            function (self, entity)
                LOGGER:trace("on_action")
                ANALYZER:store_health(entity)
                ANALYZER:initialize()
                INFO_ALERT.analyzer = ANALYZER
                INFO_ALERT.config = CONFIG
                INFO_ALERT:show()
                LOGGER:trace("on_action end")
            end
        ]=],

        -- store last action type and check if command should be stopped
        on_pre_command = [=[
            function ( self, entity, command, target, position, time_confirm )
                EA_MAIN.on_pre_command( self, entity, command, target, position, time_confirm )
            end
        ]=],

        on_station_activate = [=[
            function(self,who,what)
                LOGGER:trace("on_station_activate")
                -- clear ui:alert as it crashes the game if ui:terminal or another ui:function is called
                INFO_ALERT:clear()
            end
        ]=],

        on_terminal_activate = [=[
			function(self,who,what)
                LOGGER:trace("on_terminal_activate")
                -- clear ui:alert as it crashes the game if ui:terminal or another ui:function is called
			    INFO_ALERT:clear()
			end
		]=],

        on_enter_level = [=[
            function ( self, entity, reenter )
                LEVELMAP:on_enter_level(entity, reenter)
                CONFIG:on_enter_level(reenter)
            end
        ]=],
    }
}

world.register_on_entity(function(x)
    if x.data and x.data.ai and x.data.ai.group == "player" then
        x:attach("enemy_alerter")
        x:attach("enemy_alerter_config")
    end
end)

-- Starting to save configuration for setting cooldown and other things
-- nova.require "data/lua/configuration"
-- nova.require "configuration"
--[[function read_configuration_test()
    LOGGER:log("Config " .. tostring(configuration_scheme))
    LOGGER:log("Tutorial hints " .. tostring(configuration_scheme['general']['tutorial_hints']))
    LOGGER:log("configuration " .. tostring(configuration['prev_name']))
end]]
