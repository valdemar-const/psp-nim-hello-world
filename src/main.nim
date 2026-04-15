# src/main.nim
import psp

# --- Callbacks ---

proc exitCallback(arg1: cint; arg2: cint; common: pointer): cint {.exportc, cdecl.} =
  sceKernelExitGame()
  return 0

proc callbackThread(args: SceSize; argp: pointer): cint {.exportc, cdecl.} =
  let cbid = sceKernelCreateCallback("Exit Callback", exitCallback, nil)
  discard sceKernelRegisterExitCallback(cbid)
  sceKernelSleepThreadCB()
  return 0

proc setupCallbacks() =
  let thid = sceKernelCreateThread("update_thread", callbackThread,
                                   0x11, 0xFA0, 0, nil)
  if thid >= 0:
    discard sceKernelStartThread(thid, 0, nil)

# --- Entry point (called from main() in psp.nim) ---

proc nimMain() {.exportc: "nimMain".} =
  setupCallbacks()
  pspDebugScreenInit()
  while true:
    pspDebugScreenSetXY(0, 0)
    pspDebugScreenPrintf("Hello World!")
    sceDisplayWaitVblankStart()
