
const
  PIC0_ICW1 = 0x0020
  PIC0_OCW2 = 0x0020
  PIC0_IMR = 0x0021
  PIC0_ICW2 = 0x0021
  PIC0_ICW3 = 0x0021
  PIC0_ICW4 = 0x0021
  PIC1_ICW1 = 0x00a0
  PIC1_OCW2 = 0x00a0
  PIC1_IMR = 0x00a1
  PIC1_ICW2 = 0x00a1
  PIC1_ICW3 = 0x00a1
  PIC1_ICW4 = 0x00a1

proc init_pic() =
  io_out8(PIC0_IMR, 0xff)  # prohibit interrupt
  io_out8(PIC1_IMR, 0xff)  # prohibit interrupt

  io_out8(PIC0_ICW1, 0x11)  # edge trigger mode
  io_out8(PIC0_ICW2, 0x20)  # catch IRQ0-7 with INT20-27
  io_out8(PIC0_ICW3, 1 shl 2)  # PIC1 is connected with IRQ2
  io_out8(PIC0_ICW4, 0x01)  # non buffer mode

  io_out8(PIC1_ICW1, 0x11)  #edge trigger mode
  io_out8(PIC1_ICW2, 0x28)  # catch IRQ0-7 with INT20-27
  io_out8(PIC1_ICW3, 2)  # PIC1 is connected with IRQ2
  io_out8(PIC1_ICW4, 0x01)  # non buffer mode

  io_out8(PIC0_IMR, 0xfb)  # only PIC1
  io_out8(PIC1_IMR, 0xff)  # prohibit all interrupt

proc inthandler21(esp: ptr cint) {.exportc.} =
  binfo[].boxfill8(Color.black, 0, 0, 32 * 8 - 1, 15)
  binfo[].putfont8_asc(0, 0, Color.white, "INT 21 (IRQ-12) : PS/2 keyboard")
  while true:
    io_hlt()

proc inthandler2c(esp: ptr cint) {.exportc.} =
  binfo[].boxfill8(Color.black, 0, 0, 32 * 8 - 1, 15)
  binfo[].putfont8_asc(0, 0, Color.white, "INT 2C (IRQ-12) : PS/2 mouse")
  while true:
    io_hlt()

proc inthandler27(esp: ptr cint) {.exportc.} =
  io_out8(PIC0_OCW2, 0x67)

