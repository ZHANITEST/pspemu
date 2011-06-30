module pspemu.hle.kd.impose.sceImpose;

import pspemu.hle.ModuleNative;
import pspemu.hle.HleEmulatorState;

enum PspLanguages : int {
    JAPANESE   = 0,
    ENGLISH    = 1,
    FRENCH     = 2,
    SPANISH    = 3,
    GERMAN     = 4,
    ITALIAN    = 5,
    DUTCH      = 6,
    PORTUGUESE = 7,
    RUSSIAN    = 8,
    KOREAN     = 9,
    TRADITIONAL_CHINESE = 10,
    SIMPLIFIED_CHINESE  = 11,
}

enum PspConfirmButton : int {
    CIRCLE = 0,
    CROSS  = 1,
}

class sceImpose : ModuleNative {
	uint umdPopupStatus;
	
	void initNids() {
		mixin(registerd!(0x8C943191, sceImposeGetBatteryIconStatus));
		mixin(registerd!(0x36AA6E91, sceImposeSetLanguageMode));
        mixin(registerd!(0x72189C48, sceImposeSetUMDPopupFunction));
        mixin(registerd!(0xE0887BC8, sceImposeGetUMDPopupFunction));
	}
	
	uint sceImposeSetUMDPopupFunction(uint umdPopupStatus) {
		this.umdPopupStatus = umdPopupStatus;
		return 0;
	}
	
	uint sceImposeGetUMDPopupFunction() {
		return this.umdPopupStatus; 
	}
	
	/**
	 * Set the language and button assignment parameters
	 *
	 * @param lang   - Language
	 * @param button - Button assignment
	 *
	 * @return < 0 on error
	 */
	int sceImposeSetLanguageMode(PspLanguages lang, PspConfirmButton button) {
		logError("sceImposeSetLanguageMode(%s, %s)", to!string(lang), to!string(button));
		return 0;
	} 
	
	uint sceImposeGetBatteryIconStatus(uint* addrCharging, uint* addrIconStatus) {
        if (addrCharging !is null) {
        	*addrCharging = hleEmulatorState.emulatorState.battery.isCharging ? 1 : 0; // 0..1
        }

        if (addrIconStatus !is null) {
        	*addrIconStatus = cast(int)(hleEmulatorState.emulatorState.battery.chargedPercentage * 3); // 0..3
        }

        return 0;
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceImpose"));
}
