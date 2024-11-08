nova.require "logger"
nova.require "enemy"

local xps_per_level_needed = {
    {200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600, 2800, 3000, 3200, 3400, 3600, 3800},
    {220, 440, 660, 880, 1100, 1320, 1540, 1760, 1980, 2200, 2420, 2640, 2860, 3080, 3300, 3520, 3740, 3960, 4180},
    {300, 600, 900, 1200, 1500, 1800, 2100, 2400, 2700, 3000, 3300, 3600, 3900, 4200, 4500, 4800, 5100, 5400, 5700},
    {400, 800, 1200, 1600, 2000, 2400, 2800, 3200, 3600, 4000, 4400, 4800, 5200, 5600, 6000, 6400, 6800, 7200, 7600}
}
local function calculate_level(experience)
    local difficulty_index = DIFFICULTY + 1
    local levels = #xps_per_level_needed[difficulty_index]
    local total_xp = 0

    for level = 1, levels do
        total_xp = total_xp + xps_per_level_needed[difficulty_index][level]
        if experience < total_xp then
            return level
        end
    end

    return levels + 1
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

    initialize = function(self)
        self.prev_enemies = self.enemies
        self.enemies = {}
        self.chances = {}
        self.permutations = {}
        self.damage_odds = {}
        self.prev_xp = self.current_xp
        local player = world:get_player()
        self.current_xp = player.progression.experience
        ENEMY:initialize()

        ---@diagnostic disable-next-line: undefined-field
        for e in ENEMY.level:targets(player, 14) do
            if e.data and e.data.ai then
                local data = ENEMY:analyze(e)
                table.insert(self.enemies, data)
                LOGGER:debug("created " .. data:tostring())
            end
        end
        self:sort()
        self:create_chances()
        self:generate_permutations()
        self:calculate_odds()
    end,

    will_level_up = function(self)
        local prev_level = calculate_level(self.prev_xp)
        local current_level = calculate_level(self.current_xp)
        local result = prev_level < current_level
        LOGGER:debug("prev_level=" ..
            prev_level .. ", current_level=" .. current_level ..
            ", cxp=" ..
            self.current_xp .. ", difficulty=" .. DIFFICULTY .. ", will_level=" .. tostring(result))
        return result
    end,

    store_health = function(self, player)
        self.health_before = self.health_current
        self.health_current = player.health.current
    end,

    sort = function(self)
        table.sort(self.enemies, function(a, b)
            local acth = 0
            local bcth = 0
            if a and a.chance_to_hit then acth = a.chance_to_hit end
            if b and b.chance_to_hit then bcth = b.chance_to_hit end
            return acth > bcth
        end)
    end,

    create_chances = function(self)
        for _, d in pairs(self.enemies) do
            if d.shots and d.damage then
                for count = 1, d.shots, 1 do
                    table.insert(self.chances, { chance_to_hit = d.chance_to_hit, damage = d.damage })
                end
            end
        end
        LOGGER:debug("Chances count=" .. #self.chances)
    end,

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

    generate_permutations = function(self)
        self:combine(self.chances, 1, {}, self.permutations)
    end,

    visible_enemies = function(self)
        local count = 0
        for _ in pairs(self.enemies) do count = count + 1 end
        return count
    end,

    prev_visible_enemies = function(self)
        local count = 0
        for _ in pairs(self.prev_enemies) do count = count + 1 end
        return count
    end,

    find_enemy = function(self, enemy)
        local search_id = tostring(enemy)
        for _, e in pairs(self.enemies) do
            if e.id == search_id then return e end
        end
    end,

    calculate_odds = function(self)
        local result = {}
        for _, p in pairs(self.permutations) do
            local odd = 1.0
            local total_damage = 0
            for __, d in pairs(p) do
                odd = odd * d.chance_to_hit / 100
                total_damage = total_damage + d.damage
            end
            table.insert(result, { odd = odd, total_damage = total_damage })
        end
        self.permutations = result
        table.sort(self.permutations, function(a, b)
            return a.total_damage > b.total_damage
        end)
        result = {}
        for _, p in pairs(self.permutations) do
            if result[p.total_damage] then
                result[p.total_damage] = result[p.total_damage] * (1 - p.odd)
            else
                result[p.total_damage] = 1 - p.odd
            end
        end
        self.damage_odds = {}
        for damage, odd in pairs(result) do
            table.insert(self.damage_odds, { odd = 100 - (odd * 100), damage = damage })
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
