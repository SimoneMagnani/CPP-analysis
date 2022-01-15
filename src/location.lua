require "matrix"
require "utility"

MAX_DELTA_RAD = math.pi/15.0--Defines the max rad at which the robot decides to go head instead of turn
MIN_X = 0                   --The min X reachable from the robot
MAX_X = 4                   --The max X reachable from the robot
MIN_Y = 0                   --The min Y reachable from the robot
MAX_Y = 4                   --The max Y reachable from the robot

--Returns a table with "i","j" as indexes of the given i,j
function create_cell(i,j)
  return {i = i, j = j}
end

function cells_are_equal(cell1,cell2)
  if cell1 == nil or cell2 == nil then return false end
  return cell1.i == cell2.i and cell1.j == cell2.j
end

function sum_cells(cell1, cell2)
  return create_cell(cell1.i + cell2.i, cell1.j + cell2.j)
end

function cell_to_string(cell)
  if cell then
    return "i: " .. cell.i .. " j: " .. cell.j
  else
    return "Attention nil"
  end
end

last_cell = create_cell(nil, nil)

function get_robot_cell(matrix)
  -- donnow why are reverted
  y = robot.positioning.position.x
  x = robot.positioning.position.y
  assert(not(x > MAX_X or x < MIN_X or y > MAX_Y or y < MIN_Y), "out of bound coords")
  i = math.floor((y - MIN_Y) * #matrix[1] / MAX_Y) + 1
  j = math.floor((x - MIN_X) * #matrix    / MAX_X) + 1
  return create_cell(i,j)
end

function update_matrix_on_location(matrix)
  actual_cell = get_robot_cell(matrix)
  if not cells_are_equal(last_cell, actual_cell) then
    last_cell = actual_cell
    matrix[actual_cell.i][actual_cell.j].value = matrix[actual_cell.i][actual_cell.j].value + 1
  end
end

--Returns if the robot reached the target cell
function did_i_reach_target(target, matrix)
  return cells_are_equal(target, get_robot_cell(matrix))
end

--Returns the next target cell reached based on robot position and offset
function get_new_target_cell(offset, matrix)
  actual_cell = get_robot_cell(matrix)
  return sum_cells(actual_cell, offset)
end

function get_offset_from_cells(start, destination)
  return create_cell(destination.i - start.i, destination.j - start.j)
end


--Sets the speed of wheels to turn to target or to move to target. It also returns if the robot is turning or going
function go_to_target(matrix, target)
  actual_cell = get_robot_cell(matrix)

  -- Get robot radians                                
  yaw, pitch, roll = robot.positioning.orientation:toeulerangles()
  actual_radians = (yaw + math.pi                       -- [0, 2pi] 2pi long y axis
                        + 3*math.pi/2 ) % (2 * math.pi) -- [0, 2pi] 2pi long x axis
                        - math.pi                       -- [-pi, pi] pi long x axis 

  -- Get target radians swapping y axis to uniform orientation (y grows going down)
  target_radians = math.atan2(-(target.i - actual_cell.i), target.j - actual_cell.j)
  
  -- Decide if turn or not
  turning = math.abs(target_radians - actual_radians) > MAX_DELTA_RAD or 
            math.abs(target_radians - actual_radians) + MAX_DELTA_RAD > 2 * math.pi
  if turning then
    turn(target_radians, actual_radians, math.pi)
  else
    go_ahead()
    if not is_direction_available(DIRECTION.FRONT) then
      return false
    end
  end
  return true
end
