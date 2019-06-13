-- The nics-extern environment makes it easy to render part of the
-- presentation in a new TeX process and then embed the generated PDF
-- to the main presentation.

-- Compared to doing this by hand, the main advantage is that you
-- still only have one slides.tex source file that you can open in
-- your editor.

-- There are two main reasons for doing this: graphical operations
-- (TikZ, include png/jpg with resizing, etc.) are CPU intensive and
-- this mechanism only recompiles the externalized part if the MD5 of
-- the source code changes; if you draw elaborate pictures in TikZ,
-- then you may want to use those outside of your presentation
-- (e.g. in a handout or in marketing materials) and nics-extern can
-- save the exported image for you.
--
-- Tests: test-extern

local md5 = require("md5")
local fs = require("lfs")

local piccount = 1

-- Templates define the structure of the external TeX file, they have
-- three parts: preamble, prebody and postamble.  The final TeX file is
-- constructed like this:
--
---------
-- <preamble template part>
-- \newtoks\nicspwd\nicspwd{<pwd of the main TeX process>}
-- <tex.toks.nicsexternextra>
-- <prebody template part>
-- <the actual body of the environment>
-- <postamble template part>
---------
--
-- The nicspwd is set to make it possible to include images by
-- relative paths.
--
-- The nicsexternextra tokenlist can be used to share common TikZ
-- definitions (pics, colors, etc.) between mutiple slides that follow
-- each other.
local templates = {}

-- The default template just renders tightly to a hbox: the PDF width
-- is set to the width of the box, while the height is set to the
-- depth+height of the box.
templates.default = {}
templates.default.preamble = [[
\documentclass{minimal}
\endofdump
\begin{document}
]]
templates.default.prebody = [[
\setbox0=\hbox{%
]]

templates.default.postamble = [[}
\pagewidth\wd0
\pageheight\dimexpr\ht0+\dp0\relax
\shipout\box0
\end{document}
]]

-- Same as default, but with tcolorbox in usepackage.  tcolorbox is
-- used on titlepages (to give a shadow for the titles, to make sure
-- that they are readable on any background title picture).
templates.tcolorbox = {}
templates.tcolorbox.preamble = [[
\documentclass{minimal}
\endofdump
\usepackage{tcolorbox}
\begin{document}
]]
templates.tcolorbox.prebody = [[
\setbox0=\hbox{%
]]
templates.tcolorbox.postamble = [[}
\pagewidth\wd0
\pageheight\dimexpr\ht0+\dp0\relax
\shipout\box0
\end{document}
]]

-- Our default TikZ setup: tikz loaded, lot of libraries loaded, $
-- catcoded back to math as required by tikZ, a meaningful tikz style
-- called nics defined.
templates.tikz = {}
templates.tikz.preamble = [[
\documentclass{minimal}
\endofdump
\usepackage{tikz}
\usetikzlibrary{arrows.meta,shadows,shapes,positioning,calc,fit,decorations.pathreplacing}
\tikzset{
  nics/.style={
    rounded corners = 2pt,
    text = white,
    cloud ignores aspect, % Otherwise clouds are circular
    align = center, % so that we can have multi line nodes with normal \\ line breaks
    >=latex, % better arrow heads by default
  },
}
\begin{document}
\catcode`\$=3\relax % TikZ is incompatible with $ not being math operator
]]
templates.tikz.prebody = [[
\setbox0=\hbox{%
]]
templates.tikz.postamble = [[}
\pagewidth\wd0
\pageheight\dimexpr\ht0+\dp0\relax
\shipout\box0
\end{document}
]]

-- Inclusion of background pictures are externalized for performance
-- reasons, the related cutting and resizing takes some time for TikZ,
-- so it's better to cached the result.
--
-- The API for this is \nicsbgpic as defined in src/nics-slide.tex.
templates.bgpic = {}
templates.bgpic.preamble = [[
\documentclass{minimal}
\endofdump
\usepackage{tikz}
\usepackage{adjustbox}
\pagewidth 16cm
\pageheight 9cm
\topskip 0pt
\pdfvariable horigin 0pt
\pdfvariable vorigin 0pt
\hoffset 0pt
\voffset 0cm
\begin{document}
\catcode`\$=3\relax % TikZ is incompatible with $ not being math operator
\hsize 16cm\vsize 9cm]]
templates.bgpic.prebody = [[
\shipout\vbox{\tikz[overlay,remember picture]
\node at (8,-4.5) {\adjustbox{min size={16cm}{9cm}}{\includegraphics[width=16cm,height=9cm,keepaspectratio]{]]
templates.bgpic.postamble = [[}}};}
\end{document}
]]

-- The code template handles syntax highlighting for the
-- \nicsexterncode environment.
templates.code = {}
templates.code.preamble = ""
templates.code.prebody = ""
templates.code.postamble = "\n" -- code.sh assumes that the input file ends with a newline character
templates.code.shell = "code.sh"

-- Read src/nics-extern.tex for all the options and the TeX level
-- wrapper functions that are using the below Lua functions

local currentText

-- Useful entrypoint when you want to use nicsextern in a macro, so
-- the process_input_buffer callback trick can't be used.
function nicsexterninline(template, extra, options, name, content)
  tex.toks['@nicstok@externmode'] = 'h'
  tex.toks.nicsexterntemplate = template
  tex.toks.nicsexternextra = extra
  tex.toks['@nicstok@externname'] = name
  if options == nil then
    tex.toks['@nicstok@externoptions'] = "width=\\hsize"
  else
    tex.toks['@nicstok@externoptions'] = options
  end
  currentText = content
  tex.print(nicsexternprocesslines() .. "%")
