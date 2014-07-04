@echo off
REM This batch scripts adds toolchain bin and eclipse to PATH
REM and sets CD to User's home directory
REM Contributor: Simon Cook <simon.cook@embecosm.com>

@set "PATH=%~dp0bin;%~dp0eclipse;%PATH%"
%HOMEDRIVE%
cd "%HOMEPATH%"
