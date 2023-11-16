	PAGE
	SBTTL 'ZDOS'

	;*********************
	;GET Z-BLOCK FROM DISK 
	;*********************
	; (GET ACTUAL 256 BYTE BLOCK (= 1 SECTOR)
	;  OF GAME FROM DISK)

	;ENTRY: Z-BLOCK # IN DBLOCK
	;       TARGET PAGE IN DBUFF+HI

GETDSK:	;SET DRIVE

	;USING ONLY 8 SECTORS PER TRACK SO, USING 9 LSBITS OF DBLOCK(WORD)
	;BITS 0-2 = SECTOR  BITS 3-8 = TRACK

	LDA DBLOCK+LO		;GET LSB OF BLOCK ID
	AND #%00000111		;MASK FOR SECTOR #
	STA SECTOR

	LDA DBLOCK+HI		;GET MSB OF BLOCK ID
	AND #%00000001		;ONLY BIT 0 APPLIES, CLEAR OTHERS
	ASL A			;SHIFT LEFT TO BIT 5
	ASL A
	ASL A
	ASL A
	ASL A
	STA TRACK		;HOLD A SEC

	LDA DBLOCK+LO		;GET LSB OF BLOCK AGAIN
	LSR A			;SHIFT OVER TRACK # FOR USE
	LSR A			;(COVERING SECTOR)
	LSR A
	ORA TRACK		;ADD HIGH BIT
	CLC
	ADC #4			;ZCODE STARTS ON TRACK 4.  ADD OFFSET TO 
				;ALIGN #
	CMP #80			;HIGHEST TRACK IS 79
	BCS TRKERR
	STA TRACK		;SAVE TRACK FOR REAL

	;ENTRY FOR "RESTORE" (TRACK, SECTOR, DRIVE PRE-ASSIGNED)
	;(SETS TO READ DISK AND MOVES EACH BLOCK TO MEMORY)

GETRES:	CLC			;CARRY CLEAR = READ BLOCK
	JSR DISK		;GO READ THE BLOCK
	BCS DSKERR		;CARRY = ERROR

	LDY #0			;ELSE, MOVE CONTENTS OF IOBUFF
GDKL:	LDA IOBUFF,Y		;TO TARGET PAGE IN DBUFF
	STA (DBUFF),Y
	INY
	BNE GDKL		;LOOP TO DO ALL 256 BYTES

	INC DBLOCK+LO		;POINT TO NEXT Z-BLOCK
	BNE GDEX		;NO OVERFLOW
	INC DBLOCK+HI		;OTHERWISE INC HI BYTE ALSO
GDEX:	JMP NXTSEC		;POINT TO NEXT SECTOR & PAGE


	;******************
	;PUT DBLOCK TO DISK  
	;******************
	;(WHEN SAVE GAME, SETS TO WRITE TO DISK
	;AFTER MOVING MEMORY PAGE TO TRANSFER BUFFER (IOBUFF))

	;ENTRY:  TRACK, SECTOR, DRIVE ASSIGNED
	;        PAGE TO WRITE IN DBUFF

PUTDSK:	LDY #0			;MOVE PAGE AT DBUFF TO IOBUFF FOR I/O
PTKL:	LDA (DBUFF),Y
	STA IOBUFF,Y
	INY
	BNE PTKL		;LOOP TILL ALL 256 BYTES DONE

	SEC			;CARRY SET = WRITE BLOCK
	JSR DISK		;GO WRITE
	BCS DSKERR		;CARRY = ERROR

NXTSEC:	INC SECTOR		;POINT TO NEXT SECTOR
	LDA SECTOR
	AND #%00000111		;OVERFLOWED (ZERO RESULT)
	BNE SECTOK		;NO, CONT
	INC TRACK		;ELSE UPDATE TRACK #
SECTOK:	STA SECTOR		;AND SECTOR #

	INC DBUFF+HI		;POINT TO NEXT RAM PAGE
	RTS


	;*** ERROR 12: DISK ADDRESS OUT OF RANGE ***

TRKERR:	LDA #12
	JMP ZERROR

	;*** ERROR 14: DISK ACCESS ***

DSKERR:	LDA #14
	JMP ZERROR


	;SET UP SAVE & RESTORE SCREENS

SAVRES:	JSR ZCRLF			;CLEAR THE BUFFER
	JSR CLS				;CLEAR SCREEN
	LDX #0
	STX SCRIPT			;DISABLE SCRIPTING (SAVE CMDS SHOULD
					;NOT GO ON PAPER)
	RTS

	;DISPLAY A DEFAULT

	;ENTRY:	DEFAULT IN A

DEFAL:	DB	" (Default is "
DEFNUM:	DB	"*):"
DEFALL	EQU	$-DEFAL

