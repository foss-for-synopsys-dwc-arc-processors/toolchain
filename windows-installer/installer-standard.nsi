; ARC GNU IDE Installer
; Contributor: Simon Cook <simon.cook@embecosm.com>
; Contributor: Anton Kolesov <Anton.Kolesov@synopsys.com>
; This script requires setup-base.nsi.

; The following line is included to work around a bug with the "long string" version...
!include "EnvVarUpdate.nsh"
!define entry_name "arc_gnu"
!define arctitle "ARC GNU IDE"

!include "setup-base.nsi"

