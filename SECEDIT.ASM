;
;***************************************************************************
;*              DISPLAY SECTORS IN HEX AND ASCII
;*
;*              PUBLIC DOMAIN SOFTWARE WRITTEN BY WOEPER
;*
;***************************************************************************
;
;               CURSOR CONTRIL SET FOR ANSI BBS TERMINAL
;
;
        ORG     0100H           ; ORG start at TPA
;
BIOS    EQU     0F003H          ; BIOS Entry point      
;               
CBOOT   EQU     BIOS-3          ; Cold Boot
WBOOT   EQU     BIOS            ; Warm Boot

BCIN	EQU		BIOS+6			; Direct char in
BCOUT	EQU		BIOS+9			; Direct char out
HOME    EQU     BIOS+21         ; Home the drive
SETDISK EQU     BIOS+24         ; Select disk
SETTRK  EQU     BIOS+27         ; Set track
SETSEC  EQU     BIOS+30         ; Set sector
SETDMA  EQU     BIOS+33         ; Set trnsfer address
READ    EQU     BIOS+36         ; Read sector
WRITE	EQU		BIOS+39			; Write the sector
SECTRAN EQU     BIOS+45         ; Translate

BDOS    EQU     5               ; BDOS entry point
;
CONIN   EQU     1               ; get character
CONOUT  EQU     2               ; put character
GETSTR  EQU     10              ; Get string
;
CR      EQU     13              ;
LF      EQU     10              ;
ESC     EQU     27              ;
;
;
        LXI     SP,STACK        ; Local Stack
;               
        CALL    PRTMSG          ; Display SIGNON
        DB      'DUMP SECTORS VER 1.0-25/02/2026',CR,LF,'Select drive (A/B/C):',0
        CALL    USIN            ; Get character
        ANI     05FH            ; make uppercase
        MOV     C,A             ; copy to C
        ANI     40H             ; Test ASCII
        CPI     40H             ; Yes ?
        JNZ     WBOOT           ; no exit
        MOV     A,C             ; get it back   
        STA     SELDRIVE        ; save for later
        ANI     0FH             ; mask out low nibble
        DCR     A               ; decrement A=0 B=1 C=2 
        MOV     C,A             ; To BC
        MVI     B,0             ; 
;       
SELEC:  CALL    SETDISK         ; Set disk
        PUSH    H               ; save DPB
        MOV     E,M             ; Get Translate table address
        INX     H               ;
        MOV     D,M             ;
        XCHG                    ;
        SHLD    TRNSLATE        ; save it
        POP     H               ; get back DCB
        LXI     D,10            ; prepare offset to DPB
        DAD     D               ; Add it
        MOV     E,M             ; Get Disk parameter block address
        INX     H               ;
        MOV     D,M             ;
        XCHG                    ;                       
        SHLD    DPB             ; Store it
        MOV     A,M             ; get number of sectors for this drive
        STA     SECTORS         ; save it
        CALL    HOME            ; Home the drive
        MVI     A,0             ; start from track 0
        STA     RDSECTOR        ; and sector
        STA     RDTRACK         ; zero
        CALL    CRLF            ; clear line
        JMP     NEXT1           ; and GO
;
;
;------------------------------------------------------
; DISPLAY MENU LINE
;------------------------------------------------------                 
;
NEXT:   CALL    PRTMSG          ; print menu line
        DB      CR,LF,ESC,'[31mCommand(Track=T/Sector=S/Next=CR/Edit=E/Stop=X) _',ESC,'[39m',0
        CALL    USIN            ; get command
        ANI     5FH             ; uppercase
        CPI     'X'             ; ctrl-C ?
        JZ      WBOOT           ; exit proghram
        CPI     CR              ; CR ?
        JZ      NEXT0           ; continue to fly
        CPI     'T'             ; T ?
        JZ      CHGTRACK        ; change track
        CPI     'S'             ; S ?
        JZ      CHGSECTOR       ; change sector
		CPI		'E'				; E ?
		JZ		ESEC			; Go edit the sector
        JMP     NEXT            ; retry .....
;
;-----------------------------------------------------------------------
; CHANGE TRACK
;-----------------------------------------------------------------------                        
;
CHGTRACK: CALL  PRTMSG          ; print new line
        DB      CR,LF,0
