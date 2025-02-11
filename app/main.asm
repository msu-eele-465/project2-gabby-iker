;-------------------------------------------------------------------------------
; EELE 465, Project 2, 23 January 2025
; Gabriella Lord and Iker Sal Maturana
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
Recive_count .set   R8
Message     .set    R13
AckReg      .set    R12                     ; Acknowledge flag
Dummy_count .set    R11
Dummy_max   .set    R10
Byte        .set    R9
Pack_count  .set    R7
;SecMem      .set    R6
;MinMem      .set    R5
;HourMem     .set    R4
TempReg     .set    R3

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
; Extra Credit: Set initial time
;------------------------------------------------------------------------------
rtc_init:
	mov.b	#0D0h, Message					; Send slave address, write mode
	call	#i2c_routine_tx
	mov.b	#000h, Message					; Send "seconds" register address
	call	#i2c_routine_tx_continue
	mov.b	#055h, Message					; Send initial seconds timestamp
	call	#i2c_routine_tx_continue
	mov.b	#008h, Message					; Send initial minutes timestamp
	call	#i2c_routine_tx_continue
	mov.b	#012h, Message					; Send initial hours timestamp
	call	#i2c_routine_tx_continue
	call	#i2c_routine_end				; End the I2C transmission
;-End RTC init-----------------------------------------------------------------

;------------------------------------------------------------------------------
; Main
;------------------------------------------------------------------------------
main:
    ;mov.b   #0AAh, Message      ; Set the slave address here (Extra Credit)
    ;mov.b   #09h, Dummy_max     ; Set how high dummy counter should go (Extra Credit)
    ;call    #i2c_routine_tx     ; Initiate the I2C routine
    ;call    #dummy_count        ; Send the dummy count to the slave
    ;call    #i2c_routine_end    ;
    
    call    #i2c_slave_addresses
    jmp     main                ; Loop infinitely

;-End Main---------------------------------------------------------------------


;------------------------------------------------------------------------------
; Slave addresses
;------------------------------------------------------------------------------
i2c_slave_addresses:
    ; Set register address to read from
	mov.b	#0D0h, Message					; Send slave address, write mode
	call	#i2c_routine_tx
	tst.b	AckReg							; Abort if we didn't receive an ACK
	jz		i2c_routine_end
	
    mov.b	#000h, Message					; Send "seconds" register address
	call	#i2c_routine_tx_continue
	call	#i2c_routine_end				; End the I2C transmission

	; Read seconds, minutes, and hours
	; Extra Credit: Save data to memory
	mov.b	#0D1h, Message					; Send slave address, read mode
	call	#i2c_routine_tx
	mov.b	#0, AckReg						; Read and ACK two bytes
	
    call	#I2CReceive
	mov.b	Message, SecMem					; Save seconds to memory
	call	#I2CReceive
	mov.b	Message, MinMem					; Save minutes to memory
	mov.b	#1, AckReg						; Read and ACK a third byte
    call	#I2CReceive
	mov.b	Message, HourMem				; Save hours to memory
    call    #i2c_routine_end

	; Address temperature register
	; Extra Credit: Save data to memory
	mov.b	#0D0h, Message					; Send slave address, write mode
	call	#i2c_routine_tx
    mov.b	#0, AckReg
    
	mov.b	#011h, Message					; Send "temperature" register address
	call	#i2c_routine_tx_continue
	call    #i2c_routine_end
    ; Read temperature
	mov.b	#0D1h, Message					; Send slave address, read mode
	call	#i2c_routine_tx
	mov.b	#1, AckReg						; Read and NACK a byte
	call	#I2CReceive
	mov.b	Message, TempReg				; Save data in temperature register

endTransmission:
	call	#i2c_routine_end						; End the I2C transmission

	; Final data processing
	mov.b	TempReg, TempMem				; Save temperature to memory

	mov.w	#0FFh, Delay				; Delay to indicate end of packet
	call	#delay
	jmp		main							; Repeat forever  

;-End Slave Addresses---------------------------------------------------------------------

;------------------------------------------------------------------------------
; Dummy count up
;------------------------------------------------------------------------------
dummy_count:
    mov.b   #00h, Dummy_count       ; Set dummy count to zero
    inc     Dummy_max               ; Increment so dummy count reaches desired value
dummy_count_incr:
    mov.b   Dummy_count, Message    ; Set dummy count as the byte to send to slave
    inc     Dummy_count             ; Increment dummy count
    call    #i2c_routine_tx_continue   ; Send dummy count to slave
    cmp.b   Dummy_count, Dummy_max  ; Check if dummy count has reached desired value
    jnz     dummy_count_incr        ; Dummy count below desired value, send next value
    ret

;-End Count up-----------------------------------------------------------------

;------------------------------------------------------------------------------
; I2C routine
;------------------------------------------------------------------------------
i2c_routine_tx:                 ; Send the slave address
    call    #i2c_routine_start  ; Trigger start condition
    call    #i2c_send           ; Send the register address or message
    call    #i2c_ack_recieve    ; Recieve ack/nack
    ret
