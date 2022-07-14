local function guard_reg(regname, f)
  local reg, regtype

  ---@diagnostic disable-next-line: missing-parameter
  reg     = vim.fn.getreg(regname)
  regtype = vim.fn.getregtype(regname)

  local ret = f()

  vim.fn.setreg(regname, reg, regtype)

  return ret
end


local function visual_selected()
  local reg, regtype

  vim.api.nvim_exec("silent normal gvy", false)
  regtype = vim.fn.getregtype('"')

  if regtype == "v" then
    vim.api.nvim_exec("silent normal gvVy", false)
  end

  ---@diagnostic disable-next-line: missing-parameter
  reg     = vim.fn.getreg('"')
  regtype = vim.fn.getregtype('"')

  return reg, regtype
end


local function convert_lines(sep, lines)
  local n              = 0
  local lhss           = {}
  local rhss           = {}
  local outputs        = {}
  local safe_sep       = sep:gsub("([^%w])", "%%%1")
  local lhs_maxlen     = 0
  local current_block  = nil
  local leading_spaces = nil

  for str in (lines.."\n"):gmatch("(.-)\n") do
    local ix, l_ix, r_ix, lhs, rhs

    n = n + 1

    if leading_spaces == nil then
      ix = str:find(safe_sep)
      if ix ~= nil then
        leading_spaces = str:match("^ *"):len()
      end
    end

    if current_block ~= nil then
      l_ix, r_ix = str:match("^ *().-() *$")
      if l_ix >= current_block.col then
        local sub = str:sub(current_block.col, r_ix - 1)
        table.insert(rhss[current_block.ix], sub)

        goto continue
      end
    end

    lhs     = str:match("^ *(.-) *"..safe_sep)
    lhss[n] = lhs
    if lhs ~= nil and lhs:len() > lhs_maxlen then
      lhs_maxlen = lhs:len()
    end

    ix, rhs = str:match(safe_sep.." *()(.-) *$")
    if ix ~= nil then
      rhss[n]       = { rhs }
      current_block = rhs:len() > 0 and { ix = n, col = ix } or nil
    else
      rhss[n]       = { str }
      current_block = nil
    end

    ::continue::
  end

  ---@diagnostic disable-next-line: param-type-mismatch
  local lw = string.rep(" ", leading_spaces or 0)
  local sign_col
  if lhs_maxlen > 0 then
    sign_col = lhs_maxlen + 2
  else
    sign_col = 1
  end

  for i = 1, n do
    local lhs = lhss[i]

    if lhs == nil then
      local rhs = rhss[i]

      if rhs ~= nil then
        table.insert(outputs, rhss[i][1])
      end
    else
      for j, rhs in ipairs(rhss[i]) do
        if j == 1 then
          local lp = string.rep(" ", sign_col - lhs:len() - 1)
          local rp = rhs:len() > 0 and " " or ""
          table.insert(outputs, lw..lhs..lp..sep..rp..rhs)
        else
          local lp = string.rep(" ", sign_col + sep:len())
          table.insert(outputs, lw..lp..rhs)
        end
      end
    end
  end

  return outputs
end


local function visual_replace(text, regtype)
  vim.fn.setreg('"', text, regtype)
  vim.api.nvim_command("normal gvp")
end


local function align_with(sep)
  guard_reg('"', function ()
    local text, regtype = visual_selected()
    local outputs       = convert_lines(sep, text)

    local replacement = table.concat(outputs, "\n")
    visual_replace(replacement, regtype)
  end)
end


return {
  align_with = align_with,
}