CHGTRK2:CALL    PRTMSG          ; display track question        
        DB      'Track = ',0
        CALL    GETVALUE        ; get the string answer 
        JC      CHGTRK2
        STA     RDTRACK         ; this is the new track
        JMP     NEXT1           ; go Fly
;
;-----------------------------------------------------------------------
; CHANGE SECTOR
;-----------------------------------------------------------------------                        
;
CHGSECTOR: CALL PRTMSG          ; display CR LF
        DB      CR,LF,0
CHGSEC2: CALL   PRTMSG          ; display question
        DB      'Sector = ',0
        CALL    GETVALUE        ; get nummeric string answer
        JC      CHGSEC2
        STA     RDSECTOR        ; save as new sector
        JMP     NEXT1           ; go Fly
;
;-----------------------------------------------------------------------
; INCREMENT SECTOR AND OR TRACK
;-----------------------------------------------------------------------                        
;
NEXT0:  CALL    CRLF            ; New line
        LDA     RDSECTOR        ; get currect sector
        INR     A               ; increment
        STA     RDSECTOR        ; save again    
        MOV     C,A             ; move to C
        LDA     SECTORS         ; get  max value
        CMP     C               ; compare
        JNZ     NEXT1           ; not yet continue to Fly
        XRA     A               ; Reset sector to 0
        STA     RDSECTOR        ; save it               
        LDA     RDTRACK         ; get track
        INR     A               ; increment
        STA     RDTRACK         ; save it back
;
;-----------------------------------------------------------------------
; DISPLAY TRACK AND SECTOR TO SCREEN 
;-----------------------------------------------------------------------                        
;
NEXT1:  CALL    PRTMSG          ; Strt display info line
        DB      ESC,'[32mDISK=',0 ; display Disk
        LDA     SELDRIVE        ; get drive
        MOV     C,A             ; to C
        CALL    USOUT           ; display it
        CALL    PRTMSG          ; display track 
        DB      ': LOGICAL TRACK=',0                    ;
        LDA     RDTRACK         ; Get track  number             
        MOV     L,A             ; to
        MVI     H,0             ; HL
        CALL    DECOUT          ; output it in decimal
        CALL    PRTMSG
        DB      ' (TRACK=',0
        LDA     RDTRACK         ; Get track  number             
        ORA     A               ; Clear Carry
        RAR                     ; Calculate real track number
        MOV     L,A
        MVI     H,0
        CALL    DECOUT
        CALL    PRTMSG
        DB      ' HEAD=',0 
        LDA     RDTRACK
        ANI     00000001B       ; mask out head selection
        MOV     L,A
        MVI     H,0
        CALL    DECOUT  
        CALL    PRTMSG          ; display Sector
        DB      ') SECTOR=',0   ;       
        LDA     RDSECTOR        ; Get sector    
        MOV     L,A             ; to    
        MVI     H,0             ; HL
        CALL    DECOUT          ; Display it in decimal
        CALL    PRTMSG          ; Display real sector value after translation
        DB      '(',0           ; between barkets
        LDA     RDSECTOR        ; Get sector
        CALL    TRANSLATE       ; translate
        MOV     L,A             ; to HL
        MVI     H,0                                             ;
        CALL    DECOUT          ; Display deccimal
        CALL    PRTMSG          ; end of line
        DB      ')',ESC,'[39m',CR,LF,0  ;
;
;-----------------------------------------------------------------------
; READ THE TRANSLATED SECTOR IN BUFFER
;-----------------------------------------------------------------------                        
;
LOOP:   LXI     B,BUFFER        ; point to buffer
        CALL    SETDMA          ; tell bios
        LDA     RDSECTOR        ; get wanted sector
        CALL    TRANSLATE       ; translate it
        MOV     C,A             ; back to BC
        MVI     B,0             ;
        CALL    SETSEC          ; set the sector to read
        LDA     RDTRACK         ; get asked track
        MOV     C,A             ; move it to    
        MVI     B,0             ; BC
        CALL    SETTRK          ; Set the track
        CALL    READ            ; go read the sector
		MVI		A,1
		CALL	DISPLAY
		JMP		NEXT
;
;-----------------------------------------------------------------------
; EDIT THE SECTOR
;-----------------------------------------------------------------------
;
ESEC:	XRA		A				; Clear ACU
		STA		EDTPOS			; Store edit position
		
