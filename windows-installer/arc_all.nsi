; ARC v1+v2 Installer
; This script requires arc_setup_base.nsi.

; Copyright (C) 2013 Embecosm Limited
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


; The following line is included to work around a bug with the "long string" version...
!include "EnvVarUpdate.nsh"
!define prodname "ARC48"
!define arctitle "ARC GNU Toolchain"
!define arcprefix "ARC"
!define arcsuffix ""

!include "arc_setup_base.nsi"

