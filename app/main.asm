;-------------------------------------------------------------------------------
; EELE 465, Project 2, 23 January 2025
; Gabriella Lord
;
;-------------------------------------------------------------------------------

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
; Set Constants
;------------------------------------------------------------------------------

;-End Constants----------------------------------------------------------------

;------------------------------------------------------------------------------
; Initialize
;------------------------------------------------------------------------------

init:
    mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT   
    
    ; Initializing I2C (000111110)
    bic.b   #UCA10, &UCB0CTLW0              ; Master address is 7 bits
    bic.b   #UCSLA10, &UCB0CTLW0            ; Slave address is 7 bits
    bic.b   #UCMM, &UCB0CTLW0               ; Single master
    bis.b   #UCMST, &UCB0CTLW0              ; Set master mode
    bis.b   #UCMODE_3, &UCB0CTLW0           ; I2C mode
    bis.b   #UCSSEL_3, &UCB0CTLW0           ; SMCLK clock source 1 MHz
    bis.b   #UCTXACK, &UCB0CTLW0            ; ACK the slave address
    bis.b   #UCTR, &UCB0CTLW0               ; Transmitter mode
    bic.b   #UCTXNACK, &UCB0CTLW0           ; Acknowledge normally

    ; Configure P1.3 to use its ??? function
    bis.b	#BIT3, &P1SEL0
	bic.b	#BIT3, &P1SEL1
;    bic.b   #BIT3,&P1OUT            ; Clear P1.0 output
;    bis.b   #BIT3,&P1DIR            ; P1.0 output

    ; Configure P1.2 to use its analog function (A2)
    bis.b	#BIT2, &P1SEL0
	bic.b	#BIT2, &P1SEL1
;    bic.b   #BIT2,&P1OUT            ; Clear P1.0 output
;    bis.b   #BIT2,&P1DIR            ; P1.0 output

    
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
