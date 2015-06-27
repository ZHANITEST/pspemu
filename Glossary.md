# D Language #

D is a evolving compiled language.
It's fast like C/C++. But it have high level features like Java or C#.
It's not stalled like C and because there is only a frontend there are not compatibility problems.
It support a lot of features from a lot of different languages.
D has CTFE (Compile Time Function Evaluation), templates and mixins, that allow creating functions/classes/attributes at compile time with ease to allow optimized and very fast classes and functions.
D also allows assembler inlining with intel syntax that works on all PC oses: windows, linux, mac.
So you don't have the problem of having two times the same assembler. One por Visual Studio in intel-like and other in GAS-like for GCC.

D has the "module" approach like Java, C# and python. In contrast of C/C++, PHP that have a global space.
It allow better encapsulation and avoids the needed of header files with prototypes (they are nasty).

http://digitalmars.com/d/ Articles section from that page is very interesting.

D Features:
http://digitalmars.com/d/2.0/comparison.html
http://digitalmars.com/d/2.0/features2.html

D is a great language for making emulators.

# DMD #

[DMD](http://digitalmars.com/d/2.0/) is the Digital Mars D compiler. Created by Walter Bright (the creator of D). Is the main D compiler. That guy created a C++ compiler by himself. And the whole D language.
There are several D compilers.
[DMD](http://www.digitalmars.com/d/2.0/changelog.html) (the one from Walter Bright), [GDC](http://bitbucket.org/goshawk/gdc/wiki/Home) (one based on GCC), [LDC](http://www.dsource.org/projects/ldc) (one based on LLVM).

GDC knows to work even on PSP:
http://forums.qj.net/psp-development-forum/142864-how-program-d-psptoolchain-gdc.html

DMD compiler works on Windows, Linux and Mac.

More information about D:
http://en.wikipedia.org/wiki/D_(programming_language)
http://digitalmars.com/d/

# DFL #

[D Forms Library](http://www.dprogramming.com/dfl.php)

Is a OO library for handling forms in windows. It wraps Windows API. And it's very easy and convenient to use.

There are other alternatives, but I finally chose that because I used it in the past and other uses Tango.
The problem is that DFL only works on Windows. DWT for example is multiplatform.
But I prepared the pspemu 2.0 in a way that doesn't rely on GUI. So I would be able to change the GUI library or making an implementation for linux/mac.

```
import dfl.all;

class MyForm : Form {
	this() {
		text = "DFL Example";
	
		with (new Label) {
			font = new Font("Verdana", 14f);
			text = "Hello, DFL World!";
			location = Point(15, 15);
			autoSize = true;
			parent = this;
		}
	}
}

int main() {
	Application.run(new MyForm);
	
	return 0;
}

```

# DDBG #

DDBG is a debugger for D. It allows to debug D and to see stack traces if it is not able to handle an exception. I embeded the use of DDBG using run.bat.

```
dmd\windows\bin\ddbg -cmd "r;us;q" pspemu.exe %*

...
Loader.load Exception: object.Exception: Not implemented relocation yet.
Unhandled D Exception (object.Exception
 "Not implemented relocation yet.") at KERNELBASE.dll (0x7660b727) thread(984)
->us
#0 ?? () at pspemu\hle\Loader.d:162 from KERNELBASE.dll
#1 0x0049447c in __d_throw@4 () at pspemu\hle\Loader.d:162 from deh
#2 0x0041c578 in _D6pspemu3hle6Loader6Loader4loadMFAyaZv () at pspemu\hle\Loader.d:162
#3 0x004a2974 in extern (C) int rt.dmain2.main(int, char**) . void runMain(void*) () from dmain2
#4 0x004a29b1 in extern (C) int rt.dmain2.main(int, char**) . void runAll(void*) () from dmain2
#5 0x004a2724 in _main () from dmain2
#6 0x00519f85 in _mainCRTStartup () from constart
#7 0x74df3677 in ?? () from KERNEL32.dll
#8 0x77199d72 in ?? () from ntdll.dll
#9 0x77199d45 in ?? () from ntdll.dll
```