ES0:	CALL	PRTMSG
		DB		CR,LF,ESC,'[34mEntering Edit mode',ESC,'[35m',CR,LF,0
		MVI		A,0
		CALL	DISPEDT			; go display the edit buffer
;		
		CALL	PRTMSG			; print menu1
		DB		CR,LF,ESC,'[36mC=Change/S=Save/X=Exit _',ESC,'[s',0
		
		CALL	PRTMSG			; position cursor at top
		DB		ESC,'[8F',ESC,'[6C',0
;
ES1:	CALL	BCIN			; Get character	
		ANI		05FH			; uppercase	
		MOV		C,A				; save to C
		CPI		'S'				; is it S
		JZ		ESS				; Go save
		CPI		'X'				; is it X
		JZ		ESX				; Abort
		CPI		'D'-40H			; D?
		JZ		ESR				; Right movement
		CPI		'S'-40H			; S?
		JZ		ESL				; Left movement
		CPI		'X'-40H			; X ?
		JZ		ESD				; Down 1 line
		CPI		'E'-40H			; E ?
		JZ		ESU				; Up one line
		CPI		'C'				; C ?
		JZ		ESE				; Go change the byte
		JMP		ES1				; loop back
		
ESE:	CALL	GETHEX			; Get hex value
		PUSH	PSW				; Save
		LXI		H,BUFFER		; get buffer address
		LDA		EDTPOS			; get position
		MOV		E,A				; to E
		MVI		D,0				; D to 0
		DAD		D				; Add D to H
		POP		PSW				; GEt value back
		MOV		M,A				; to buffer
		PUSH	PSW				; save value
		CALL	PRTMSG			; print color
		DB		ESC,'[37m',0	; white		
		POP		PSW				; get back value
		CALL	HPR				; display it
		CALL	PRTMSG			; print 
		DB		ESC,'[2D',0		; cursor back 2 positions
		JMP		ES1				; Next hit
;
ESS:	CALL	PRTMSG				
		DB		ESC,'[uS',0
		CALL	WRITE
		JMP		NEXT		

ESX:	CALL	PRTMSG
		DB		ESC,'[uX',0
		JMP		NEXT		
;
ESR:	LXI		H,EDTPOS
		MOV		A,M
		ANI		15
		CPI		15
		JZ		ES1
		INR		M
		CALL	PRTMSG
		DB		ESC,'[3C',0
		JMP		ES1
;
ESL:	LXI		H,EDTPOS
		MOV		A,M
		ANI		15
		CPI		0
		JZ		ES1
		DCR		M
		CALL	PRTMSG
		DB		ESC,'[3D',0
		JMP		ES1		
;		
ESD:	LXI		H,EDTPOS
		MOV		A,M
		ANI		0F0H
		CPI		070H
		JZ		ES1
		MOV		A,M
		ADI		16
		MOV		M,A
		CALL	PRTMSG
		DB		ESC,'[1B',0
		JMP		ES1		
;
ESU:	LXI		H,EDTPOS
		MOV		A,M
		ANI		0F0H
		CPI		000H
		JZ		ES1
		MOV		A,M
		SBI		16
		MOV		M,A
		CALL	PRTMSG
		DB		ESC,'[1A',0
		JMP		ES1		

;                       
;-----------------------------------------------------------------------
; DISPLAY BUFFER  HEXIDECIMAL WITH SPACES EVRY 4 BYTES AND ASCII 
;-----------------------------------------------------------------------
;
DISPLAY:LXI     H,BUFFER        ; point HL to buffer
        MVI     A,0             ; start line
        STA     CNTLINES        ; save it
ALOOPE: CALL    HLOUT2          ; Display address (in hex) with 2 spaces
        MVI     D,16            ; 16 bytes / line
        PUSH    H               ; Save address
ALP1:   MOV     A,M             ; Get byte
        CALL    HPR             ; Output in hex
        CALL    SPACE           ; Space over
		MOV     A,D             ; Get count
        CPI     9               ; At boundary?
        CZ      SPACE           ; Yes, extra space
		MOV     A,D             ; Get count
		ANI     7               ; Mask for low bits
		CPI     5               ; At boundary?
		CZ      SPACE           ; Extra space
AL1:   	INX     H               ; Advance address
        DCR     D               ; Reduce count
        JNZ     ALP1            ; Do them all
        MVI     D,4             ; # separating spaces
