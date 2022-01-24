DIRECTION = {
  FRONT = 0,
  LEFT = 1,
  BEHIND = 2,
  RIGHT = 3
}

ABS_DIRECTION = {
  NORTH = 0,
  WEST = 1,
  SOUTH = 2,
  EAST = 3
}

NUMBER_TO_DIRECTION = {
  DIRECTION.FRONT,
  DIRECTION.LEFT,
  DIRECTION.BEHIND,
  DIRECTION.RIGHT,
}

DIRECTION_TO_COORD = { -- non è direction TODO
  create_cell(-1,0),
  create_cell(0,-1),
  create_cell(1,0),
  create_cell(0,1)
}

ANGLE = math.pi / 2
N_DIRECTIONS = #DIRECTION_TO_COORD

function get_abs_dir_from_dir(dir)
  yaw, pitch, roll = robot.positioning.orientation:toeulerangles()
  direction_radians = (yaw + math.pi                   -- [0, 2pi] 2pi long y axis
                        + dir * ANGLE) % (2 * math.pi)   -- slide of dir angle
  return math.floor(direction_radians / ANGLE + 0.5) % 4
end

function get_dir_from_absolute(abs_dir)
  yaw, pitch, roll = robot.positioning.orientation:toeulerangles()
  return math.floor((abs_dir * ANGLE - (yaw + math.pi)) / ANGLE + 4.5) % 4
end

function direction_robot_to_offset(dir)
  return abs_direction_to_offset(get_abs_dir_from_dir(dir))
end

function abs_direction_to_offset(direction)
  if direction and DIRECTION_TO_COORD[direction + 1] then
    return DIRECTION_TO_COORD[direction + 1]
  end
end

function is_near_from_starting_index(init_front_index)
  front_index_1 = init_front_index
  front_index_2 = move_index_of(front_index_1, 1, n_sensors)
  post_index = move_index_of(front_index_1, 2, n_sensors)
  prev_index = move_index_of(front_index_1, n_sensors-1, n_sensors)
  return object_near((robot.proximity[front_index_1].value +
                      robot.proximity[front_index_2].value) * 2+
                      robot.proximity[prev_index].value +
                      robot.proximity[post_index].value, 6)
end

function get_directions_availabile()
  init_front_index = 24
  dirs = {}
  n_sensors = #robot.proximity
  for i=1,N_DIRECTIONS do
    dirs[cast_to_direction(i)] = is_near_from_starting_index(move_index_of(init_front_index, (i-1) * (n_sensors / N_DIRECTIONS), n_sensors))
  end
  return dirs
end

function is_direction_available(dir)
  return get_directions_availabile()[dir] and true or false
end

function get_abs_dir_available(shift)
  n_sensors = #robot.proximity
  yaw, pitch, roll = robot.positioning.orientation:toeulerangles()
  init_front_index = math.ceil(
                        ((yaw + math.pi)       --[0, 2pi]
                          / (2 * math.pi)) * n_sensors  --[0, 24]
                      )
  init_front_index = shift and init_front_index + n_sensors / N_DIRECTIONS / 2 or init_front_index
  init_north_index = n_sensors - init_front_index % n_sensors
  dirs = {}
  --log(yaw, " ",init_front_index," ", init_north_index)
  for i=1,N_DIRECTIONS do
    dirs[cast_to_direction(i)] = is_near_from_starting_index(move_index_of(init_north_index, (i-1) * (n_sensors / N_DIRECTIONS), n_sensors))
  end
  return dirs
end

function is_abs_dir_available(abs_dir)
  return get_abs_dir_available(false)[abs_dir] and true or false
end

function is_shifted_counterclock_abs_dir_available(abs_dir)
  return get_abs_dir_available(true)[abs_dir] and true or false
end

function is_shifted_clock_abs_dir_available(abs_dir)
  return get_abs_dir_available(true)[turn_direction_clock(abs_dir)] and true or false
end

function cast_to_direction(index)
  assert(index >= 1 and index <= N_DIRECTIONS)
  return NUMBER_TO_DIRECTION[index]
end

function dir_to_string(dir)
  return dir == DIRECTION.FRONT and "Front" or
          dir == DIRECTION.LEFT and "Left" or
          dir == DIRECTION.BEHIND and "Behind" or
          dir == DIRECTION.RIGHT and "Right"
end

function abs_dir_to_string(dir)
  return dir == ABS_DIRECTION.NORTH and "^" or
          dir == ABS_DIRECTION.WEST and "<" or
          dir == ABS_DIRECTION.SOUTH and "v" or
          dir == ABS_DIRECTION.EAST and ">"
end

function get_abs_dir_from_cells(actual, destination)
  assert(not cells_are_equal(actual, destination))
  if actual == nil or destination == nil then
    --log("param==nil => directions = nil")
    return
  end
  offset = get_offset_from_cells(actual, destination)
  for k,v in pairs(DIRECTION_TO_COORD) do
    if cells_are_equal(v,offset) then
      return cast_to_direction(k)
    end
  end
  if actual.i > destination.i then
    abs_dir = ABS_DIRECTION.NORTH
  elseif actual.i < destination.i then
    abs_dir = ABS_DIRECTION.SOUTH
  end
  if abs_dir and is_abs_dir_available(abs_dir) then
    choose_abs_dir = function(new_abs) return is_abs_dir_available(new_abs) and new_abs or abs_dir end
  else
    choose_abs_dir = function(new_abs) return new_abs end
  end
  if actual.j > destination.j then
    abs_dir = choose_abs_dir(ABS_DIRECTION.WEST)
  elseif actual.j < destination.j then
    abs_dir = choose_abs_dir(ABS_DIRECTION.EAST)
  end
  --log(abs_dir_to_string(abs_dir))
  assert(abs_dir)
  return abs_dir
end

function turn_direction_counterclock(direction)
  return (direction + 1) % N_DIRECTIONS
end

function turn_direction_clock(direction)
  return (direction +  N_DIRECTIONS - 1) % N_DIRECTIONS
end

function opposite_direction(direction)
  return (direction + 2) % N_DIRECTIONS
end