DODEF:	CLC
	ADC #'0'			;CONVERT TO ASCII
	STA DEFNUM			;INSERT IN STRING

	LDX #LOW DEFAL
	LDA #HIGH DEFAL
	LDY #DEFALL
	JSR DLINE			;DISPLAY
	RTS


	; *****************************
	; GET SAVE & RESTORE PARAMETERS
	; *****************************

	;THESE INCLUDE POSITION (1-5 AS CHOSEN BE PLAYER), DRIVE (0-1 AS 
	;CHOSEN BY PLAYER), TRACK AND SECTOR (CALCULATED FROM POSITION)

POSIT:	DB	EOL
	DB	"Position 1-5"
POSITL	EQU	$-POSIT

WDRIV:	DB	EOL
	DB	"Drive 0, 1, 2, or 3"
WDRIVL	EQU	$-WDRIV

MIND:	DB	EOL
	DB	EOL
	DB	"Position "
MPOS:	DB	"*; Drive #"
MDRI:	DB	"*."
	DB	EOL
	DB	"Are you sure? (Y or N):"
MINDL	EQU	$-MIND

INSM:	DB	EOL
	DB	"Insert SAVE disk into Drive #"
SAVDRI:	DB	"*."
INSML	EQU	$-INSM

YES:	DB	'YES'
	DB	EOL
YESL	EQU	$-YES

NO:	DB	"NO"
	DB	EOL
NOL	EQU	$-NO

PARAMS:	LDX #LOW POSIT
	LDA #HIGH POSIT
	LDY #POSITL
	JSR DLINE		;"POSITION 1-5"

	;GET GAME POSITION

CHANGE:	LDA GPOSIT		;SHOW CURRENT
	CLC
	ADC #1			;SO 0 = '1'
	JSR DODEF		;DEFAULT POSITION

GETPOS:	JSR GETKEY		;WAIT FOR A KEY
	CMP #EOL		;IF [RET]
	BEQ POSSET		;USE DEFAULT
	SEC
	SBC #'1'		;ELSE CONVERT ASCII TO BINARY
	CMP #5			;IF BELOW "6"
	BCC SETPOS		;MAKE IT THE NEW DEFAULT
	JSR BOOP		;ELSE RAZZ
	JMP GETPOS		;AND TRY AGAIN

POSSET:	LDA GPOSIT		;USE DEFAULT

SETPOS:	STA TPOSIT		;USE KEYPRESS
	CLC
	ADC #'1'		;CONVERT TO ASCII "1"-"5"
	STA MPOS		;STORE IN TEMP STRING
	STA SVPOS
	STA RSPOS
	JSR OSWRCH		;AND DISPLAY IT

	;GET DRIVE ID

	LDX #LOW WDRIV
	LDA #HIGH WDRIV
	LDY #WDRIVL
	JSR DLINE		;"DRIVE 0 1 2 3"

	LDA GDRIVE		;SHOW DEFAULT
	JSR DODEF

GETDRV:	JSR GETKEY		;GET A KEYPRESS
	CMP #EOL		;IF [RET]
	BEQ DRVSET		;USE DEFAULT
	SEC
	SBC #'0'		;CONVERT TO BINARY
	CMP #4			;IF WITHIN RANGE
	BCC SETDRV		;SET NEW DEFAULT
	JSR BOOP
	JMP GETDRV		;ELSE TRY AGAIN

DRVSET:	LDA GDRIVE		;USE DEFAULT

SETDRV:	STA TDRIVE		;USE A
	CLC
	ADC #'0'		;CONVERT TO ASCII 
	STA SAVDRI		;STORE TO DRIVE STRING
	STA MDRI		;AND IN TEMP STRING
	JSR OSWRCH		;AND SHOW NEW SETTING

	LDX #LOW MIND		;SHOW TEMP SETTINGS
	LDA #HIGH MIND
	LDY #MINDL
	JSR DLINE

GETYES:	JSR GETKEY
	CMP #'Y'		;IF REPLY IS "Y"
	BEQ ALLSET		;ACCEPT RESPONSES
	CMP #'y'
	BEQ ALLSET

	CMP #'N'		;IF REPLY IS "N"
	BEQ RETRY		;TRY AGAIN
	CMP #'n'
	BEQ RETRY

	JSR BOOP		;INSIST ON Y/N
	JMP GETYES

RETRY:	LDX #LOW NO		;PRINT NO
	LDA #HIGH NO
	LDY #NOL
	JSR DLINE
	JMP PARAMS		;AND TRY AGAIN (LOOPS BACK)

