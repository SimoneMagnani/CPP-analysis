require "location"
require "utility"
require "directions"
require "spanning_tree"

stack = {}
matrix_cell = {}
starting_cell = {}

function init_controller(matrix)
  init_tree(matrix, calc_coord_cell_to_sub)
  matrix_cell = create_matrix(calc_coord_sub_to_cell(#matrix), calc_coord_sub_to_cell(#matrix[1]), false)
  starting_cell = get_robot_cell(matrix_cell)
  table.insert(stack, create_couple(nil, starting_cell))
end

function robot_step()
  if #stack > 0 then
    stc(stack[#stack])
  else
    log("done")
  end
end

function stc(couple)
  parent, actual = get_from_couple(couple)
  matrix_cell[actual.i][actual.j] = true
  init_direction = get_direction_from_cells(parent, actual) or ABS_DIRECTION.EAST
  if parent then
    --log(to_string(parent), "->", to_string(actual), "dir: ",dir_to_string(init_direction))
  end
  direction = init_direction
  repeat
    direction = turn_direction_clock(direction)
    --log(dir_to_string(direction), abs_direction_to_offset(direction).i, abs_direction_to_offset(direction).j)
    target = sum_cells(actual, abs_direction_to_offset(direction))
    is_target_new = coords_are_valid(matrix_cell, target.i, target.j) and not (matrix_cell[target.i][target.j])
  until (is_target_new or direction == init_direction)
  if is_target_new then
    --log( get_robot_cell(matrix_cell).i, get_robot_cell(matrix_cell).j, " -> ", target.i, target.j)
    can_continue = move_following_tree(actual, target)
    if not can_continue then
      matrix_cell[target.i][target.j] = true
    --log("tar: ",to_string(target), "pos: ", to_string(get_robot_cell(matrix_cell)))
    elseif cells_are_equal(target, get_robot_cell(matrix_cell)) then
      --log("ins coup: ", to_string(actual), to_string(target))
      table.insert(stack, create_couple(actual, target))
    end
  else
    --log("act: ",to_string(actual), " eff: ", to_string(get_robot_cell(matrix_cell)), " parent: ",to_string(parent))
    if not cells_are_equal(actual, starting_cell) then
      if not cells_are_equal(parent, get_robot_cell(matrix_cell)) then
        move_following_tree(actual, parent)
      else
        table.remove(stack)
      end
      --move back from x to a subcell of w along edge
    else
      table.remove(stack)
    end
  end
end

function create_couple(parent, actual)
  return {parent = parent, actual = actual}
end

function get_from_couple(couple)
  return couple.parent, couple.actual
end

function calc_coord_sub_to_cell(coord)
  return math.ceil(coord / MULTIPLIER)
end

function calc_coord_cell_to_sub(coord)
  return coord * MULTIPLIER - 1
end  
