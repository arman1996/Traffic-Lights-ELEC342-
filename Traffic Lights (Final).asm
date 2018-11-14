;******************************************************************************
;                                                                             *
;   This file is a basic code template for code generation on the             *
;   PIC18F14K22. This file contains the basic code building blocks to build   *
;   upon.                                                                     *
;******************************************************************************

;------------------------------------------------------------------------------
; PROCESSOR DECLARATION
;------------------------------------------------------------------------------

     LIST      P=PIC18F14K22          ; list directive to define processor
     #INCLUDE <P18F14K22.INC>         ; processor specific variable definitions

;------------------------------------------------------------------------------
;
; CONFIGURATION WORD SETUP
;
; The 'CONFIG' directive is used to embed the configuration word within the 
; .asm file. The lables following the directive are located in the respective 
; .inc file.  See the data sheet for additional information on configuration 
; word settings.
;
;------------------------------------------------------------------------------

     ;Setup CONFIG11H
     CONFIG FOSC = IRC, PLLEN = OFF, PCLKEN = OFF, FCMEN = OFF, IESO = OFF
     ;Setup CONFIG2L
     CONFIG PWRTEN = ON, BOREN = OFF, BORV = 19
     ;Setup CONFIG2H
     CONFIG WDTEN = OFF, WDTPS = 1
     ;Setup CONFIG3H
     CONFIG MCLRE = OFF, HFOFST = OFF
     ;Setup CONFIG4L
     CONFIG STVREN = OFF, LVP = OFF, BBSIZ = OFF, XINST = OFF
     ;Setup CONFIG5L
     CONFIG CP0 = OFF, CP1 = OFF
     ;Setup CONFIG5H
     CONFIG CPB = OFF, CPD = OFF
     ;Setup CONFIG6L
     CONFIG WRT0 = OFF, WRT1 = OFF
     ;Setup CONFIG6H
     CONFIG WRTB = OFF, WRTC = OFF, WRTD = OFF
     ;Setup CONFIG7L
     CONFIG EBTR0 = OFF, EBTR1 = OFF
     ;Setup CONFIG7H
     CONFIG EBTRB = OFF

;------------------------------------------------------------------------------
;
; VARIABLE DEFINITIONS
;
; Refer to datasheet for available data memory (RAM) organization
;
;------------------------------------------------------------------------------

    CBLOCK 0x60 ; Sample GPR variable register allocations
        MYVAR1  ; user variable at address 0x60
        MYVAR2  ; user variable at address 0x61
        MYVAR3  ; user variable at address 0x62
    ENDC
    
    CBLOCK  0x00        ; Access RAM
    ENDC

;------------------------------------------------------------------------------
; EEPROM INITIALIZATION
; The 18F14K22 has 256 bytes of non-volatile EEPROM starting at 0xF00000 
;------------------------------------------------------------------------------

;DATAEE    ORG  0xF00000 ; Starting address for EEPROM for 18F14K22
;    DE    "MCHP"        ; Place 'M' 'C' 'H' 'P' at address 0,1,2,3

;------------------------------------------------------------------------------
; RESET VECTOR
;------------------------------------------------------------------------------

RES_VECT  ORG     0x0000            ; processor reset vector
          GOTO    START             ; go to beginning of program

;------------------------------------------------------------------------------
; HIGH PRIORITY INTERRUPT VECTOR
;------------------------------------------------------------------------------

ISRH      ORG     0x0008

          ; Run the High Priority Interrupt Service Routine
          GOTO    HIGH_ISR             

;------------------------------------------------------------------------------
; LOW PRIORITY INTERRUPT VECTOR
;------------------------------------------------------------------------------

ISRL      ORG     0x0018
          
          ; Run the High Priority Interrupt Service Routine
          GOTO    LOW_ISR             

;------------------------------------------------------------------------------
; HIGH PRIORITY INTERRUPT SERVICE ROUTINE
;------------------------------------------------------------------------------

HIGH_ISR  

          ; Insert High Priority ISR Here

          RETFIE  FAST

;------------------------------------------------------------------------------
; LOW PRIORITY INTERRUPT SERVICE ROUTINE
;------------------------------------------------------------------------------

LOW_ISR
          RETFIE

;------------------------------------------------------------------------------
; MAIN PROGRAM
;------------------------------------------------------------------------------

SPIregadd	equ	0x20	
SPIvalue	equ	0x21
state		equ	0x22
temp1		equ	0x23
temp		equ	0x24


; Variable delay in seconds

DELAY
    movwf   0x70
DELAYLOOP0
    movlw   0x19
    movwf   0x71
