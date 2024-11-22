-- All credits to https://github.com/cpiod/JH-JoviSec-PDA

-- global Log object used to display the action log
CPIOD_LOG = {
  description = function()
    local result = ""
    local log_number = math.min(#CPIOD_LOG, 15)
    for i = 1, log_number do
      result = result .. CPIOD_LOG[#CPIOD_LOG - i + 1]
      if i < log_number then
        result = result .. "\n"
      end
    end
    return result
  end
}

-- Logs the result from player action for the log to be displayed
register_blueprint "cpiod_logger"
{
  flags = { EF_NOPICKUP },
  attributes = {
    last_entry = nil,
    cpiod_wait = 0,
  },
  callbacks = {
    on_receive_damage = [=[
			function ( self, entity, source, weapon, amount )
                -- destination must have an AI to avoid "X attacks crates/barrel/etc."
                -- but keep them as source (to know if a barrel destroyed an enemy for example)
                if amount > 0 then
                    if source and source.data and source.data.ai and source.data.ai.group == "player" then
                        table.insert(CPIOD_LOG, "You deal {!"..tostring(amount).."} to {!"..world:get_text( world:get_id(entity), "name" ).."}")
                    else
                        local s = world:get_text( world:get_id(source), "name" )
                        s = string.upper(s:sub(1,1))..s:sub(2,#s)
                        table.insert(CPIOD_LOG, "{!"..s.."} deals {!"..tostring(amount).."} to {!"..world:get_text( world:get_id(entity), "name" ).."}")
                    end
                    self.attributes.last_entry = #CPIOD_LOG
                    self.attributes.cpiod_wait = 0
                end
            end
		]=],
    on_die = [=[
			function ( self )
                if self.attributes.last_entry then
                    CPIOD_LOG[self.attributes.last_entry] = CPIOD_LOG[self.attributes.last_entry]..", killing it"
                end
            end
		]=],
    on_enter_level = [=[
            function ( self, entity, reenter )
                for k,v in pairs(CPIOD_LOG) do -- delete previous logs
                    CPIOD_LOG[k] = nil
                end
                if world.data.level[world.data.current].name then
                    CPIOD_LOG[1] = "You enter {!".. world.data.level[world.data.current].name.."}"
                end
            end
		]=],
    on_post_command = [=[
			function ( self, entity, cmt, target, time )
                if entity.data and entity.data.ai and entity.data.ai.group == "player" then
                    if cmt == COMMAND_WAIT then
                        self.attributes.cpiod_wait = self.attributes.cpiod_wait + 1
                        if self.attributes.cpiod_wait == 1 then
                            table.insert(CPIOD_LOG, "You wait")
                        else
                            CPIOD_LOG[#CPIOD_LOG] = "You wait ("..self.attributes.cpiod_wait.." times)"
                        end
                    -- elseif cmt == COMMAND_DROP then
                    --     table.insert(CPIOD_LOG, "You drop "..world:get_text( world:get_id(target), "name" ))
                    --     self.attributes.cpiod_wait = false
                    -- elseif cmt == COMMAND_PICKUP then
                    --     table.insert(cpiod_log, "You pick up "..world:get_text( world:get_id(target), "name" ))
                    --     self.attributes.cpiod_wait = false
                    elseif cmt == COMMAND_RELOAD then
                        table.insert(CPIOD_LOG, "You reload")
                        self.attributes.cpiod_wait = 0
                    end
                end
            end
		]=],

    on_rearm = [=[
			function ( self, entity, wpn, wpn_next )
                if entity.data and entity.data.ai and entity.data.ai.group == "player" then
                    table.insert(CPIOD_LOG, "You equip {!"..world:get_text( world:get_id(wpn), "name" ).."}")
                    self.attributes.cpiod_wait = 0
                end
            end
		]=],

  }
}

world.register_on_entity(function(entity)
  if entity.data and entity.data.ai then
    entity:attach("cpiod_logger")
  end
end)
