ALERT = {
    size_x = 0,
    rounds_shown = 0,
    title = "",
    display = "",
}

ENEMIES = {
    visible = 0,
    prev_visible = 0,
    types = {},
}

ACTION = {
    last_command = 0,
    used_weapon = false,
    last_action_time = 0,
    last_receive_damage_time = 0,
    player_rushing = false,
    rushed_cooldown_rounds = 0,
}

function set_last_command(command, target)
    ACTION.used_weapon = false
    ACTION.last_command = command
    if command == COMMAND_USE and target and target.weapon then
        ACTION.used_weapon = true
    end
end

function last_command()
    local result = "unknown command=" .. ACTION.last_command
    if ACTION.last_command == COMMAND_ACTIVATE then
        result = "activate"
    elseif ACTION.last_command == COMMAND_DROP then
        result = "drop"
    elseif ACTION.last_command == COMMAND_MOVE_E then
        result = "move_e"
    elseif ACTION.last_command == COMMAND_MOVE_N then
        result = "move_n"
    elseif ACTION.last_command == COMMAND_MOVE_S then
        result = "move_s"
    elseif ACTION.last_command == COMMAND_MOVE_W then
        result = "move_w"
    elseif ACTION.last_command == COMMAND_PICKUP then
        result = "pickup"
    elseif ACTION.last_command == COMMAND_REARM then
        result = "rearm"
    elseif ACTION.last_command == COMMAND_RELOAD then
        result = "reload"
    elseif ACTION.last_command == COMMAND_USE then
        result = "use"
    elseif ACTION.last_command == COMMAND_WAIT then
        result = "wait"
    end
    return result
end

function last_command_moved()
    if ACTION.last_command and ACTION.last_command >= COMMAND_MOVE and ACTION.last_command <= COMMAND_MOVE_F then
        return true
    else
        return false
    end
end

-- Increments the enemy with identifier by Type in ENEMIES
function increment_enemy(identifier)
    if identifier then
        if ENEMIES.types[identifier] then
            ENEMIES.types[identifier] = ENEMIES.types[identifier] + 1
        else
            ENEMIES.types[identifier] = 1
        end
    else
        nova.log("Error: increment_enemy for idenfifier with nil value")
    end
end

-- Checks if enemy is exalted and returns true / false
function is_exalted(target)
    if target and target.text and target.text.name and string.match(target.text.name, "xalted") then
        return true
    else
        return false
    end
end

function red_text(text)
    return "{R" .. text .. "}"
end

function yellow_text(text)
    return "{Y" .. text .. "}"
end

function ranges(item_attributes)
    local result = ""
    if item_attributes.opt_distance then result = result .. item_attributes.opt_distance end
    if item_attributes.max_distance then result = result .. "/" .. item_attributes.max_distance end
    if result:len() > 0 then result = "(" .. result .. ")" end
    return result
end

function shots_x_damage(item_attributes)
    local result = ""
    if item_attributes then
        if item_attributes.damage then result = result .. item_attributes.damage end
        if item_attributes.shots and item_attributes.shots > 1 then result = result .. "x" .. item_attributes.shots end
    end
    return result
end

function main_weapon(entity)
    local item = entity:get_weapon()
    local display = ""
    if item then
        if item.attributes then
            display = red_text(shots_x_damage(item.attributes))
            display = display .. " " .. ranges(item.attributes)
        end
    end
    return display
end

function calculate_size_x(line)
    ALERT.size_x = math.max(line:len(), ALERT.size_x)
end

function append_enemy_line(line)
    if ALERT.display:len() > 0 then ALERT.display = ALERT.display .. "\n" end
    ALERT.display = ALERT.display .. line
end

function count_enemy_types()
    for target in world:get_level():targets(world:get_player(), 16) do
        if target.data and target.data.ai then
            ENEMIES.visible = ENEMIES.visible + 1
            local weapon = main_weapon(target)
            if is_exalted(target) then weapon = "Exalted " .. weapon end
            increment_enemy(weapon)
        end
    end
end

function set_shown_alert()
    if ENEMIES.visible > ENEMIES.prev_visible then
        ALERT.rounds_shown = 0
    elseif ENEMIES.visible <= ENEMIES.prev_visible then
        ALERT.rounds_shown = ALERT.rounds_shown + 1
    end
