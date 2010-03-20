#include <pspkernel.h>
#include <pspdisplay.h>
#include <pspdebug.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
//#include <assert.h>

#include <pspctrl.h>
#include <pspgu.h>
#include <psprtc.h>

PSP_MODULE_INFO("Test2", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER);

typedef struct {
	unsigned mantissa : 23;
	unsigned exponent : 8;
	unsigned sign     : 1;
} FLOAT;

#define assert(v) { if (!(v)) { asm("break"); } }
void emitInt     (int   v) { asm("syscall 0x2308"); }
void emitFloat   (float v) { asm("syscall 0x2309"); }
void emitString  (char *v) { asm("syscall 0x230A"); }
void startTracing()        { asm("syscall 0x230B"); }
void stopTracing()         { asm("syscall 0x230C"); }

void testIntToFloat() {
	int table[] = {8, 10, 12};
	int n;
	float x = 0;

	emitFloat(x);
	for (n = 0; n < sizeof(table) / sizeof(table[0]); n++) {
		x += table[n];
		emitFloat(x);
	}
}

void testFloatManip() {
	float f1 = -8.4;
	float f2 = +4.8;
	FLOAT ff;

	ff = *(FLOAT *)&f1;
	emitInt(ff.sign);
	emitInt(ff.exponent);
	emitInt(ff.mantissa);

	ff = *(FLOAT *)&f2;
	emitInt(ff.sign);
	emitInt(ff.exponent);
	emitInt(ff.mantissa);
}

void testFloatExtra() {
	float y = 0.;
	float x = 16.4;
	int n = 0;

	y = (float)frexp(x, &n );
	emitFloat(y);
	emitInt(n);
	//assert(y == 0.512500);
	//assert(n == 5);
}

void testBitOps() {
	unsigned int value = 0x73A4C5F0;
	unsigned int v1 = 1;
	unsigned int v2 = 1;
	v2 += 2;
	emitInt((value >> 7) & 0x7);
	emitInt(v1 ^ v2);
}

typedef struct {
	float x, y, z;
} Vector;

void testString() {
	Vector pos;
	char temp[64];
	float value = 2.6112;
	sprintf(temp, "x: %.2f, y: %.2f, z: %.2f", 2.6112, 240.0, 220.0);
	//sprintf(temp, "x: %.2f y: %.2f z: %.2f", pos.x, pos.y, pos.z);
	//pspDebugScreenPrintf("x: %.2f y: %.2f z: %.2f",pos.x,pos.y,pos.z);
	emitString(temp);
}

void testSimpleString() {
	char temp[64];
	startTracing();
	sprintf(temp, "%f", 240.0);
	stopTracing();
	emitString(temp);
	assert(0);
}

void testBitExtract() {
	unsigned int value = 0xC493A10F;
	int n;
	emitString("normal");
	for (n = 0; n < 32; n++) {
		emitInt((value >> n) & 1);
	}
	emitString("reversed");
	for (n = 31; n >= 0; n--) {
		emitInt(((value << n) & 0x80000000) >> 31);
	}
	assert(0);
}

int main(int argc, char* argv[]) {
	/*
	char temp[16];
	//asm("break");
	sprintf(temp, "%f", 240.0);
	asm("break");
	*/
	//testBitExtract();
	testSimpleString();
	testIntToFloat();
	testFloatExtra();
	//testFloatManip();
	testBitOps();
	testString();

	return 0;
}