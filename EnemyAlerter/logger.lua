-- simple helper to enable different log levels
LOGGER = {
  levels = { 'trace', 'debug', 'info', 'warn', 'error' },
  level = 5,

  set_level = function(self, new_level)
    for i, name in pairs(self.levels) do
      if name == new_level then
        self.level = i
        nova.log("Setting LOGGER level to " .. i .. ", name=" .. name .. ", given level=" .. new_level)
        return
      end
    end
  end,

  trace = function(self, text)
    if self.level == nil then nova.log("LOGGER called without 'self' reference") end
    if self.level <= 1 then self:log('TRACE', text) end
  end,

  debug = function(self, text)
    if self.level == nil then nova.log("LOGGER called without 'self' reference") end
    if self.level <= 2 then self:log('DEBUG', text) end
  end,

  info = function(self, text)
    if self.level == nil then nova.log("LOGGER called without 'self' reference") end
    if self.level <= 3 then self:log('INFO', text) end
  end,

  warn = function(self, text)
    if self.level == nil then nova.log("LOGGER called without 'self' reference") end
    if self.level <= 4 then self:log('WARN', text) end
  end,

  error = function(self, text)
    if self.level == nil then nova.log("LOGGER called without 'self' reference") end
    if self.level <= 5 then self:log('ERROR', text) end
  end,

  log = function(self, name, text)
    nova.log("EA-" .. name .. ": " .. text)
  end,
}
