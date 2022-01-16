require "utility"
require "directions"
require "location"
require "evaluation" -- to remove
require "cell_state"

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
future_offset = nil
next_target_subcell = nil
future_target_subcell = nil
last_target_cell = nil
last_subcell = nil
abs_dir_parallel = nil
abs_dir_normal = nil
first_target_subcell = nil
next_walking_subcell = nil


function init_tree(matrix_sub, cell_to_subcell, init_cell)
  matrix = matrix_sub
  calc_coord_cell_to_first_subcell = cell_to_subcell
  starting_cell = init_cell
  last_target_cell = nil
  disable_longer_way()
  ending_condition = {
    [QUADRANT.UP_LEFT] = false,
    [QUADRANT.DOWN_LEFT] = false,
    [QUADRANT.DOWN_RIGHT] = false,
    [QUADRANT.UP_RIGHT]  = false
  }
end

function move_following_tree(actual_cell, target_cell, coming_back, ending)
  ending = ending or false
  assert(not cells_are_equal(actual_cell, target_cell)) -- ~
  if (not cells_are_equal(target_cell, last_target_cell) or cells_are_equal(actual_cell, last_target_cell))  and future_offset then
    disable_longer_way()
  end
  last_target_cell = target_cell
  subcell = get_robot_cell(matrix)
  if get_cell_state(matrix, subcell) ~= CELL_STATE.VISITABLE then
    set_cell_state(matrix, subcell, CELL_STATE.VISITABLE)
  end
  --set_cell_visitable(matrix, subcell, true)
  if cells_are_equal(actual_cell, starting_cell) then
    ending_condition[get_quadrant_from_cells(actual_cell, subcell)] = true
  end
  --log(cell_to_string(actual_cell), " -> ", cell_to_string(target_cell), "from ", cell_to_string(subcell))
  target_subcell = nil
  if abs_dir_normal and abs_dir_parallel then
    log(cell_to_string(subcell))
    walk_near_wall()
    return true
  elseif future_offset then   -- same as above
    target_subcell = longer_way(actual_cell, target_cell, ending)
  else
    target_subcell = default_calc_target_subcell(actual_cell, target_cell, ending)
  end
  --[[if cells_are_equal(actual_cell, create_cell(6,3)) then
    log(cell_to_string(subcell)," in ", quad_to_string(quad)," => ", cell_to_string(target_subcell), " in ", quad_to_string(get_quadrant_from_cells(actual_cell, target_subcell)))
  end]]
  --target_subcell = get_new_target_cell(create_cell(0,-1),matrix)
  --log("tar: ",cell_to_string(target_subcell))
  abs_dir = get_abs_dir_from_cells(subcell, target_subcell)
  dir = get_dir_from_absolute(abs_dir)
  assert(get_new_target_cell(abs_direction_to_offset(dir), matrix))
  if get_cell_state(matrix, target_subcell) == CELL_STATE.UNVISITED then
    set_cell_state(matrix, target_subcell, is_direction_available(dir) and CELL_STATE.VISITING or CELL_STATE.UNVISITABLE)
  end
  target_state = get_cell_state(matrix, target_subcell)
  if target_state == CELL_STATE.VISITABLE or (target_state == CELL_STATE.VISITING and is_direction_available(dir)) then
    --log("going to", cell_to_string(target_subcell))
    is_reachable = go_to_target(matrix, target_subcell)
    if not is_reachable then
      if target_state == CELL_STATE.VISITABLE then
        set_cell_state(matrix, target_subcell, CELL_STATE.WASVISITABLE)
      else
        set_cell_state(matrix, target_subcell, CELL_STATE.UNVISITABLE)
      end
      quad_in_starting = get_quadrant_from_cells(starting_cell, target_subcell)
      if quad_in_starting ~= QUADRANT.OUT then
        ending_condition[get_quadrant_from_cells(actual_cell, target_subcell)] = true
      end
    end
    return is_reachable
  else
    offset_cell = get_offset_from_cells(actual_cell, target_cell)
    log(cell_to_string(actual_cell), "->", cell_to_string(target_cell))
    log("ho un muro ", abs_dir_to_string(abs_dir)," da", cell_to_string(get_robot_cell(matrix)), "->", cell_to_string(target_subcell))
    if next_target_subcell and not next_target_subcell.visited then
      log(cell_to_string(offset_cell))
      log("two obstacles near me, can't continue",   "next_t:", cell_to_string(next_target_subcell), "fut_t:", cell_to_string(future_target_subcell), " last_t", cell_to_string(last_subcell))
      if coming_back then
        possible_new_target_subcell = get_new_target_cell(future_offset, matrix)
        log(abs_dir_to_string(get_abs_dir_from_cells(actual_cell, target_cell)), cell_to_string(subcell), "->", cell_to_string(possible_new_target_subcell))
        if get_cell_state(matrix, possible_new_target_subcell) == CELL_STATE.VISITABLE and
            is_abs_dir_available(get_abs_dir_from_cells(actual_cell, target_cell)) then
          new_target_subcell = possible_new_target_subcell
          assert(get_quadrant_from_cells(target_cell, new_target_subcell) ~= QUADRANT.OUT,
                 quad_to_string(get_quadrant_from_cells(target_cell, new_target_subcell)))-- TODO
        else
          function calc_abs_dirs(best, worst) 
            abs_dir_parallel = abs_dir_parallel and opposite_direction(abs_dir_parallel) or get_abs_dir_from_cells(best, subcell) --if parallel exists take opposite
            abs_dir_normal = get_abs_dir_from_cells(subcell, worst)
          end
          choose_best_cell_to_walk_near(first_target_subcell, next_target_subcell, calc_abs_dirs)
          log(state_to_string(get_cell_state(matrix, first_target_subcell)), state_to_string(get_cell_state(matrix, next_target_subcell)))
          walk_near_wall()
        end
        return true
      end
      disable_longer_way()
      return false
    elseif future_target_subcell and not future_target_subcell.visited then
      if cells_are_equal(get_offset_from_cells(subcell, future_target_subcell), offset_cell) then
        log("two obstacles as wall, can't pass it :",   "next_t:", cell_to_string(next_target_subcell), "fut_t:", cell_to_string(future_target_subcell), " last_t", cell_to_string(last_subcell), cell_to_string(offset_cell))
        if coming_back then
          function calc_abs_dirs(best, worst) 
            abs_dir_parallel = get_abs_dir_from_cells(worst, best)
            abs_dir_normal = get_abs_dir_from_cells(subcell, future_target_subcell)
          end
          choose_best_cell_to_walk_near(first_target_subcell, future_target_subcell, calc_abs_dirs)
          walk_near_wall()
          return true
        end
        disable_longer_way()
        return false
      else
        log("two obstacles as wall, don't have to pass it")
        future_target_subcell = nil
        return true
      end
    elseif future_offset then
      log("an other obstacle, can redo same as bef")
      enable_longer_way(target_subcell, offset_cell, abs_dir)
      return true
    else
      log("enable longer way cause obstacle")
      enable_longer_way(target_subcell, offset_cell, abs_dir)
      return true
    end
  end
