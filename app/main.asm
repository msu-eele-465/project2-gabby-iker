;-------------------------------------------------------------------------------
; Include files
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------

            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer

;------------------------------------------------------------------------------
; Initialize
;------------------------------------------------------------------------------

init:
    mov.w   #WDTPW+WDTHOLD,&WDTCT           ; stop watchdog timer     
    
    bic.w   #LOCKLPM5,&PM5CTL0              ; Disable low-power mode
;-End Initialize---------------------------------------------------------------


;------------------------------------------------------------------------------
; Main
;------------------------------------------------------------------------------
main:

    nop 
    jmp main
    nop
;-End Main---------------------------------------------------------------------

;------------------------------------------------------------------------------
; Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;
