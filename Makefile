BIN = bootjack
SRC = "$(BIN).asm"

default: 	build

build:		build_img build_com check_size

build_img:
			nasm -f bin -l "$(BIN).lst" -o "$(BIN).img" $(SRC)

build_com:
			nasm -f bin -l "$(BIN).lst" -o "$(BIN).com" -Dcom_file=1 $(SRC)

qemu:		build
			qemu-system-i386 -drive file="$(BIN).img",format=raw,index=0,media=disk

check_size:
			stat --printf="size: %s byte(s)\n" "$(BIN).com"

clean:
			rm -f *.o *.lst *.img *.com
