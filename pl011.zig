// PrimeCell UART (PL011) Technical Reference Manual:
// https://developer.arm.com/documentation/ddi0183/f/

const device = @import("device.zig");
const dtb = @import("dtb.zig");
const log = @import("log.zig");

extern fn __delay(count: i32) void;

/// Register offsets.
const Reg = enum(u32) {
    DR = 0x000,
    RSRECR = 0x004,
    FR = 0x018,
    ILPR = 0x020,
    IBRD = 0x024,
    FBRD = 0x028,
    LCR_H = 0x02C,
    CR = 0x030,
    IFLS = 0x034,
    IMSC = 0x038,
    RIS = 0x03C,
    MIS = 0x040,
    ICR = 0x044,
    DMACR = 0x048,
    ITCR = 0x080,
    ITIP = 0x084,
    ITOP = 0x088,
    TDR = 0x08C,
    PeriphID0 = 0xFE0,
    PeriphID1 = 0xFE4,
    PeriphID2 = 0xFE8,
    PeriphID3 = 0xFEC,
    PCellID0 = 0xFF0,
    PCellID1 = 0xFF4,
    PCellID2 = 0xFF8,
    PCellID3 = 0xFFC,
};

// Flag bits for the UARTFR register.
const FR_CTS = 1 << 0;
const FR_DSR = 1 << 1;
const FR_DCD = 1 << 2;
const FR_BUSY = 1 << 3;
const FR_RXFE = 1 << 4;
const FR_TXFF = 1 << 5;
const FR_RXFF = 1 << 6;
const FR_TXFE = 1 << 7;
const FR_RI = 1 << 8;

// Flag bits for the UARTLCR_H register.
const LCR_H_BRK = 1 << 0;
const LCR_H_PEN = 1 << 1;
const LCR_H_EPS = 1 << 2;
const LCR_H_STP2 = 1 << 3;
const LCR_H_FEN = 1 << 4;
const LCR_H_SPS = 1 << 6;

// Flag bits for the UARTCR register.
const CR_UARTEN = 1 << 0;
const CR_SIREN = 1 << 1;
const CR_SIRLP = 1 << 2;
const CR_LBE = 1 << 7;
const CR_TXE = 1 << 8;
const CR_RXE = 1 << 9;
const CR_DTR = 1 << 10;
const CR_RTS = 1 << 11;
const CR_Out1 = 1 << 12;
const CR_Out2 = 1 << 13;
const CR_RTSEn = 1 << 14;
const CR_CTSEn = 1 << 15;

pub const pl011 = struct {
    const Self = @This();

    dev: device.MMIOPeripheralDevice(Reg),

    fn setBaudRate(self: Self, clock: u32, baud: u32) void {
        const divider = @divFloor(clock, 16 * baud);
        const fract = @divFloor(64 * clock, 16 * baud) - 64 * divider;
        self.dev.writeReg(.IBRD, divider);
        self.dev.writeReg(.FBRD, fract);
    }

    pub fn enable(self: Self, clock: u32, baud: u32) void {
        self.setBaudRate(clock, baud);

        // Enable FIFO and 8 bit data transmission (1 stop bit, no parity).
        self.dev.writeReg(.LCR_H, LCR_H_FEN | (0b11 << 5));

        // Mask all interrupts.
        self.dev.writeReg(.IMSC, (1 << 10) - 1);

        // Enable UART, transmit and receive.
        self.dev.writeReg(.CR, CR_UARTEN | CR_TXE | CR_RXE);
    }

    /// Blocking read of a single character.
    pub fn read(self: Self) u8 {
        // Wait until there is data in the receive FIFO.
        while ((self.dev.readReg(.FR) & FR_RXFE) != 0) {}
        return self.dev.readReg(.DR);
    }

    /// Blocking write of a single character.
    pub fn write(self: Self, c: u8) void {
        // Wait until there is space in the transmit FIFO.
        while ((self.dev.readReg(.FR) & FR_TXFF) != 0) {}
        self.dev.writeReg(.DR, c);
    }

    pub fn probe(node: dtb.Node) !Self {
        const self = Self{
            .dev = try device.MMIOPeripheralDevice(Reg).init(node)
        };

        // Disable everything.
        self.dev.writeReg(.CR, 0x00000000);

        // Clear all pending interrupts.
        self.dev.writeReg(.ICR, 0x7FF);

        return self;
    }
};
