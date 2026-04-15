# src/psp.nim
# PSP SDK bindings and required module boilerplate.
#
# Import this module in any PSP Nim program instead of declaring bindings inline.
# The {.emit.} blocks here inject the C code that the PSP linker requires
# (PSP_MODULE_INFO, PSP_MAIN_THREAD_ATTR) exactly once, in the right place.

# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------

type
  SceSize* = cint
  SceUID*  = cint

# ---------------------------------------------------------------------------
# pspkernel.h
# ---------------------------------------------------------------------------

proc sceKernelExitGame*() {.importc, header: "<pspkernel.h>".}

proc sceKernelCreateCallback*(name: cstring; cb: pointer; arg: pointer): SceUID
  {.importc, header: "<pspkernel.h>".}

proc sceKernelRegisterExitCallback*(cbid: SceUID): cint
  {.importc, header: "<pspkernel.h>".}

proc sceKernelSleepThreadCB*() {.importc, header: "<pspkernel.h>".}

proc sceKernelCreateThread*(name: cstring; entry: pointer; initPriority: cint;
                             stackSize: cint; attr: cint; opt: pointer): SceUID
  {.importc, header: "<pspkernel.h>".}

proc sceKernelStartThread*(thid: SceUID; arglen: SceSize; argp: pointer): cint
  {.importc, header: "<pspkernel.h>".}

# ---------------------------------------------------------------------------
# pspdisplay.h
# ---------------------------------------------------------------------------

proc sceDisplayWaitVblankStart*() {.importc, header: "<pspdisplay.h>".}

# ---------------------------------------------------------------------------
# pspdebug.h
# ---------------------------------------------------------------------------

proc pspDebugScreenInit*() {.importc, header: "<pspdebug.h>".}
proc pspDebugScreenSetXY*(x: cint; y: cint) {.importc, header: "<pspdebug.h>".}
proc pspDebugScreenPrintf*(fmt: cstring) {.importc, header: "<pspdebug.h>", varargs.}

# ---------------------------------------------------------------------------
# Required PSP module declaration macros
#
# "/*TYPESECTION*/" instructs Nim to place this emit block after all generated
# #include / typedef lines, ensuring PSP_MODULE_INFO is already defined.
# These macros must appear exactly once per PRX; psp.nim is that one place.
# ---------------------------------------------------------------------------

{.emit: """/*TYPESECTION*/
#include <pspkernel.h>
PSP_MODULE_INFO("Hello World", 0, 1, 0);
PSP_MAIN_THREAD_ATTR(PSP_THREAD_ATTR_USER);
""".}

# ---------------------------------------------------------------------------
# C entry point shim
#
# Nim generates NimMain() (runtime init) but not a C main().
# We declare NimMain here and define main() so the PSP CRT can call it.
# nimMain() (lowercase) is the user-defined entry point in main.nim.
# ---------------------------------------------------------------------------

proc nimMain*() {.exportc: "nimMain", importc: "nimMain".}

{.emit: """
void NimMain(void);

int main(int argc, char *argv[]) {
    NimMain();
    nimMain();
    return 0;
}
""".}
