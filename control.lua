--[[
  Robots Configurable Behavior

  1. Redirect mined items to nearest storage
  Makes construction robots deliver mined/deconstructed items to the nearest
  storage chest. Since the game API does not allow changing a robot's destination,
  we add the same temporary entity to the nearest chest when the robot is about to
  mine the entity (robot will choose this chest by prioritization because it's already filled with the same entity)
  and just remove it in short time.
]]

local DELAY_TICKS = 3  -- Wait for items to move from event buffer into robot_cargo

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

local function add_entity_to_chest(entity, chest)
  if not chest.valid then return false end
  local inv = chest.get_inventory(defines.inventory.chest)
  if not inv then return false end

  local prototype_exists = game.item_prototypes[entity.name];

  if prototype_exists == nil then return false end

  local existing_count = inv.get_item_count(entity.name)
  if existing_count > 0 then return false end

  return inv.insert({ name = entity.name, count = 1 }) > 0
end

local function on_robot_pre_mined(event)
  if not is_redirect_enabled() then return end

  local storages = get_storages_sorted_by_distance(event.robot.logistic_network, event.robot.position)
  if #storages == 0 then return false end
  if add_entity_to_chest(event.entity, storages[1]) == false then return end

  global.chests_queue = global.chests_queue or {}
  table.insert(global.chests_queue, {
    chest = storages[1],
    entity_name = event.entity.name,
    apply_tick = event.tick + DELAY_TICKS
  })
end

local function on_tick(event)
  local queue = global.chests_queue
  if not queue or #queue == 0 then return end
  for i = #queue, 1, -1 do
    local entry = queue[i]
    if entry.apply_tick <= event.tick then
      local inv = entry.chest.get_inventory(defines.inventory.chest)
      inv.remove({ name = entry.entity_name, count = 1 })
      table.remove(queue, i)
    end
  end
end

local function on_load()
  global.chests_queue = global.chests_queue or {}
end

script.on_init(on_load)
script.on_load(on_load)

script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_robot_pre_mined, on_robot_pre_mined)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting ~= "robots-configurable-behavior-redirect-to-nearest-storage" then return end
end)
