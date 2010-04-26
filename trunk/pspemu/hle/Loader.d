module pspemu.hle.Loader;

//version = DEBUG_LOADER;
//version = ALLOW_UNIMPLEMENTED_NIDS;
//version = LOAD_DWARF_INFORMATION;

import std.stream, std.stdio, std.string;

import pspemu.utils.Utils;
import pspemu.utils.Expression;

import pspemu.formats.elf.Elf;
import pspemu.formats.elf.ElfDwarf;
import pspemu.formats.Pbp;

import pspemu.hle.Module;
import pspemu.hle.kd.iofilemgr;
import pspemu.hle.kd.sysmem;
import pspemu.hle.kd.threadman;

import pspemu.core.Memory;
import pspemu.core.cpu.Cpu;
import pspemu.core.cpu.Interrupts;
import pspemu.core.cpu.Assembler;
import pspemu.core.cpu.Instruction;
import pspemu.core.cpu.InstructionCounter;

import pspemu.models.IDebugSource;

import pspemu.utils.Logger;

import std.xml;

version (unittest) {
	import pspemu.utils.SparseMemory;
}

static const string psplibdoc_xml = import("psplibdoc.xml");

template LazySingleton() {
	static typeof(this) _singleton;
	static typeof(this) singleton() {
		if (_singleton is null) _singleton = new typeof(this);
		return _singleton;
	}
}

class PspLibdoc {
	mixin LazySingleton;

	protected this() {
		this.parse();
	}

	class LibrarySymbol {
		uint nid;
		string name;
		string comment;
		Library library;

		string toString() {
			return std.string.format(typeof(this).stringof ~ "(nid=0x%08X, name='%s' comment='%s')", nid, name, comment);
		}
	}

	class Function : LibrarySymbol { }
	class Variable : LibrarySymbol { }

	class Library {
		string name;
		uint flags;
		Function[uint] functions;
		Variable[uint] variables;
		LibrarySymbol[uint] symbols;
		Prx prx;

		string toString() {
			string s;
			s ~= std.string.format("  <Library name='%s' flags='0x%08x'>\n", name, flags);
			foreach (func; functions) s ~= std.string.format("    %s\n", func.toString);
			foreach (var ; variables) s ~= std.string.format("    %s\n", var .toString);
			s ~= std.string.format("  </Library>");
			return s;
		}
	}

	class Prx {
		string moduleName, fileName;
		Library[string] libraries;
		
		string toString() {
			string s;
			s ~= std.string.format("<Prx moduleName='%s' fileName='%s'>\n", moduleName, fileName);
			foreach (library; libraries) s ~= std.string.format("%s\n", library.toString);
			s ~= std.string.format("</Prx>");
			return s;
		}
	}

	Library[string] libraries;
	Prx[] prxs;

	LibrarySymbol locate(uint nid, string libraryName) {
		if (libraryName is null) {
			foreach (clibraryName; libraries.keys) if (auto symbol = locate(nid, clibraryName)) return symbol;
			return null;
		}
		if (libraryName !in libraries) return null;
		if (nid !in libraries[libraryName].symbols) return null;
		return libraries[libraryName].symbols[nid];
	}

	string getPrxPath(string libraryName) {
		return onException(libraries[libraryName].prx.fileName, "<unknown path>");
	}
	
	string getPrxName(string libraryName) {
		return onException(libraries[libraryName].prx.moduleName, "<unknown name>");
	}
	
	string getPrxInfo(string libraryName) {
		return std.string.format("%s (%s)", getPrxPath(libraryName), getPrxName(libraryName));
	}

