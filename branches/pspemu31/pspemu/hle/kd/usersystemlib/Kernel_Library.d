module pspemu.hle.kd.usersystemlib.Kernel_Library;

import pspemu.hle.ModuleNative;

class Kernel_Library : ModuleNative {
	void initNids() {
		mixin(registerd!(0x092968F4, sceKernelCpuSuspendIntr));
		mixin(registerd!(0x5F10D406, sceKernelCpuResumeIntr));
	}
	
	/**
	 * Suspend all interrupts.
	 *
	 * @return The current state of the interrupt controller, to be used with ::sceKernelCpuResumeIntr().
	 */
	uint sceKernelCpuSuspendIntr() {
		hleEmulatorState.emulatorState.enabledInterrupts = false;
		//logInfo("Not implemented :: sceKernelCpuSuspendIntr");
		return -1;
	}
	
	/**
	 * Resume all interrupts.
	 *
	 * @param flags - The value returned from ::sceKernelCpuSuspendIntr().
	 */
	void sceKernelCpuResumeIntr(uint flags) {
		hleEmulatorState.emulatorState.enabledInterrupts = true;
		//logInfo("Not implemented :: sceKernelCpuResumeIntr (0b%032b)", flags);
	}
}

static this() {
	mixin(ModuleNative.registerModule("Kernel_Library"));
}