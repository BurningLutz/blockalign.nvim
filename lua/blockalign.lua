local function protect_register(f)
  local reg, reg_type, old_reg, old_reg_type

  ---@diagnostic disable-next-line: missing-parameter
  old_reg      = vim.fn.getreg('"')
  old_reg_type = vim.fn.getregtype('"')

  vim.api.nvim_exec("silent normal gvy", false)
  reg_type = vim.fn.getregtype('"')

  if reg_type == "v" then
    vim.api.nvim_exec("silent normal gvVy", false)
  end

  ---@diagnostic disable-next-line: missing-parameter
  reg      = vim.fn.getreg('"')
  reg_type = vim.fn.getregtype('"')

  local ret = f(reg, reg_type)

  vim.fn.setreg('"', old_reg, old_reg_type)

  return ret
end


local function convert_lines(sign, lines)
  local strings = {}
  local outputs = {}
  local l_parts = {}
  local r_parts = {}
  local sign_col = 1
  local current_block = nil
  local current_block_col = nil
  local leading_spaces = nil

  local n = 0
  for str in lines:gmatch("[^\n]+") do
    n = n + 1

    table.insert(strings, str)

    if leading_spaces == nil then
      local ix = str:find(sign)
      if ix ~= nil then
        leading_spaces = str:match("^ *"):len()
      end
    end

    if current_block ~= nil then
      local l_ix, r_ix = str:match("^ *().-() *$")
      if l_ix >= current_block_col then
        local sub = str:sub(current_block_col, r_ix - 1)
        table.insert(r_parts[current_block], sub)

        goto continue
      end
    end

    local l_part = str:match("^ *(.-) *"..sign) or ""
    table.insert(l_parts, l_part)
    if l_part:len() > sign_col then
      sign_col = l_part:len()
    end

    local ix, r_part = str:match(sign.." *()(.-) *$")
    if ix ~= nil then
      table.insert(r_parts, {r_part})
      current_block = n
      current_block_col = ix
    else
      table.insert(r_parts, {str})
      current_block = nil
      current_block_col = nil
    end

    ::continue::
  end

  sign_col = sign_col + 1
  ---@diagnostic disable-next-line: param-type-mismatch
  local lw = string.rep(" ", leading_spaces)

  for i, l in ipairs(l_parts) do
    if l:len() == 0 then
      table.insert(outputs, r_parts[i][1])
    else
      for j, r in ipairs(r_parts[i]) do
        if j == 1 then
          local lp = string.rep(" ", sign_col - l:len())
          local rp = " "
          table.insert(outputs, lw..l..lp..sign..rp..r)
        else
          local lp = string.rep(" ", sign_col + sign:len() + 1)
          table.insert(outputs, lw..lp..r)
        end
      end
    end
  end

  return outputs
end


local function align_with(sign)
  protect_register(function (lines, reg_type)
    local outputs = convert_lines(sign, lines)

    local output = table.concat(outputs, "\n")
    vim.fn.setreg('"', output, reg_type)
    vim.api.nvim_command("normal gvp")
  end)
end


return {
  align_with = align_with,
}
