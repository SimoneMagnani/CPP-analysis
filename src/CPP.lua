require "utility"
require "matrix"
require "evaluation"
require "location"
require "directions"
require "cell_state"

require "controller_online_STC"
--require "controller_random_chaos"

online = true

--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
  already_done = false
  matrix = create_matrix(30, 30, function () return { value = 0 } end)
  how_init_state = online and
                          function (i,j) return CELL_STATE.UNKNOWN end or
                          function (i,j)
                            if i >= 12 and i <= 19 and j >= 12 and j <= 19 then     --central obstacle
                              return CELL_STATE.UNVISITABLE
                            elseif i >= 5 and i <= 6 and j >= 5 and j <= 6 then     --up-left obstacle
                              return CELL_STATE.UNVISITABLE
                            elseif i >= 5 and i <= 6 and j >= 26 and j <= 27 then   --up-right obstacle
                              return CELL_STATE.UNVISITABLE
                            elseif i >= 26 and i <= 27 and j >= 5 and j <= 6 then   --down-left obstacle
                              return CELL_STATE.UNVISITABLE
                            elseif i >= 26 and i <= 27 and j >= 26 and j <= 27 then --down-right obstacle
                              return CELL_STATE.UNVISITABLE
                            end
                            return CELL_STATE.VISITING
                          end
  init_cell_state(matrix, how_init_state)
  init_controller(matrix, online)
  init_checkpoints(1,33,50,80,87,88,89,90,91)
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
  if is_simulation_ended(matrix) or controller_ended() then
    if not already_done then
      already_done = true
      on_end()
    end
    turn_clock()
    return
  end
  robot_step()
  update_matrix_on_location(matrix)
  step_evaluation(matrix)
end



--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
  init()
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
  -- put your code here
end
