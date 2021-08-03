; ARC GNU Installer Base Script

; Copyright (C) 2013-2017 Synopsys Inc.
;
; Contributor: Simon Cook <simon.cook@embecosm.com>
; Contributor: Anton Kolesov  <anton.kolesov@synopsys.com>

; This program is free software; you can redistribute it and/or modify it
; under the terms of the GNU General Public License as published by the Free
; Software Foundation; either version 3 of the License, or (at your option)
; any later version.

; This program is distributed in the hope that it will be useful, but WITHOUT
; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
; more details.

; You should have received a copy of the GNU General Public License along
; with this program.  If not, see <http://www.gnu.org/licenses/>.          

!include "EnvVarUpdate.nsh"
!define entry_name "arc_gnu"
!define arctitle "ARC GNU IDE"

!define snps_startmenu_dir "Synopsys Inc"
!define startmenu_dir "${snps_startmenu_dir}\${arctitle} ${arcver}"

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

;=================================================
; Check for mandatory variable
!ifndef arcver
  !error "arcver varaible must be defined."
!endif

# Check that NSIS build for large strings is used
!if ${NSIS_MAX_STRLEN} < 8192
    !error "NSIS_MAX_STRLEN is ${NSIS_MAX_STRLEN} which is less than 8192, \
    Please see comments in installer.nsi for details on installing NSIS 'big \
    string' version."
!endif

;=================================================
; Settings

# File and Installer Name
outfile "${entry_name}_${arcver}_ide_win_install.exe"
Name "${arctitle} ${arcver}"

# Default directory
installDir "C:\${entry_name}"

# Enable CRC
CRCCheck on

# Compression
SetCompress force
# SetCompressor zlib
SetCompressor /FINAL lzma

# Our registry key for uninstallation
!define uninstreg "Software\Microsoft\Windows\CurrentVersion\Uninstall\${entry_name}"

# We want admin rights
RequestExecutionLevel admin

;=================================================

# Defines for pages must be before page macro insertion.
!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "snps_logo.bmp"

!insertmacro MUI_PAGE_LICENSE "Synopsys_FOSS_Notices.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

# Uninstaller pages mostly use same defines as installer ones, so to have
# different texts, defiens should be done twice: for install page and for
# uninstall page.
!define MUI_FINISHPAGE_TEXT "Please note: uninstall process can only remove \
files created by the installer. Programs like Eclipse may create files \
which will be left behind by the installer. Users should manually remove these \
file after uninstall to avoid any problems, especially when uninstalling to \
upgrade to new version being re-installed to same location."

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

;=================================================
; On start, we want to ensure we have admin rights
; (akolesov): But do we really need this func? We already have
; `RequestExecutionLEvem admin`...

Function .onInit
  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin" ;Require admin rights on NT4+
      MessageBox mb_iconstop "Administrator rights are required to install this program."
      SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
      Quit
  ${EndIf}

  ReadRegStr $0 HKLM "${uninstreg}" "UninstallString"
  ${If} $0 != ""
    MessageBox mb_iconstop "Please, uninstall previous version of ${arctitle} first."
    Abort
  ${EndIf}
FunctionEnd

#
# Default section - always installed
#
section ""
    SetOutPath "$INSTDIR"
    File /r tmp\common\*
    # Make sure that /bin exists (will be added to the PATH).
    SetOutPath "$INSTDIR\bin"

    SetOutPath "$INSTDIR\eclipse"

    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Write registry entries for uninstaller
    WriteRegStr HKLM "${uninstreg}" "DisplayName" "${arctitle} ${arcver}"
    WriteRegStr HKLM "${uninstreg}" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "${uninstreg}" "EstimatedSize" "$0"
    WriteRegDWORD HKLM "${uninstreg}" "NoModify" "1"
    WriteRegDWORD HKLM "${uninstreg}" "NoRepair" "1"

    ; Add install directory to PATH and create shortcut to Eclipse
    ; See http://nsis.sourceforge.net/Environmental_Variables:_append,_prepend,_and_remove_entries
    ; NOTE THAT WE NEED A CUSTOM BUILD OF NSIS THAT SUPPORTS LONGER STRINGS TO
    ; SUPPORT THIS VERSION!!!
    ; http://nsis.sourceforge.net/Special_Builds (has build for 8192 length strings)
    ; http://nsis.sourceforge.net/Docs/AppendixG.html  (to build yourself)
    ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\bin"
    SetShellVarContext all

    # Create shortcuts
    CreateDirectory "$SMPROGRAMS\${startmenu_dir}"
    CreateShortCut "$SMPROGRAMS\${startmenu_dir}\${arctitle} ${arcver} Command Prompt.lnk" \
	'%comspec%' '/k "$INSTDIR\arcshell.bat"'
    CreateShortCut "$SMPROGRAMS\${startmenu_dir}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
    CreateShortCut "$SMPROGRAMS\${startmenu_dir}\GNU Toolchain User Guide.lnk" \
	"$INSTDIR\share\doc\GNU_Toolchain_for_ARC.pdf"
    CreateShortCut "$SMPROGRAMS\${startmenu_dir}\IDE Documentation online.lnk" \
      "https://foss-for-synopsys-dwc-arc-processors.github.io/toolchain/ide/index.html"
    CreateShortCut "$SMPROGRAMS\${startmenu_dir}\IDE Releases on GitHub.lnk" \
      "https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain/releases"
SectionEnd

#
# Optional sections
#

# Toolchain little-endian
Section "GNU Toolchain for ARC" SecToolchain
    SetOutPath "$INSTDIR"
    File /r tmp\toolchain_le\*

    # Create shortcuts
    SetShellVarContext all
    CreateShortCut "$SMPROGRAMS\${startmenu_dir}\Documentation.lnk" "$INSTDIR\share\doc"
