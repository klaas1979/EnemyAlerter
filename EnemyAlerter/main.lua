nova.log("Enemy Alerter loading")

nova.require "analyzer"
nova.require "info_alert"
nova.require "stop_alert"

register_blueprint "enemy_alerter" {
    flags = {EF_NOPICKUP},
    callbacks = {
        on_action = [=[
            function ( self, entity )
                ANALYZER:store_health(entity)
                ANALYZER:initialize()
                INFO_ALERT.analyzer = ANALYZER
                INFO_ALERT:show()
            end
        ]=],

        -- store last action type
        on_pre_command = [=[
            function ( self, entity, command, target )
                --nova.log("on_pre_command last=" .. last_command() .. ", commmand=" .. get_command_name(command))
                STOP_ALERT.analyzer = ANALYZER
                STOP_ALERT:set_last_command(command, target)
                STOP_ALERT:calculate_rushing()
                if STOP_ALERT:stop_command() then
                    STOP_ALERT:reset_rushed_cooldown()
                    nova.log("Stopped command " .. STOP_ALERT:last_command() .. ", ms: " .. ui:get_time_ms())
                    STOP_ALERT:show(ANALYZER)
                    return -1
                end
            end
        ]=],

        on_post_command = [=[
            function ( self, actor, command, target, time )
                --nova.log("on_post_command command=" .. last_command())
            end
        ]=],

        -- prevent an alert to be shown over level up dialog
        on_level_up = [=[
            function ( self, entity )
                nova.log("on_level_up")
                ui:alert_clear(1)
                ui:alert_clear(2)
            end
        ]=]
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
    nova.log("Config " .. tostring(configuration_scheme))
    nova.log("Tutorial hints " .. tostring(configuration_scheme['general']['tutorial_hints']))
    nova.log("configuration " .. tostring(configuration['prev_name']))
end]]
