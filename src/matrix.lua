--Returns a i_max x j_max size matrix of init_value
function create_matrix(i_max, j_max, gen_init_value)
  a = {}
  for i=1, i_max do
    a[i] = {}
    for j=1, j_max do
      a[i][j] = gen_init_value()
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
  exec_on_each_cell_row(matrix, funct, function () end)
end

function exec_on_each_cell_row(matrix, funct_cell, funct_row)
  assert(matrix_is_valid(matrix), "invalid matrix")
  for i=1, #matrix do
    for j=1, #matrix[i] do
      funct_cell(matrix[i][j])
    end
    funct_row()
  end
end

function matrix_to_string(matrix, to_string, separator_cell, separator_row)
  to_string = to_string or function(cell_val) return cell_val end
  separator_cell = separator_cell or " "
  separator_row = separator_row or "\n"
  row = ""
  build_row = function (cell_val) row = row .. separator_cell .. to_string(cell_val) end
  new_row = function () row = row .. separator_row end
  exec_on_each_cell_row(matrix, build_row, new_row)
  return row
end
