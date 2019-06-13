local lines = {}

local function doline(env)
  return function(line)
    if line:gsub("%s", ""):sub(1, 6 + #env) == "\\end{" .. env .. "}" then
      -- TODO(errgelow): do we want to push back the remaining line to the TeX input buffer here?
      luatexbase.remove_from_callback("process_input_buffer", "nics_verb_doline")
      return "\\end{" .. env .. "}%"
    else
      lines[#lines+1] = line
      return "%"
    end
  end
end

local alloc = luatexbase.new_luafunction("@nicslfn@verbstart")
tex.print(luatexbase.catcodetables["latex-package"],
          "\\def\\@nicslfn@verbstart{\\luafunction " .. alloc .. "}")
lua.get_functions_table()[alloc] =
  function()
    lines = {}
    luatexbase.add_to_callback("process_input_buffer", doline(tex.toks["@nicstok@verbenv"]), "nics_verb_doline")
  end

local alloc = luatexbase.new_luafunction("@nicslfn@verbend")
tex.print(luatexbase.catcodetables["latex-package"],
          "\\def\\@nicslfn@verbend{\\luafunction " .. alloc .. "}")
lua.get_functions_table()[alloc] =
  function()
    if tex.toks["@nicstok@verbmode"] == 'v' then
      -- If we have been called in vertical mode, then we return an
      -- hbox to hsize, so the whole terminal/code is a full line, we
      -- also center inside this new hbox.
      if tex.count.nicsverbnoautocenter == 1 then
        tex.print("\\hbox to \\hsize{%")
      else
        tex.print("\\hbox to \\hsize{\\hss%")
      end
    elseif tex.toks["@nicstok@verbmode"] == 'h' then
      -- In horizontal mode we return an as tight box as possible, so
      -- this return value can be composed with other ideas (frame,
      -- zooming, putting stuff to the left or to the right, etc.).
    else
      tex.error("@nicslfn@verbend called while @nicstok@verbmode was unset")
    end
    tex.print(luatexbase.catcodetables["latex-package"],
              "{\\colorbox{\\the\\@nicstok@verbbg}{\\vbox{%")
    local gobblerx = ""
    if #lines > 0 then
      local gobble = #lines[1] - #lines[1]:gsub("^ *", "")
      gobblerx = "^" .. string.rep(" ", gobble)
    end
    for _, v in ipairs(lines) do
      tex.print("\\hbox{\\nicsallowlocalpars1\\strut%")
      local quoting = true
      for part in v:gmatch("[^" .. tex.toks.nicsverbescapechar .. "]+") do
        local cctbl = -1
        local commentchar = "%"
        if quoting then
          cctbl = luatexbase.catcodetables["@nicscct@verb"]
          commentchar = ""
        end
        tex.print(cctbl, (part:gsub(gobblerx, "")) .. commentchar)
        quoting = not quoting
      end
      tex.print("}%")
    end
    tex.print("}}}%")
    if tex.toks["@nicstok@verbmode"] == 'v' then
      tex.print("\\hss}")
    end
  end
