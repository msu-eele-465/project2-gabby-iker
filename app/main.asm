;-------------------------------------------------------------------------------
; EELE 465, Project 2, 23 January 2025
; Gabriella Lord
;
; P6.0  SDA (Serial Data Line)
; P6.1  SCL (Serial clock line)
; R15   Delay register
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
Delay       .set    R15
Send_count  .set    R14
Message     .set    R13
;-End Constants----------------------------------------------------------------

;------------------------------------------------------------------------------
; Initialize
;------------------------------------------------------------------------------

init:
    mov.w   #WDTPW+WDTHOLD,&WDTCTL          ; Stop WDT   

    bic.w   #LOCKLPM5,&PM5CTL0              ; Disable low-power mode
;-End Initialize---------------------------------------------------------------


;------------------------------------------------------------------------------
; Main
;------------------------------------------------------------------------------
main:
    nop
    mov.b   #055h, Message
    call #i2c_start
    call #send_message
    call #i2c_end
    jmp main
    nop

;-End Main---------------------------------------------------------------------

;------------------------------------------------------------------------------
; Start Condition
;------------------------------------------------------------------------------
i2c_start:
    bic.b   #SDA, &P6OUT
    call    #delay

    bic.b   #SCL, &P6OUT
    call    #delay
    ret

;-End Start Condition---------------------------------------------------------------------

;------------------------------------------------------------------------------
; End Condition
;------------------------------------------------------------------------------
i2c_end:
    bic.b   #SDA, &P6OUT
    bis.b   #SCL, &P6OUT        ; 
    call    #delay              ; Delay
    bis.b	#SDA, &P6OUT       ; Pull SDA high
    ret

;-End End Condition------------------------------------------------------------

;-Send Message-----------------------------------------------------------------
send_message:
    mov.b   #07h, Send_count
    bis.b   #0x01, &P6DIR    ; Configura P6.0 como salida (P6DIR = 0x01)
L2  call    #send_byte
    bic.b   #SCL, &P6OUT
    call    #delay
    rla.b   Message                    
    dec.w   Send_count
    jnz     L2
    ret
;------------------------------------------------------------------------------
;Send Byte--------------------------------------------------------------------
send_byte:

    ; Read the value of X (for example, X is stored in R12)
    tst.b   Message          ; Compare X (stored in R13) with 0
    jz      P6OUT_0          ; If X is 0, jump to P6OUT_0 (set P6.0 low)

    bis.b   #0x01, &P6OUT    ; If X is 1, set P6.0 high/Set P6.0 high (1)
    bis.b   #SDA, &P6OUT
    call    #delay
    bis.b   #SCL, &P6OUT
    jmp     END_SEND         

P6OUT_0:                     ; Jump here if X was 0
    bic.b   #0x01, &P6OUT    ; Set P6.0 low (0)
    bic.b   #SDA, &P6OUT
    call    #delay
    bis.b   #SCL, &P6OUT
    ret

END_SEND:
    ret
; Delay loop

;------------------------------------------------------------------------------
delay:
    mov.w   #088F6h, Delay          ; Initialize inner loop counter for 100 ms delay
L1:
    dec.w   Delay                   ; Decrement inner loop counter
    jnz     L1                      ; Inner loop is not done; keep decrementing

    ret                             ; Outer loop is done

;-End Delay----------------------------------------------------------------------------


;------------------------------------------------------------------------------
; Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;
