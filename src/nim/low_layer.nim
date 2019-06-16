
proc io_hlt*() {.importc.}
proc io_cli*() {.importc.}
proc io_sti*() {.importc.}
proc io_stihlt*() {.importc.}

proc io_in8*(port: cint): cint {.importc.}
proc io_in16*(port: cint): cint {.importc.}
proc io_in32*(port: cint): cint {.importc.}

proc io_out8*(port: uint16, data: uint16) {.importc.}
proc io_out16*(port, data: cint) {.importc.}
proc io_out32*(port, data: cint) {.importc.}

proc io_load_eflags*(): cint {.importc.}
proc io_store_eflags*(eflags: cint) {.importc.}

proc load_gdtr*(limit, address: cint) {.importc.}
proc load_idtr*(limit, address: cint) {.importc.}

