local function protect_register(f)
  local reg, reg_type, old_reg, old_reg_type

  old_reg      = vim.fn.getreg('"')
  old_reg_type = vim.fn.getregtype('"')

  vim.api.nvim_command("normal gvy")
  reg_type = vim.fn.getregtype('"')

  if reg_type == "v" then
    vim.api.nvim_command("normal gvVy")
  end

  reg      = vim.fn.getreg('"')
  reg_type = vim.fn.getregtype('"')

  f(reg, reg_type)

  vim.fn.setreg('"', old_reg, old_reg_type)
end

local function align_with(sign)
  protect_register(function (content)
    local strings = {}
    local outputs = {}
    local l_parts = {}
    local r_parts = {}

    for str in string.gmatch(content, "[^\n]+") do
      strings:insert(str)

      local l_part = str:match("^ *(.-) *"..sign)
      l_parts:insert(l_part)

      local r_part = str:match(sign.." *(.-) *$")
      if r_part ~= nil then
        r_parts:insert(r_part)
      else
        r_parts:insert(str)
      end
    end

    local leading_spaces
    for _, str in ipairs(strings) do
      local l, _ = str:find(sign)

      if l ~= nil then
        leading_spaces = str:match("^ *"):len()
        break
      end
    end

    if leading_spaces == nil then
      return strings
    end

    for i, str in ipairs(strings) do
    end

    local rb = math.max(unpack(sign_ix))

    if rb == 0 then
      return
    end

    for i, str in ipairs(strings) do
      local pos   = sign_ix[i]
      local count = rb - pos

      local lsym = str:sub(1, pos - 1):match("^ *(.-) *$")
      local rsym = str:sub(pos + 1):match("^ *(.*)$")
    end


    for i, v in ipairs(sign_ix) do
    end

    print(vim.inspect(sign_ix))
  end)
end

protect_register(function (reg, reg_type)
end)


-- TODO leading space should always be preserved
-- align_with("=")
