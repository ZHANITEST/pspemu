module pspemu.hle.kd.utility; // kd/utility.prx (sceUtility_Driver):

import pspemu.hle.Module;

class sceUtility : Module {
	void initNids() {
		mixin(registerd!(0x50C4CD57, sceUtilitySavedataInitStart));
		mixin(registerd!(0x9790B33C, sceUtilitySavedataShutdownStart));
		mixin(registerd!(0xD4B95FFB, sceUtilitySavedataUpdate));
		mixin(registerd!(0x8874DBE0, sceUtilitySavedataGetStatus));
		mixin(registerd!(0xA5DA2406, sceUtilityGetSystemParamInt));
		mixin(registerd!(0x5EEE6548, sceUtilityCheckNetParam));
		mixin(registerd!(0x434D4B3A, sceUtilityGetNetParam));
	}

	/**
	 * Get Integer System Parameter
	 *
	 * @param id - which parameter to get
	 * @param value - pointer to integer value to place result in
	 * @return 0 on success, PSP_SYSTEMPARAM_RETVAL_FAIL on failure
	 */
	int sceUtilityGetSystemParamInt( int id, int *value ) {
		unimplemented_notice();
		return -1;
	}

	/**
	 * Saves or Load savedata to/from the passed structure
	 * After having called this continue calling sceUtilitySavedataGetStatus to
	 * check if the operation is completed
	 *
	 * @param params - savedata parameters
	 * @return 0 on success
	 */
	int sceUtilitySavedataInitStart(/*SceUtilitySavedataParam*/void* params) {
		unimplemented();
		return -1;
	}

	/**
	 * Shutdown the savedata utility. after calling this continue calling
	 * ::sceUtilitySavedataGetStatus to check when it has shutdown
	 *
	 * @return 0 on success
	 *
	 */
	int sceUtilitySavedataShutdownStart() {
		unimplemented();
		return -1;
	}

	/**
	 * Refresh status of the savedata function
	 *
	 * @param unknown - unknown, pass 1
	 */
	void sceUtilitySavedataUpdate(int unknown) {
		unimplemented();
	}
	
	/**
	 * Check the current status of the saving/loading/shutdown process
	 * Continue calling this to check current status of the process
	 * before calling this call also sceUtilitySavedataUpdate
	 * @return 2 if the process is still being processed.
	 * 3 on save/load success, then you can call sceUtilitySavedataShutdownStart.
	 * 4 on complete shutdown.
	 */
	int sceUtilitySavedataGetStatus() {
		unimplemented();
		return -1;
	}

	/**
	 * Check existance of a Net Configuration
	 *
	 * @param id - id of net Configuration (1 to n)
	 * @return 0 on success, 
	 */
	int sceUtilityCheckNetParam(int id) {
		unimplemented_notice();
		return -1;
	}

	/**
	 * Get Net Configuration Parameter
	 *
	 * @param conf - Net Configuration number (1 to n)
	 * (0 returns valid but seems to be a copy of the last config requested)
	 * @param param - which parameter to get
	 * @param data - parameter data
	 * @return 0 on success, 
	 */
	int sceUtilityGetNetParam(int conf, int param, netData *data) {
		unimplemented_notice();
		return -1;
	}
}

union netData {
	u32 asUint;
	char asString[128];
}

/+
struct SceUtilitySavedataParam {
	pspUtilityDialogCommon base;

	PspUtilitySavedataMode mode;
	
	int unknown1;
	
	int overwrite;

	/** gameName: name used from the game for saves, equal for all saves */
	char gameName[13];
	char reserved[3];
	/** saveName: name of the particular save, normally a number */
	char saveName[20];

	/** saveNameList: used by multiple modes */
	char (*saveNameList)[20];

	/** fileName: name of the data file of the game for example DATA.BIN */
	char fileName[13];
	char reserved1[3];

	/** pointer to a buffer that will contain data file unencrypted data */
	void *dataBuf;
	/** size of allocated space to dataBuf */
	SceSize dataBufSize;
	SceSize dataSize;

	PspUtilitySavedataSFOParam sfoParam;

	PspUtilitySavedataFileData icon0FileData;
	PspUtilitySavedataFileData icon1FileData;
	PspUtilitySavedataFileData pic1FileData;
	PspUtilitySavedataFileData snd0FileData;

	/** Pointer to an PspUtilitySavedataListSaveNewData structure */
	PspUtilitySavedataListSaveNewData *newData;

	/** Initial focus for lists */
	PspUtilitySavedataFocus focus;

	/** unknown2: ? */
	int unknown2[4];

//#if _PSP_FW_VERSION >= 200

	/** key: encrypt/decrypt key for save with firmware >= 2.00 */
	char key[16];

	/** unknown3: ? */
	char unknown3[20];

//#endif

}
+/

static this() {
	mixin(Module.registerModule("sceUtility"));
}