	void parse() {
		auto xml = new Document(psplibdoc_xml);
		Function func;
		Variable var;
		Library library;
		Prx prx;

		void parseFunction(Element xml) {
			func = new Function();
			foreach (node; xml.elements) {
				switch (node.tag.name) {
					case "NID" : func.nid  = cast(uint)parseString(node.text); break;
					case "NAME": func.name = node.text; break;
					case "COMMENT": func.comment = node.text; break;
				}
			}
			func.library = library;
			library.functions[func.nid] = func;
			library.symbols[func.nid] = func;
		}

		void parseVariable(Element xml) {
			var = new Variable();
			foreach (node; xml.elements) {
				switch (node.tag.name) {
					case "NID" : var.nid  = cast(uint)parseString(node.text); break;
					case "NAME": var.name = node.text; break;
					case "COMMENT": var.comment = node.text; break;
				}
			}
			var.library = library;
			library.variables[var.nid] = var;
			library.symbols[var.nid] = var;
		}

		void parseLibrary(Element xml) {
			library = new Library();
			foreach (node; xml.elements) {
				switch (node.tag.name) {
					case "NAME"     : library.name  = node.text; break;
					case "FLAGS"    : library.flags = cast(uint)parseString(node.text); break;
					case "FUNCTIONS": foreach (snode; node.elements) if (snode.tag.name == "FUNCTION") parseFunction(snode); break;
					case "VARIABLES": foreach (snode; node.elements) if (snode.tag.name == "VARIABLE") parseVariable(snode); break;
				}
			}
			library.prx = prx;
			prx.libraries[library.name] = library;
		}

		void parsePrxFile(Element xml) {
			prx = new Prx();
			foreach (node; xml.elements) {
				switch (node.tag.name) {
					case "PRX"    : prx.fileName   = node.text; break;
					case "PRXNAME": prx.moduleName = node.text; break;
					case "LIBRARIES": foreach (snode; node.elements) if (snode.tag.name == "LIBRARY") parseLibrary(snode); break;
				}
			}
			foreach (library; prx.libraries) libraries[library.name] = library;
			prxs ~= prx;
		}

		foreach (node; xml.elements) if (node.tag.name == "PRXFILES") foreach (snode; node.elements) if (snode.tag.name == "PRXFILE") parsePrxFile(snode);

		//foreach (cprx; prxs) writefln("%s", cprx);
	}
}

class Loader : IDebugSource {
	enum ModuleFlags : ushort {
		User   = 0x0000,
		Kernel = 0x1000,
	}

	enum LibFlags : ushort {
		DirectJump = 0x0001,
		Syscall    = 0x4000,
		SysLib     = 0x8000,
	}

	static struct ModuleExport {
		uint   name;         /// Address to a stringz with the module.
		ushort _version;     ///
		ushort flags;        ///
		byte   entry_size;   ///
		byte   var_count;    ///
		ushort func_count;   ///
		uint   exports;      ///

		// Check the size of the struct.
		static assert(this.sizeof == 16);
	}

	static struct ModuleImport {
		uint   name;           /// Address to a stringz with the module.
		ushort _version;       /// Version of the module?
		ushort flags;          /// Flags for the module.
		byte   entry_size;     /// ???
		byte   var_count;      /// 
		ushort func_count;     /// 
		uint   nidAddress;     /// Address to the nid pointer. (Read)
		uint   callAddress;    /// Address to the function table. (Write 16 bits. jump/syscall)

		// Check the size of the struct.
		static assert(this.sizeof == 20);
	}
	
	static struct ModuleInfo {
		uint flags;     ///
		char[28] name;      /// Name of the module.
		uint gp;            /// Global Pointer initial value.
		uint exportsStart;  ///
		uint exportsEnd;    ///
		uint importsStart;  ///
		uint importsEnd;    ///

		// Check the size of the struct.
		static assert(this.sizeof == 52);
	}

	Elf elf;
	ElfDwarf dwarf;
	Cpu cpu;
	ModuleManager moduleManager;
	AllegrexAssembler assembler, assemblerExe;
	Memory memory() { return cpu.memory; }
	ModuleInfo moduleInfo;
	ModuleImport[] moduleImports;
	ModuleExport[] moduleExports;
	
