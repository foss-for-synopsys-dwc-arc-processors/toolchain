; ARC GNU Installer

; Copyright (C) 2014 Synopsys Inc.

; Contributor: Simon Cook <simon.cook@embecosm.com>
; Contributor: Anton Kolesov <Anton.Kolesov@synopsys.com>

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

; This script requires setup-base.nsi.

; The following line is included to work around a bug with the "long string" version...
!include "EnvVarUpdate.nsh"
!define entry_name "arc_gnu"
!define arctitle "ARC GNU IDE"

!include "setup-base.nsi"