end

function create_long_alert()
    ALERT.title = yellow_text(ENEMIES.visible) .. " Enemies"
    for weapon_used, count in pairs(ENEMIES.types) do
        local enemy_display_line = yellow_text(count) .. "x" .. weapon_used
        calculate_size_x(enemy_display_line)
        append_enemy_line(enemy_display_line)
    end
end

function create_short_alert()
    ALERT.title =  yellow_text(ENEMIES.visible) .. " En"
    for weapon_used, count in pairs(ENEMIES.types) do
        local enemy_display_line = yellow_text(count) .. "x" .. string.sub(weapon_used, 1, 4)
        calculate_size_x(enemy_display_line)
        append_enemy_line(enemy_display_line)
    end
end

function count_enemies()
    ENEMIES.prev_visible = ENEMIES.visible
    ENEMIES.visible = 0
    ALERT.size_x = 0
    ENEMIES.types = {}
    ALERT.display = ""
    count_enemy_types()
    set_shown_alert()
    if ALERT.rounds_shown <= 3 then
        create_long_alert()
    else
        create_short_alert()
    end
end

function calculate_rushing()
    local current_time = ui:get_time_ms()
    local duration = current_time - ACTION.last_action_time
    ACTION.last_action_time = current_time
    if duration < 500 and ACTION.rushed_cooldown_rounds <= 0 then
        ACTION.player_rushing = true
    else
        ACTION.player_rushing = false
        ACTION.rushed_cooldown_rounds = ACTION.rushed_cooldown_rounds - 1
    end
end

function reset_rushed_cooldown()
    ACTION.rushed_cooldown_rounds = 15
end

function rushed_into_enemies()
    if ENEMIES.prev_visible == 0 and ENEMIES.visible > 0 and last_command_moved() then
        return true
    else
        return false
    end
end
function many_new_enemies()
    if ENEMIES.visible > (ENEMIES.prev_visible + 3) then
        return true
    else
        return false
    end
end

register_blueprint "enemy_alerter"
{
    flags = { EF_NOPICKUP },
    callbacks = {
        on_action = [=[
            function ( self, entity )
                count_enemies()
                calculate_rushing()
                ui:alert_clear(1)
                if ENEMIES.visible > 0 then
                    ui:alert {
                            id = 1,
                            title = ALERT.title,
                            teletype = 0,
                            content = ALERT.display,
                            size = ivec2(ALERT.size_x, -1),
                            position = ivec2(1, 20),
                            modal = false,
                        }
                end

                if ACTION.player_rushing and (rushed_into_enemies() or many_new_enemies()) then
                    reset_rushed_cooldown()
                    ui:alert {
                            id = 2,
                            title = ALERT.title,
                            teletype = 0,
                            content = "Stop rushing enemies in sight!",
                            size = ivec2(40, -1),
                            position = ivec2(-1, -1),
                            modal = true,
                        }
                end
            end
        ]=],

        -- store last action type
        on_pre_command = [=[
            function ( self, entity, command, target )
                set_last_command(command, target)
                nova.log("Last command=" .. last_command())
            end
        ]=],

        -- store last time damage was received
        on_receive_damage = [=[
            function ( self, source, weapon, amount )
                ACTION.last_receive_damage_time = ui:get_time_ms()
            end
        ]=],

        -- prevent an alert to be shown over level up dialog
        on_level_up = [=[
            function ( self, entity )
                ui:alert_clear(1)
                ui:alert_clear(2)
            end
        ]=],
    },
}

world.register_on_entity(
function(x)
	if x.data and x.data.ai and x.data.ai.group == "player" then
		x:attach("enemy_alerter")
	end
    end)

-- Starting to save configuration for setting cooldown and other things
--nova.require "data/lua/configuration"
--nova.require "configuration"
--[[function read_configuration_test()
    nova.log("Config " .. tostring(configuration_scheme))
    nova.log("Tutorial hints " .. tostring(configuration_scheme['general']['tutorial_hints']))
    nova.log("configuration " .. tostring(configuration['prev_name']))
end]]