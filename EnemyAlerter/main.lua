nova.require "analyzer"
nova.require "info_alert"
nova.require "logger"
nova.require "stop_alert"

-- set the logging level
LOGGER:set_level('info')

LOGGER:info("Enemy Alerter loading")

--[[
TODOs
Check if this is a problem:
you should also remove the box on any ui:terminal calls, because it's not just the level up dialog that freezes with the modal=false alert
also probably ui:confirm, can't recall
--]]

register_blueprint "enemy_alerter" {
    flags = { EF_NOPICKUP },
    callbacks = {
        on_action = [=[
            function (self, entity)
                ANALYZER:store_health(entity)
                ANALYZER:initialize()
                INFO_ALERT.analyzer = ANALYZER
                INFO_ALERT:show()
            end
        ]=],

        -- store last action type
        on_pre_command = [=[
            function ( self, entity, command, target )
                LOGGER:debug("on_pre_command last=" .. STOP_ALERT:last_command() .. ", commmand=" .. STOP_ALERT:get_command_name(command))
                STOP_ALERT.analyzer = ANALYZER
                STOP_ALERT:set_last_command(command, target)
                STOP_ALERT:calculate_rushing()
                if STOP_ALERT:stop_command() then
                    STOP_ALERT:reset_rushed_cooldown()
                    LOGGER:info("Stopped command " .. STOP_ALERT:last_command() .. ", ms: " .. ui:get_time_ms())
                    STOP_ALERT:show()
                    return -1
                end
            end
        ]=],

        -- purely used for logging and comparing received dmg with calculated ones
        on_receive_damage = [=[
            function ( self, entity, source, weapon, amount )
                local found_enemy_data = ANALYZER:find_enemy(source)
                if found_enemy_data then
                    if not found_enemy_data.damage == amount then
                        LOGGER:warn(string.format("Enemy dealt %idmg calc %idmg, enemy data: %s", amount, found_enemy_data.damage, found_enemy_data:tostring()))
                    else
                        LOGGER:debug(string.format("Dealt %idmg == calc %idmg", amount, found_enemy_data.damage))
                    end
                end
            end
        ]=],
    }
}

world.register_on_entity(function(x)
    if x.data and x.data.ai and x.data.ai.group == "player" then
        x:attach("enemy_alerter")
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
