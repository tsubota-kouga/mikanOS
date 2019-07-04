
const MaxSheets

type Sheet = object
  buf: ptr cuchar
  bxsize, bysize: int
  vx0, vy0: int
  col_inv, height, flags: int

type SheetControl = object
  vram: ptr cuchar
  xsize, ysize, top: int
  sheets: ptr array[MaxSheets, Sheet]
  sheet0: array[MaxSheets, Sheet]


