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
    nop
    mov.b   #055h, Message
    call    #i2c_start
    call    #send_message
    call    #i2c_send_ack
    mov.b   #41h, Message
    call    #send_message
    call    #i2c_send_ack
    call    #i2c_end
    jmp     main

;-End Main---------------------------------------------------------------------

;------------------------------------------------------------------------------
; Start Condition
;------------------------------------------------------------------------------
i2c_start:
    bic.b   #SDA, &P6OUT                    ; Set SDA low
    mov.w   #01h, Delay                     ; Short delay
    call    #delay

    bic.b   #SCL, &P6OUT                    ; Set SCL low
    mov.w   #05h, Delay                     ; Long delay
    call    #delay

    ret

;-End Start Condition---------------------------------------------------------------------

;------------------------------------------------------------------------------
; End Condition
;------------------------------------------------------------------------------
i2c_end:
    bic.b   #SDA, &P6OUT
    mov.w   #05h, Delay
    call    #delay
    
    bis.b   #SCL, &P6OUT        ; Set SCL high
    mov.w   #05h, Delay         ; Short delay
    call    #delay              ; Delay

    bis.b	#SDA, &P6OUT        ; Pull SDA high
    mov.w   #05h, Delay         ; Long delay
    call    #delay

    ret

;-End End Condition------------------------------------------------------------

;------------------------------------------------------------------------------
; Send Message
;------------------------------------------------------------------------------
send_message:
    mov.b   #08h, Send_count
L2: 
    call    #send_byte
    bic.b   #SCL, &P6OUT
    mov.w	#05, Delay     		; Long delay 
    call    #delay         
    dec.w   Send_count
    jnz     L2
    ret

send_byte:
    clrc
    rla.b   Message
    jnc     P6OUT_0

P6OUT_1:
    bis.b   #SDA, &P6OUT
    mov.w	#1, Delay     		; Short delay
    call    #delay
    bis.b   #SCL, &P6OUT
    ret        

P6OUT_0:                        ; Jump here if X was 0
    bic.b   #SDA, &P6OUT
    mov.w	#1, Delay     		; Short delay
    call    #delay
    bis.b   #SCL, &P6OUT
    ret
;-End Send Message-------------------------------------------------------------

;------------------------------------------------------------------------------
; Delay loop
;------------------------------------------------------------------------------
delay:
    dec.w   Delay                 ; Decrement inner loop counter
    jnz     delay               ; Loop is not done; keep decrementing
    ret                         ; Loop is done

;-End Delay--------------------------------------------------------------------

;------------------------------------------------------------------------------
; Manual Acknowledge
;------------------------------------------------------------------------------
i2c_send_ack:
    bic.b   #SDA, P6OUT
    mov.w   #01h, Delay
    call    #delay

    bis.b   #SCL, P6OUT
    mov.w   #01h, Delay
    call    #delay

    bic.b   #SCL, P6OUT
    mov.w   #01h, Delay
    call    #delay

    ret    

;-End Manual Ack---------------------------------------------------------------

;------------------------------------------------------------------------------
; Acknowledge
;------------------------------------------------------------------------------
i2c_ack_recieve:
    bis.b   #SDA, &P6DIR        ; Input mode (for now)
    bis.b	#SDA, &P6OUT		; Set pull-up resistor
	bis.b	#SDA, &P6REN		; Enable input PUD resistor
	mov.w	#5, Delay     		; Long delay

    bis.b   #SCL, P6OUT         ; Set SCL high
    mov.w   #01h, Delay           ; Short delay
    call    #delay

    mov.w   #P6IN, AckReg       ; Capture potential ACK/NACK
    and.b	#SDA, AckReg		; Clear all unimportant bits

    bic.b   #SCL, P6OUT         ; Set SCL low
    mov.w   #05h, Delay           ; Long delay
    call    #delay

    bic.b	#SDA, &P6REN		; Disable input PUD resistor
    bis.b   #SDA, &P6DIR        ; Output mode
    
    ret

;-End Delay----------------------------------------------------------------------------


;------------------------------------------------------------------------------
; Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;