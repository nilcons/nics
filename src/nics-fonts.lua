tex.print("\\usepackage{fontspec}")

local fontpath = tex.toks.nicsroot .. "/fonts/"

local usefont = function(name, font)
  tex.print("\\set" .. name .. "font[" ..
              "Path = " .. fontpath .. "," ..
              "BoldFont = " .. font .. "-Bold.ttf," ..
              "ItalicFont = " .. font .. "-Italic.ttf," ..
              "BoldItalicFont = " .. font .. "-BoldItalic.ttf," ..
              "]{" .. font .. ".ttf}"
  )
end

usefont("sans", "NICS-DejaVuSans")   -- use with {\sffamily foobar} or \textsf{foobar}
usefont("roman", "NICS-DejaVuSerif") -- use with {\rmfamily foobar} or \textrm{foobar}
usefont("mono", "NICS-GoMono")       -- use with {\ttfamily foobar} or \texttt{foobar}

-- use with {\lightfont foobar}, used for image attributions
tex.print("\\newfontface\\lightfont[Path=" .. fontpath .. "]{NICS-DejaVuSans-ExtraLight.ttf}")
