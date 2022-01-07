require "utility"
require "directions"
require "location"

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

function init_tree(matrix_sub, cell_to_subcell)
  matrix = matrix_sub
  calc_coord_cell_to_first_subcell = cell_to_subcell
end

function move_following_tree(actual_cell, target_cell)
  assert(not cells_are_equal(actual_cell, target_cell) and target_cell ~= nil and actual_cell ~= nil)
  --log(actual_cell.i, actual_cell.j, " -> ", target.i, target.j)
  offset_cell = get_offset_from_cells(actual_cell, target_cell)
  subcell = get_robot_cell(matrix)
  quad = get_quadrant_from_cells(actual_cell, subcell)
  target_subcell = nil
  --log(quad_to_string(quad))
  --[[log(abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad]).i,
      abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad]).j,
      offset_cell.i,offset_cell.j,
      cells_are_equal(offset_cell, abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])))]]
  if quad == QUADRANT.OUT then
    target_subcell = create_cell(calc_coord_cell_to_first_subcell(actual_cell.i), calc_coord_cell_to_first_subcell(actual_cell.j))
    --log("return to cell")
  elseif cells_are_equal(offset_cell, abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])) then
    --log("exit")
    target_subcell = get_new_target_cell(offset_cell, matrix)
  else
    --log("stay")
    target_subcell = get_new_target_cell(abs_direction_to_offset(turn_direction_counterclock(QUADRANT_TO_POSSIBLE_DIRECTION[quad])), matrix)
  end
  --target_subcell = get_new_target_cell(create_cell(0,-1),matrix)
  --log("tar: ",to_string(target_subcell))
  return go_to_target(matrix, target_subcell)
end

function get_quadrant_from_cells(cell, subcell)
  --log("cell:", to_string(cell), "sub: ",to_string(subcell))
  starting_i = calc_coord_cell_to_first_subcell(cell.i)
  starting_j = calc_coord_cell_to_first_subcell(cell.j)
  --log(starting_i, starting_j)
  if subcell.i ~= starting_i and subcell.i ~= starting_i + 1 or
    (subcell.j ~= starting_j and subcell.j ~= starting_j + 1) then
    return QUADRANT.OUT
  end
  if subcell.i > starting_i  then
    return (subcell.j > starting_j) and QUADRANT.DOWN_RIGHT or QUADRANT.DOWN_LEFT
  else
    return (subcell.j > starting_j) and QUADRANT.UP_RIGHT or QUADRANT.UP_LEFT
  end
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
