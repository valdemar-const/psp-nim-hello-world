-- xmake/rules/nim_psp.lua
-- Rule: "psp.nim"
--
-- Compiles a Nim source file for PSP:
--   1. nim c --compileOnly  →  generates .c files in nimcache/
--   2. Compiles each .c → .o with psp-gcc (using the target's cxflags/includedirs)
--   3. Adds the resulting .o files to the target's link list
--
-- Usage in xmake.lua:
--   add_rules("psp.nim")
--   add_files("src/main.nim")
--
-- Nim flags used:
--   --cpu:mipsel        PSP is MIPS I little-endian
--   --os:standalone     no OS; triggers panicoverride.nim
--   --mm:arc            lightest memory manager; safe for bare-metal
--   --noMain            Nim should not emit its own main(); we write it in .nim
--   --compileOnly       stop after C code generation; xmake drives the rest
--   -d:danger           strip all Nim safety checks (speed, size)
--   -d:noSignalHandler  no signal() calls — PSP SDK doesn't have them

rule("psp.nim")
    set_extensions(".nim")

    on_build_file(function (target, sourcefile, opt)
        import("core.project.depend")
        import("utils.progress")

        -- Directories
        local nimcache = path.join(target:autogendir(), "nimcache")
        local objdir   = path.join(target:autogendir(), "objs")
        os.mkdir(nimcache)
        os.mkdir(objdir)

        -- Collect cflags and includedirs from the target (set by toolchain + target)
        local cflags = {}
        for _, flag in ipairs(target:get("cxflags") or {}) do
            table.insert(cflags, flag)
        end
        for _, inc in ipairs(target:get("includedirs") or {}) do
            table.insert(cflags, "-I" .. inc)
        end

        -- Step 1: Nim → C
        -- We always regenerate; depend tracking is per-object below.
        os.tryrm(nimcache)
        os.mkdir(nimcache)

        local nim_lib = try { function()
            return os.iorun("nim dump --hints:off 2>/dev/null | grep 'lib$'")
        end} or "/usr/lib/nim/lib"
        nim_lib = nim_lib:gsub("%s+", "")

        progress.show(opt.progress, "${color.build.object}nim.compile %s", sourcefile)
        os.vrunv("nim", {
            "c",
            "--cpu:mipsel",
            "--os:standalone",
            "--mm:arc",
            "--noMain",
            "--compileOnly",
            "--nimcache:" .. nimcache,
            "-d:danger",
            "-d:noSignalHandler",
            sourcefile,
        })

        -- Step 2: .c → .o
        -- assertions.nim.c contains only rawoutput/panic, which are already
        -- defined in system.nim.c. Skip it to avoid "multiple definition" errors.
        local c_files = os.files(path.join(nimcache, "*.c"))
        if #c_files == 0 then
            raise("nim produced no .c files for " .. sourcefile)
        end

        for _, cf in ipairs(c_files) do
            if path.basename(cf):find("assertions") then
                -- duplicate of symbols in system.nim.c — skip unconditionally
                goto continue
            end

            local objfile = path.join(objdir, path.basename(cf) .. ".o")
            depend.on_changed(function ()
                progress.show(opt.progress, "${color.build.object}psp-gcc %s", path.filename(cf))
                os.vrunv("psp-gcc", table.join({"-c", "-o", objfile, cf}, cflags))
            end, { files = cf, dependfile = target:dependfile(objfile) })

            -- Register the object file so the linker picks it up
            table.insert(target:objectfiles(), objfile)

            ::continue::
        end
    end)

    -- Clean generated files alongside the normal build artefacts
    on_clean(function (target)
        local nimcache = path.join(target:autogendir(), "nimcache")
        local objdir   = path.join(target:autogendir(), "objs")
        os.tryrm(nimcache)
        os.tryrm(objdir)
    end)
rule_end()
