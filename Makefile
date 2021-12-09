BIN = bootjack
SRC = "$(BIN).asm"

AS = nasm
LD = ld
GDB = gdb
QEMU = qemu-system-i386

QEMU_FLAGS = -drive format=raw,index=0,media=disk,file="$(BIN).img"
#-drive format=raw,index=0,if=floppy,file="$(BIN).img"

default: 	build

build:		build_img build_com check_size

build_img:
			$(AS) -f bin -o "$(BIN).img" $(SRC)

build_com:
			$(AS) -f bin -l "$(BIN).lst" -o "$(BIN).com" -Dcom_file=1 $(SRC)

qemu:		build
			$(QEMU) $(QEMU_FLAGS)

check_size:
			stat --printf="size: %s byte(s)\n" "$(BIN).com"

clean:
			rm -f *.o *.lst *.elf *.img *.com

# debugging ... couldn't quite get it, leaving for reference
# https://astralvx.com/debugging-16-bit-in-qemu-with-gdb-on-windows/
# https://gist.github.com/gsingh93/2c8e7bbff37dbced6bd7325d8c08ec85
#

build_debug:
			$(AS) -f elf32 -g3 -F dwarf -Dis_debug=1 $(SRC) -o "$(BIN).o"
			$(LD) -Ttext=0x7c00 -melf_i386 "$(BIN).o" -o "$(BIN).elf"
			objcopy -O binary "$(BIN).elf" "$(BIN).img"

debug:		build_debug
			$(QEMU) $(QEMU_FLAGS) -s -S -boot a \
				& $(GDB) "$(BIN).elf" \
					-ex 'target remote localhost:1234' \
					-ex 'set architecture i8086' \
					-ex 'layout src' \
					-ex 'layout regs' \
					-ex 'break _start' \
					-ex 'continue'
