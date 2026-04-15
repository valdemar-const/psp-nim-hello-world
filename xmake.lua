-- xmake.lua
-- Project entry point.
-- All PSP/Nim infrastructure lives in xmake/; this file only describes targets.

includes("xmake/toolchains/pspdev.lua")
includes("xmake/rules/nim_psp.lua")
includes("xmake/rules/psp_executable.lua")

-- xmake does not support user-defined platform() scopes; we declare the
-- cross-compilation target directly and bind the toolchain to the target.
set_plat("cross")
set_arch("mipsel")

target("hello_psp")
    set_kind("binary")
    set_toolchains("pspdev")

    add_rules("psp.nim")
    add_rules("psp.executable")

    add_files("src/main.nim")

    set_values("psp.title", "Hello World")
target_end()