AL2:    CALL    SPACE           ; Output a space
        DCR     D               ; Reduce count
        JNZ     AL2             ; And proceed
        POP     H
        MVI     D,16            ; 16 chars / display
AL3:    MOV     A,M             ; Get data byte
        CALL    OUTP            ; Display (if printable)
        INX     H               ; Advance to next
        DCR     D               ; Reduce count
        JNZ     AL3             ; Do them allCALL CHKSUS                                   ; Handle output suspension
        LDA     CNTLINES        ; get current line
        INR     A               ; increment
        STA     CNTLINES        ; save again
        CPI     8               ; Line 8=end of buffer
        RZ		    			; next Buffer
        CALL    CRLF            ; CR LF
        JMP     ALOOPE          ; And continue

;-----------------------------------------------------------------------
; DISPLAY BUFFER  HEXIDECIMAL NO SPACES WITH ASCII
;-----------------------------------------------------------------------
;
DISPEDT:LXI     H,BUFFER        ; point HL to buffer
        MVI     A,0             ; start line
        STA     CNTLINES        ; save it
ALOOP:  CALL    HLOUT2          ; Display address (in hex) with 2 spaces
        MVI     D,16            ; 16 bytes / line
        PUSH    H               ; Save address
ALPE1:  MOV     A,M             ; Get byte
        CALL    HPR             ; Output in hex
        CALL    SPACE           ; Space over
ALE1:   INX     H               ; Advance address
        DCR     D               ; Reduce count
        JNZ     ALPE1           ; Do them all
        MVI     D,4             ; # separating spaces
ALE2:   CALL    SPACE          ; Output a space
        DCR     D               ; Reduce count
        JNZ     ALE2            ; And proceed
        POP     H
        MVI     D,16            ; 16 chars / display
ALE3:   MOV     A,M             ; Get data byte
        CALL    OUTP            ; Display (if printable)
        INX     H               ; Advance to next
        DCR     D               ; Reduce count
        JNZ     ALE3            ; Do them allCALL CHKSUS                                   ; Handle output suspension
        LDA     CNTLINES        ; get current line
        INR     A               ; increment
        STA     CNTLINES        ; save again
        CPI     8               ; Line 8=end of buffer
        RZ		    			; next Buffer
        CALL    CRLF            ; CR LF
        JMP     ALOOP           ; And continue
;
;-----------------------------------------------------------------------
; DISPLAY HL IN HEXIDECIMAL
;-----------------------------------------------------------------------
;
HLOUT:  MVI     A,0             ; Get HIGH byte ( FORCED TO 0 )
        CALL    HPR             ; Output
        MOV     A,L             ; Get LOW byte
		CALL	HPR
		RET
		
;-----------------------------------------------------------------------------
;       HEX BYTE OUT TO PORT  
;-----------------------------------------------------------------------------
;
HPR:	PUSH    PSW			; SAVE VALUE
		RLC
		RLC			
		RLC
		RLC
		CALL    HPR1		; OUTPUT TO PORT
		POP     PSW			; GET BACK VALUE
HPR1:	ANI     15			; GET LEFT BEET
		ADI     '0'         ; MAKE DIGIT 0 - 9
		CPI     '9'+1
		MOV     C,A         ; TO C
		JC      USOUT
		ADI     7           ; ADJUST FOR A - F
		MOV     C,A         ; TO E
		JMP     USOUT      	; GO ECHO IT
;				
;---------------------------------------------------------------------------
;       GET NUMBER 0 TO 255 FROM PORT IN ACU 
;---------------------------------------------------------------------------
;
GETHEX: PUSH    B           ; save bc
		CALL    BCIN        ; read first  byte
		POP		B
		CALL    MKBIN       ; convert digit
		RLC
		RLC
		RLC
		RLC
		MOV     B,A         ; save in b
		PUSH	B
		CALL    BCIN        ; Read next character
		POP		B
		CALL    MKBIN
		ORA     B           ; Combine byte
		RET               	
		
;---------------------------------------------------------------------------
;       MAKE BINAIRY
;---------------------------------------------------------------------------
;
MKBIN:  SUI     '0'			; remove ascii 0
		CPI     10			; Test if a-f range
		RM					; No ok return
		SUI     7			; ELse adjust it
		RET					; And return
