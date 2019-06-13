luatexbase.add_to_callback("start_page_number",
                           function ()
                             print("Writing PDF for slide " .. tex.count[0]-1)
                           end,
                           "nics_messages_start_page_number")

luatexbase.add_to_callback("stop_page_number",
                           function ()
                           end,
                           "nics_messages_stop_page_number")

luatexbase.add_to_callback("start_file",
                           function (cat, fname)
                             if cat == 1 then
                               cat = "<src>"
                             end
                             if cat == 2 then
                               cat = "<fmp>"
                             end
                             if cat == 3 then
                               cat = "<pic>"
                             end
                             if cat == 4 then
                               cat = "<fnt>"
                             end
                             if cat == 5 then
                               cat = "<eft>"
                             end
                             print(cat .. " " .. fname)
                           end,
                           "nics_messages_start_file")

luatexbase.add_to_callback("stop_file",
                           function (cat)
                           end,
                           "nics_messages_stop_file")

luatexbase.add_to_callback("hpack_quality",
                           function (incident, detail, head, first, last)
                             print()
                             print()
                             print("ERROR in " .. tex.jobname .. ".tex, Bad hquality: " .. incident .. "(" .. detail .. "), line " .. first .. "-" .. last .. " in a " .. tostring(node.types()[head.id]))
                             print()
                             print()
                             if not os.getenv("NICS_FORCE_QUALITY") then os.exit(1) end
                           end,
                           "nics_messages_hpack_quality")

luatexbase.add_to_callback("vpack_quality",
                           function (incident, detail, head, first, last)
                             print()
                             print()
                             print("ERROR in " .. tex.jobname .. ".tex, Bad vquality: " .. incident .. "(" .. detail .. "), line " .. first .. "-" .. last .. " in a " .. tostring(node.types()[head.id]))
                             print()
                             if not os.getenv("NICS_FORCE_QUALITY") then os.exit(1) end
                           end,
                           "nics_messages_vpack_quality")

luatexbase.add_to_callback("insert_local_par",
                           function (nod, loc)
                             local enforcing = tex.count["@nicsbool@nolocalpars"]
                             local allowing = tex.count.nicsallowlocalpars
                             if allowing == 0 and enforcing == 1 then
                               tex.error("Do not use paragraphs directly in a nicscolumn, use a nicspar/nicsparjust/nicsitem/nicsheader")
                             end
                           end,
                           "nics_messages_insert_local_par")