	this(Cpu cpu, ModuleManager moduleManager) {
		this.cpu           = cpu;
		this.moduleManager = moduleManager;
		this.assembler     = new AllegrexAssembler(memory);
		this.assemblerExe  = new AllegrexAssembler(memory);
	}

	void load(Stream stream, string name = "<unknown>") {
		// Assembler.
		if (name.length >= 4 && name[$ - 4..$] == ".asm") {
			assemblerExe.assembleBlock(cast(string)stream.readString(cast(uint)stream.size));
		}
		// Binary
		else {
			while (true) {
				auto magics = new SliceStream(stream, 0, 4);
				auto magic_data = cast(ubyte[])magics.readString(4);
				switch (cast(string)magic_data) {
					case "\x7FELF":
					break;
					case "~PSP":
						throw(new Exception("Not support compressed elf files"));
					break;
					case "\0PBP":
						stream = (new Pbp(stream))["psp.data"];
						continue;
					break;
					default:
						throw(new Exception(std.string.format("Unknown file type '%s' : [%s]", name, magic_data)));
					break;
				}
				break;
			}
			
			this.elf = new Elf(stream);

			version (DEBUG_LOADER) elf.dumpSections();

			try {
				load();
			} catch (Object o) {
				writefln("Loader.load Exception: %s", o);
				throw(o);
			}

			version (DEBUG_LOADER) { count(); moduleManager.dumpLoadedModules(); }

			version (LOAD_DWARF_INFORMATION) loadDwarfInformation();
		}
	}

	string lastLoadedFile;

	void load(string fileName) {
		memory.reset();
		cpu.reset();
		reset();
		fileName = fileName.replace("\\", "/");

		string path = ".";
		int index = fileName.lastIndexOf('/');
		if (index != -1) path = fileName[0..index];
		moduleManager.get!(IoFileMgrForUser).setVirtualDir(path);

		load(new BufferedFile(lastLoadedFile = fileName, FileMode.In), fileName);
	}

	void reloadAndExecute() {
		loadAndExecute(lastLoadedFile);
	}

	void reset() {
		moduleManager.reset();
		cpu.interrupts.registerCallback(
			Interrupts.Type.THREAD0,
			&moduleManager.get!(ThreadManForUser).threadManager.switchNextThread
		);
	}

	void loadAndExecute(string fileName) {
		load(fileName);
		setRegisters();

		core.memory.GC.collect();

		cpu.gpu.start(); // Start GPU.
		cpu.start();     // Start CPU.
	}

	void loadDwarfInformation() {
		try {
			dwarf = new ElfDwarf;
			dwarf.parseDebugLine(elf.SectionStream(".debug_line"));
			dwarf.find(0x089004C8);
			cpu.debugSource = this;
			writefln("Loaded debug information");
		} catch (Object o) {
			writefln("Can't find debug information: '%s'", o);
		}
	}

	bool lookupDebugSourceLine(ref DebugSourceLine debugSourceLine, uint address) {
		if (dwarf is null) return false;
		auto state = dwarf.find(address);
		if (state is null) return false;
		debugSourceLine.file    = state.file_full_path;
		debugSourceLine.address = state.address;
		debugSourceLine.line    = state.line;
		return true;
	}

	bool lookupDebugSymbol(ref DebugSymbol debugSymbol, uint address) {
		return false;
	}

	void count() {
		try {
			auto counter = new InstructionCounter;
			counter.count(elf.SectionStream(".text"));
			counter.dump();
		} catch (Object o) {
			writefln("Can't count instructions: '%s'", o.toString);
		}
	}

