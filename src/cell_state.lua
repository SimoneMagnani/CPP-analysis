require "matrix"

CELL_STATE = {
  UNKNOWN = 0,
  VISITING = 1,
  VISITABLE = 2,
  UNVISITABLE = 3,
  WASVISITABLE = 4
}

function init_cell_state(matrix, set_state)
  for i=1, #matrix do
    for j=1, #matrix[i] do
      set_cell_state_from_coord(matrix, i, j, set_state(i, j))
    end
  end
end

function get_cell_state(matrix, cell)
  assert(cell, "cell nil")
  if not cell then return CELL_STATE.UNVISITABLE end
  return get_cell_state_from_coord(matrix, cell.i, cell.j)
end

function get_cell_state_from_coord(matrix, i, j)
  if not coords_are_valid(matrix, i, j) then return CELL_STATE.UNVISITABLE end
  return matrix[i][j].state
end

function set_cell_state(matrix, cell, new_state)
  if cell then
    set_cell_state_from_coord(matrix, cell.i, cell.j, new_state)
  end
end

function set_cell_state_from_coord(matrix, i, j, new_state)
  if coords_are_valid(matrix, i, j) then
    matrix[i][j].state = new_state
  end
end

function state_to_string(state)
  return state == CELL_STATE.UNKNOWN and "Uknown" or
        (state == CELL_STATE.VISITING and "Visiting") or
        (state == CELL_STATE.VISITABLE and "Visitable") or
        (state == CELL_STATE.UNVISITABLE and "UnVisitable") or
        (state == CELL_STATE.WASVISITABLE and "Was Visitable")
      
end
