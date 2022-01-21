require "location" --to remove

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
      matrix[i][j].state = set_state(i, j) -- set_cell_state?
    end
  end
end

function get_cell_state(matrix, cell)
  assert(cell, "cell nil")
  if not coords_are_valid(matrix, cell.i, cell.j) then return CELL_STATE.UNVISITABLE end
  return matrix[cell.i][cell.j].state
end

function set_cell_state(matrix, cell, new_state)
  matrix[cell.i][cell.j].state = new_state
  --log(cell_to_string(cell), " is ", state_to_string(new_state))
end

function state_to_string(state)
  return state == CELL_STATE.UNKNOWN and "Uknown" or
        (state == CELL_STATE.VISITING and "Visiting") or
        (state == CELL_STATE.VISITABLE and "Visitable") or
        (state == CELL_STATE.UNVISITABLE and "UnVisitable") or
        (state == CELL_STATE.WASVISITABLE and "Was Visitable")
      
end
