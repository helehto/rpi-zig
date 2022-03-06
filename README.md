An experiment in bare-metal programming using the [Zig programming language](https://ziglang.org/) on Raspberry Pi 3B+.

Untested on real hardware.

## Running

To build (tested with Zig 0.9.0):

    $ zig build

To run it in QEMU, you will need a compiled device tree (dtb) for the Raspberry
Pi 3B+. Then, run it, supplying the device tree:

    $ qemu-system-aarch64 -M raspi3b -kernel zig-out/bin/kernel8.img -dtb bcm2710-rpi-3-b.dtb
