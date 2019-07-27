import constant
import util
import display
import sheet

proc createWindow8*(sht: ptr Sheet, xsize, ysize: int, title: cstring) =
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
  sht.buf.boxfill8(xsize, Color.gray     , 0         , 0         , xsize - 1 , 0         )
  sht.buf.boxfill8(xsize, Color.black    , 1         , 1         , xsize - 2 , 1         )
  sht.buf.boxfill8(xsize, Color.gray     , 0         , 0         , 0         , ysize - 1 )
  sht.buf.boxfill8(xsize, Color.white    , 1         , 1         , 1         , ysize - 2 )
  sht.buf.boxfill8(xsize, Color.dark_gray, xsize - 2 , 1         , xsize - 2 , ysize - 2 )
  sht.buf.boxfill8(xsize, Color.black    , xsize - 1 , 0         , xsize - 1 , ysize - 1 )
  sht.buf.boxfill8(xsize, Color.gray     , 2         , 2         , xsize - 3 , ysize - 3 )
  sht.buf.boxfill8(xsize, Color.dark_gray , 3         , 3         , xsize - 4 , 20        )
  sht.buf.boxfill8(xsize, Color.dark_gray, 1         , ysize - 2 , xsize - 2 , ysize - 2 )
  sht.buf.boxfill8(xsize, Color.black    , 0         , ysize - 1 , xsize - 1 , ysize - 1 )
  sht.buf.putasc8(xsize, 24, 4, Color.black, title)
  for y in 0 ..< 14:
    for x in 0 ..< 16:
      let c = CLOSEBUTTON[y][x]
      sht.buf[(5 + y)*xsize + (xsize - 21 + x)] =
        case CLOSEBUTTON[y][x]:
          of '.':
            Color.black
          of '$':
            Color.dark_gray
          of '%':
            Color.gray
          else:
            Color.white