end

function choose_best_cell_to_walk_near(cell1, cell2, calc_abs_dirs)
  cell1_state = get_cell_state(matrix, cell1)
  if cell1_state == CELL_STATE.WASVISITABLE or
      (cell1_state == CELL_STATE.VISITING and get_cell_state(matrix, cell2) == CELL_STATE.UNVISITABLE) then
    calc_abs_dirs(cell2, cell1)
  else
    calc_abs_dirs(cell1, cell2)
  end
end

function walk_near_wall()
  --[[if not is_direction_available(get_dir_from_absolute(abs_dir_parallel)) then
    log("changing")
    tmp_dir = abs_dir_parallel
    abs_dir_parallel = opposite_direction(abs_dir_normal)
    abs_dir_normal = tmp_dir
  end]]
  if not (turn_direction_counterclock(abs_dir_parallel) == abs_dir_normal or
          turn_direction_clock(abs_dir_parallel) == abs_dir_normal) then
    if not is_abs_dir_available(turn_direction_counterclock(abs_dir_normal)) then
      abs_dir_parallel = turn_direction_counterclock(abs_dir_normal)
    elseif not is_abs_dir_available(turn_direction_clock(abs_dir_normal)) then
      abs_dir_parallel = turn_direction_clock(abs_dir_normal)
    end
  end
    
  assert(turn_direction_counterclock(abs_dir_parallel) == abs_dir_normal or
          turn_direction_clock(abs_dir_parallel) == abs_dir_normal,
          abs_dir_to_string(abs_dir_parallel) .. abs_dir_to_string(abs_dir_normal))
  if is_abs_dir_available(abs_dir_parallel) then
    offset = abs_direction_to_offset(abs_dir_parallel)
  else
    offset = abs_direction_to_offset(abs_dir_normal)
  end
  go_to_target(matrix, get_new_target_cell(offset, matrix))
  --[[exist_obj_near = false
  for _, val in pairs(robot.proximity) do
    if object_near(val.value, 1) then
      exist_obj_near = true
    end
  end]]
  if is_direction_available(get_dir_from_absolute(abs_dir_normal)) then
    log("disable wall")
    --abs_dir_parallel = nil
    abs_dir_normal = nil
  end
end

