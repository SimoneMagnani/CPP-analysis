require "utility"
require "matrix"
require "evaluation"
require "location"
require "directions"
require "cell_state"

require "controller_online_STC"
--require "controller_random_chaos"


n_steps = 0


--[[ This function is executed every time you press the 'execute'
     button ]]
function init()
  left_v = robot.random.uniform(0,MAX_VELOCITY)
  right_v = robot.random.uniform(0,MAX_VELOCITY)
  robot.wheels.set_velocity(left_v,right_v)
  n_steps = 0
  robot.leds.set_all_colors("black")
  matrix = create_matrix(30, 30, function () return { value = 0 } end)
  --matrix = create_matrix(30,30)
  how_init_state = is_controller_online() and
                          function (i,j) return CELL_STATE.UNVISITED end or
                          function (i,j) return CELL_STATE.UNVISITED end --TODO offline methods
  init_cell_state(matrix, how_init_state)
  init_controller(matrix)
  init_checkpoints(1,33,50,80,87,88,89,90,91,100)
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
  if is_simulation_ended(matrix) or controller_ended() then
    --log(coverage_percentage(matrix))
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
