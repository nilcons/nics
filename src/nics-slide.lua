-- We handle page numbers in a tricky way without double runs.

-- The idea is that the nics-slide.tex's \begin{slide}...\end{slide}
-- environment is not doing a shipout itself, just rendering into a
-- \box, that we remember here (in @nicslfn@saveslide).  Once we reach
-- end of document (@nicslfn@finished callback), we go through the saved
-- boxes and ship them out with the slide count.  At this point, we
-- know the total number of slides, so we can render the slide count
-- in current/total format without double runs.

-- We measured the performance impact of this hack, and it's around
-- 2-5%, but actually the important thing is 30% faster: if there are
-- errors, you get them sooner, as no PDF writing had to be done.

local slides = {}

local alloc = luatexbase.new_luafunction("@nicslfn@saveslide")
tex.print(luatexbase.catcodetables["latex-package"],
          "\\def\\@nicslfn@saveslide{\\luafunction " .. alloc .. "}")
lua.get_functions_table()[alloc] =
  function()
    slides[#slides+1] = {}
    slides[#slides].box = tex.count["@nicscnt@currentslide"]
    slides[#slides].page = tex.count["nicspagenumber"]
    print("Slide " .. #slides .. " rendering finished ")
  end

local alloc = luatexbase.new_luafunction("@nicslfn@finished")
tex.print(luatexbase.catcodetables["latex-package"],
          "\\def\\@nicslfn@finished{\\luafunction " .. alloc .. "}")
lua.get_functions_table()[alloc] =
  function()
    for k, v in ipairs(slides) do
      tex.print("\\global\\count0=" .. k .. "\\relax")
      if v.page == 0 then
        tex.print("\\shipout\\vbox{\\unvbox" .. v.box .. "}")
      else
        -- TODO(errgelow): have a callback instead that writes the page number, so the end user can override it
        tex.print("\\shipout\\vbox{\\unvbox" .. v.box .. "\\vbox to 0pt{\\kern8.36cm\\hbox to \\hsize{\\Small \\strut \\hss" .. k .. "/" .. #slides .. "\\kern3mm}\\vss}}")
      end
    end
  end

tex.print(luatexbase.catcodetables["latex-package"],
          "\\AtEndDocument{\\@nicslfn@finished}")

tex.toks.nicspwd = require("lfs").currentdir() .. "/"
