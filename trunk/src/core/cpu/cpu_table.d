module pspemu.core.cpu.cpu_table;

import pspemu.core.cpu.instruction;

import std.stdio;

alias InstructionDefinition array;

// --------------------------
//  Related implementations:
// --------------------------
// OLD:       http://pspemu.googlecode.com/svn/branches/old/util/gen/tables/cpu_table.php
// PSPPlayer: 
// Jpcsp:     http://jpcsp.googlecode.com/svn/trunk/src/jpcsp/Allegrex.isa
// mfzpsp:    
// pcsp:      

// http://svn.ps2dev.org/filedetails.php?repname=psp&path=/trunk/prxtool/disasm.C&rev=0&sc=0
/* Format codes
 * %d - Rd
 * %t - Rt
 * %s - Rs
 * %i - 16bit signed immediate
 * %I - 16bit unsigned immediate (always printed in hex)
 * %o - 16bit signed offset (rs base)
 * %O - 16bit signed offset (PC relative)
 * %j - 26bit absolute offset
 * %J - Register jump
 * %a - SA
 * %0 - Cop0 register
 * %1 - Cop1 register
 * %2? - Cop2 register (? is (s, d))
 * %p - General cop (i.e. numbered) register
 * %n? - ins/ext size, ? (e, i)
 * %r - Debug register
 * %k - Cache function
 * %D - Fd
 * %T - Ft
 * %S - Fs
 * %x? - Vt (? is (s/scalar, p/pair, t/triple, q/quad, m/matrix pair, n/matrix triple, o/matrix quad)
 * %y? - Vs
 * %z? - Vd
 * %X? - Vo (? is (s, q))
 * %Y - VFPU offset
 * %Z? - VFPU condition code/name (? is (c, n))
 * %v? - VFPU immediate, ? (3, 5, 8, k, i, h, r, p? (? is (0, 1, 2, 3, 4, 5, 6, 7)))
 * %c - code (for break)
 * %C - code (for syscall)
 * %? - Indicates vmmul special exception
 */
