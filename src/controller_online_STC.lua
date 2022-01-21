require "location"
require "utility"
require "directions"
require "spanning_tree"
require "STC_utility"

stack = {}
matrix_cell = {}
starting_cell = {}

function is_controller_online()
  return true
end

function init_controller(matrix)
  have_to_print = true
  matrix_cell = create_matrix(
                  calc_coord_sub_to_cell(#matrix),
                  calc_coord_sub_to_cell(#matrix[1]),
                  function () return {value = false, unvisitable_from = {}} end)
  starting_cell = get_robot_cell(matrix_cell)
  init_tree(matrix, calc_coord_cell_to_sub, starting_cell)
  table.insert(stack, create_couple(nil, starting_cell))
end

function robot_step()
  if #stack > 0 then
    stc(stack[#stack])
  else
    if have_to_print then
      have_to_print = false
      print_in()
      turn_clock()
    end
    return ""
  end
end

function controller_ended()
  return not (#stack > 0)
end

function stc(couple)
  parent, actual = get_from_couple(couple)
  matrix_cell[actual.i][actual.j].value = true
  target, is_target_new = calc_new_target(matrix_cell, parent, actual)
  if is_target_new then
    can_continue = move_following_tree(actual, target, false)
    if cells_are_equal(target, get_robot_cell(matrix_cell)) then
      table.insert(stack, create_couple(actual, target))
    elseif not can_continue then
      table.insert(matrix_cell[target.i][target.j].unvisitable_from, actual)
    end
  else
    if not cells_are_equal(actual, starting_cell) then
      if not cells_are_equal(parent, get_robot_cell(matrix_cell)) then
        move_following_tree(actual, parent, true)
      else
        table.remove(stack)
      end
    else
      move_following_tree(actual, target, true, true)
      if is_submovement_ended() then
        print_in()
        table.remove(stack)
      end
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
