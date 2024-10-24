ENEMIES = {
    visible = 0,
    prev_visible = 0,
    size_x = 0,
    rounds_shown = 0,
    title = "",
    display = "",
    types = {},
    last_action_time = 0,
    player_rushing = false,
    rushed_cooldown_rounds = 0,
}

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
    local result = "("
    if item_attributes.opt_distance then result = result .. item_attributes.opt_distance end
    if item_attributes.max_distance then result = result .. "/" .. item_attributes.max_distance end
    return result .. ")"
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
    ENEMIES.size_x = math.max(line:len(), ENEMIES.size_x)
end

function append_enemy_line(line)
    if ENEMIES.display:len() > 0 then ENEMIES.display = ENEMIES.display .. "\n" end
    ENEMIES.display = ENEMIES.display .. line
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
        ENEMIES.rounds_shown = 0
    elseif ENEMIES.visible <= ENEMIES.prev_visible then
        ENEMIES.rounds_shown = ENEMIES.rounds_shown + 1
    end
end

function create_long_alert()
    ENEMIES.title = yellow_text(ENEMIES.visible) .. " Enemies"
    for weapon_used, count in pairs(ENEMIES.types) do
        local enemy_display_line = yellow_text(count) .. "x" .. weapon_used
        calculate_size_x(enemy_display_line)
        append_enemy_line(enemy_display_line)
    end
end

function create_short_alert()
    ENEMIES.title =  yellow_text(ENEMIES.visible) .. " En"
    for weapon_used, count in pairs(ENEMIES.types) do
        local enemy_display_line = yellow_text(count) .. "x" .. string.sub(weapon_used, 1, 4)
        calculate_size_x(enemy_display_line)
        append_enemy_line(enemy_display_line)
    end
end

function count_enemies()
    ENEMIES.prev_visible = ENEMIES.visible
    ENEMIES.visible = 0
    ENEMIES.size_x = 0
    ENEMIES.types = {}
    ENEMIES.display = ""
    count_enemy_types()
    set_shown_alert()
    if ENEMIES.rounds_shown <= 3 then
        create_long_alert()
    else
        create_short_alert()
    end
end

function calculate_rushing()
    local current_time = ui:get_time_ms()
    local duration = current_time - ENEMIES.last_action_time
    ENEMIES.last_action_time = current_time
    if duration < 600 and ENEMIES.rushed_cooldown_rounds <= 0 then
        ENEMIES.player_rushing = true
    else
        ENEMIES.player_rushing = false
        ENEMIES.rushed_cooldown_rounds = ENEMIES.rushed_cooldown_rounds - 1
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
                            title = ENEMIES.title,
                            teletype = 0,
                            content = ENEMIES.display,
                            size = ivec2(ENEMIES.size_x, -1),
                            position = ivec2(1, 20),
                            modal = false,
                        }
                end

                local rushed_into_enemies = false
                if ENEMIES.prev_visible == 0 and ENEMIES.visible > 0 then rushed_into_enemies = true end
                local many_new_enemies = false
                if ENEMIES.visible > (ENEMIES.prev_visible + 3) then many_new_enemies = true end
                if ENEMIES.player_rushing and (rushed_into_enemies or many_new_enemies) then
                    ENEMIES.rushed_cooldown_rounds = 15
                    ui:alert {
                            id = 2,
                            title = ENEMIES.title,
                            teletype = 0,
                            content = "Stop rushing enemies in sight!",
                            size = ivec2(40, -1),
                            position = ivec2(-1, -1),
                            modal = true,
                        }
                end
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