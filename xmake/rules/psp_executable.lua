-- xmake/rules/psp_executable.lua
-- Rule: "psp.executable"
--
-- Post-link pipeline that turns the linked ELF into a runnable PSP package:
--   ELF  →  psp-fixup-imports  →  psp-prxgen  →  PRX
--   PRX  +  mksfo              →  EBOOT.PBP
--
-- The rule reads two optional target values so the caller can customise the
-- package metadata without touching infrastructure code:
--
--   set_values("psp.title",      "My Game")      -- shown in XMB (default: target name)
--   set_values("psp.title_id",   "MYGA00001")    -- 9-char, optional
--
-- Usage in xmake.lua:
--   add_rules("psp.executable")

rule("psp.executable")

    after_link(function (target)
        import("utils.progress")

        local elf    = target:targetfile()
        local outdir = path.directory(elf)
        local stem   = path.basename(elf)
        local prx    = path.join(outdir, stem .. ".prx")
        local sfo    = path.join(outdir, "PARAM.SFO")
        local eboot  = path.join(outdir, "EBOOT.PBP")

        -- Optional metadata from the target description
        local title = (target:get("values") or {})["psp.title"]
                   or target:name()

        -- Step 1: fix up import stubs in the ELF
        progress.show(100, "${color.build.target}psp-fixup-imports %s", path.filename(elf))
        os.vrunv("psp-fixup-imports", { elf })

        -- Step 2: convert ELF → PRX
        progress.show(100, "${color.build.target}psp-prxgen %s", path.filename(prx))
        os.vrunv("psp-prxgen", { elf, prx })

        -- Step 3: create PARAM.SFO with the game title
        progress.show(100, "${color.build.target}mksfo '%s'", title)
        os.vrunv("mksfo", { title, sfo })

        -- Step 4: pack everything into EBOOT.PBP
        -- Argument order: EBOOT.PBP SFO ICON0 ICON1 PIC0 PIC1 SND0 DATA.PSP DATA.PSAR
        -- NULL means "no file" for the optional slots.
        progress.show(100, "${color.build.target}pack-pbp %s", path.filename(eboot))
        os.vrunv("pack-pbp", {
            eboot, sfo,
            "NULL", "NULL", "NULL", "NULL", "NULL",
            prx, "NULL",
        })

        cprint("${bright green}[PSP]${reset} %s → %s (%d bytes)",
            path.filename(elf), path.filename(eboot), os.filesize(eboot))
    end)

    -- Remove PSP artefacts on xmake clean
    on_clean(function (target)
        local elf    = target:targetfile()
        local outdir = path.directory(elf)
        local stem   = path.basename(elf)
        os.tryrm(path.join(outdir, stem .. ".prx"))
        os.tryrm(path.join(outdir, "PARAM.SFO"))
        os.tryrm(path.join(outdir, "EBOOT.PBP"))
    end)

rule_end()
