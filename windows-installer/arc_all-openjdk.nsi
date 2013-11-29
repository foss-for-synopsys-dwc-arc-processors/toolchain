; ARC v1+v2 Installer
; Contributor: Simon Cook <simon.cook@embecosm.com>
; This script requires arc_setup_base.nsi.

; The following line is included to work around a bug with the "long string" version...
!include "EnvVarUpdate.nsh"
!define prodname "ARC48"
!define arctitle "ARC GNU Toolchain"
!define arcprefix "ARC-openjdk"
!define arcsuffix "-openjdk"

!include "arc_setup_base.nsi"

