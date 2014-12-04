;; *******************************************************************************************************************
;; -----------------
;; ARC start up file
;; -----------------
;; The startup code for the ARC family of processors does the following before transferring control to user defined
;; _main label :
;;		1. Set sp to __stack_top (link time variable)
;;		2. Set fp to zero
;; After returning from main, the processor is halted and the pipeline is flushed out
;;
;; *******************************************************************************************************************
	.file "crt0.s"

	.section .ivt, "a", @progbits
;; *******************************************************************************************************************
;// handler's name              type      number  name                    offset in IVT (hex/dec)
.word   __start             ;   exception   0   program entry point offset  0x0     0
.word   memory_error        ;   exception   1   memory_error        offset  0x4     4
.word   instruction_error   ;   exception   2   instruction_error   offset  0x8     8
.word   EV_MachineCheck     ;   exception   3   EV_MachineCheck     offset  0xC     12
.word   EV_TLBMissI         ;   exception   4   EV_TLBMissI         offset  0x10    16
.word   EV_TLBMissD         ;   exception   5   EV_TLBMissD         offset  0x14    20
.word   EV_ProtV            ;   exception   6   EV_ProtV            offset  0x18    24
.word   EV_PrivilegeV       ;   exception   7   EV_PrivilegeV       offset  0x1C    28
.word   EV_SWI              ;   exception   8   EV_SWI              offset  0x20    32
.word   EV_Trap             ;   exception   9   EV_Trap             offset  0x24    36
.word   EV_Extension        ;   exception   10  EV_Extension        offset  0x28    40
.word   EV_DivZero          ;   exception   11  EV_DivZero          offset  0x2C    44
.word   EV_DCError          ;   exception   12  EV_DCError          offset  0x30    48
.word   EV_Malignedr        ;   exception   13  EV_Maligned         offset  0x34    52
.word   _exit_halt          ;   exception   14  unused              offset  0x38    56
.word   _exit_halt          ;   exception   15  unused              offset  0x3C    60
.word   IRQ_Timer0          ;   IRQ         16  Timer 0             offset  0x40    64
.word   IRQ_Timer1          ;   IRQ         17  Timer 1             offset  0x44    68
.word   IRQ_18              ;   IRQ         18                      offset  0x48    72
.word   IRQ_19              ;   IRQ         19                      offset  0x4C    76
.word   IRQ_20              ;   IRQ         20                      offset  0x50    80
;; *******************************************************************************************************************

	.extern main
	.section .init

	.global __start
	.type __start, @function
__start:
	mov 	gp, @__SDATA_BEGIN__
	mov 	sp, @__stack_top ; initialize stack pointer, and this instruction has 2 words

	;; branch to main
	mov 	fp, 0 ; initialize frame pointer
	jl 	@main
		  ; r0 contains exit code
	j 	@_exit_halt


	.global abort
	.type abort, @function
	.align 4
abort:
	mov r0, 1
	j @_exit_halt

.weak   memory_error
.weak   instruction_error
.weak   EV_MachineCheck
.weak   EV_TLBMissI
.weak   EV_TLBMissD
.weak   EV_ProtV
.weak   EV_PrivilegeV
.weak   EV_SWI
.weak   EV_Trap
.weak   EV_Extension
.weak   EV_DivZero
.weak   EV_DCError
.weak   EV_Malignedr
.weak   IRQ_Timer0
.weak   IRQ_Timer1
.weak   IRQ_18
.weak   IRQ_19
.weak   IRQ_20

	.global _exit_halt
	.type _exit_halt, @function
	.align 4
memory_error        :
	b.d     _exit_halt
	mov	r0, 0x101
instruction_error   :
	b.d     _exit_halt
	mov	r0, 0x102
EV_MachineCheck     :
	b.d     _exit_halt
	mov	r0, 0x103
EV_TLBMissI         :
	b.d     _exit_halt
	mov	r0, 0x104
EV_TLBMissD         :
	b.d     _exit_halt
	mov	r0, 0x105
EV_ProtV            :
	b.d     _exit_halt
	mov	r0, 0x106
EV_PrivilegeV       :
	b.d     _exit_halt
	mov	r0, 0x108
EV_SWI              :
	b.d     _exit_halt
	mov	r0, 0x109
EV_Trap             :
	b.d     _exit_halt
	mov	r0, 0x10A
EV_Extension        :
	b.d     _exit_halt
	mov	r0, 0x10B
EV_DivZero          :
	b.d     _exit_halt
	mov	r0, 0x10C
EV_DCError          :
	b.d     _exit_halt
	mov	r0, 0x10D
EV_Malignedr        :
	b.d     _exit_halt
	mov	r0, 0x10E
IRQ_Timer0          :
	b.d     _exit_halt
	mov	r0, 0x110
IRQ_Timer1          :
	b.d     _exit_halt
	mov	r0, 0x111
IRQ_18              :
IRQ_19              :
IRQ_20              :
_exit_halt          :
	; r0 contains exit code
	flag 0x01
	nop
	nop
	nop
	b @_exit_halt
	nop
