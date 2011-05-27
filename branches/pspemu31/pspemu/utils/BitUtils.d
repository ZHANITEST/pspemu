module pspemu.utils.BitUtils;

class BitUtils {
	static public T makeMask(T = uint, uint bits)() {
		return cast(T)((1 << bits) - 1);
	}

	static public T extract(T = uint, uint start, uint bits)(T from) {
		return cast(T)((from >> start) & makeMask!(T, bits));
	}

	static public T extractNormalized(T = uint, uint start, uint bits, uint maxValue = 255)(T from) {
		return cast(T)((extract!(T, start, bits)(from) * maxValue) / makeMask!(T, bits));
	}
}