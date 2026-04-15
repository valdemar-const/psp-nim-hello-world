# src/main.nim

# --- PSP SDK bindings ---

type SceSize = cint
type SceUID = cint

proc sceKernelExitGame() {.importc, header: "<pspkernel.h>".}
proc sceKernelCreateCallback(name: cstring, cb: pointer, arg: pointer): SceUID
  {.importc, header: "<pspkernel.h>".}
proc sceKernelRegisterExitCallback(cbid: SceUID): cint
  {.importc, header: "<pspkernel.h>".}
proc sceKernelSleepThreadCB() {.importc, header: "<pspkernel.h>".}
proc sceKernelCreateThread(name: cstring, entry: pointer, initPriority: cint,
                           stackSize: cint, attr: cint, opt: pointer): SceUID
  {.importc, header: "<pspkernel.h>".}
proc sceKernelStartThread(thid: SceUID, arglen: SceSize, argp: pointer): cint
  {.importc, header: "<pspkernel.h>".}
proc sceDisplayWaitVblankStart() {.importc, header: "<pspdisplay.h>".}

proc pspDebugScreenInit() {.importc, header: "<pspdebug.h>".}
proc pspDebugScreenSetXY(x: cint, y: cint) {.importc, header: "<pspdebug.h>".}
proc pspDebugScreenPrintf(fmt: cstring) {.importc, header: "<pspdebug.h>", varargs.}

# --- PSP module boilerplate ---
# "/*TYPESECTION*/" makes Nim place this emit after all includes/typedefs
# so PSP_MODULE_INFO macro is already defined when invoked.
{.emit: """/*TYPESECTION*/
#include <pspkernel.h>
PSP_MODULE_INFO("Hello World", 0, 1, 0);
PSP_MAIN_THREAD_ATTR(PSP_THREAD_ATTR_USER);
""".}

# --- Callbacks ---

proc exitCallback(arg1: cint, arg2: cint, common: pointer): cint {.exportc, cdecl.} =
  sceKernelExitGame()
  return 0

proc callbackThread(args: SceSize, argp: pointer): cint {.exportc, cdecl.} =
  let cbid = sceKernelCreateCallback("Exit Callback", exitCallback, nil)
  discard sceKernelRegisterExitCallback(cbid)
  sceKernelSleepThreadCB()
  return 0

proc setupCallbacks() =
  let thid = sceKernelCreateThread("update_thread", callbackThread,
                                   0x11, 0xFA0, 0, nil)
  if thid >= 0:
    discard sceKernelStartThread(thid, 0, nil)

# --- Entry point ---
# NimMain is called from the C main() below; then we call nimMain (our logic)

proc nimMain() {.exportc: "nimMain".} =
  setupCallbacks()
  pspDebugScreenInit()
  while true:
    pspDebugScreenSetXY(0, 0)
    pspDebugScreenPrintf("Hello World!")
    sceDisplayWaitVblankStart()

{.emit: """
void NimMain(void);

int main(int argc, char *argv[]) {
  NimMain();
  nimMain();
  return 0;
}
""".}
