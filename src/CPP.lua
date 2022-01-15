require "utility"
require "matrix"
require "evaluation"
require "location"
require "directions"

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
  init_controller(matrix)
  init_cell_state(matrix, function (i,j) return CELL_STATE.UNVISITED end)
  init_checkpoints(1,33,50,80,87,88,89,90,100)
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
  if is_simulation_ended(matrix) then
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
