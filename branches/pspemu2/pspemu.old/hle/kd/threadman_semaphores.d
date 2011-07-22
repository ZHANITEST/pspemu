module pspemu.hle.kd.threadman_semaphores;

import pspemu.hle.kd.threadman_common;

template ThreadManForUser_Semaphores() {
	PspSemaphoreManager semaphoreManager;

	void initModule_Semaphores() {
		threadManager = new PspThreadManager(this);
		semaphoreManager = new PspSemaphoreManager(this);
	}

	void initNids_Semaphores() {
		mixin(registerd!(0xD6DA4BA1, sceKernelCreateSema));
		mixin(registerd!(0x28B6489C, sceKernelDeleteSema));
		mixin(registerd!(0x3F53E640, sceKernelSignalSema));
		mixin(registerd!(0x4E3A1105, sceKernelWaitSema));
		mixin(registerd!(0x6D212BAC, sceKernelWaitSemaCB));
		mixin(registerd!(0x58B1F937, sceKernelPollSema));
	}

	/**
	 * Creates a new semaphore
	 *
	 * @par Example:
	 * @code
	 * int semaid;
	 * semaid = sceKernelCreateSema("MyMutex", 0, 1, 1, 0);
	 * @endcode
	 *
	 * @param name      - Specifies the name of the sema
	 * @param attr      - Sema attribute flags (normally set to 0)
	 * @param initCount - Sema initial value 
	 * @param maxCount  - Sema maximum value
	 * @param option    - Sema options (normally set to 0)
	 * @return A semaphore id
	 */
	SceUID sceKernelCreateSema(string name, SceUInt attr, int initCount, int maxCount, SceKernelSemaOptParam* option) {
		auto semaphore = semaphoreManager.createSemaphore();

		semaphore.name = name;
		semaphore.info.name[0..name.length] = name[0..$];
		semaphore.info.attr           = attr;
		semaphore.info.initCount      = initCount;
		semaphore.info.currentCount   = initCount; // Actually value
		semaphore.info.maxCount       = maxCount;
		semaphore.info.numWaitThreads = 0;

		return reinterpret!(SceUID)(semaphore);
	}

	/**
	 * Destroy a semaphore
	 *
	 * @param semaid - The semaid returned from a previous create call.
	 * @return Returns the value 0 if its succesful otherwise -1
	 */
	int sceKernelDeleteSema(SceUID semaid) {
		auto pspSemaphore = reinterpret!(PspSemaphore)(semaid);
		if (pspSemaphore is null) return -1;
		semaphoreManager.removeSemaphore(pspSemaphore);
		return 0;
	}

	/**
	 * Poll a sempahore.
	 *
	 * @param semaid - UID of the semaphore to poll.
	 * @param signal - The value to test for.
	 *
	 * @return < 0 on error.
	 */
	int sceKernelPollSema(SceUID semaid, int signal) {
		unimplemented();
		return -1;
	}

	/**
	 * Retrieve information about a semaphore.
	 *
	 * @param semaid - UID of the semaphore to retrieve info for.
	 * @param info - Pointer to a ::SceKernelSemaInfo struct to receive the info.
	 *
	 * @return < 0 on error.
	 */
	int sceKernelReferSemaStatus(SceUID semaid, SceKernelSemaInfo* info) {
		unimplemented();
		return -1;
	}

	/**
	 * Lock a semaphore
	 *
	 * @par Example:
	 * @code
	 * sceKernelWaitSema(semaid, 1, 0);
	 * @endcode
	 *
	 * @param semaid - The sema id returned from sceKernelCreateSema
	 * @param signal - The value to wait for (i.e. if 1 then wait till reaches a signal state of 1)
	 * @param timeout - Timeout in microseconds (assumed).
	 *
	 * @return < 0 on error.
	 */
	int sceKernelWaitSema(SceUID semaid, int signal, SceUInt* timeout) {
		auto semaphore = reinterpret!(PspSemaphore)(semaid);
		
		// @TODO implement timeout!

		semaphore.info.numWaitThreads++;
		return threadManager.currentThread.pauseAndYield("sceKernelWaitSema", (PspThread pausedThread) {
			if (semaphore.info.currentCount >= signal) {
				semaphore.info.numWaitThreads--;
				semaphore.info.currentCount -= signal;
				pausedThread.resumeAndReturn(0);
			}
		});
	}
	
	/**
	 * Lock a semaphore a handle callbacks if necessary.
	 *
	 * @par Example:
	 * @code
	 * sceKernelWaitSemaCB(semaid, 1, 0);
	 * @endcode
	 *
	 * @param semaid - The sema id returned from sceKernelCreateSema
	 * @param signal - The value to wait for (i.e. if 1 then wait till reaches a signal state of 1)
	 * @param timeout - Timeout in microseconds (assumed).
	 *
	 * @return < 0 on error.
	 */
	int sceKernelWaitSemaCB(SceUID semaid, int signal, SceUInt *timeout) {
		unimplemented();
		return -1;
	}

	/**
	 * Send a signal to a semaphore
	 *
	 * @par Example:
	 * @code
	 * // Signal the sema
	 * sceKernelSignalSema(semaid, 1);
	 * @endcode
	 *
	 * @param semaid - The sema id returned from sceKernelCreateSema
	 * @param signal - The amount to signal the sema (i.e. if 2 then increment the sema by 2)
	 *
	 * @return < 0 On error.
	 */
	int sceKernelSignalSema(SceUID semaid, int signal) {
		auto semaphore = reinterpret!(PspSemaphore)(semaid);
		if (signal    <= 0   ) return PspKernelErrorCodes.SCE_KERNEL_ERROR_ILLEGAL_COUNT;
		if (semaphore is null) return PspKernelErrorCodes.SCE_KERNEL_ERROR_UNKNOWN_UID;

		with (semaphore.info) {
			currentCount += signal;
			if (currentCount > maxCount) {
				currentCount = maxCount;
			}
		}
		return 0;
	}
}