;
;-----------------------------------------------------------------------
; DISPLAY A CHARACTER IF ITS PRINTABLE       
;-----------------------------------------------------------------------
;
OUTP:   CPI     ' '             ; < ' '
        JC      OUTP1           ; Invalid, exchange it
        CPI     7Fh             ; PrinTRNSLATE?
        MOV     C,A
        JC      USOUT           ; Ok to display
OUTP1:  MVI     C,'.'           ; Set to DOT to indicate invalid
        JMP     USOUT           ; And display

;
;-----------------------------------------------------------------------
; WRITE A LINE - FEED AND CARRIAGE - RETURN TO CONSOLE
;-----------------------------------------------------------------------
;
CRLF:   MVI     C,0Dh           ; Carriage return
        CALL    USOUT           ; Output
        MVI     C,0Ah           ; Line - feed   
        JMP     USOUT

;
;-----------------------------------------------------------------------
; HL OUTPUT PLUS SPACE
;-----------------------------------------------------------------------   
;     
HLOUT2: CALL    HLOUT           ; Output value
        CALL    SPACE           ; Output a space
;
;-----------------------------------------------------------------------
; DISPLAY A SPACE ON THE CONSOLE
;-----------------------------------------------------------------------
;
SPACE:  MVI     C,' '           ; Get a space
        JMP     USOUT           ; Display it    
;
;-----------------------------------------------------------------------
; ** BINAIR TO ASCII  5 DIGITS IN HL
;-----------------------------------------------------------------------
;
DECOUT: MVI     B,80H           ; flag to no print
        LXI     D,-10000        ; setup 10000
        CALL    DECNO           ; see how many
        LXI     D,-1000         ; setup 1000
        CALL    DECNO           ; see howmany
        LXI     D,-100          ; setup 100
        CALL    DECNO           ; see how many
        LXI     D,-10           ; setup 10
        CALL    DECNO           ; see howmany
        MVI     B,0             ; clear inhibit print flag
        LXI     D,-1            ; setup 1
DECNO:  INR     B               ; see howmany
        DAD     D               ; substract it
        JC      DECNO           ; carry ?
        DCR     B               ; yes adjust count
        XCHG                    ; to de
        XRA     A               ; clear carry clear acu
        SUB     L               ; substarct l
        MOV     L,A             ; save l
        MVI     A,0             ; save carry but a to 0
        SBB     H               ; substract h
        MOV     H,A             ; save h
        XCHG                    ; back to hl
        DAD     D               ; readd
        MOV     A,B             ; get no print flag
        CPI     80H             ; still set
        RZ                      ; yes then return
        MOV     A,B             ; get flag
        ANI     7FH             ; mask out flag
        ORI     '0'             ; make ascii  
        MOV     C,A     
        CALL    USOUT           ; echo it
        MVI     B,0             ; disable flag now
        RET 
;
;------------------------------------------------------------------------------
;               TEXT TO CONSOLE
;------------------------------------------------------------------------------
;
PRTMSG: XTHL                    ; get string address
UTXT01: MOV     A,M             ; get byte from it
        ORA     A               ; test if eos
        JZ      UTXT02          ; ok end of string
        MOV     C,A             ; to c
        CALL    USOUT           ; output it
        INX     H               ; pointer++
        JMP     UTXT01          ; Jump on
UTXT02: INX     H               ; Adjust for return
        XTHL                    ; Reset return address
        RET                     ; go on
;
;------------------------------------------------------------------------------
;               CHARACTER  TO CONSOLE
;------------------------------------------------------------------------------
;
USOUT:  PUSH    B               ; To be sure
        PUSH    D               ; save all registers 
        PUSH    H               ;:-)
        MOV     E,C             ; char to E
        MVI     C,CONOUT        ; tell Char Out 
        CALL    BDOS            ; work bdos ....
        POP     H               ; restore 
        POP     D
        POP     B
        RET
;
;------------------------------------------------------------------------------
;               CHARACTER  FROM CONSOLE
;------------------------------------------------------------------------------
;
USIN:   PUSH    B               ; To be sure
        PUSH    D               ; save all registers 
        PUSH    H               ; :-)
        MOV     E,C             ; char to E
        MVI     C,CONIN         ; tell Char Out 
        CALL    BDOS            ; work bdos ....
        POP     H               ; restore 
        POP     D
        POP     B
        RET
