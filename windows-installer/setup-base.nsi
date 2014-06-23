; ARC 4.8 Installer Base Script

; Copyright (C) 2013 Synopsys Inc.
; Contributor: Simon Cook <simon.cook@embecosm.com>

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

;=================================================
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
;!include "EnvVarUpdate.nsh" (placed in top level script to avoid crashing)

;=================================================
; Settings
  
  # File and Installer Name
  outfile "${prodname}_${arcver}_win_install.exe"
  Name "${arctitle} ${arcver}"
 
  # Default directory  
  installDir "C:\${prodname}_${arcver}"

  # Enable CRC
  CRCCheck on

  # Compression
  SetCompress force
  #SetCompressor zlib
  SetCompressor /FINAL lzma

  # Our registry key for uninstallation
  !define uninstreg "Software\Microsoft\Windows\CurrentVersion\Uninstall\${prodname}"

  # We want admin rights
  RequestExecutionLevel admin

;=================================================
; Pages to Use

  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;=================================================
; On start, we want to ensure we have admin rights

Function .onInit
  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin" ;Require admin rights on NT4+
      MessageBox mb_iconstop "Administrator rights are required to install this program."
      SetErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
      Quit
  ${EndIf}
FunctionEnd

;=================================================
; Default section - files to install

  section
    !include "install_files.nsi"
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Write registry entries for uninstaller
    WriteRegStr HKLM "${uninstreg}" "DisplayName" "${arctitle} ${arcver}"
    WriteRegStr HKLM "${uninstreg}" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "${uninstreg}" "EstimatedSize" "$0"
    WriteRegDWORD HKLM "${uninstreg}" "NoModify" "1"
    WriteRegDWORD HKLM "${uninstreg}" "NoRepair" "1"

    !define shelldir "${arctitle} ${arcver}"

    ; Add install directory to PATH and create shortcut to Eclipse
    ; See http://nsis.sourceforge.net/Environmental_Variables:_append,_prepend,_and_remove_entries
    ; NOTE THAT WE NEED A CUSTOM BUILD OF NSIS THAT SUPPORTS LONGER STRINGS TO SUPPORT THIS VERSION!!!
    ; http://nsis.sourceforge.net/Special_Builds       (has build for 8192 length strings)
    ; http://nsis.sourceforge.net/Docs/AppendixG.html  (to build yourself)
    ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR\bin"
    SetShellVarContext all
    CreateDirectory "$SMPROGRAMS\${shelldir}"
    CreateShortCut "$SMPROGRAMS\${shelldir}\${arctitle} ${arcver} Command Prompt.lnk" '%comspec%' '/k "$INSTDIR\arcshell.bat"'
    CreateShortCut "$DESKTOP\${arctitle} ${arcver} Eclipse.lnk" "$INSTDIR\eclipse\eclipse.exe" "" "$INSTDIR\eclipse\eclipse.exe" 0
    CreateShortCut "$SMPROGRAMS\${shelldir}\${arctitle} ${arcver} Eclipse.lnk" "$INSTDIR\eclipse\eclipse.exe" "" "$INSTDIR\eclipse\eclipse.exe" 0
    CreateShortCut "$SMPROGRAMS\${shelldir}\Uninstall ${arctitle} ${arcver}.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
    CreateShortCut "$SMPROGRAMS\${shelldir}\Documentation.lnk" "$INSTDIR\share\doc" 0
  sectionend

;=================================================
; Uninstaller

  section "Uninstall"
    SetShellVarContext all
    Delete "$DESKTOP\${arctitle} ${arcver} Eclipse.lnk"
    Delete "$SMPROGRAMS\${arctitle}\${arctitle} ${arcver} Eclipse.lnk"
    Delete "$SMPROGRAMS\${arctitle}\${arctitle} ${arcver} Command Prompt.lnk"
    Delete "$SMPROGRAMS\${arctitle}\Uninstall ${arctitle} ${arcver}.lnk"
    RmDir "$SMPROGRAMS\${arctitle}"
    ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR\bin"
    !include "uninstall_files.nsi"
    Delete "$INSTDIR\Uninstall.exe"
    DeleteRegKey HKLM "${uninstreg}"
    RMDir "$INSTDIR"
  sectionend

