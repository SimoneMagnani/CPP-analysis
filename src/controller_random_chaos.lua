require "location"
require "utility"

N_CELLS_TO_REMEMBER = 0 --Defines how many steps need the robot to consider a cell visitable again
RANDOM = false          --Defines if direction is choosen random or caotically
R=3.7                   --Sets the multiplier to calculate chaotic

unvisitable_cells = {}
chaotic = 0
can_continue = true
matrix = {}

function is_controller_online()
  return true
end

function init_controller(m, online)
  assert(online, "Random controller must be online_controller")
  matrix = m
  can_continue = true
  target_cell = get_next_target()
  if not RANDOM then
    repeat
      chaotic = robot.random.uniform()
    until chaotic ~= 0
  end
end

function controller_ended()
  return false
end


function robot_step()
  if did_i_reach_target(target_cell, matrix) or (not can_continue) then
    -- If the robot reached the target I update it
    target_cell = get_next_target()
  end
  can_continue = go_to_target(matrix, target_cell)
end

--Returns next valid direction incapsulating the logic of random or chaos
function get_next_direction()
  repeat
    -- If no valid dir exists, removes last unvisitable cell
    if not exists_valid_dir() then
      table.remove(unvisitable_cells,1)
    end
    -- Decide next direction
    if RANDOM then
      next_direction = math.floor(robot.random.uniform_int(1,N_DIRECTIONS + 1))
    else 
      chaotic = R * chaotic * (1 - chaotic)
      next_direction = math.floor((chaotic * 1000000) % N_DIRECTIONS) + 1
    end
    next_direction = cast_to_direction(next_direction)
  until is_valid_dir(next_direction)
  -- Update the direction distribution with the next valid direction
  return next_direction
end

--Returns the next valid target cell and updates the queue of target cells
function get_next_target()
  target = get_new_target_cell(direction_robot_to_offset(get_next_direction()), matrix)
  -- Update next unvisitable cells
  table.insert(unvisitable_cells, target)
  if #unvisitable_cells > N_CELLS_TO_REMEMBER then
    table.remove(unvisitable_cells,1)
  end
  return target
end

--Returns if dir is valid
function is_valid_dir(dir)
  if is_direction_available(dir) then
    target = get_new_target_cell(direction_robot_to_offset(dir), matrix)
    for k,v in pairs(unvisitable_cells) do
      -- If the target is equal to an unvisitable cell return false otherwise true
      if are_cells_equal(v,target) then
        return false
      end
    end
    return true
  end
  return false
end

--Checks if exists a valid dir 
function exists_valid_dir()
  for i=1, N_DIRECTIONS do
    if is_valid_dir(i) then
      return true
    end
  end
  return false
end
