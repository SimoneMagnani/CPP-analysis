--Returns a i_max x j_max size matrix of init_value
function create_matrix(i_max, j_max, init_value)
  a = {}
  for i=1, i_max do
    a[i] = {}
    for j=1, j_max do
      a[i][j] = init_value
    end
  end
  return a
end

function coords_are_valid(matrix, i, j)
  return (i >= 1 and
          j >= 1 and 
          i <= #matrix and
          j <= #matrix[1] and
          i == math.floor(i) and
          j == math.floor(j))
end

function matrix_is_valid(matrix)
  if #matrix > 0 then
    for i=1, #matrix do
      for j=1, #matrix[i] do
        if not (#matrix[i] > 0 and #matrix[i] == #matrix[1]) then
          return false
        end
      end
    end
    return true
  else
    return false
  end

end

function exec_on_each_cell(matrix, funct)
  if not matrix_is_valid(matrix) then error('matrix not valid') end
  for i=1, #matrix do
    for j=1, #matrix[i] do
      -- if function returns a value it's assigned to cell
      funct(matrix[i][j])
    end
  end
end
