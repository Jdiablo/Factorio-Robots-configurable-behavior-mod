--[[
  Robots Configurable Behavior
  Makes construction robots deliver mined/deconstructed items to the nearest
  storage chest. Since the game API does not allow changing a robot's destination,
  we do "manual delivery": take the robot's cargo and insert it into the nearest
  storage chest(s), then clear the robot (it will fly to its original target with
  empty cargo and then go idle).
]]

local DELAY_TICKS = 1  -- Wait for items to move from event buffer into robot_cargo

local function is_redirect_enabled()
  local s = settings.global["robots-configurable-behavior-redirect-to-nearest-storage"]
  return s and s.value
end

--- Find storage chests in the robot's network, sorted by distance from position.
local function get_storages_sorted_by_distance(network, from_position)
  if not network or not network.valid then return {} end
  local storages = network.storages
  if not storages or #storages == 0 then return {} end
  local list = {}
  for _, entity in ipairs(storages) do
    if entity.valid then
      list[#list + 1] = entity
    end
  end
  local x, y = from_position.x, from_position.y
  table.sort(list, function(a, b)
    local da = (a.position.x - x) ^ 2 + (a.position.y - y) ^ 2
    local db = (b.position.x - x) ^ 2 + (b.position.y - y) ^ 2
    return da < db
  end)
  return list
end

--- Move robot's cargo into the nearest storage chest(s). Returns true if any items were moved.
local function deliver_robot_cargo_to_nearest_storage(robot)
  if not robot or not robot.valid then return false end
  local cargo = robot.get_inventory(defines.inventory.robot_cargo)
  if not cargo then return false end
  local contents = cargo.get_contents()
  if not contents or next(contents) == nil then return false end

  local network = robot.logistic_network
  local storages = get_storages_sorted_by_distance(network, robot.position)
  if #storages == 0 then return false end

  local moved = false
  for name, count in pairs(contents) do
    local remaining = count
    for i = 1, #storages do
      if remaining <= 0 then break end
      local chest = storages[i]
      if not chest.valid then goto continue end
      local inv = chest.get_inventory(defines.inventory.chest)
      if not inv then goto continue end
      local inserted = inv.insert({ name = name, count = remaining })
      if inserted > 0 then
        cargo.remove({ name = name, count = inserted })
        remaining = remaining - inserted
        moved = true
      end
      ::continue::
    end
  end
  return moved
end

local function on_robot_mined(event)
  if not is_redirect_enabled() then return end
  local robot = event.robot
  if not robot or not robot.valid or robot.type ~= "construction-robot" then return end
  global.redirect_queue = global.redirect_queue or {}
  table.insert(global.redirect_queue, {
    robot = robot,
    apply_tick = event.tick + DELAY_TICKS
  })
end

local function on_tick(event)
  local queue = global.redirect_queue
  if not queue or #queue == 0 then return end
  for i = #queue, 1, -1 do
    local entry = queue[i]
    if entry.apply_tick <= event.tick then
      deliver_robot_cargo_to_nearest_storage(entry.robot)
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
end)