ALLSET:	LDX #LOW YES		;PRINT "YES"
	LDA #HIGH YES
	LDY #YESL
	JSR DLINE

	LDA TDRIVE		;MAKE THE TEMP DRIVE
	STA GDRIVE		;THE DEFAULT DRIVE
	STA DRIVE		;SET FOR ACTUAL WRITE
	LDA TPOSIT		;AND TEMP POSITION
	STA GPOSIT		;THE DEFAULT POSITION

	;CALC TRACK & SECTOR OF GAME POSITION ON SAVE DISK
	;EACH POSITION REQUIRES 12 TRACKS (8 SECTORS EA)

	;A = POSITION#
	ASL A			; * 2
	ASL A			; * 4
	STA TRACK		; SAVE HERE A SEC
	ASL A			; * 8
	CLD
	ADC TRACK		; * 12
	STA TRACK
	LDA #0
	STA SECTOR		;ALWAYS START @ SECTOR #0

	LDX #LOW INSM
	LDA #HIGH INSM
	LDY #INSML
	JSR DLINE		;"INSERT SAVE DISK IN DRIVE X."
	JSR RETURN		;"HIT [RET] TO CONTINUE."
	CLC			;FOR SUCCESS
	RTS


	;*********************
	;"PRESS RETURN" PROMPT
	;*********************

RETURN:	LDX #LOW RTN
	LDA #HIGH RTN
	LDY #RTNL
	JSR DLINE

	;ENTRY FOR QUIT/RESTART  (INTERNAL OF 'RETURN')
GETRET:	JSR GETKEY		;WAIT FOR <RET>
	CMP #EOL
	BEQ RETEX		;GOT IT
	JSR BOOP		;ACCEPT NO SUBSTITUTES
	JMP GETRET
RETEX:	RTS

RTN:	DB	EOL
	DB	"Press <RETURN> to continue."
	DB	EOL
RTNL	EQU	$-RTN


	;********************
	;PROMPT FOR GAME DISK
	;********************

GAME:	DB	EOL
	DB	"Insert STORY disk into drive #0."
GAMEL	EQU	$-GAME

TOBOOT:	LDX #LOW GAME
	LDA #HIGH GAME
	LDY #GAMEL
	JSR DLINE		;"INSERT DISK"
	JSR RETURN		;"PRESS [RET]"
	
	LDA #$FF		;RE-ENABLE SCRIPTING
	STA SCRIPT
	JMP CLS			;CLEAR SCREEN & RETURN


	; *********
	; SAVE GAME
	; *********

SAV:	DB	"Save Position"
	DB	EOL
SAVL	EQU	$-SAV

SVING:	DB	EOL
	DB	"Saving  position "
SVPOS:	DB	"* ..."
	DB	EOL
SVINGL	EQU	$-SVING

	;(ZSAVE IS A 0-OP)

ZSAVE:	JSR SAVRES		;SET UP SCREEN

	LDX #LOW SAV
	LDA HIGH SAV