SectionEnd

Section un.SecToolchain
    !include "section_toolchain_le_uninstall.nsi"

    # Remove shortcuts
    SetShellVarContext all
    Delete "$SMPROGRAMS\${startmenu_dir}\Documentation.lnk"
SectionEnd

LangString DESC_SecToolchain ${LANG_ENGLISH} \
    "Baremetal GNU Toolchain for ARC processors (little endian)"

# Toolchain big-endian
Section /o "GNU Toolchain for ARC (big endian)" SecToolchainBE
    SetOutPath "$INSTDIR"
    File /r tmp\toolchain_be\*

    # Create shortcuts (dup of little-endian)
    SetShellVarContext all
    CreateShortCut "$SMPROGRAMS\${startmenu_dir}\Documentation.lnk" "$INSTDIR\share\doc"
SectionEnd

Section un.SecToolchainBE
    !include "section_toolchain_be_uninstall.nsi"

    # Remove shortcuts (dup of little-endian)
    SetShellVarContext all
    Delete "$SMPROGRAMS\${startmenu_dir}\Documentation.lnk"
SectionEnd

LangString DESC_SecToolchainBE ${LANG_ENGLISH} \
    "Baremetal GNU Toolchain for ARC processors (big endian)"

# Eclipse
Section "Eclipse IDE for ARC" SecEclipse
    SetOutPath "$INSTDIR"
    File /r tmp\eclipse\*

    SetShellVarContext all

    # Desktop shortcut
    CreateShortCut "$DESKTOP\${arctitle} ${arcver} Eclipse.lnk" \
	"$INSTDIR\eclipse\eclipse.exe"
    # Start menu items. Default section is done first, so directories exist.
    CreateShortCut \
	"$SMPROGRAMS\${startmenu_dir}\${arctitle} ${arcver} Eclipse.lnk" \
	"$INSTDIR\eclipse\eclipse.exe"
SectionEnd

Section un.SecEclipse
    SetShellVarContext all
    !include "section_eclipse_uninstall.nsi"

    # Desktop shortcut
    Delete "$DESKTOP\${arctitle} ${arcver} Eclipse.lnk"
    # Start menu entry
    Delete "$SMPROGRAMS\${startmenu_dir}\${arctitle} ${arcver} Eclipse.lnk"
SectionEnd

LangString DESC_SecEclipse ${LANG_ENGLISH} \
    "Eclipse IDE for C/C++ development for ARC processors"

# JRE
Section "Java runtime for Eclipse" SecJRE
    SetOutPath "$INSTDIR"
    File /r tmp\jre\*
SectionEnd

Section un.SecJRE
    !include "section_jre_uninstall.nsi"
SectionEnd

LangString DESC_SecJRE ${LANG_ENGLISH} \
    "Private copy of Java runtime for Eclipse. Not required if your machine already has \
Java runtime >= 1.7 installed."

# MSYS core utils
Section "MSYS Core Utils" SecMSYSCoreUtils
    SetOutPath "$INSTDIR"
    File /r tmp\coreutils\*
SectionEnd

Section un.SecMSYSCoreUtils
    !include "section_coreutils_uninstall.nsi"
SectionEnd

LangString DESC_SecMSYSCoreUtils ${LANG_ENGLISH} \
    "*nix core utilites: cp, mv, tail, etc. Required for Eclipse IDE."

# GNU make
Section "GNU Make" SecGNUMake
    SetOutPath "$INSTDIR"
    File /r tmp\make\*
SectionEnd

Section un.SecGNUMake
    !include "section_make_uninstall.nsi"
SectionEnd

LangString DESC_SecGNUMake ${LANG_ENGLISH} \
    "GNU make. Required for IDE for ARC."

# OpenOCD
Section "OpenOCD" SecOpenOCD
    SetOutPath "$INSTDIR"
    File /r tmp\openocd\*
SectionEnd

Section un.SecOpenOCD
    !include "section_openocd_uninstall.nsi"
SectionEnd

LangString DESC_SecOpenOCD ${LANG_ENGLISH} \
    "Required to connect to hardware targets via JTAG."

# Now assign descriptions to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMSYSCoreUtils} $(DESC_SecMSYSCoreUtils)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecGNUMake} $(DESC_SecGNUMake)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecOpenOCD} $(DESC_SecOpenOCD)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecToolchain} $(DESC_SecToolchain)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecToolchainBE} $(DESC_SecToolchainBE)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecEclipse} $(DESC_SecEclipse)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecJRE} $(DESC_SecJRE)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

#
# Default section - always uninstalled
#
Section "Uninstall"
    SetShellVarContext all
    !include "section_common_uninstall.nsi"

    ; Start menu entries
    Delete "$SMPROGRAMS\${startmenu_dir}\${arctitle} ${arcver} Command Prompt.lnk"
    Delete "$SMPROGRAMS\${startmenu_dir}\Uninstall.lnk"
    Delete "$SMPROGRAMS\${startmenu_dir}\Documentation.lnk"
    Delete "$SMPROGRAMS\${startmenu_dir}\IDE Wiki on GitHub.lnk"
    Delete "$SMPROGRAMS\${startmenu_dir}\IDE Releases on GitHub.lnk"
    Delete "$SMPROGRAMS\${startmenu_dir}\GNU Toolchain User Guide.lnk"
    RmDir "$SMPROGRAMS\${startmenu_dir}"
    RmDir "$SMPROGRAMS\${snps_startmenu_dir}"

    ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"
    Delete "$INSTDIR\Uninstall.exe"
    DeleteRegKey HKLM "${uninstreg}"
    # bin is always created, so should be always removed.
    RMDir "$INSTDIR\bin"
    RMDir "$INSTDIR"
SectionEnd