const PspInstructions = [
	// MIPS instructions
	array("add"      , 0x00000020, 0xFC0007FF, "%d, %s, %t"),
	array("addi"     , 0x20000000, 0xFC000000, "%t, %s, %i"),
	array("addiu"    , 0x24000000, 0xFC000000, "%t, %s, %i"),
	array("addu"     , 0x00000021, 0xFC0007FF, "%d, %s, %t"),
	array("and"      , 0x00000024, 0xFC0007FF, "%d, %s, %t"),
	array("andi"     , 0x30000000, 0xFC000000, "%t, %s, %I"),
	array("beq"      , 0x10000000, 0xFC000000, "%s, %t, %O"),
	/*
	array("beql"     , 0x50000000, 0xFC000000),
	*/
	array("bgez"     , 0x04010000, 0xFC1F0000, "%s, %O"),
	array("bgezal"   , 0x04110000, 0xFC1F0000, "%s, %O"),
	array("bgezl"    , 0x04030000, 0xFC1F0000, "%s, %O"),
	/*
	array("bgtz"     , 0x1C000000, 0xFC1F0000),
	array("bgtzl"    , 0x5C000000, 0xFC1F0000),
	array("bitrev"   , 0x7C000520, 0xFFE007FF),
	array("blez"     , 0x18000000, 0xFC1F0000),
	array("blezl"    , 0x58000000, 0xFC1F0000),
	array("bltz"     , 0x04000000, 0xFC1F0000),
	array("bltzl"    , 0x04020000, 0xFC1F0000),
	array("bltzal"   , 0x04100000, 0xFC1F0000),
	array("bltzall"  , 0x04120000, 0xFC1F0000),
	array("bne"      , 0x14000000, 0xFC000000),
	array("bnel"     , 0x54000000, 0xFC000000),
	array("break"    , 0x0000000D, 0xFC00003F),
	array("cache"    , 0xBC000000, 0xFC000000),
	array("cfc0"     , 0x40400000, 0xFFE007FF),
	array("clo"      , 0x00000017, 0xFC1F07FF),
	array("clz"      , 0x00000016, 0xFC1F07FF),
	array("ctc0"     , 0x40C00000, 0xFFE007FF),
	array("max"      , 0x0000002C, 0xFC0007FF),
	array("min"      , 0x0000002D, 0xFC0007FF),
	array("dbreak"   , 0x7000003F, 0xFFFFFFFF),
	array("div"      , 0x0000001A, 0xFC00FFFF),
	array("divu"     , 0x0000001B, 0xFC00FFFF),
	array("dret"     , 0x7000003E, 0xFFFFFFFF),
	array("eret"     , 0x42000018, 0xFFFFFFFF),
	array("ext"      , 0x7C000000, 0xFC00003F),
	array("ins"      , 0x7C000004, 0xFC00003F),
	*/
	array("j"        , 0x08000000, 0xFC000000, "%j"),
	array("jr"       , 0x00000008, 0xFC1FFFFF, "%J"),
	array("jalr"     , 0x00000009, 0xFC1F07FF, "%J"),
	array("jal"      , 0x0C000000, 0xFC000000, "%j"),
	/*
	array("lb"       , 0x80000000, 0xFC000000),
	array("lbu"      , 0x90000000, 0xFC000000),
	array("lh"       , 0x84000000, 0xFC000000),
	array("lhu"      , 0x94000000, 0xFC000000),
	array("ll"       , 0xC0000000, 0xFC000000),
	array("lui"      , 0x3C000000, 0xFFE00000),
	array("lw"       , 0x8C000000, 0xFC000000),
	array("lwl"      , 0x88000000, 0xFC000000),
	array("lwr"      , 0x98000000, 0xFC000000),
	array("madd"     , 0x0000001C, 0xFC00FFFF),
	array("maddu"    , 0x0000001D, 0xFC00FFFF),
	array("mfc0"     , 0x40000000, 0xFFE007FF),
	array("mfdr"     , 0x7000003D, 0xFFE007FF),
	array("mfhi"     , 0x00000010, 0xFFFF07FF),
	array("mfic"     , 0x70000024, 0xFFE007FF),
	array("mflo"     , 0x00000012, 0xFFFF07FF),
	array("movn"     , 0x0000000B, 0xFC0007FF),
	array("movz"     , 0x0000000A, 0xFC0007FF),
	array("msub"     , 0x0000002E, 0xFC00FFFF),
	array("msubu"    , 0x0000002F, 0xFC00FFFF),
	array("mtc0"     , 0x40800000, 0xFFE007FF),
	array("mtdr"     , 0x7080003D, 0xFFE007FF),
	array("mtic"     , 0x70000026, 0xFFE007FF),
	array("halt"     , 0x70000000, 0xFFFFFFFF),
	array("mthi"     , 0x00000011, 0xFC1FFFFF),
	array("mtlo"     , 0x00000013, 0xFC1FFFFF),
	array("mult"     , 0x00000018, 0xFC00FFFF),
	array("multu"    , 0x00000019, 0xFC0007FF),
	array("nor"      , 0x00000027, 0xFC0007FF),
	array("or"       , 0x00000025, 0xFC0007FF),
	array("ori"      , 0x34000000, 0xFC000000),
	array("rotr"     , 0x00200002, 0xFFE0003F),
	array("rotrv"    , 0x00000046, 0xFC0007FF), // ?
	array("seb"      , 0x7C000420, 0xFFE007FF),
	array("seh"      , 0x7C000620, 0xFFE007FF),
	array("sb"       , 0xA0000000, 0xFC000000),
	array("sh"       , 0xA4000000, 0xFC000000),
	array("sllv"     , 0x00000004, 0xFC0007FF),
	array("sll"      , 0x00000000, 0xFFE0003F),
	array("slt"      , 0x0000002A, 0xFC0007FF),
	array("slti"     , 0x28000000, 0xFC000000),
	array("sltiu"    , 0x2C000000, 0xFC000000),
	array("sltu"     , 0x0000002B, 0xFC0007FF),
	array("sra"      , 0x00000003, 0xFFE0003F),
	array("srav"     , 0x00000007, 0xFC0007FF),
	array("srlv"     , 0x00000006, 0xFC0007FF),
	array("srl"      , 0x00000002, 0xFFE0003F),
	array("sw"       , 0xAC000000, 0xFC000000),
	array("swl"      , 0xA8000000, 0xFC000000),
	array("swr"      , 0xB8000000, 0xFC000000),
	array("sub"      , 0x00000022, 0xFC0007FF),
	array("subu"     , 0x00000023, 0xFC0007FF),
	array("sync"     , 0x0000000F, 0xFFFFFFFF),
	array("syscall"  , 0x0000000C, 0xFC00003F),
	array("xor"      , 0x00000026, 0xFC0007FF),
	array("xori"     , 0x38000000, 0xFC000000),
	array("wsbh"     , 0x7C0000A0, 0xFFE007FF),
	array("wsbw"     , 0x7C0000E0, 0xFFE007FF),

	// FPU instructions
	array("abs.s"    , 0x46000005, 0xFFFF003F),
	array("add.s"    , 0x46000000, 0xFFE0003F),
	array("bc1f"     , 0x45000000, 0xFFFF0000),
	array("bc1fl"    , 0x45020000, 0xFFFF0000),
	array("bc1t"     , 0x45010000, 0xFFFF0000),
	array("bc1tl"    , 0x45030000, 0xFFFF0000),
	array("c.f.s"    , 0x46000030, 0xFFE007FF),
	array("c.un.s"   , 0x46000031, 0xFFE007FF),
	array("c.eq.s"   , 0x46000032, 0xFFE007FF),
	array("c.ueq.s"  , 0x46000033, 0xFFE007FF),
	array("c.olt.s"  , 0x46000034, 0xFFE007FF),
	array("c.ult.s"  , 0x46000035, 0xFFE007FF),
	array("c.ole.s"  , 0x46000036, 0xFFE007FF),
	array("c.ule.s"  , 0x46000037, 0xFFE007FF),
	array("c.sf.s"   , 0x46000038, 0xFFE007FF),
	array("c.ngle.s" , 0x46000039, 0xFFE007FF),
	array("c.seq.s"  , 0x4600003A, 0xFFE007FF),
	array("c.ngl.s"  , 0x4600003B, 0xFFE007FF),
	array("c.lt.s"   , 0x4600003C, 0xFFE007FF),
	array("c.nge.s"  , 0x4600003D, 0xFFE007FF),
	array("c.le.s"   , 0x4600003E, 0xFFE007FF),
	array("c.ngt.s"  , 0x4600003F, 0xFFE007FF),
	array("ceil.w.s" , 0x4600000E, 0xFFFF003F),
	array("cfc1"     , 0x44400000, 0xFFE007FF),
	array("ctc1"     , 0x44C00000, 0xFFE007FF),
	array("cvt.s.w"  , 0x46800020, 0xFFFF003F),
	array("cvt.w.s"  , 0x46000024, 0xFFFF003F),
	array("div.s"    , 0x46000003, 0xFFE0003F),
	array("floor.w.s", 0x4600000F, 0xFFFF003F),
	array("lwc1"     , 0xC4000000, 0xFC000000),
	array("mfc1"     , 0x44000000, 0xFFE007FF),
	array("mov.s"    , 0x46000006, 0xFFFF003F),
	array("mtc1"     , 0x44800000, 0xFFE007FF),
	array("mul.s"    , 0x46000002, 0xFFE0003F),
	array("neg.s"    , 0x46000007, 0xFFFF003F),
	array("round.w.s", 0x4600000C, 0xFFFF003F),
	array("sqrt.s"   , 0x46000004, 0xFFFF003F),
	array("sub.s"    , 0x46000001, 0xFFE0003F),
	array("swc1"     , 0xE4000000, 0xFC000000),
	array("trunc.w.s", 0x4600000D, 0xFFFF003F),
	*/
];

unittest {
	writefln("Unittesting: " ~ __FILE__ ~ "...");
}