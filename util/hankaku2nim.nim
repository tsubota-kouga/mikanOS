
import os, times
import strutils

block:
  let
    fnim: File = open("util/hankaku.nim", FileMode.fmWrite)
    fhankaku: File = open("util/hankaku.txt", FileMode.fmRead)
  defer:
    close(fnim)
    close(fhankaku)

  var lineCounter = 0
  fnim.writeLine "const fonts*: array[256, array[16, int8]] = ["
  while fhankaku.endOfFile == false:
    var line: string = fhankaku.readline()
    if line.startsWith(".") or line.startsWith("*"):
      fnim.writeLine "  ["
      for i in 0..<16:
        line = line.multiReplace([(".", "0"), ("*", "1")])
        line = "0b" & line & "'i8,"
        fnim.writeLine "    " & line
        lineCounter.inc()
        if fhankaku.endOfFile == false:
          line = fhankaku.readline()
      fnim.writeLine "  ],"
    else:
      fnim.writeLine ""
  for i in lineCounter ..< 4096:
    fnim.writeLine "  0b00000000'i8,"
  fnim.writeLine "  ]"

