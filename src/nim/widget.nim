import constant
import util
import display
import sheet

proc createWindow8*(sht: ptr Sheet, title: cstring) =
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
  let
    xsize = sht.bxsize
    ysize = sht.bysize
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

proc createLineEdit8*(sht: ptr Sheet, x0, y0, xsize, ysize: int, color: Color) =
  let
    x1 = x0 + xsize
    y1 = y0 + ysize
  sht.buf.boxfill8(sht.bxsize, Color.gray     , x0 - 2    , y0 - 3    , x1 + 1    , y0 - 3    )
  sht.buf.boxfill8(sht.bxsize, Color.gray     , x0 - 3    , y0 - 3    , x0 + 1    , y1 + 1    )
  sht.buf.boxfill8(sht.bxsize, Color.white    , x0 - 3    , y1 + 2    , x1 + 1    , y1 + 2    )
  sht.buf.boxfill8(sht.bxsize, Color.white    , x1 + 2    , y0 - 3    , x1 + 2    , y1 + 2    )
  sht.buf.boxfill8(sht.bxsize, Color.black    , x0 - 1    , y0 - 2    , x1 + 0    , y0 - 2    )
  sht.buf.boxfill8(sht.bxsize, Color.black    , x0 - 2    , y0 - 2    , x0 - 2    , y1 + 0    )
  sht.buf.boxfill8(sht.bxsize, Color.dark_gray, x0 - 2    , y1 + 1    , x1 + 0    , y1 + 1    )
  sht.buf.boxfill8(sht.bxsize, Color.dark_gray, x1 + 1    , y0 - 2    , x1 + 1    , y1 + 1    )
  sht.buf.boxfill8(sht.bxsize, color          , x0 - 1    , y0 - 1    , x1 + 0    , y1 + 0    )

