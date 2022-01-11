require "utility"
require "directions"
require "location"
require "evaluation" -- to remove

MULTIPLIER = 2

QUADRANT = {
  UP_LEFT = 1,
  DOWN_LEFT = 2,
  DOWN_RIGHT = 3,
  UP_RIGHT = 4,
  OUT = 5
}

QUADRANT_TO_POSSIBLE_DIRECTION = {
  [QUADRANT.UP_LEFT] = ABS_DIRECTION.WEST,
  [QUADRANT.DOWN_LEFT] = ABS_DIRECTION.SOUTH,
  [QUADRANT.DOWN_RIGHT] = ABS_DIRECTION.EAST,
  [QUADRANT.UP_RIGHT]  = ABS_DIRECTION.NORTH
}


matrix = {}
calc_coord_cell_to_first_subcell = nil
starting_cell = nil
ending_condition = nil
first_step_done = false
future_target_subcell = nil

function init_tree(matrix_sub, cell_to_subcell, init_cell)
  matrix = matrix_sub
  calc_coord_cell_to_first_subcell = cell_to_subcell
  starting_cell = init_cell
  first_step_done = false
  future_target_subcell = nil
  ending_condition = {
    [QUADRANT.UP_LEFT] = false,
    [QUADRANT.DOWN_LEFT] = false,
    [QUADRANT.DOWN_RIGHT] = false,
    [QUADRANT.UP_RIGHT]  = false
  }
end

function move_following_tree(actual_cell, target_cell, ending)
  ending = ending or false
  assert(not cells_are_equal(actual_cell, target_cell) and target_cell ~= nil and actual_cell ~= nil)
  --log(cell_to_string(actual_cell), " -> ", cell_to_string(target))
  subcell = get_robot_cell(matrix)
  quad = get_quadrant_from_cells(actual_cell, subcell)
  offset_cell = get_offset_from_cells(actual_cell, target_cell)
  --[[if cells_are_equal(actual_cell, starting_cell) then
    ending_condition[quad] = true
    print_in()
  end]]
  target_subcell = nil
  --log(quad_to_string(quad))
  --[[log(cell_to_string(abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])),
        cell_to_string(offset_cell),
        cells_are_equal(offset_cell, abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])))]]
  if quad == QUADRANT.OUT then
    if subcell.i > calc_bound_coord_cell(calc_coord_cell_to_first_subcell(actual_cell.i)) then
      abs_dir = ABS_DIRECTION.NORTH
    elseif subcell.i < calc_coord_cell_to_first_subcell(actual_cell.i) then
      abs_dir = ABS_DIRECTION.SOUTH
    end
    if subcell.j > calc_bound_coord_cell(calc_coord_cell_to_first_subcell(actual_cell.j)) then
      abs_dir = ABS_DIRECTION.WEST
    elseif subcell.j < calc_coord_cell_to_first_subcell(actual_cell.j) then
      abs_dir = ABS_DIRECTION.EAST
    end
    --log(abs_dir_to_string(abs_dir))
    target_subcell = get_new_target_cell(abs_direction_to_offset(abs_dir), matrix)
    --log("return to cell")
  else
    if cells_are_equal(offset_cell, abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])) and not ending then
      --log("exit")
      target_subcell = get_new_target_cell(offset_cell, matrix)
    else
      --log("stay")spanning_tree.lua
      target_subcell = get_new_target_cell(abs_direction_to_offset(turn_direction_counterclock(QUADRANT_TO_POSSIBLE_DIRECTION[quad])), matrix)
    end
  end
  --[[if cells_are_equal(actual_cell, create_cell(6,3)) then
    log(cell_to_string(subcell)," in ", quad_to_string(quad)," => ", cell_to_string(target_subcell), " in ", quad_to_string(get_quadrant_from_cells(actual_cell, target_subcell)))
  end]]
  --target_subcell = get_new_target_cell(create_cell(0,-1),matrix)
  --log("tar: ",cell_to_string(target_subcell))
  is_reachable = go_to_target(matrix, target_subcell)
  return is_reachable
end

function get_quadrant_from_cells(cell, subcell)
  --log("cell:", cell_to_string(cell), "sub: ",cell_to_string(subcell))
  starting_i = calc_coord_cell_to_first_subcell(cell.i)
  starting_j = calc_coord_cell_to_first_subcell(cell.j)
  --log(starting_i, starting_j)
  if subcell.i ~= starting_i and subcell.i ~= calc_bound_coord_cell(starting_i) or
    (subcell.j ~= starting_j and subcell.j ~= calc_bound_coord_cell(starting_j)) then
    return QUADRANT.OUT
  end
  if subcell.i > starting_i  then
    return (subcell.j > starting_j) and QUADRANT.DOWN_RIGHT or QUADRANT.DOWN_LEFT
  else
    return (subcell.j > starting_j) and QUADRANT.UP_RIGHT or QUADRANT.UP_LEFT
  end
end

function calc_future_target_subcell()
  return get_new_target_cell(
          abs_direction_to_offset(
            turn_direction_counterclock(
              turn_direction_counterclock(QUADRANT_TO_POSSIBLE_DIRECTION[quad]))), matrix)
end

function calc_bound_coord_cell(coord)
  return coord + 1
end

function get_next_quad(quad)
  move_index_of(quad, 1, #QUADRANT)
end

function quad_to_string(quad)
  return quad == QUADRANT.UP_LEFT and "Up-left" or
          quad == QUADRANT.DOWN_LEFT and "Down-left" or
          quad == QUADRANT.UP_RIGHT and "Up-right" or
          quad == QUADRANT.DOWN_RIGHT and "Down-right" or
          quad == QUADRANT.OUT and "Out of Cell"
end

function print_in()
  log(cell_to_string(get_robot_cell(matrix)))
  print(matrix_to_string(matrix))
  log(coverage_percentage(matrix))
end

function is_submovement_ended()
  for _, completed in pairs(ending_condition) do
    if not completed then
      return false
    end
  end
  return true
end
