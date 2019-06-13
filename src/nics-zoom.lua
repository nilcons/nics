-- The command \nicszoom[<target dimen>]{box content} zooms the
-- content to the target size horizontally.  It would definitely be
-- possible to do same for vertical zooming, but in practice,
-- horizontal space is the scarce resource and since we keep aspect
-- ratio, you can kind of zoom vertically by zooming horizontally.
--
-- <target dimen> is optional and defaults to \hsize.
--
-- The main implementation trick here is that \nicszoom is actually a
-- one-parameter macro that evaluates to a \hbox at the end of the
-- substitution, so the box content looks like a parameter, but
-- actually it's not.  Therefore it's compatible with most of the
-- other constructs.
--
-- Most of this is just a simplified version of the adjustbox package.

local alloc = luatexbase.new_luafunction("@nicslfn@dozoom")
tex.print(luatexbase.catcodetables["latex-package"],
          "\\def\\@nicslfn@dozoom{\\ifhmode\\@nicstok@zoommode{h}\\else\\ifvmode\\@nicstok@zoommode{v}\\fi\\fi\\luafunction " .. alloc .. "}")
lua.get_functions_table()[alloc] =
  function()
    local mode
    if tex.toks["@nicstok@zoommode"] == 'v' then
      -- If we have been called in vertical mode, then we return an
      -- hbox, so the whole terminal/code is a full line, we also
      -- center it (unless nicszoomnoautocenter is 1).
      mode = 'v'
    elseif tex.toks["@nicstok@zoommode"] == 'h' then
      -- In horizontal mode we return an as tight box as possible, so
      -- this return value can be composed with other ideas.
      mode = 'h'
    else
      tex.error("internal error: nicszoom called and @nicstok@zoommode remained unset")
    end
    local ratio = string.format("%.10f", tex.dimen["@nicsdmn@zoomtarget"] / tex.box["@nicsbox@zoomsave"].width)
    if (ratio == "inf") then
      tex.error("Infinite zooming required in nicszoom")
    end
    local newwidth  = tex.box["@nicsbox@zoomsave"].width  * ratio
    local newdepth  = tex.box["@nicsbox@zoomsave"].depth  * ratio
    local newheight = tex.box["@nicsbox@zoomsave"].height * ratio
    tex.box["@nicsbox@zoomsave"].width = 0
    tex.box["@nicsbox@zoomsave"].height = 0
    tex.box["@nicsbox@zoomsave"].depth = 0
    tex.print(luatexbase.catcodetables["latex-package"],
              "\\setbox\\@nicsbox@zoomrender\\hbox" ..
                "{\\pdfextension save\\relax\\pdfextension setmatrix {" .. ratio .. " 0 0 " .. ratio .. "}\\relax" ..
                "\\box\\@nicsbox@zoomsave\\pdfextension restore\\relax}%")
    tex.print(luatexbase.catcodetables["latex-package"], "\\wd\\@nicsbox@zoomrender " .. newwidth .. "sp\\relax%")
    tex.print(luatexbase.catcodetables["latex-package"], "\\dp\\@nicsbox@zoomrender " .. newdepth .. "sp\\relax%")
    tex.print(luatexbase.catcodetables["latex-package"], "\\ht\\@nicsbox@zoomrender " .. newheight .. "sp\\relax%")
    if mode == 'v' then
      if tex.count.nicszoomnoautocenter == 1 then
        tex.print(luatexbase.catcodetables["latex-package"], "\\hbox to \\hsize{\\copy\\@nicsbox@zoomrender\\hss}")
      else
        tex.print(luatexbase.catcodetables["latex-package"], "\\hbox to \\hsize{\\hss\\copy\\@nicsbox@zoomrender\\hss}")
      end
    else
      tex.print(luatexbase.catcodetables["latex-package"], "\\copy\\@nicsbox@zoomrender%")
    end
  end
