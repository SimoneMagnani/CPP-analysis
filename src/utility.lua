MAX_VELOCITY = 20           --Sets the max speed of the robot
PROXIMITY_THRESHOLD = 0.15   --The threshold above which a proximity sensor is considered

--gap must be positive
function move_index_of(start, gap, max)
  assert(gap >= 0)
  new_index = (start + gap) % max
  if new_index == 0 then
    return max
  else
    return new_index
  end
end

function object_near(proximity, n_sensors)
  return (proximity / n_sensors) < PROXIMITY_THRESHOLD
end

--Choose and turn to the shortest way
function turn(target, actual, half)
  -- Decide the shortest way
  if (target > actual and target - half < actual)
   or (target < actual and target + half < actual) then
    turn_counter_clock()
  else
    turn_clock()
  end
end

function turn_clock()
  robot.wheels.set_velocity(MAX_VELOCITY,-MAX_VELOCITY)
end

function turn_counter_clock()
  robot.wheels.set_velocity(-MAX_VELOCITY,MAX_VELOCITY)
end

function go_ahead()
  robot.wheels.set_velocity(MAX_VELOCITY,MAX_VELOCITY)
end

function table_contains_as_val(table, elem, check)
  check = check or function (e1,e2) return e1 == e2 end
  for _, value in pairs(table) do
    if check(value, elem) then
      return true
    end
  end
  return false
end

function table_contains_as_key(table, elem, check)
  check = check or function (e1,e2) return e1 == e2 end
  for key, _ in pairs(table) do
    if check(key, elem) then
      return true
    end
  end
  return false
end

function table_is_empty(table)
  for i,v in pairs(table) do
    return false
  end
  return true
end
