-- PDF outline entries (bookmarks in your viewer pointing to sections)
-- have to be represented in ASCII or UTF-16, so to support
-- non-English section names, we have to convert from UTF-8 (LuaTeX's
-- only supported file encoding) to UTF-16.
--
-- UTF8->UTF16 conversion stolen from
-- /usr/share/texlive/texmf-dist/tex/generic/navigator/navigator.tex
--
-- Tests: test-titlepage

local function to8 (...)
  local arg, str = {...}, ""
  for _, num in ipairs(arg) do
    str = str .. string.format("\\noexpand\\%.3o", num)
  end
  return str
end

function nicstoutf16(str)
  local result = ""
  for c in string.utfvalues(str) do
    if c < 0x10000 then
      result = result .. to8(c / 256, c % 256)
    else
      c = c - 0x10000
      local a, b = c / 1024 + 0xD800, c % 1024 + 0xDC00
      result = result .. to8(a / 256, a % 256, b / 256, b % 256)
    end
  end
  result = [[\noexpand\376\noexpand\377]] .. result
  tex.print(result)
end