	void allocatePartitionBlock() {
		// Not a Memory supplied.
		if (cast(Memory)this.memory is null) return;

		uint allocateAddress;
		uint allocateSize    = this.elf.requiredBlockSize;
		if (this.elf.relocationAddress) {
			allocateAddress = this.elf.relocationAddress;
		} else {
			allocateAddress = getRelocatedAddress(this.elf.suggestedBlockAddress);
		}

		auto sysMemUserForUser = moduleManager.get!(SysMemUserForUser);
		
		auto blockid = sysMemUserForUser.sceKernelAllocPartitionMemory(2, "Main Program", PspSysMemBlockTypes.PSP_SMEM_Addr, allocateSize, allocateAddress);
		uint blockaddress = sysMemUserForUser.sceKernelGetBlockHeadAddr(blockid);

		Logger.log(Logger.Level.DEBUG, "Loader", "relocationAddress:%08X", this.elf.relocationAddress);
		Logger.log(Logger.Level.DEBUG, "Loader", "suggestedBlockAddress(no reloc):%08X", this.elf.suggestedBlockAddress);
		Logger.log(Logger.Level.DEBUG, "Loader", "allocateAddress:%08X", allocateAddress);
		Logger.log(Logger.Level.DEBUG, "Loader", "allocateSize:%08X", allocateSize);
		Logger.log(Logger.Level.DEBUG, "Loader", "allocatedIn:%08X", blockaddress);
		
		if (this.elf.relocationAddress != 0) {
			this.elf.relocationAddress = blockaddress;
		}
	}

	uint getRelocatedAddress(uint addr) {
		if (addr >= elf.relocationAddress) {
			if (elf.relocationAddress > 0) {
				Logger.log(Logger.Level.WARNING, "Loader", "Trying to get an already relocated address:%08X", addr);
			}
			return addr;
		} else {
			return addr + elf.relocationAddress;
		}
	}

	Stream getMemorySliceRelocated(uint from, uint to) {
		return new SliceStream(memory, getRelocatedAddress(from), getRelocatedAddress(to));
	}

	Stream getMemorySlice(uint from, uint to) {
		return new SliceStream(memory, (from), (to));
	}