function longer_way(actual_cell, target_cell, ending)
  subcell = get_robot_cell(matrix)
  if next_target_subcell and not next_target_subcell.visited then
    if cells_are_equal(next_target_subcell, subcell) then
      log("reached next_target_subcell ", cell_to_string(next_target_subcell), " go to future", cell_to_string(future_target_subcell))
      next_target_subcell.visited = true
      return future_target_subcell
    elseif new_target_subcell then
      log("exit from wrong cell bef next_t ", cell_to_string(get_robot_cell(matrix)), '->',cell_to_string(get_new_target_cell(future_offset, matrix)))
      return new_target_subcell
    else
      log("going to next_target_subcell", cell_to_string(next_target_subcell))
      return next_target_subcell
    end
  elseif future_target_subcell and not future_target_subcell.visited then
    if cells_are_equal(future_target_subcell, subcell) then
      future_target_subcell.visited = true
      if cells_are_equal(future_offset, get_offset_from_cells(actual_cell, target_cell)) then -- have to exit from the wrong point
        log("have to exit from wrong point", cell_to_string(get_robot_cell(matrix)), '->',cell_to_string(get_new_target_cell(future_offset, matrix)))
        return get_new_target_cell(future_offset, matrix)
      else
        log("follow default movement to continue then exit",cell_to_string(actual_cell),"->",cell_to_string(target_cell))
        disable_longer_way()
        return default_calc_target_subcell(actual_cell, target_cell, ending)
      end
    else
      log("going to future_target_subcell", cell_to_string(future_target_subcell))
      return future_target_subcell
    end
  else
    if get_quadrant_from_cells(target_cell, subcell) ~= QUADRANT.OUT and not cells_are_equal(last_subcell, subcell) then log("arrivato con out") end -- TODO check it
    if get_quadrant_from_cells(target_cell, subcell) ~= QUADRANT.OUT or cells_are_equal(last_subcell, subcell) then -- sono arrivato?
      log("past the obstacle, restart normal cycle")
      if get_quadrant_from_cells(actual_cell, subcell) ~= QUADRANT.OUT and
          is_abs_dir_available(get_abs_dir_from_cells(actual_cell, target_cell)) then
        return get_new_target_cell(get_offset_from_cells(actual_cell, target_cell), matrix)
      end
      -- TODO se le celle sono uguali ma non sono ancora uscito posso uscire!!! TODO TODO
      disable_longer_way()
      return default_calc_target_subcell(actual_cell, target_cell, ending)
    else
      log("going to exit")
      return last_subcell
    end
  end
end

function disable_longer_way()
  log("disable")
  first_target_subcell = nil
  future_offset = nil
  last_subcell = nil
  next_target_subcell = nil
  future_target_subcell = nil
  abs_dir_parallel = nil
  abs_dir_normal = nil
  next_walking_subcell = nil
  new_target_subcell = nil
end

function enable_longer_way(target_subcell, last_offset, obstacle_abs_dir)
  first_target_subcell = target_subcell
  future_offset = last_offset
  next_target_subcell = get_new_target_cell(abs_direction_to_offset(turn_direction_counterclock(obstacle_abs_dir)), matrix)
  future_target_subcell = sum_cells(next_target_subcell, abs_direction_to_offset(obstacle_abs_dir))
  last_subcell = sum_cells(future_target_subcell, future_offset) -- TODO Solo se deve uscire
  log(state_to_string(get_cell_state(matrix, {i=5,j=12})),
      state_to_string(get_cell_state(matrix,get_robot_cell(matrix))),
      state_to_string(get_cell_state(matrix,next_target_subcell)),
      state_to_string(get_cell_state(matrix,future_target_subcell)),
      state_to_string(get_cell_state(matrix,last_subcell)) )
  log("next_t:", cell_to_string(next_target_subcell), "fut_t:", cell_to_string(future_target_subcell), " last_t", cell_to_string(last_subcell))
end

function get_quadrant_from_cells(cell, subcell)
  --log("cell:", cell_to_string(cell), "sub: ",cell_to_string(subcell))
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

function default_calc_target_subcell(actual_cell, target_cell, ending)
    subcell = get_robot_cell(matrix)
    quad = get_quadrant_from_cells(actual_cell, subcell)
    offset_cell = get_offset_from_cells(actual_cell, target_cell)
    --log(quad_to_string(quad))
    --[[log(cell_to_string(abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])),
          cell_to_string(offset_cell),
          cells_are_equal(offset_cell, abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])))]]
    if quad == QUADRANT.OUT then
      --log("cause out")
      return nearest_subcell_in_cell(matrix, actual_cell)
      --log("return to cell")
    else
      if cells_are_equal(offset_cell, abs_direction_to_offset(QUADRANT_TO_POSSIBLE_DIRECTION[quad])) and not ending then
        --log("exit")
        return get_new_target_cell(offset_cell, matrix)
      else
        --log("stay")
        return get_new_target_cell(abs_direction_to_offset(turn_direction_counterclock(QUADRANT_TO_POSSIBLE_DIRECTION[quad])), matrix)
      end
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

function print_in()
  log(cell_to_string(get_robot_cell(matrix)))
  print(matrix_to_string(matrix, function (cell) return cell.value end))
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

function nearest_subcell_in_cell(matrix, cell)
  subcell = get_robot_cell(matrix)
  cell_i_as_sub = calc_coord_cell_to_first_subcell(cell.i)
  cell_j_as_sub = calc_coord_cell_to_first_subcell(cell.j)
  return create_cell(
    subcell.i > cell_i_as_sub and (cell_i_as_sub + 1) or cell_i_as_sub,
    subcell.j > cell_j_as_sub and (cell_j_as_sub + 1) or cell_j_as_sub
  )
end
