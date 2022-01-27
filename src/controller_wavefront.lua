require "location"
require "utility"
require "matrix"
require "cell_state"
require "directions"
require "utility"

WAVEFRONT_INDEX = "wavefront"
MAX_CELL_UPDATED= 100
matrix = {}

function is_controller_online()
  return false
end

function init_controller(m, online)
  assert(not online, "Wavefront controller must be offline controller")
  can_continue = true
  done = false
  matrix = m
  max_cell_value = #matrix * #matrix[1] + 1
  exec_on_each_cell(matrix, function (cell) cell[WAVEFRONT_INDEX] = max_cell_value end)
  final_cell = choose_final_cell(matrix) --needs to know the state
  log(cell_to_string(final_cell))
  set_wavefront_value(final_cell, 0)
  need_to_update_neighbours = {}
  table.insert(need_to_update_neighbours, final_cell)
  target_cell = get_robot_cell(matrix)
end

function controller_ended()
  return done
end

function choose_final_cell(matrix)
  actual_cell = get_robot_cell(matrix)
  repeat
    i = robot.random.uniform_int(1, #matrix + 1)
    j = robot.random.uniform_int(1, #matrix[1] + 1)
    proposed_cell = create_cell(i,j)
  until(get_cell_state(matrix, proposed_cell) == CELL_STATE.VISITING and not cells_are_equal(actual_cell, proposed_cell))
  assert(get_cell_state(matrix, proposed_cell) == CELL_STATE.VISITING and not cells_are_equal(actual_cell, proposed_cell))
  return proposed_cell
end

function robot_step()
  if #need_to_update_neighbours > 0 then
    create_wavefront()
  else
    set_cell_state(matrix, get_robot_cell(matrix), CELL_STATE.VISITABLE)
    assert(matrix[2][2][WAVEFRONT_INDEX] ~= max_cell_value, "wrong init")
    if did_i_reach_target(target_cell, matrix) then
      set_cell_state(matrix, target_cell, CELL_STATE.VISITABLE)
      -- If the robot reached the target, it needs to update
      if cells_are_equal(target_cell, final_cell) and #(get_visitable_neighbours(final_cell, CELL_STATE.VISITING)) == 0 then
        neighbours = get_visitable_neighbours(final_cell, CELL_STATE.VISITING)
        log(cell_to_string(final_cell), #neighbours)
        print(matrix_to_string(matrix, function (cell) return cell.value end))
          print(matrix_to_string(matrix, function (cell) return cell.wavefront end))
        done = true
        turn_clock()
      else
        --print(matrix_to_string(matrix, function (cell) return cell.value end))
        target_cell = get_next_target()
        --log("choosing new target ", cell_to_string(target_cell), "d:", done)
      end
    end
    go_to_target(matrix, target_cell)
  end
end

function create_wavefront()
  cell_updated = 0
  repeat
  actual_cell = need_to_update_neighbours[1]
  assert(coords_are_valid(matrix, actual_cell.i, actual_cell.j), cell_to_string(actual_cell))
  new_val = get_wavefront_value(actual_cell) + 1
  for _,cell in pairs(get_visitable_neighbours(actual_cell, CELL_STATE.VISITING)) do
    if get_wavefront_value(cell) > new_val then
      set_wavefront_value(cell, new_val)
      table.insert(need_to_update_neighbours, cell)
    end
  end
  cell_updated = cell_updated + 1
  table.remove(need_to_update_neighbours, 1)
  until(cell_updated == MAX_CELL_UPDATED or #need_to_update_neighbours == 0)
  --print(matrix_to_string(matrix, function (cell) return cell.wavefront end))
end

function get_next_target()
  neighbours = get_visitable_neighbours(get_robot_cell(matrix), CELL_STATE.VISITING)
  if #neighbours == 0 then
    neighbours = get_visitable_neighbours(get_robot_cell(matrix), CELL_STATE.VISITABLE)
    last_wavefront_value = max_cell_value
    check_value = function(val, last_val) return (val <= last_val) end
    printer = true
  else
    last_wavefront_value = 0
    check_value = function(val, last_val) return (val >= last_val) end
  end
  for _,cell in pairs(neighbours) do
    assert(cell, "cell nil")
    possible_value = get_wavefront_value(cell)
    if printer then
      --log(cell_to_string(get_robot_cell(matrix)), "->", cell_to_string(cell), " ", state_to_string(get_cell_state(matrix, cell)), possible_value, " ", check_value(possible_value, last_wavefront_value))
    end
    if check_value(possible_value, last_wavefront_value) then
        -- if are equals, toss the coin
      if possible_value ~= last_wavefront_value or robot.random.bernoulli() then
        last_wavefront_value = possible_value
        proposed_target = cell
      end
    end
  end
  return proposed_target
end

function get_visitable_neighbours(cell, state)
  neighbours = {}
  for i=1, N_DIRECTIONS do
    offset = abs_direction_to_offset(cast_to_abs_dir(i))
    possible_target = sum_cells(cell, offset)
    --log(state_to_string(get_cell_state(matrix, possible_target)), get_cell_state(matrix, possible_target) == state, state_to_string(state))
    if get_cell_state(matrix, possible_target) == state then
      table.insert(neighbours, possible_target)
    end
  end
  return neighbours
end

function get_wavefront_value(cell)
  return matrix[cell.i][cell.j][WAVEFRONT_INDEX]
end

function set_wavefront_value(cell, value)
  assert(cell, "cell nil")
  matrix[cell.i][cell.j][WAVEFRONT_INDEX] = value
end
