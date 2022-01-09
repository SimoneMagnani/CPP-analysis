PROXIMITY_THRESHOLD = 0.01  --The threshold above which a sum of proximity sensor consider a cell occupied

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

function robot_dir_to_absolute(dir)
  yaw, pitch, roll = robot.positioning.orientation:toeulerangles()
  direction_radians = (yaw + math.pi                   -- [0, 2pi] 2pi long y axis
                        + dir * ANGLE) % (2 * math.pi)   -- slide of dir angle
  return math.floor(direction_radians / ANGLE + 0.5) % 4
end

function direction_robot_to_offset(dir)
  return abs_direction_to_offset(robot_dir_to_absolute(dir))
end

function abs_direction_to_offset(direction)
  if direction and DIRECTION_TO_COORD[direction + 1] then
    return DIRECTION_TO_COORD[direction + 1]
  end
end

function get_directions_availabile()
  init_front_index = 24
  dirs = {}
  for i=1,N_DIRECTIONS do
    n_sensors = #robot.proximity
    front_index = move_index_of(init_front_index, (i-1) * (n_sensors / N_DIRECTIONS), n_sensors)
    prev_index = move_index_of(front_index, n_sensors-1, n_sensors)
    post_index = move_index_of(front_index, 1, n_sensors)
    proximity_sum = robot.proximity[prev_index ].value +
                    robot.proximity[front_index].value +
                    robot.proximity[post_index ].value
    dirs[cast_to_direction(i)] = proximity_sum < PROXIMITY_THRESHOLD
  end
  return dirs
end

function is_direction_available(dir)
  return get_directions_availabile()[dir] and true or false
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

function get_direction_from_cells(actual, destination)
  if actual == nil or destination == nil then
    log("param==nil => directions = nil")
    return
  end
  offset = get_offset_from_cells(actual, destination)
  for k,v in pairs(DIRECTION_TO_COORD) do
    if cells_are_equal(v,offset) then
      return cast_to_direction(k)
    end
  end
  log(actual.i,actual.j, " des ", destination.i, destination.j)
  assert(false)
end

function turn_direction_counterclock(direction)
  return (direction + 1) % N_DIRECTIONS
end

function turn_direction_clock(direction)
  return (direction +  N_DIRECTIONS - 1) % N_DIRECTIONS
end
