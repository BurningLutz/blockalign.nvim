local fn = vim.fn


local function guard_reg(regname, f)
  local reg, regtype

  reg     = fn.getreg(regname)
  regtype = fn.getregtype(regname)

  local ret = f()

  fn.setreg(regname, reg, regtype)

  return ret
end


local function visual_selected()
  local reg, regtype

  vim.cmd "silent normal gvzy"
  regtype = fn.getregtype('"')

  if regtype == "v" then
    vim.cmd "silent normal gvVzy"
  end

  reg     = fn.getreg('"')
  regtype = fn.getregtype('"')

  return reg, regtype
end


local function convert_lines(sep, lines, padding)
  local n              = 0
  local lhss           = {}
  local rhss           = {}
  local outputs        = {}
  local safe_sep       = sep:gsub("([^%w])", "%%%1")
  local lhs_maxlen     = 0
  local current_block  = nil
  local leading_spaces = nil

  for str in (lines.."\n"):gmatch("(.-)\n") do
    local ix, lhs, rhs

    n = n + 1

    if leading_spaces == nil then
      ix = str:find(safe_sep)
      if ix ~= nil then
        leading_spaces = str:match("^ *"):len()
      end
    end

    if current_block ~= nil then
      local lix, rix = str:match("^ *().-() *$")
      local lix_u    = lix <= str:len() and vim.str_utfindex(str, lix) or lix

      if lix_u >= current_block.col then
        lix       = vim.str_byteindex(str, current_block.col)
        local sub = str:sub(lix, rix - 1)

        table.insert(rhss[current_block.ix], sub)

        goto continue
      end
    end

    lhs     = str:match("^ *(.-) *"..safe_sep)
    lhss[n] = lhs
    if lhs ~= nil then
      lhs_maxlen = math.max(lhs_maxlen, vim.str_utfindex(lhs))
    end

    ix, rhs = str:match(safe_sep.." *()(.-) *$")
    if ix ~= nil then
      local ix_u    = ix <= str:len() and vim.str_utfindex(str, ix) or ix
      rhss[n]       = { rhs }
      current_block = rhs:len() > 0 and { ix = n, col = ix_u } or nil
    else
      rhss[n]       = { str }
      current_block = nil
    end

    ::continue::
  end

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
          local lhs_len = vim.str_utfindex(lhs)
          local lp      = string.rep(" ", sign_col - lhs_len + padding - 2)
          local rp      = rhs:len() > 0 and string.rep(" ", padding) or ""

          table.insert(outputs, lw..lhs..lp..sep..rp..rhs)
        else
          local sep_len = vim.str_utfindex(sep)
          local lp      = string.rep(" ", sign_col + sep_len + padding - 1)

          table.insert(outputs, lw..lp..rhs)
        end
      end
    end
  end

  return outputs
end


local function visual_replace(text, regtype)
  fn.setreg('"', text, regtype)
  vim.cmd "normal gvp"
end


local function align_with(sep, has_padding)
  guard_reg('"', function ()
    local padding       = has_padding and 1 or 0
    local text, regtype = visual_selected()
    local outputs       = convert_lines(sep, text, padding)

    local replacement = table.concat(outputs, "\n")
    visual_replace(replacement, regtype)
  end)
end


return { align_with = align_with
       }
