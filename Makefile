BIN = bootjack
SRC = "$(BIN).asm"
QEMU = qemu-system-i386

default: build

build:
		nasm -f bin -o $(BIN) $(SRC)

qemu:	build
		$(QEMU) -hda $(BIN)

clean:
		rm -f *.o $(BIN)