end

local alloc = luatexbase.new_luafunction("@nicslfn@externstart")
tex.print(luatexbase.catcodetables["latex-package"],
          "\\def\\@nicslfn@externstart{\\luafunction " .. alloc .. "}")
lua.get_functions_table()[alloc] =
  function()
    currentText = ""
    luatexbase.add_to_callback("process_input_buffer", nicsexterndoline, "nicsextern_doline")
  end

function nicsexterndoline(line)
  if line:gsub("%s", ""):sub(1, 16) == "\\end{nicsextern}" then
    -- TODO(errgelow): do we want to push back the remaining line to the TeX input buffer here?
    luatexbase.remove_from_callback("process_input_buffer", "nicsextern_doline")
    return nicsexternprocesslines() .. "\\end{nicsextern}%"
  else
    currentText = (currentText) .. line .. "\n"
    return "%" -- Every line is replaced by a comment from TeX's point of view
  end
end

local names = {}
function nicsexternprocesslines()
  local wd = fs.currentdir()

  -- remove final newline, this makes it possible to create
  -- externalizations without final new line
  local str = currentText:gsub("\n$", "")
  if tex.count['@nicsbool@externinitialwhitespace'] < 1 then
    str = str:gsub("^ *", "")
  end
  local options = tex.toks['@nicstok@externoptions']
  local name = tex.toks['@nicstok@externname']
  if name ~= "" then
    if names[name] then
      print()
      print()
      print()
      print("Duplicated extern name in " .. wd .. "/" .. tex.jobname .. ".tex:" .. symlink)
      print()
      print()
      print()
      os.exit(1)
    else
      names[name] = true
    end
  end

  local template = tex.toks.nicsexterntemplate
  local preamble = templates[template].preamble
  local prebody = templates[template].prebody
  local postamble = templates[template].postamble
  local shell = templates[template].shell
  local shellparam = tex.toks['@nicstok@externshellparam']
  local nicssubdir = "\\newtoks\\nicspwd\\nicspwd{" .. wd .. "/}"
  if tex.count['@nicsbool@externnopwd'] > 0 then
    nicssubdir = ""
  end
  local fullstr = preamble .. nicssubdir .. tex.toks.nicsexternextra .. prebody .. str .. postamble
  local fbasename = md5.sumHEXA(template .. fullstr .. (shellparam or ""))
  local pdfname = fbasename .. ".pdf"
  local texname = fbasename .. ".tex"
  local texnametmp = fbasename .. ".tex.before"
  local logname = fbasename .. ".log"
  local nicsroot = tex.toks.nicsroot

  fs.chdir(nicsroot .. "/extern-build")
  if not fs.isfile(pdfname) then
    local tex
    if shell then
      tex = io.open(texnametmp, "w+")
    else
      tex = io.open(texname, "w+")
    end
    local cmdecho = "% Compile with: make TEMPLATE=" .. template .. " " .. pdfname .. "\n"
    if not shell then
      tex:write(cmdecho)
    end
    tex:write(fullstr)
    tex:close()
    if shell then
      os.remove(texname)
      tex = io.open(texname, "w+")
      tex:write(cmdecho)
      tex:close()
      if 0 ~= os.spawn({"./" .. shell, texname, shellparam}) then
        print()
        print()
        print()
        print("nicsextern pre-command failed for: " .. texname .. "(" .. template .. ")")
        print()
        print()
        print()
        os.exit(1)
      end
      if not fs.isfile(texname) then
        print()
        print()
        print()
        print("nicsextern pre-command didn't produce: " .. texname .. "(" .. template .. ")")
        print()
        print()
        print()
        os.exit(1)
      end
    end
    if 0 ~= os.spawn({"make", "-s", "TEMPLATE=" .. template, pdfname}) then
      print()
      print()
      print()
      print("nics sub-LaTeX failed: " .. texname .. "(" .. template .. ")")
      print("See " .. nicsroot .. "/extern-build/failed.log for details")
      print()
      print()
      print()
      os.remove("failed.tex")
      os.remove("failed.log")
      fs.link(texname, "failed.tex", true)
      fs.link(logname, "failed.log", true)
      os.exit(1)
    end
  end
  if name ~= "" then
    tex.settoks("global", "nicsexternlastname", string.format("%04d", piccount) .. "-" .. name)
    -- We used to have a hard link here, but when using Docker, the
    -- /nics and /slides are two separate bind mounts, therefore it's
    -- not possible to hard link between them.
    local copyfromf = io.open(pdfname, "rb")
    local copytof = io.open(wd .. "/build/named/"  .. tex.toks.nicsexternlastname .. ".pdf", "wb")
    copytof:write(copyfromf:read("*all"))
    copytof:close()
    piccount = piccount + 1
  end
  fs.chdir(wd)
  local ret = ""
  -- Similar vmode/hmode logic as in nicsverb
  if tex.toks['@nicstok@externmode'] == 'v' then
    if tex.count.nicsexternnoautocenter == 1 then
      ret = "\\hbox to \\hsize{"
    else
      ret = "\\hbox to \\hsize{\\hss"
    end
  elseif tex.toks['@nicstok@externmode'] == 'h' then
    -- intentionally left blank
  else
    tex.error("nicsexternprocesslines called while @nicstok@externmode was unset")
  end
  ret = ret .. "{\\nicsallowlocalpars1\\includegraphics[" .. options .. "]{" .. tex.toks.nicsroot .. "/extern-build/" .. pdfname .. "}}"
  if tex.toks['@nicstok@externmode'] == 'v' then
    ret = ret .. "\\hss}"
  end
  return ret
end
