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
            .cdecls C,LIST,"msp430.h"       ; Include device header file
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
;I2CIN       .set    P6IN                    ; I2C input
;I2COUT      .set    P6OUT                   ; I2C output
;I2CDIR      .set    P6DIR                   ; I2C direction
;12CREN      .set    P6REN                   ; I2C pulling enable
;I2CSEL0     .set    P6SEL0                  ; I2C port selection register 0
;I2CSEL1     .set    P6SEL1                  ; I2C port selection register 1
;I2CSELC     .set    P6SELC                  ; I2C complement selection (likely unused)
Delay       .set    R15
Send_count  .set    R14
Message     .set    R13
AckReg      .set    R12                     ; Acknowledge flag
;-End Constants----------------------------------------------------------------

;------------------------------------------------------------------------------
; Initialize
;------------------------------------------------------------------------------

init:
    mov.w   #WDTPW+WDTHOLD,&WDTCTL          ; Stop WDT

    ; Initialize the SDA
    bic.b   #SDA, &P6SEL0                   ; GPIO fuctionality
    bic.b   #SDA, &P6SEL1
    bis.b   #SDA, &P6DIR                    ; Output mode (initially)
    bis.b   #SDA, &P6OUT                    ; Initially high
    bic.b   #SDA, &P6REN                    ; Input PUD resistor disabled

    ; Initialize the SCL
    bic.b   #SCL, &P6SEL0                   ; GPIO fuctionality
    bic.b   #SCL, &P6SEL1
    bis.b   #SCL, &P6DIR                    ; Output mode
    bis.b   #SCL, &P6OUT                    ; Initially high

    bic.w   #LOCKLPM5,&PM5CTL0              ; Disable low-power mode
;-End Initialize---------------------------------------------------------------


;------------------------------------------------------------------------------
; Main
;------------------------------------------------------------------------------
main:
    call    #i2c_routine
    jmp     main

;-End Main---------------------------------------------------------------------

;------------------------------------------------------------------------------
; I2C routine
;------------------------------------------------------------------------------
i2c_routine:
    mov.b   #0AAh, Message      ; Set register address 55h, write bit
    call    #i2c_start          ; Trigger start condition
    call    #i2c_send           ; Send the register address
    call    #i2c_ack_recieve    ; Recieve ack/nack
i2c_first_byte:
    mov.b   #41h, Message       ; Set the first byte of information
    call    #i2c_send           ; Send the byte
    call    #i2c_ack_recieve    ; Recieve ack/nack
    call    #i2c_end            ; Trigger stop condition
    ret

;-End I2C routine--------------------------------------------------------------

;------------------------------------------------------------------------------
; Start Condition
;------------------------------------------------------------------------------
i2c_start:
    call    #i2c_sda_low        ; Set SDA low
    call    #i2c_scl_low        ; Set SCL low
    ret

;-End Start Condition---------------------------------------------------------------------

;------------------------------------------------------------------------------
; End Condition
;------------------------------------------------------------------------------
i2c_end:
    call    #i2c_sda_low        ; Set SDA low
    call    #i2c_scl_high       ; Set SCL high
    call    #i2c_sda_high       ; Set SDA high
    ret

;-End End Condition------------------------------------------------------------

;------------------------------------------------------------------------------
; Send Message
;------------------------------------------------------------------------------
i2c_send:
    mov.b   #08h, Send_count    ; Send an 8-bit message
i2c_send_loop: 
    call    #i2c_send_rotate
    call    #i2c_scl_low        ; Set SCL low
    dec.w   Send_count          ; Decrement counter
    jnz     i2c_send_loop       ; Counter non-zero, more bits to send
    ret
i2c_send_rotate:
    clrc                        ; Clear the carry flag
    rla.b   Message             ; Rotate the MSB to the carry flag
    jnc     i2c_send_low        ; Set SDA low if carry flag is zero
i2c_send_high:
    call    #i2c_sda_high       ; Set SDA high
    bis.b   #SCL, &P6OUT        ; Set SCL high - no delay
    ret
i2c_send_low:
    call    #i2c_sda_low        ; Set SDA low
    bis.b   #SCL, &P6OUT        ; Set SCL high - no delay
    ret
;-End Send Message-------------------------------------------------------------

;------------------------------------------------------------------------------
; Acknowledge Send from Master
;------------------------------------------------------------------------------
i2c_ack_send:
    call    #i2c_sda_low        ; Set SDA low
    call    #i2c_scl_high       ; Set SCL high
    call    #i2c_scl_low        ; Set SCL low
    ret    

;-End Ack Send-----------------------------------------------------------------

;------------------------------------------------------------------------------
; Acknowledge Recieve from Slave
;------------------------------------------------------------------------------
i2c_ack_recieve:
    bis.b   #SDA, &P6DIR        ; Input mode (for now)
    bis.b	#SDA, &P6OUT		; Set pull-up resistor
	bis.b	#SDA, &P6REN		; Enable input PUD resistor
	mov.w	#05h, Delay         ; Long delay

    bis.b   #SCL, P6OUT         ; Set SCL high
    mov.w   #01h, Delay         ; Short delay
    call    #delay

    mov.w   #P6IN, AckReg       ; Capture potential ACK/NACK
    and.b	#SDA, AckReg		; Clear all unimportant bits

    bic.b   #SCL, P6OUT         ; Set SCL low
    mov.w   #05h, Delay         ; Long delay
    call    #delay

    bic.b	#SDA, &P6REN		; Disable input PUD resistor
    bis.b   #SDA, &P6DIR        ; Output mode
    
    ret

;-End Ack Recieve---------------------------------------------------------------

;------------------------------------------------------------------------------
; Control SDA and SCL
;------------------------------------------------------------------------------
i2c_sda_high:
    bis.b   #SDA, P6OUT         ; Set SDA low
    mov.w   #01h, Delay         ; Short delay
    call    #delay
    ret

i2c_sda_low:
    bic.b   #SDA, P6OUT         ; Set SDA low
    mov.w   #01h, Delay         ; Short delay
    call    #delay
    ret

i2c_scl_high:
    bis.b   #SCL, P6OUT         ; Set SCL high
    mov.w   #01h, Delay         ; Short delay
    call    #delay
    ret

i2c_scl_low:
    bic.b   #SCL, P6OUT         ; Set SCL low
    mov.w   #01h, Delay         ; Short delay
    call    #delay
    ret
;-End Control SDA and SCL------------------------------------------------------

;------------------------------------------------------------------------------
; Delay loop
;------------------------------------------------------------------------------
delay:
    dec.w   Delay               ; Decrement loop counter
    jnz     delay               ; Loop is not done; keep decrementing
    ret                         ; Loop is done
;-End Delay--------------------------------------------------------------------

;------------------------------------------------------------------------------
; Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;