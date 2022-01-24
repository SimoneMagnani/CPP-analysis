require "location"
require "utility"
require "directions"
require "spanning_tree_mover"
require "STC_utility"

stack = {}
matrix_cell = {}
starting_cell = {}

function is_controller_online()
  return am_i_online
end

function set_offline_state(matrix)
  am_i_online = false
  for i=0, #matrix do
    for j=0, #matrix do
      if get_cell_state_from_coord(matrix, i, j) == CELL_STATE.UNVISITABLE then
        prev_i = calc_coord_sub_to_cell(j - 1)
        prev_j = calc_coord_sub_to_cell(j - 1)
        actual_i = calc_coord_sub_to_cell(i)
        actual_j = calc_coord_sub_to_cell(i)
        next_i = calc_coord_sub_to_cell(i + 1)
        next_j = calc_coord_sub_to_cell(i + 1)
        if actual_j == next_j and get_cell_state_from_coord(matrix, i, j + 1) == CELL_STATE.UNVISITABLE then --horizontal wall
          target = create_cell(actual_i == next_i and prev_i or next_i, actual_j)
          set_unvisitable_from(matrix_cell, target, create_cell(actual_i, actual_j))
        end
        if actual_i == next_i and get_cell_state_from_coord(matrix, i + 1, j) == CELL_STATE.UNVISITABLE then --vertical wall
          target = create_cell(actual_i, actual_j == next_j and prev_j or next_j)
          set_unvisitable_from(matrix_cell, target, create_cell(actual_i, actual_j))
        end
        if actual_i == next_i and
            actual_j == next_j and
            get_cell_state_from_coord(matrix, i + 1, j + 1) == CELL_STATE.UNVISITABLE then --up-left and down-right obstacle
        end
        if actual_i == prev_i and
            actual_j == next_j and
            get_cell_state_from_coord(matrix, i - 1, j + 1) == CELL_STATE.UNVISITABLE then --up-right and down-left obstacle
        end
      end
    end
  end
end

function init_controller(matrix, online)
  have_to_print = true
  matrix_cell = create_matrix(
                  calc_coord_sub_to_cell(#matrix),
                  calc_coord_sub_to_cell(#matrix[1]),
                  function () return {value = false, unvisitable_from = {}} end)
  starting_cell = get_robot_cell(matrix_cell)
  am_i_online = online
  if not is_controller_online() then
    set_offline_state(matrix)
  end
  init_mover(matrix, calc_coord_cell_to_sub, starting_cell)
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
      set_unvisitable_from(matrix_cell, target, actual)
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

function set_unvisitable_from(matrix_cell, target, actual)
  if coords_are_valid(matrix_cell, target.i, target.j) and coords_are_valid(matrix_cell, actual.i, actual.j) then
    table.insert(matrix_cell[target.i][target.j].unvisitable_from, actual)
    table.insert(matrix_cell[actual.i][actual.j].unvisitable_from, target)
  end
end
