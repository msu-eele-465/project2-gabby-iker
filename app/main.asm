;-------------------------------------------------------------------------------
; EELE 465, Project 2, 23 January 2025
; Gabriella Lord
;
; P6.0 SDA (Serial Data Line)
; P6.1 SCL (Serial clock line)
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
SDA			.set	BIT0					; I2C data pin
SCL			.set	BIT1					; I2C clock pin
I2C         .set    SDA + SCL               ; I2C pins
;I2CIN       .set    P6IN                    ; I2C input (likely unused)
;I2COUT      .set    P6OUT                   ; I2C output
;I2CDIR      .set    P6DIR                   ; I2C direction
;12CREN      .set    P6REN                   ; I2C pulling enable
;I2CSEL0     .set    P6SEL0                  ; I2C port selection register 0
;I2CSEL1     .set    P6SEL1                  ; I2C port selection register 1
;I2CSELC     .set    P6SELC                  ; I2C complement selection (likely unused)

;-End Constants----------------------------------------------------------------

;------------------------------------------------------------------------------
; Initialize
;------------------------------------------------------------------------------

init:
    mov.w   #WDTPW+WDTHOLD,&WDTCTL          ; Stop WDT

    ; Initialize I2C data pin
    bic.b	#SDA, &P6SEL0                   ; General purpose I/O is selected
	bic.b	#SDA, &P6SEL1                   ; General purpose I/O is selected
    bis.b   #SDA, &P6OUT                    ; Set I2C output high
    bis.b   #SDA, &P6DIR                    ; SDA output direction (initially)
    bic.b   #SDA, &P6REN                    ; PUD resistor disabled

    ; Initialize I2C clock pin
    bic.b	#SCL, &P6SEL0                   ; General purpose I/O is selected
	bic.b	#SCL, &P6SEL1                   ; General purpose I/O is selected
    bis.b   #SCL, &P6OUT                    ; Set I2C output high
    bis.b   #SCL, &P6DIR                    ; SDA output direction

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
; Start Condition
;------------------------------------------------------------------------------
i2c_start:
    nop

;-End Start Condition---------------------------------------------------------------------

;------------------------------------------------------------------------------
; End Condition
;------------------------------------------------------------------------------
i2c_end:
    nop

;-End End Condition---------------------------------------------------------------------

;------------------------------------------------------------------------------
; Delay loop

;------------------------------------------------------------------------------
delay:
    mov.w   #088F6h,R15             ; Initialize inner loop counter for 100 ms delay
L1:
    dec.w   R15                     ; Decrement inner loop counter
    jnz     L1                      ; Inner loop is not done; keep decrementing

    ret                             ; Outer loop is done

;-End Delay----------------------------------------------------------------------------


;------------------------------------------------------------------------------
; Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;
