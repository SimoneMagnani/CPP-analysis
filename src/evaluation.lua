require "matrix"

checkpoint = {}
init_time = 0
n_steps = 0

function init_checkpoints(...)
  local args = {...}
  checkpoint = {}
  for k,v in pairs(args) do
    checkpoint[v] = false
  end
  init_time = os.clock()
end

function step_evaluation(matrix)
  n_steps = n_steps + 1
  print_simulation_on_checkpoint(matrix)
end

function print_simulation_on_checkpoint(matrix)
  val_time = os.clock()
  coverage = coverage_percentage(matrix)
  for i,v in pairs(checkpoint) do
    if not checkpoint[i] and coverage >= i then
      checkpoint[i] = true
      --do stuff
      log("checkpoint ",i ," done with cov: ", coverage)
    end
  end
end

function is_simulation_ended(matrix)
  return coverage_percentage(matrix) == 100
end

function coverage_percentage(matrix)
  tot_cells = 0
  seen_cells = 0
  function count_cells(cell) 
    tot_cells = tot_cells + 1
    if cell > 0 then
      seen_cells = seen_cells + 1
    end 
  end
  exec_on_each_cell(matrix, count_cells)
  --log(seen_cells, " ", tot_cells, " ", 100 * seen_cells / tot_cells)
  return 100 * seen_cells / tot_cells
end