;
;------------------------------------------------------------------------------
;               TRANSLATE SECTOR NUMBER
;------------------------------------------------------------------------------
;       
TRANSLATE: PUSH PSW             ; Sve sector
        LHLD    TRNSLATE        ; Get translate table
        MOV     A,L             ; Check if TAble is 0
        ORA     H               ; by comparing H to L
        JZ      NOTRANS         ; now should be non zero
        POP     PSW             ; get back sector
        MOV     E,A             ; to
        MVI     D,0             ; DE
        DAD     D               ; Add to start of table
        MOV     A,M             ; get new sector value
        RET                     ; and return
NOTRANS:POP     PSW             ; no table return same value
        RET                     ; return

;
;------------------------------------------------------------------------------
;               READ STRING FROM CONSOLE 
;------------------------------------------------------------------------------
;                               
GETVALUE: LXI   D,CONSTR        ; point to buffer zone
        MVI             C,GETSTR; get BDOS string
        CALL    BDOS            ; work horse
        LDA     CONSTR+1        ; load number of characters     
        CPI     0               ; nothing entered retry
        JZ      GETVALUE1       ; Again
        CPI     1               ; only 1 
        JZ      GETVALUE2       ; process 1
        CPI     2               ; only 2
        JZ      GETVALUE3       ; process 2
        CPI     3               ; 3
        JZ      GETVALUE4       ; ok nothing to do
GETVALUE1:CALL  PRTMSG  ; print
        DB      ESC,'[2K',0     ; erase line
        STC                     ; set carry
        RET                     ; report error
GETVALUE2:LDA   CONSTR+2        ; Adjust character position
        STA     CONSTR+4        ; to obtain 
        MVI     A,'0'           ; a 3 character
        STA     CONSTR+3        ; leading
        STA     CONSTR+2        ; zeroes        
        JMP     GETVALUE4       ; string
GETVALUE3:LDA   CONSTR+3        ; ready
        STA     CONSTR+4        ; to 
        LDA     CONSTR+2        ; concverted
        STA     CONSTR+3        ; to
        MVI     A,'0'           ; decimal
        STA     CONSTR+2        ; value
GETVALUE4:CALL  CONVERT         ; NOW !
        MOV     A,C             ; result to A and C     
        STC                     ; set carry
        CMC                     ; clear carry
        RET                     ; return to caller
;
;------------------------------------------------------------------------------
;               CONVERT 3 CHARACTER STRING TO DECIMAL IN C
;------------------------------------------------------------------------------
;                       
CONVERT:LDA     CONSTR+2        ; get first character value 10
        ANI     0FH             ; mask out
        MOV     C,A             ; to C as counter
        MVI     B,0             ; prepare result 0
CONVERT0:MOV    A,C             ; get count
        ORA     A               ; check 0
        JZ      CONVERT2        ; yes done
        MOV     A,B             ; get value
        ADI     100             ; add 10
        MOV     B,A             ; save back
        DCR     C               ; decrement counter     
        JMP     CONVERT0        ; loop again
CONVERT2:LDA    CONSTR+3        ; get first character value 10
        ANI     0FH             ; mask out
        MOV     C,A             ; to C as counter
CONVERT3:MOV    A,C             ; get count
        ORA     A               ; check 0
        JZ      CONVERT4        ; yes done
        MOV     A,B             ; get value
        ADI     10              ; add 10
        MOV     B,A             ; save back
        DCR     C               ; decrement counter     
        JMP     CONVERT3        ; loop again
CONVERT4:LDA    CONSTR+4        ; Get lsb
        ANI     0FH             ; mask out value
        ADD     B               ; add previous value
        MOV     C,A             ; mov to C      
        RET
;
;
;               RAM AREA
;
CONSTR: DB      5,0,0,0,0,0,0
; 
TRNSLATE:	DW	0               
RDTRACK:	DB  0
RDSECTOR:	DB  0       
CNTLINES:	DB  0       
PARMS:  	DW  0
DPB:    	DW  0
SECTORS:	DB  0
SELDRIVE:	DB  0
EDTPOS:		DB	0       
;
;
			DS		(($ & 0FF00H) + 256) - $,0
		
BUFFER  	DS      128
			DS      128
STACK   	EQU     $
;
			END     0
;
