nova.require "logger"
nova.require "enemy"

-- Experience points required per level for different difficulties
local XP_PER_LEVEL_NEEDED = {
    {200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600, 2800, 3000, 3200, 3400, 3600, 3800},
    {220, 440, 660, 880, 1100, 1320, 1540, 1760, 1980, 2200, 2420, 2640, 2860, 3080, 3300, 3520, 3740, 3960, 4180},
    {300, 600, 900, 1200, 1500, 1800, 2100, 2400, 2700, 3000, 3300, 3600, 3900, 4200, 4500, 4800, 5100, 5400, 5700},
    {400, 800, 1200, 1600, 2000, 2400, 2800, 3200, 3600, 4000, 4400, 4800, 5200, 5600, 6000, 6400, 6800, 7200, 7600}
}

--- Calculates the player level based on experience points.
-- @param experience The current experience points of the player.
-- @return The calculated level of the player.
local function calculate_level(experience)
    local difficulty_index = DIFFICULTY + 1
    local total_xp = 0

    for level = 1, #XP_PER_LEVEL_NEEDED[difficulty_index] do
        total_xp = total_xp + XP_PER_LEVEL_NEEDED[difficulty_index][level]
        if experience < total_xp then
            return level
        end
    end

    return #XP_PER_LEVEL_NEEDED[difficulty_index] + 1
end

ANALYZER = {
    health_current = 100,
    health_before = 100,
    enemies = {},
    prev_enemies = {},
    chances = {},
    permutations = {},
    prev_xp = 0,
    current_xp = 0,

    --- Initializes the analyzer by resetting values and gathering enemy data.
    initialize = function(self)
        self.prev_enemies = self.enemies
        self.enemies = {}
        self.chances = {}
        self.permutations = {}
        self.prev_xp = self.current_xp

        local player = world:get_player()
        self.current_xp = player.progression.experience
        ENEMY:initialize()

---@diagnostic disable-next-line: undefined-field
        for e in ENEMY.level:targets(player, 14) do
            if e.data and e.data.ai then
                local data = ENEMY:analyze(e)
                table.insert(self.enemies, data)
                LOGGER:debug("Created " .. data:tostring())
            end
        end

        self:sort_enemies()
        self:create_chances()
        self:generate_permutations()
        self:calculate_odds()
    end,

    --- Checks if the player will level up based on current experience.
    -- @return True if the player will level up, false otherwise.
    will_level_up = function(self)
        local prev_level = calculate_level(self.prev_xp)
        local current_level = calculate_level(self.current_xp)
        local result = prev_level < current_level

        LOGGER:debug(string.format("prev_level=%d, current_level=%d, cxp=%d, difficulty=%d, will_level=%s",
            prev_level, current_level, self.current_xp, DIFFICULTY, tostring(result)))
        return result
    end,

    --- Stores the player's current health for later comparison.
    -- @param player The player entity.
    store_health = function(self, player)
        self.health_before = self.health_current
        self.health_current = player.health.current
    end,

    --- Sorts the enemies based on their chance to hit.
    sort_enemies = function(self)
        table.sort(self.enemies, function(a, b)
            return (a.chance_to_hit or 0) > (b.chance_to_hit or 0)
        end)
    end,

    --- Creates a list of chances based on enemy data.
    create_chances = function(self)
        for _, enemy_data in pairs(self.enemies) do
            if enemy_data.shots and enemy_data.damage then
                for _ = 1, enemy_data.shots do
                    table.insert(self.chances, { chance_to_hit = enemy_data.chance_to_hit, damage = enemy_data.damage })
                end
            end
        end
        LOGGER:debug("Chances count=" .. #self.chances)
    end,

    --- Combines arrays recursively to generate permutations.
    -- @param arr The array to combine.
    -- @param start The starting index for combination.
    -- @param current The current combination being built.
    -- @param result The result array to store combinations.
    combine = function(self, arr, start, current, result)
        if #current > 0 then
---@diagnostic disable-next-line: deprecated
            table.insert(result, { unpack(current) })
        end

        for i = start, #arr do
            table.insert(current, arr[i])
            self:combine(arr, i + 1, current, result)
            table.remove(current)
        end
    end,

    --- Generates all possible permutations of chances.
    generate_permutations = function(self)
        self:combine(self.chances, 1, {}, self.permutations)
    end,

    --- Counts the number of visible enemies.
    -- @return The number of visible enemies.
    visible_enemies = function(self)
        return #self.enemies
    end,

    --- Counts the number of previously visible enemies.
    -- @return The number of previously visible enemies.
    prev_visible_enemies = function(self)
        return #self.prev_enemies
    end,

    --- Finds an enemy in the current list based on its ID.
    -- @param enemy The enemy to search for.
    -- @return The enemy data if found, nil otherwise.
    find_enemy = function(self, enemy)
        local search_id = tostring(enemy)
        for _, e in pairs(self.enemies) do
            if e.id == search_id then return e end
        end
        return nil
    end,

    --- Calculates the odds of damage based on enemy permutations.
    calculate_odds = function(self)
        local result = {}
        for _, p in pairs(self.permutations) do
            local odd = 1.0
            local total_damage = 0

            for _, d in pairs(p) do
                odd = odd * (d.chance_to_hit / 100)
                total_damage = total_damage + d.damage
            end

            table.insert(result, { odd = odd, total_damage = total_damage })
        end

        self.permutations = result

        -- Sort by highest total damage first
        table.sort(self.permutations, function(a, b)
            return a.total_damage > b.total_damage
        end)

        result = {}
        for _, p in pairs(self.permutations) do
            if result[p.total_damage] then
                result[p.total_damage] = 1 - ((1 - result[p.total_damage]) * (1 - p.odd))
            else
                result[p.total_damage] = p.odd
            end
        end

        self.damage_odds = {}
        for damage, odd in pairs(result) do
            table.insert(self.damage_odds, { odd = odd * 100, damage = damage })
        end

        table.sort(self.damage_odds, function(a, b)
            return a.odd > b.odd
        end)

        LOGGER:debug("Created " .. #self.damage_odds .. " odds")
        for _, p in pairs(self.damage_odds) do
            LOGGER:trace(string.format("odd %.f%%=%i dmg", p.odd, p.damage))
        end
    end,
}
