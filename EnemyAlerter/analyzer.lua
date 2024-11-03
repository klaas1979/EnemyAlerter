nova.require "enemy"

ANALYZER = {
    health_current = 100,
    health_before = 100,
    enemies = {},
    prev_enemies = {},
    chances = {},
    permutations = {},

    initialize = function(self)
        self.prev_enemies = self.enemies
        self.enemies = {}
        self.chances = {}
        self.permutations = {}
        self.damage_odds = {}
        ENEMY:initialize()

        ---@diagnostic disable-next-line: undefined-field
        for e in ENEMY.level:targets(ENEMY.player, 14) do
            if e.data and e.data.ai then
                local data = ENEMY:analyze(e)
                table.insert(self.enemies, data)
                nova.log("created " .. data:tostring())
            end
        end
        self:sort()
        self:create_chances()
        self:generate_permutations()
        self:calculate_odds()
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
        nova.log("Chances count=" .. #self.chances)
    end,

    combine = function(self, arr, start, current, result)
        -- Füge die aktuelle Kombination zur Ergebnis-Tabelle hinzu, wenn sie nicht leer ist
        if #current > 0 then
            ---@diagnostic disable-next-line: deprecated
            table.insert(result, { unpack(current) })
        end

        for i = start, #arr do
            -- Füge das aktuelle Element zur Kombination hinzu
            table.insert(current, arr[i])
            -- Rekursiver Aufruf für die nächste Position
            self:combine(arr, i + 1, current, result)
            -- Entferne das letzte Element, um die nächste Kombination zu erstellen
            table.remove(current)
        end
    end,

    -- Funktion zur Initialisierung und Aufruf der Kombinationsfunktion
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
            table.insert(self.damage_odds, { odd = 100 - odd * 100, damage = damage })
        end
        table.sort(self.damage_odds, function(a, b)
            return a.odd > b.odd
        end)
        --[[for _, p in pairs(self.damage_odds) do
            nova.log(string.format("%.f%%=%i", p.odd, p.damage))
        end
        --]]
    end,
}