i2c_routine_start:
    call    #i2c_scl_sda_high
    call    #i2c_sda_low        ; Set SDA low
    call    #i2c_scl_low        ; Set SCL low
    ret
i2c_routine_tx_continue:
    call    #i2c_send           ; Send the byte
    call    #i2c_ack_recieve    ; Recieve ack/nack
    ret
i2c_routine_end:
    call    #i2c_sda_low        ; Set SDA low
    call    #i2c_scl_high       ; Set SCL high
    call    #i2c_sda_high       ; Set SDA high
    ret

;-End I2C routine--------------------------------------------------------------

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

;-------------------------------------------------------------------------------
; Receive a bit of data via I2C
;-------------------------------------------------------------------------------
I2CReceiveBit:
    mov.w	#5, Delay    					; Long delay
	call	#delay
    call    #i2c_scl_high                   ; Set SCL high

	bit.b	#SDA, &P6IN					; Capture a received bit
	bic.b	#SCL, &P6OUT					; Pull SCL low

	; Implicit long delay. NOTE: processing and function calls/returns take
	; long enough that no explicit delay is needed
	jnz		I2CReceiveBitHigh				; Store the received bit
I2CReceiveBitLow:
	bic.b	#BIT0, Message
	jmp		I2CReceiveBitFinish
I2CReceiveBitHigh:
	bis.b	#BIT0, Message
I2CReceiveBitFinish:

	ret
;-- End I2CReceiveBit ----------------------------------------------------------

;-------------------------------------------------------------------------------
; Receive a byte of data via I2C
;-------------------------------------------------------------------------------
I2CReceive:
	; Prepare to receive data
	bic.b	#SDA, &P6DIR					; Input mode (for now)
	bis.b	#SDA, &P6OUT					; Set pull-up resistor
	bis.b	#SDA, &P6REN					; Enable input PUD resistor

	; Read a byte of data
	mov.w	#8, Send_count
I2CReceiveContinue:
	rla.b	Message							; Left-shift the data buffer
	call	#I2CReceiveBit					; Actually read one bit
	dec.w	Send_count						; Update bit counter
	jnz		I2CReceiveContinue				; Continue receiving if not done

	; Send a potential ACK
	bic.b	#SDA, &P6REN					; Disable input PUD resistor
	bis.b	#SDA, &P6DIR					; Back to output mode

	tst.b	AckReg							; Check whether we need to ACK
	jnz		I2CReceiveSendNack				; And respond accordingly
I2CReceiveSendAck:
	bic.b	#SDA, &P6OUT					; Send an ACK
	jmp		I2CReceiveSendFinish
I2CReceiveSendNack:
	bis.b	#SDA, &P6OUT					; Send a NACK
I2CReceiveSendFinish:
	mov.w	#1, Delay					; Short delay
	call	#delay

	bis.b	#SCL, &P6OUT					; Pull SCL high
	mov.w	#5, Delay					; Long delay
	call	#delay

	bic.b	#SCL, &P6OUT					; Pull SCL low
	mov.w	#5, Delay					; Long delay
	call	#delay

	ret
;-- End I2CReceive -------------------------------------------------------------




;------------------------------------------------------------------------------
; Acknowledge Recieve from Slave
;------------------------------------------------------------------------------
i2c_ack_recieve:
    bic.b   #SDA, &P6DIR        ; Input mode (for now)
    bis.b	#SDA, &P6REN		; Enable input PUD resistor
    bis.b	#SDA, &P6OUT		; Set pull-up resistor
	mov.w	#05h, Delay         ; Short delay
    call    #delay

    call    #i2c_scl_high       ; Set SCL high
    mov.w   #05h, Delay         ; Long delay
    call    #delay

    mov.w   #P6IN, AckReg       ; Capture potential ACK/NACK
    and.b	#SDA, AckReg		; Clear all unimportant bits

    call    #i2c_scl_low        ; Set SCL low
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
i2c_scl_sda_high:
    bis.b   #I2C, P6OUT         ; Set SCL low
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
; Acknowledge Send from Master
;------------------------------------------------------------------------------
i2c_ack_send:
    ;call    #i2c_sda_low        ; Set SDA low
    ;call    #i2c_scl_high       ; Set SCL high
    ;call    #i2c_scl_low        ; Set SCL low
    ;ret
    ; Send a potential ACK
	bic.b	#SDA, &P6REN					; Disable input PUD resistor
	bis.b	#SDA, &P6DIR					; Back to output mode

	tst.b	Message							; Check whether we need to ACK
	jnz		I2CReceiveSendNack				; And respond accordingly


	ret    
;-End Ack Send-----------------------------------------------------------------

;-------------------------------------------------------------------------------
; Memory initialization
;-------------------------------------------------------------------------------
			.data
			.retain
SecMem		.space	1
MinMem		.space	1
HourMem		.space	1
TempMem		.space	1

;------------------------------------------------------------------------------
; Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;