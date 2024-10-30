nova.require "enemy"

ANALYZER = {
    enemies = {},
    prev_enemies = {},

    initialize = function(self)
        self.prev_enemies = self.enemies
        self.enemies = {}
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
    end,

    sort = function(self)
        table.sort(self.enemies, function(a, b)
            return a.chance_to_hit >= b.chance_to_hit
        end)
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

}