	void load() {
		this.elf.preWriteToMemory(memory);
		{
			allocatePartitionBlock();
		}
		try {
			this.elf.writeToMemory(memory);
		} catch (Object o) {
			Logger.log(Logger.Level.CRITICAL, "Loader", "Failed this.elf.writeToMemory : %s", o);
			throw(o);
		}
		readInplace(moduleInfo, elf.SectionStream(".rodata.sceModuleInfo"));

		auto importsStream = getMemorySliceRelocated(moduleInfo.importsStart, moduleInfo.importsEnd);
		auto exportsStream = getMemorySliceRelocated(moduleInfo.exportsStart, moduleInfo.exportsEnd);
		
		// Load Imports.
		version (DEBUG_LOADER) writefln("Imports (0x%08X-0x%08X):", moduleInfo.importsStart, moduleInfo.importsEnd);

		uint[][string] unimplementedNids;
	
		while (!importsStream.eof) {
			auto moduleImport     = read!(ModuleImport)(importsStream);
			//writefln("%08X", moduleImport.name);
			auto moduleImportName = moduleImport.name ? readStringz(memory, moduleImport.name) : "<null>";
			//assert(moduleImport.entry_size == moduleImport.sizeof);
			version (DEBUG_LOADER) {
				writefln("  '%s'", moduleImportName);
				writefln("  {");
			}
			try {
				moduleImports ~= moduleImport;
				auto nidStream  = getMemorySlice(moduleImport.nidAddress , moduleImport.nidAddress  + moduleImport.func_count * 4);
				auto callStream = getMemorySlice(moduleImport.callAddress, moduleImport.callAddress + moduleImport.func_count * 8);
				//writefln("%08X", moduleImport.callAddress);
				
				auto pspModule = nullOnException(moduleManager[moduleImportName]);

				while (!nidStream.eof) {
					uint nid = read!(uint)(nidStream);
					
					if ((pspModule !is null) && (nid in pspModule.nids)) {
						version (DEBUG_LOADER) writefln("    %s", pspModule.nids[nid]);
						callStream.write(cast(uint)(0x0000000C | (0x1000 << 6))); // syscall 0x2307
						callStream.write(cast(uint)cast(void *)&pspModule.nids[nid]);
					} else {
						version (DEBUG_LOADER) writefln("    0x%08X:<unimplemented>", nid);
						//callStream.write(cast(uint)(0x70000000));
						//callStream.write(cast(uint)0);
						unimplementedNids[moduleImportName] ~= nid;
					}
					//writefln("++");
					//writefln("--");
				}
			} catch (Object o) {
				writefln("  ERRROR!: %s", o);
				throw(o);
			}
			version (DEBUG_LOADER) {
				writefln("  }");
			}
		}
		
		if (unimplementedNids.length > 0) {
			int count = 0;
			writefln("unimplementedNids:");
			foreach (moduleName, nids; unimplementedNids) {
				writefln("  %s // %s:", moduleName, PspLibdoc.singleton.getPrxInfo(moduleName));
				foreach (nid; nids) {
					if (auto symbol = PspLibdoc.singleton.locate(nid, moduleName)) {
						writefln("    mixin(registerd!(0x%08X, %s));", nid, symbol.name);
					} else {
						writefln("    0x%08X:<Not found!>", nid);
					}
				}
				count += nids.length;
			}
			//writefln("%s", PspLibdoc.singleton.prxs);
			version (ALLOW_UNIMPLEMENTED_NIDS) {
			} else {
				throw(new Exception(std.string.format("Several unimplemented NIds. (%d)", count)));
			}
		}
		// Load Exports.
		version (DEBUG_LOADER) writefln("Exports (0x%08X-0x%08X):", moduleInfo.exportsStart, moduleInfo.exportsEnd);
		while (!exportsStream.eof) {
			auto moduleExport = read!(ModuleExport)(exportsStream);
			auto moduleExportName = moduleExport.name ? readStringz(memory, moduleExport.name) : "<null>";
			version (DEBUG_LOADER) writefln("  '%s'", moduleExportName);
			moduleExports ~= moduleExport;
		}
	}

	uint PC() {
		//writefln("assemblertext: %08X", assemblerExe.segments["text"]);
		return elf ? getRelocatedAddress(elf.header.entryPoint) : assemblerExe.segments["text"];
	}
	uint GP() { return elf ? getRelocatedAddress(moduleInfo.gp) : 0; }

	void setRegisters() {
		auto threadManForUser = moduleManager.get!(ThreadManForUser);

		assembler.assembleBlock(import("KernelUtils.asm"));

		auto thid = threadManForUser.sceKernelCreateThread("Main Thread", PC, 32, 0x8000, 0, null);
		auto pspThread = threadManForUser.getThreadFromId(thid);
		with (pspThread) {
			registers.pcSet = PC;
			registers.GP = GP;

			registers.K0 = registers.SP;
			registers.RA = 0x08000000;
			registers.A0 = 32; // argumentsLength.
			registers.A1 = registers.SP; // argumentsPointer
			memory.position = registers.SP;
			memory.writeString("ms0:/PSP/GAME/virtual/EBOOT.PBP\0");
		}
		threadManForUser.sceKernelStartThread(thid, 0, null);
		pspThread.switchToThisThread();

		Logger.log(Logger.Level.DEBUG, "Loader", "PC: %08X", cpu.registers.PC);
		Logger.log(Logger.Level.DEBUG, "Loader", "GP: %08X", cpu.registers.GP);
		Logger.log(Logger.Level.DEBUG, "Loader", "SP: %08X", cpu.registers.SP);
	}
}

/*
unittest {
	const testPath = "demos";
	auto memory = new SparseMemoryStream;
	try {
		auto loader = new Loader(
			new BufferedFile(testPath ~ "/controller.elf", FileMode.In),
			memory
		);
	} finally {
		//memory.smartDump();
	}

	//assert(0);
}
*/
