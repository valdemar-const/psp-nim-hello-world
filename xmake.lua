-- xmake.lua

set_plat("psp")
set_arch("mips")

toolchain("pspdev")
    set_kind("standalone")
    set_sdkdir("/usr/local/pspdev")

    set_toolset("cc", "psp-gcc")
    set_toolset("cxx", "psp-g++")
    set_toolset("ld", "psp-gcc")
    set_toolset("ar", "psp-ar")
    set_toolset("strip", "psp-strip")
toolchain_end()

set_toolchains("pspdev")

local PSPDEV     = "/usr/local/pspdev"
local PSP_INC    = PSPDEV .. "/psp/include"
local PSP_SDK_INC= PSPDEV .. "/psp/sdk/include"
local PSP_LIB    = PSPDEV .. "/psp/lib"
local PSP_SDK_LIB= PSPDEV .. "/psp/sdk/lib"
local NIM_LIB    = "/usr/lib/nim/lib"

local CFLAGS = table.concat({
    "-DPSP", "-D__PSP__", "-D_PSP_FW_VERSION=600",
    "-G0",
    "-O2", "-DNDEBUG",
    "-fomit-frame-pointer", "-ffunction-sections", "-fdata-sections",
    "-fno-asynchronous-unwind-tables", "-fno-math-errno",
    "-I" .. PSP_INC,
    "-I" .. PSP_SDK_INC,
    "-I" .. NIM_LIB,
}, " ")

local LDFLAGS = table.concat({
    "-Wl,--build-id=none",
    "-specs=" .. PSP_SDK_LIB .. "/prxspecs",
    "-Wl,-T," .. PSP_SDK_LIB .. "/linkfile.prx",
    "-Wl,-q",
    "-L" .. PSP_LIB,
    "-L" .. PSP_SDK_LIB,
    "-lpspdebug", "-lpspdisplay", "-lpspge",
    "-lpspctrl", "-lpspuser", "-lpspkernel", "-lpspsdk",
}, " ")

target("hello_psp")
    set_kind("phony")  -- we drive the build ourselves

    on_build(function (target)
        local objdir  = "build/objs"
        local outdir  = "build/psp/mips/release"
        local elf     = outdir .. "/hello_psp"

        -- 1. Generate C from Nim
        print(">>> Cleaning nimcache...")
        os.rmdir("nimcache")
        os.mkdir("nimcache")
        print(">>> Running nim...")
        os.exec(table.concat({
            "nim c",
            "--cpu:mipsel",
            "--os:standalone",
            "--mm:arc",
            "--noMain",
            "--compileOnly",
            "--nimcache:nimcache",
            "-d:danger",
            "-d:noSignalHandler",
            "src/main.nim",
        }, " "))

        local c_files = os.files("nimcache/*.c")
        if #c_files == 0 then
            raise("Nim produced no .c files")
        end
        print(">>> Nim generated " .. #c_files .. " .c file(s).")

        -- 2. Compile each .c -> .o
        -- assertions.nim.c contains ONLY rawoutput/panic, which are already
        -- defined in system.nim.c. Skip it unconditionally to avoid
        -- "multiple definition" linker errors.
        os.mkdir(objdir)
        local obj_files = {}
        for _, cf in ipairs(c_files) do
            local basename = path.basename(cf)
            if basename:find("assertions") then
                print(">>> Skipping (duplicate symbols): " .. basename)
                goto continue
            end
            local obj = objdir .. "/" .. basename .. ".o"
            os.exec(table.concat({
                "psp-gcc -c",
                CFLAGS,
                "-o", obj, cf,
            }, " "))
            table.insert(obj_files, obj)
            ::continue::
        end

        -- 3. Link
        os.mkdir(outdir)
        local ld_cmd = table.concat({
            "psp-gcc",
            table.concat(obj_files, " "),
            "-o", elf,
            LDFLAGS,
            "-v",
        }, " ")
        print(">>> Link cmd: " .. ld_cmd)
        os.exec(ld_cmd)

        print(">>> Linked: " .. elf)
    end)

    after_build(function (target)
        local outdir = "build/psp/mips/release"
        local elf    = outdir .. "/hello_psp"
        local prx    = outdir .. "/hello_psp.prx"
        local sfo    = outdir .. "/PARAM.SFO"
        local eboot  = outdir .. "/EBOOT.PBP"

        os.exec("psp-fixup-imports " .. elf)
        os.exec("psp-prxgen " .. elf .. " " .. prx)
        os.exec("mksfo 'Hello World' " .. sfo)
        os.exec(table.concat({
            "pack-pbp", eboot, sfo,
            "NULL", "NULL", "NULL", "NULL", "NULL",
            prx, "NULL",
        }, " "))

        print(">>> Built: " .. eboot)
    end)
