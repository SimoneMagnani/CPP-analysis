require "utility"
require "matrix"
require "directions"
require "location"

function cell_has_new_target(matrix_cell, cell)
  for _,abs_dir in pairs(ABS_DIRECTION) do
    if have_to_visit_target(matrix_cell, get_next_cell_from_abs_dir(cell, abs_dir), cell) then
      return true
    end
  end
  return false
end
    
function have_to_visit_target(matrix_cell, target, actual)
  return coords_are_valid(matrix_cell, target.i, target.j) and
                      not (matrix_cell[target.i][target.j].value) and
                      not table_contains_as_val(matrix_cell[target.i][target.j].unvisitable_from, actual, cells_are_equal)
end

function get_next_cell_from_abs_dir(actual, abs_dir)
  return sum_cells(actual, abs_direction_to_offset(abs_dir))
end

function calc_new_target(matrix_cell, parent, actual)
  init_direction = get_abs_dir_from_cells(parent, actual) or ABS_DIRECTION.WEST -- my dir
  init_direction = opposite_direction(init_direction)                           -- was coming from
  direction = init_direction
  repeat
    direction = turn_direction_counterclock(direction)
    target = get_next_cell_from_abs_dir(actual, direction)
    is_target_new = have_to_visit_target(matrix_cell, target, actual)
  until (is_target_new or direction == init_direction)
  assert(is_target_new or not cell_has_new_target(matrix_cell, actual))
  return target, is_target_new
end