`	LDY #SAVL
	JSR DLINE		;"SAVE POSITION"

	JSR PARAMS		;GET PARAMETERS
	BCC DOSAVE		;ERROR IF CARRY SET

BADSAV:	LDA #0			;RESET DRIVE TO GAME DRIVE
	STA DRIVE
	JSR TOBOOT		;GET BOOT DISK
	JMP PREDF		;PREDICATE FAILS

DOSAVE:	LDX #LOW SVING
	LDA #HIGH SVING
	LDY #SVINGL
	JSR DLINE		;"SAVING POSITION X"

	;SAVE GAME PARAMETERS IN BUFSAV

	LDA ZBEGIN+ZID		;MOVE GAME ID
	STA BUFSAV+0		;INTO 1ST 2 BYTES
	LDA ZBEGIN+ZID+1	;OF THE AUX LINE BUFFER
	STA BUFSAV+1

	LDA ZSP			;MOVE Z-STACK POINTER
	STA BUFSAV+2		;TO 3RD BYTE
	LDA OLDZSP		;MOVE OLD ZSP
	STA BUFSAV+3		;TO 4TH

	LDX #2			;MOVE CONTERNTS OF ZPC
ZPCSAV:	LDA ZPC,X		;TO BYTES 5-7
	STA BUFSAV+4,X		;OF BUFSAV
	DEX
	BPL ZPCSAV		;3 BYTES, 3 TIMES

	;WRITE LOCALS/BUFSAV PAGE TO DISK

	LDA #HIGH LOCALS
	STA DBUFF+HI		;POINT TO THE PAGE
	JSR PUTDSK		;AND WRITE IT OUT
	BCS BADSAV		;CATCH WRITE ERROR HERE

	;WRITE CONTENTS OF Z-STCK TO DISK

	LDA #HIGH ZSTAKL	;POINT TO 1ST PAGE
	STA DBUFF+HI
	JSR PUTDSK		;WRITE 1ST AND
	JSR PUTDSK		;2ND PAGE OF Z-STACK

	;WRITE ENTIRE GAME PRELOAD TO DISLK

	LDA ZCODE		;POINT TO 1ST PAGE
	STA DBUFF+HI		;OF PRELOAD  (HIGH ONLY, PAGE ALIGNED)

	LDX ZBEGIN+ZPURBT	;GET # IMPURE PAGES
	INX			;USE FOR INDEXING
	STX I+LO

LSAVE:	JSR PUTDSK
	DEC I+LO
	BNE LSAVE		;DO ALL PAGES OF PRELOAD

	LDA #0			;RESET TO GAME DRIVE
	STA DRIVE

	JSR TOBOOT		;PROMPT FOR GAME DISK
	JMP PREDS		;ELSE PREDICATE SUCCEEDS


	; ************
	; RESTORE GAME
	; ************

RES:	DB	"Restore Position"
	DB	EOL
RESL	EQU	$-RES

RSING:	DB	EOL
	DB	"Restoring position "
RSPOS:	DB	"* ..."
	DB 	EOL
RSINGL	EQU	$-RSING

ZREST:	JSR SAVRES		;SET UP SCREEN

	LDX #LOW RES
	LDA #HIGH RES
	LDY #RESL
	JSR DLINE		;"RESTORE POSITION"

	JSR PARAMS		;GET PARAMETERS
	BCS BADRES		;ERROR IF CARRY SET

	LDX #LOW RSING
	LDA #HIGH RSING
	LDY #RSINGL
	JSR DLINE		;"RESTORING POSITION X "

	;SAVE LOCALS IN CASE OF ERROR

	LDX #31
LOCSAV:	LDA LOCALS,X		;COPY ALL LOCALS
	STA $0100,X		;TO BOTTOM OF MACHINE STACK
	DEX
	BPL LOCSAV		;ALL

	LDA #HIGH LOCALS
	STA DBUFF+HI
	JSR GETRES		;RETRIEVE 1ST BLOCK OF PRELOAD

	LDA BUFSAV+0		;DOES 1ST BYTE OF SAVED GAME ID
	CMP ZBEGIN+ZID		;MATCH THE CURRENT ID?
	BNE WRONG		;WRONG DISK IF NOT

	LDA BUFSAV+1		;WHAT ABOUT 2ND BYTE?
	CMP ZBEGIN+ZID+1
	BEQ RIGHT		;CONTINUE IF BOTH BYTES MATCH

	;HANDLE INCORRECT SAVE DISK

WRONG:	LDX #31			;RESTORE ALL SAVED LOCALS
WR0:	LDA $0100,X
	STA LOCALS,X
	DEX
	BPL WR0			;ALL

BADRES:	LDA #0			;RESET TO GAME DRIVE
	STA DRIVE
	JSR TOBOOT		;PROMPT FOR GAME DISK
	JMP PREDF		;PREDICATE FAILS

	;CONTINUE RESTORE

RIGHT:	LDA ZBEGIN+ZSCRIP	;SAVE BOTH FLAG BYTES
	STA I+LO
	LDA ZBEGIN+ZSCRIP+1
	STA I+HI

	LDA #HIGH ZSTAKL	;RETRIEVE OLD CONTENTS OF 
	STA DBUFF+HI		;Z-STACK
	JSR GETRES		;GET 1ST BLOCK OF Z-STACK
	JSR GETRES		;AND 2ND BLOCK

	LDA ZCODE
	STA DBUFF+HI
	JSR GETRES		;GET 1ST BLOCK OF PRELOAD

	LDA I+LO		;RSTORE THE STATE
	STA ZBEGIN+ZSCRIP	;OF THE FLAG WORD
	LDA I+HI
	STA ZBEGIN+ZSCRIP+1

	LDA ZBEGIN+ZPURBT	;GET # PAGES TO LOAD
	STA I+LO

LREST:	JSR GETRES		;FETCH THE REMAINDER
	DEC I+LO		;OF THE PRELOAD
	BNE LREST

	;RESTORE THE STATE OF THE SAVED GAME

	LDA BUFSAV+2		;RESTORE THE ZSP
	STA ZSP
	LDA BUFSAV+3		;AND THE OLDZSP
	STA OLDZSP

	LDX #2			;RESTORE THE ZPC
RESZPC:	LDA BUFSAV+4,X
	STA ZPC,X
	DEX
	BPL RESZPC

	LDA #FALSE
	STA ZPCFLG		;INVALIDATE ZPC
	
	LDA #0			;RESET TO GAME DRIVE
	STA DRIVE

	JSR TOBOOT		;PROMPT FOR GAME DISK	
	JMP PREDS		;PREDICATE SUCCEEDS

	END