DELAYLOOP1
    movlw   0x20
    movwf   0x72
DELAYLOOP2
    movlw   0x00
    movwf   0x73
DELAYLOOP3
    nop
    decfsz  0x73
    goto    DELAYLOOP3
    decfsz  0x72
    goto    DELAYLOOP2
    decfsz  0x71
    goto    DELAYLOOP1
    decfsz  0x70
    goto    DELAYLOOP0
    return



; Bits sequence for each individual light

MR  equ 0x20
SR  equ 0x10
MY  equ 0x01
SY  equ 0x08
MG  equ 0x02
SG  equ 0x04



display
    call    stateW      ; get LED pattern in W from state
    movwf   PORTC
    return
stateW
    clrf    PCLATH
    movf    state,W
    andlw   0x07	; only states 0-7
    addlw   LOW table
    movwf   PCL
    nop
    nop
table           	; the table must not extend over a 256 byte boundary
    retlw   MG|SR
    retlw   MG|SR
    retlw   MY|SR
    retlw   MR|SR
    retlw   MR|SG
    retlw   MR|SG
    retlw   MR|SY
    retlw   MR|SR


; Calculate the delay in seconds according to the state

DELAYV
    call    stateDW     ; get LED pattern in W from state
    return
stateDW
    clrf    PCLATH
    movf    state,W
    andlw   0x07	; only states 0-7
    addlw   LOW tableD
    movwf   PCL
    nop
    nop
tableD           	; the table must not extend over a 256 byte boundary
    retlw   20
    retlw   1
    retlw   3
    retlw   3
    retlw   5
    retlw   1
    retlw   3
    retlw   3


FLASHING_LIGHTS
    			clrf    state   ; state of the traffic lights
LOOP2
    			call    display ; display the current state
    			call    DELAYV  ; calcualte the delay in this state
    			call    DELAY   ; and delay that many seconds

; The lights have been displayed long enough. Now, we recalculate and make a decision based on inputs

    			movf    state,W
    			movwf   temp1
    			decfsz  temp1
    			goto    notState1

; state 1 - check MR
    			movf    PORTC,W
    			andlw   0xC0
    			btfss   STATUS,2    ; if neither Side is set we stay here
    			incf    state       ; not Zero means side road triggered
    			goto    LOOP2        ; end of state 1

notState1
    			xorlw   0x05        ; are we in state 5 (side check after 5 seconds)
    			btfss   STATUS,2    ; if Z flag is set we are in state 5
    			goto    notState5

; state 5 - check side road, or check main road
    			movf    PORTC,W
    			andlw   0xc0        ; side road set?
    			btfsc   STATUS,2    ; if Z is set it means we move on
    			goto    incState    ; no side road triggered, move to next state
    			movf    PORTC,W
    			andlw   0x30        ; check main road triggered
    			btfss   STATUS,2
    			incf    state       ; main road triggered move to next state
    			goto    LOOP2
notState5               		    ; not in state 1 or 5 - move to the next state

incState
    			incf    state
    			movlw   0x07
    			andwf   state
    			goto    LOOP2




SPI_SEND
			movwf	SSPBUF
LOOP
			btfss	SSPSTAT, BF
			goto	LOOP
			movf	SSPBUF, W
return



; Writing to the Port Ecpander

FULLSIGNAL_SEND
			bcf		PORTC, 6
			movlw	0x40
			call	SPI_SEND
			movf	SPIregadd,W
			call	SPI_SEND
			movf	SPIvalue,W
			call	SPI_SEND
			bsf		PORTC,6
return



START       		; Insert User Program Here

			CLRF    ANSEL
            		CLRF    ANSELH
			clrf	PORTB
			movlw	0x10
			movwf	TRISB
			movlw	0x0f
			movwf	PORTC
			clrf	TRISC
			movlw	0x20
			movwf	SSPCON1
			movlw	0x40
			movwf	SSPSTAT


			;Initialization for port expander
			
			movlw	0x01
			movwf	SPIregadd
			movlw	0x00
			movwf	SPIvalue
			call	FULLSIGNAL_SEND

			movlw	0x00
			movwf	SPIregadd
			movlw	0x00
			movwf	SPIvalue
			call	FULLSIGNAL_SEND

main	


			movlw	0x15
			movwf	SPIregadd	
			movlw	0xff
			movwf	SPIvalue
			call	FULLSIGNAL_SEND

			movlw	0x14
			movwf	SPIregadd	
			movlw	0xff
			movwf	SPIvalue
			call	FULLSIGNAL_SEND
			goto	main



 STOP        GOTO    STOP                                    ; loop program counter

          END