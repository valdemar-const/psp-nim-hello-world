# panicoverride.nim
# Must be in the project root (same dir as nim.cfg / where nim is invoked from).
# Nim automatically uses this for --os:standalone instead of its default panic.

proc rawoutput(s: string) {.exportc.} =
  discard

proc panic(s: string) {.exportc, noreturn.} =
  while true:
    discard
