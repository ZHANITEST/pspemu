module pspemu.hle.Callbacks;

import std.stdio;
import std.conv;

import pspemu.core.ThreadState;
import pspemu.hle.HleEmulatorState;

public import pspemu.hle.kd.threadman.Types;
import pspemu.utils.sync.WaitEvent;
import pspemu.utils.Logger;

/**
 * Psp Callback.
 */
class PspCallback {
	/**
	 * Name of the callback.
	 */
	string name;

	/**
	 * Pointer to the callback function to execute.
	 */
	SceKernelCallbackFunction func;

	/**
	 * Argument to send to callback function.
	 */
	void* arg;
	
	uint argumentValue;

	/**
	 * Constructor.
	 */
	this(string name, SceKernelCallbackFunction func, void* arg) {
		this.name = name;
		this.func = func;
		this.arg  = arg;
	}
	
	public string toString() {
		return std.string.format("PspCallback('%s', %08X, %08X)", name, func, arg);
	}
}

class CallbacksHandler {
	enum Type {
		MemoryStickInsertEject,
		GraphicEngine,
		VerticalBlank,
		/*
		PSP_GPIO_SUBINT     = PspInterrupts.PSP_GPIO_INT,
		PSP_ATA_SUBINT      = PspInterrupts.PSP_ATA_INT,
		PSP_UMD_SUBINT      = PspInterrupts.PSP_UMD_INT,
		PSP_DMACPLUS_SUBINT = PspInterrupts.PSP_DMACPLUS_INT,
		PSP_GE_SUBINT       = PspInterrupts.PSP_GE_INT,
		PSP_DISPLAY_SUBINT  = PspInterrupts.PSP_VBLANK_INT
		*/
	}
	
	HleEmulatorState hleEmulatorState;
	
	bool[PspCallback][Type] registered;
	
	alias void delegate(ThreadState) Callback;
	
	Callback[] queuedCallbacks;
	
	WaitEvent waitEvent;
	
	this(HleEmulatorState hleEmulatorState) {
		this.hleEmulatorState = hleEmulatorState;
		this.waitEvent = new WaitEvent("CallbacksHandlerEvent");
		this.waitEvent.callback = delegate(Object object) {
			executeQueued(cast(ThreadState)object);
		};
		
		hleEmulatorState.emulatorState.display.vblankEvent += delegate() {
			trigger(Type.VerticalBlank, []);
		};
	}

	/**
	 * Execute all the pending queued callbacks in the current thread
	 * with the specified ThreadState.
	 */
	void executeQueued(ThreadState threadState) {
		Logger.log(Logger.Level.INFO, "CallbacksHandler", std.string.format("executeQueued(%s)", threadState));
		Callback[] thisQueuedCallbacks;

		synchronized (this) {
			thisQueuedCallbacks = queuedCallbacks.dup;
			queuedCallbacks = [];
		}

		foreach (callback; thisQueuedCallbacks) {
			callback(threadState);
		}
	}

	/**
	 * Trigger an event type. This will queue for executing all the registered callbacks for
	 * the registered type.
	 *
	 * @param  type  Type of event to trigger.
	 */
	void trigger(Type type, uint[] arguments) {
		Logger.log(Logger.Level.INFO, "CallbacksHandler", std.string.format("trigger(%d:%s)(%s)", type, to!string(type), arguments));
		
		synchronized (this) {
			if (type in registered) {
				PspCallback[] queuedPspCallbacks = registered[type].keys.dup;
				
				queuedCallbacks ~= delegate(ThreadState threadState) {
					Logger.log(Logger.Level.INFO, "CallbacksHandler", std.string.format("Executing queued callbacks"));
					foreach (pspCallback; queuedPspCallbacks) {
						Logger.log(Logger.Level.INFO, "CallbacksHandler", std.string.format("Executing callback: %s", pspCallback));

						foreach (k, argument; arguments) threadState.registers.R[4 + k] = argument;
						hleEmulatorState.executeGuestCode(threadState, pspCallback.func);
					}
				};
			}
		}
		
		waitEvent.signal();
	}

	/**
	 * Registers a callback for an specified type of event.
	 */
	void register(Type type, PspCallback pspCallback) {
		Logger.log(Logger.Level.INFO, "CallbacksHandler", std.string.format("Register callback(%d:%s) <- %s", type, to!string(type), pspCallback));
		registered[type][pspCallback] = true;
	}
	
	/**
	 * Unregisters a callback for an specified type of event.
	 */
	void unregister(Type type, PspCallback pspCallback) {
		Logger.log(Logger.Level.INFO, "CallbacksHandler", std.string.format("Unregister callback(%d:%s) <- %s", type, to!string(type), pspCallback));
		registered[type].remove(pspCallback);
	}
}