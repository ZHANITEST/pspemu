@echo off
del pspemu.exe 2> NUL
xfbuild %* pspemu\main.d +xstd +xcore -d -Jimport -O -release -noboundscheck +o=pspemu.exe dfl/olepro32_dfl.lib dfl/shell32_dfl.lib dfl/user32_dfl.lib gdi32.lib comctl32.lib advapi32.lib comdlg32.lib ole32.lib uuid.lib ws2_32.lib import\psp.res