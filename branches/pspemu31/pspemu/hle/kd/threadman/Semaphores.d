module pspemu.hle.kd.threadman.Semaphores;

//import pspemu.hle.kd.threadman_common;

import std.math;
import core.thread;

import pspemu.utils.MathUtils;

import pspemu.hle.kd.Types;
import pspemu.hle.kd.threadman.Types;

import pspemu.core.EmulatorState;
import pspemu.core.exceptions.HaltException;

import core.sync.condition;
import core.sync.mutex;

import std.c.windows.windows;

class PspSemaphore {
	string name;
	SceKernelSemaInfo info;
	Condition updatedCountCondition;
	
	this() {
		updatedCountCondition = new Condition(new Mutex());
	}

	public void incrementCount(int count) {
		info.currentCount = min(info.maxCount, info.currentCount + count);
		updatedCountCondition.notify();
	}
	
	public void waitSignal(EmulatorState emulatorState, int signal, uint timeout) {
		// @TODO: ignored timeout
		info.numWaitThreads++;
		{
			while (info.currentCount < signal) {
				// @TODO This should be done with a set of mutexs, and a wait for any.
				if (!emulatorState.runningState.running) throw(new HaltException("Halt"));
				updatedCountCondition.wait(dur!"msecs"(10));
				//updatedCountCondition.wait();
				//Thread.yield();
			}
			info.currentCount -= signal;
		}
		info.numWaitThreads--;
	}
	
	public string toString() {
		return std.string.format("PspSemaphore(init:%d, current:%d, max:%d)", info.initCount, info.currentCount, info.maxCount);
	}
}

template ThreadManForUser_Semaphores() {
	//PspSemaphoreManager semaphoreManager;

	void initModule_Semaphores() {
		//threadManager = new PspThreadManager(this);
		//semaphoreManager = new PspSemaphoreManager(this);
	}

	void initNids_Semaphores() {
		mixin(registerd!(0xD6DA4BA1, sceKernelCreateSema));
		mixin(registerd!(0x3F53E640, sceKernelSignalSema));
		mixin(registerd!(0x28B6489C, sceKernelDeleteSema));
		mixin(registerd!(0x4E3A1105, sceKernelWaitSema));
		mixin(registerd!(0x58B1F937, sceKernelPollSema));
		mixin(registerd!(0x6D212BAC, sceKernelWaitSemaCB));
		mixin(registerd!(0xBC6FEBC5, sceKernelReferSemaStatus));
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
	 *
	 * @return A semaphore id
	 */
	SceUID sceKernelCreateSema(string name, SceUInt attr, int initCount, int maxCount, SceKernelSemaOptParam* option) {
		auto semaphore = new PspSemaphore();
		{
			semaphore.info.name[0..semaphore.name.length] = semaphore.name[0..$];
			semaphore.info.attr           = attr;
			semaphore.info.initCount      = initCount;
			semaphore.info.currentCount   = initCount; // Actual value
			semaphore.info.maxCount       = maxCount;
			semaphore.info.numWaitThreads = 0;
		}
		semaphore.name = cast(string)semaphore.info.name[0..semaphore.name.length];
		uint uid = hleEmulatorState.uniqueIdFactory.add(semaphore);
		logInfo("sceKernelCreateSema(%d:'%s') :: %s", uid, name, semaphore);
		return uid;
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
		auto semaphore = hleEmulatorState.uniqueIdFactory.get!PspSemaphore(semaid); 
		logInfo("sceKernelSignalSema(%d:'%s', %d) :: %s", semaid, semaphore.name, signal, semaphore);
		semaphore.incrementCount(signal);
		return 0;
	}
	
	/**
	 * Destroy a semaphore
	 *
	 * @param semaid - The semaid returned from a previous create call.
	 * @return Returns the value 0 if its succesful otherwise -1
	 */
	int sceKernelDeleteSema(SceUID semaid) {
		auto semaphore = hleEmulatorState.uniqueIdFactory.get!PspSemaphore(semaid);
		logInfo("sceKernelDeleteSema(%d:'%s')", semaid, semaphore.name);
		hleEmulatorState.uniqueIdFactory.remove!PspSemaphore(semaid);
		return 0;
	}
	
	/**
	 * Lock a semaphore
	 *
	 * @par Example:
	 * @code
	 * sceKernelWaitSema(semaid, 1, 0);
	 * @endcode
	 *
	 * @param semaid  - The sema id returned from sceKernelCreateSema
	 * @param signal  - The value to wait for (i.e. if 1 then wait till reaches a signal state of 1 or greater)
	 * @param timeout - Timeout in microseconds (assumed).
	 *
	 * @return < 0 on error.
	 */
	int sceKernelWaitSema(SceUID semaid, int signal, SceUInt* timeout) {
		auto semaphore = hleEmulatorState.uniqueIdFactory.get!PspSemaphore(semaid);
		logInfo("sceKernelWaitSema(%d:'%s', %d, %d) :: %s", semaid, semaphore.name, signal, (timeout is null) ? 0 : *timeout, semaphore);
		currentCpuThread.threadState.waitingBlock({
			semaphore.waitSignal(currentEmulatorState, signal, (timeout !is null) ? *timeout : 0);
		});
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
		auto semaphore = hleEmulatorState.uniqueIdFactory.get!PspSemaphore(semaid);
		*info = semaphore.info;
		return 0;
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
}
