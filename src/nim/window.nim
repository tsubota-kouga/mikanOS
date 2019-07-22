import constant
import util
import display

proc createWindow8*(vram: Vram, xsize, ysize: int, title: cstring) =
  const CLOSEBUTTON = [
    "ooooooooooooooo.",
    "o%%%%%%%%%%%%%$.",
    "o%%%%%%%%%%%%%$.",
    "o%%%##%%%%##%%$.",
    "o%%%%##%%##%%%$.",
    "o%%%%%####%%%%$.",
    "o%%%%%%##%%%%%$.",
    "o%%%%%####%%%%$.",
    "o%%%%##%%##%%%$.",
    "o%%%##%%%%##%%$.",
    "o%%%%%%%%%%%%%$.",
    "o%%%%%%%%%%%%%$.",
    "o$$$$$$$$$$$$$$.",
    "................"
  ]
  vram.boxfill8(xsize, Color.gray     , 0         , 0         , xsize - 1 , 0         )
  vram.boxfill8(xsize, Color.black    , 1         , 1         , xsize - 2 , 1         )
  vram.boxfill8(xsize, Color.gray     , 0         , 0         , 0         , ysize - 1 )
  vram.boxfill8(xsize, Color.white    , 1         , 1         , 1         , ysize - 2 )
  vram.boxfill8(xsize, Color.dark_gray, xsize - 2 , 1         , xsize - 2 , ysize - 2 )
  vram.boxfill8(xsize, Color.black    , xsize - 1 , 0         , xsize - 1 , ysize - 1 )
  vram.boxfill8(xsize, Color.gray     , 2         , 2         , xsize - 3 , ysize - 3 )
  vram.boxfill8(xsize, Color.dark_gray , 3         , 3         , xsize - 4 , 20        )
  vram.boxfill8(xsize, Color.dark_gray, 1         , ysize - 2 , xsize - 2 , ysize - 2 )
  vram.boxfill8(xsize, Color.black    , 0         , ysize - 1 , xsize - 1 , ysize - 1 )
  vram.putasc8(xsize, 24, 4, Color.black, title)
  for y in 0 ..< 14:
    for x in 0 ..< 16:
      let c = CLOSEBUTTON[y][x]
      vram[(5 + y)*xsize + (xsize - 21 + x)] =
        case CLOSEBUTTON[y][x]:
          of '.':
            Color.black
          of '$':
            Color.dark_gray
          of '%':
            Color.gray
          else:
            Color.white

