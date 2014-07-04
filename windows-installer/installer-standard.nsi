; ARC GNU IDE Installer
; Contributor: Simon Cook <simon.cook@embecosm.com>
; Contributor: Anton Kolesov <Anton.Kolesov@synopsys.com>
; ; This script requires setup-base.nsi.

; The following line is included to work around a bug with the "long string" version...
!include "EnvVarUpdate.nsh"
!define prodname "ARC_GNU_IDE"
!define arctitle "ARC GNU IDE"

# This is undefined intentionally. Insert here proper version that you are
# releasing, e.g. 1.1.0.
#!define arcver "1.1.0"

!include "setup-base.nsi"

