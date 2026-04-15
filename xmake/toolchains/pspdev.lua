-- xmake/toolchains/pspdev.lua
-- PSP toolchain definition for pspdev/pspdev Docker image.
-- Mirrors what psp-cmake's toolchain file does: points to /usr/local/pspdev,
-- sets compiler prefixes, and injects the flags required for PSP/MIPS ABI.

toolchain("pspdev")
    set_kind("standalone")
    set_sdkdir("/usr/local/pspdev")
    set_bindir("/usr/local/pspdev/bin")

    set_toolset("cc",    "psp-gcc")
    set_toolset("cxx",   "psp-g++")
    set_toolset("ld",    "psp-gcc")
    set_toolset("ar",    "psp-ar")
    set_toolset("strip", "psp-strip")
    set_toolset("as",    "psp-gcc")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("psp-gcc", {paths = "/usr/local/pspdev/bin"})
    end)

    on_load(function (toolchain)
        local pspdev    = toolchain:sdkdir()
        local psp_inc   = path.join(pspdev, "psp/include")
        local sdk_inc   = path.join(pspdev, "psp/sdk/include")
        local psp_lib   = path.join(pspdev, "psp/lib")
        local sdk_lib   = path.join(pspdev, "psp/sdk/lib")

        -- Compiler flags
        -- -G0  : no GP-relative addressing — required for PSP MIPS ABI
        -- -DPSP / -D__PSP__ : platform defines expected by pspsdk headers
        toolchain:add("cxflags",
            "-DPSP", "-D__PSP__", "-D_PSP_FW_VERSION=600",
            "-G0",
            "-fomit-frame-pointer",
            "-ffunction-sections", "-fdata-sections",
            "-fno-asynchronous-unwind-tables",
            "-fno-math-errno"
        )
        toolchain:add("includedirs", psp_inc, sdk_inc)

        -- Linker flags
        -- prxspecs / linkfile.prx : produce a relocatable PRX instead of a plain ELF
        -- -Wl,-q              : keep relocs so psp-prxgen can process the file
        -- -Wl,--build-id=none : PSP loader does not understand GNU build-id notes
        -- -lpspsdk last       : contains stub resolver; must follow user libs
        toolchain:add("ldflags",
            "-Wl,--build-id=none",
            "-specs=" .. path.join(sdk_lib, "prxspecs"),
            "-Wl,-T," .. path.join(sdk_lib, "linkfile.prx"),
            "-Wl,-q"
        )
        toolchain:add("linkdirs", psp_lib, sdk_lib)
        toolchain:add("syslinks",
            "pspdebug", "pspdisplay", "pspge",
            "pspctrl", "pspuser", "pspkernel",
            "pspsdk"   -- must be last: contains stub resolver
        )
    end)
toolchain_end()
