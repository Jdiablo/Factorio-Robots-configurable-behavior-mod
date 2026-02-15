--[[
  Robots Configurable Behavior
  Redirects construction robots to drop mined/deconstructed items at the nearest
  storage chest instead of the destination chosen by the logistic network.
  Uses the "re-delivery" method: after a robot picks up items we force it to
  re-evaluate its drop-off so it seeks the closest valid storage.
]]

local REDIRECT_DELAY_TICKS = 2  -- Wait for game to assign destination, then clear it

local function is_redirect_enabled()
  local s = settings.global["robots-configurable-behavior-redirect-to-nearest-storage"]
  return s and s.value
end

local function force_robot_to_nearest_storage(robot)
  if not robot or not robot.valid then return end
  -- Re-delivery method: toggle active so the robot drops its current task and
  -- recalculates; it will then seek the closest storage chest for its cargo.
  robot.active = false
  robot.active = true
  if not ok and err then log("Robots Configurable Behavior: could not toggle robot active: " .. tostring(err)) end
end

local function on_robot_mined(event)
  if not is_redirect_enabled() then return end
  local robot = event.robot
  if not robot or not robot.valid or robot.type ~= "construction-robot" then return end
  global.redirect_queue = global.redirect_queue or {}
  table.insert(global.redirect_queue, {
    robot = robot,
    apply_tick = event.tick + REDIRECT_DELAY_TICKS
  })
end

local function on_tick(event)
  local queue = global.redirect_queue
  if not queue or #queue == 0 then return end
  for i = #queue, 1, -1 do
    local entry = queue[i]
    if entry.apply_tick <= event.tick then
      force_robot_to_nearest_storage(entry.robot)
      table.remove(queue, i)
    end
  end
end

local function on_load()
  global.redirect_queue = global.redirect_queue or {}
end

script.on_init(on_load)
script.on_load(on_load)

script.on_event(defines.events.on_robot_mined_entity, on_robot_mined)
script.on_event(defines.events.on_robot_mined_tile, on_robot_mined)
script.on_event(defines.events.on_tick, on_tick)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting ~= "robots-configurable-behavior-redirect-to-nearest-storage" then return end
  -- No state to update; next mined entity will respect new value
end)
