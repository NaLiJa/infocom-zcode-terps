;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;									;;;
;;;			    SCREEN SETUP				;;;
;;;									;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	TITLE	SETUP -- SCREEN SETUP ROUTINES      MS-DOS 2.0 VERSION

	PAGE	58,132
	.LIST

	SUBTTL	STACK AND DATA SEGMENTS INITIALIZATION

STK_SG	SEGMENT	PARA STACK
	DW	200H DUP(?)
STK_TOP	LABEL	WORD
STK_SG	ENDS

DATA_SG	SEGMENT	PARA

	; MS-DOS FUNCTION CALLS WITH INT 21H

CCONIN	EQU	1H		; KEYBOARD INPUT
CCONIO	EQU	6H		; DIRECT CONSOLE I/O
CFOPEN	EQU	0FH		; OPEN FILE
CFCLOS	EQU	10H		; CLOSE FILE
CFDELE	EQU	13H		; DELETE FILE
CFMAKE	EQU	16H		; CREATE FILE
CSDMAO	EQU	1AH		; SET DISK TRANSFER ADDRESS
CWRRND	EQU	22H		; RANDOM WRITE
CPDONE	EQU	4CH		; TERMINATE A PROCESS (EXIT)

SSVER	EQU	"A"-10		; ADD THIS TO THE VERTICAL HEIGHT
SSHOR	EQU	-6		; ADD THIS TO THE HORIZONTAL WIDTH

FLNT	EQU	3		; LENGTH OF SETUP FILE

FBUF	DB	'PJY'		; 80X25 Y FOR YES ANSI SUPPORT
FFCB	DB	0,"SETUP   INF",30 DUP (0)

RADIX	DW	10		; RADIX TO READ IN NUMBERS

	; SOME STRINGS FOR USER INTERACTION

STITLE	DB	"SETUP MENU -- IBM/MS-DOS",0
SQVER	DB	"Number of lines per screen (5-50).",13,10
	DB	"The default is 25: ",0
SQHOR1	LABEL 	BYTE
SQHOR2	DB	"Number of columns per screen (38-132).",13,10
	DB	"The default is 80: ",0
SQTER	LABEL 	BYTE
SQDONE	DB	"Are the inputs correct? (Y/N) :",0
SEVER	DB	"The number of lines has to be between 5 and 50.",0
SEHOR1	DB	"The number of columns has to be between 10 and 132.",0
SEHOR2	DB	"The number of columns has to be between 38 and 132.",0
SETER	DB	"Please type N or Y.",0
MSG2	DB	"Cannot create a new Setup File.",0
MSG3	DB	"Cannot write into the Setup File because disk is full.",0
MSG4	DB	"Cannot close the new Setup File.",0

DATA_SG	ENDS

	SUBTTL	MACROS
	PAGE	+

MOVM	MACRO	D,S,R		; MOVE MEMORY TO MEMORY
	MOV	R,S
	MOV	D,R
	ENDM

PRINT	MACRO	STR		; PRINT A STRING, POINTER IS ARGUMENT
	PUSH	BX
	MOV	BX,OFFSET STR
	CALL	OSTR
	POP	BX
	ENDM

	SUBTTL	SYSTEM INITIALIZATION
	PAGE	+

CODE_SG	SEGMENT	PARA
ASSUME	CS:CODE_SG,DS:DATA_SG,ES:DATA_SG,SS:STK_SG

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;									;;;
;;;				MAIN LOOP				;;;
;;;									;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START	PROC	FAR
	MOVM	DS,DATA_SG,AX	; SETUP THE DS:, ES:, AND SS: 
	MOVM	SS,STK_SG,AX
	MOV	SP,OFFSET STK_TOP
	PUSH	ES
	MOVM	ES,DATA_SG,AX
	JMP	BODY		; EXECUTE THE MAIN BODY
START	ENDP

FINISH	PROC	FAR
	MOV	AH,4CH		; 
	INT	21H
FINISH	ENDP

BODY	PROC
	PRINT	STITLE		; PRINT THE TITLE
	CALL	OCRLF
LUP:	JMP	BODY1		; FOLLOW 7 LINES SKIPPED TO AVOID ?ANSI
	CALL	QTER		; ASK FOR TERMINAL TYPE
	MOV	BX,OFFSET FBUF
	MOV	AL,[BX+2]
	CMP	AL,"Y"
	JE	BODY1
	CALL	QHOR1		; ASK FOR WIDTH
	JMP	BODY2
BODY1:	CALL	QHOR2		; ASK FOR WIDTH
BODY2:	CALL	QVER		; ASK FOR HEIGHT
	CALL	QDONE		; ASK IF USER IS DONE
	TEST	AX,AX
	JE	LUP		; TRY AGAIN IF NOT SATISFIED
	CALL	FOPEN
	CALL	FSAVE		; NOW CREATE THE SETUP FILE AND SAVE IT
	CALL	FCLOSE
	JMP	FINISH		; THAT'S IT!!!
BODY	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;									;;;
;;;				SUBROUTINES				;;;
;;;									;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	; OPEN A NEW SETUP FILE
FOPEN	PROC
	MOV	DX,OFFSET FFCB
	MOV	AH,CFDELE	; DELETE THE SETUP FILE IF IT IS AROUND
	INT	21H
	MOV	DX,OFFSET FFCB
	MOV	AH,CFMAKE	; CREATE A NEW SETUP FILE
	INT	21H
	CMP	AL,0FFH
	JNE	FOPEN1
	PRINT	MSG2
FOPEN1:	RET
FOPEN	ENDP

	; WRITE OUT THE NEW SETUP FILE
FSAVE	PROC
	MOV	BX,OFFSET FFCB
	MOV	WORD PTR [BX+14],FLNT
	MOV	DX,OFFSET FBUF
	MOV	AH,CSDMAO	; POINT TO THE OUTPUT BUFFER
	INT	21H
	MOV	DX,OFFSET FFCB
	MOV	AH,CWRRND	; WRITE OUT THE BUFFER
	INT	21H
	CMP	AL,0
	JE	FSAVE1
	PRINT	MSG3
FSAVE1:	RET
FSAVE	ENDP

	; CLOSE THE SETUP FILE
FCLOSE	PROC
	MOV	DX,OFFSET FFCB
	MOV	AH,CFCLOS	; CLOSE THE SETUP FILE
	INT	21H
	CMP	AL,0FFH
	JNE	FCLOS1
	PRINT	MSG4
FCLOS1:	RET
FCLOSE	ENDP

	; ASK FOR THE NUMBER OF LINES ON SCREEN
QVER	PROC
	PRINT	SQVER
	CALL	RNUM
	CMP	AL,0
	JNZ	QV1
	MOV	AX,25
QV1:	CALL	OCRLF
	CMP	AX,5
	JL	QVER1
	CMP	AX,50
	JG	QVER1
	ADD	AX,SSVER
	PUSH	BX
	MOV	BX,OFFSET FBUF
	MOV	[BX],AL
	POP	BX
	RET
QVER1:	PRINT	SEVER
	CALL	OCRLF
	JMP	QVER
QVER	ENDP

	; ASK FOR THE NUMBER OF COLUMNS ON SCREEN
QHOR1	PROC
	PRINT	SQHOR1
	CALL	RNUM
	CALL	OCRLF
	CMP	AX,10
	JL	QHOR11
	CMP	AX,132
	JG	QHOR11
	ADD	AX,SSHOR
	PUSH	BX
	MOV	BX,OFFSET FBUF
	MOV	[BX+1],AL
	POP	BX
	RET
QHOR11:	PRINT	SEHOR1
	CALL	OCRLF
	JMP	QHOR1
QHOR1	ENDP

	; ASK FOR THE NUMBER OF COLUMNS ON SCREEN
QHOR2	PROC
	PRINT	SQHOR2
	CALL	RNUM
	CMP	AL,0
	JNZ	QH1
	MOV	AX,80
QH1:	CALL	OCRLF
	CMP	AX,38
	JL	QHOR21
	CMP	AX,132
	JG	QHOR21
	ADD	AX,SSHOR
	PUSH	BX
	MOV	BX,OFFSET FBUF
	MOV	[BX+1],AL
	POP	BX
	RET
QHOR21:	PRINT	SEHOR2
	CALL	OCRLF
	JMP	QHOR2
QHOR2	ENDP

	; ASK FOR ASCII OR ANSI TERMINAL
QTER	PROC

	PRINT	SQTER
	CALL	ICHR
	CALL	OCRLF
	CMP	AL,"Y"
	JE	QTER1
	CMP	AL,"y"
	JE	QTER1
	CMP	AL,"N"
	JE	QTER2
	CMP	AL,"n"
	JE	QTER2
	PRINT	SETER
	CALL	OCRLF
	JMP	QTER
QTER1:	MOV	AL,"Y"
	JMP	QTER3
QTER2:	MOV	AL,"N"
QTER3:	PUSH	BX
	MOV	BX,OFFSET FBUF
	MOV	[BX+2],AL
	POP	BX
	RET
QTER	ENDP

	; ASK IF THE USER IS SATISFIED WITH THE RESULT
QDONE	PROC

	PRINT	SQDONE
	CALL	ICHR
	CALL	OCRLF
	CMP	AL,"Y"
	JE	QDONE1
	CMP	AL,"y"
	JE	QDONE1
	CMP	AL,"N"
	JE	QDONE2
	CMP	AL,"n"
	JE	QDONE2
	PRINT	SETER
	CALL	OCRLF
	JMP	QDONE
QDONE1:	MOV	AX,1
	RET
QDONE2:	XOR	AX,AX
	RET
QDONE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;									;;;
;;;			LOW LEVEL I/O SUBROUTINES			;;;
;;;									;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; READ A NUMBER AND PLACE IT IN AX
RNUM	PROC

	PUSH	BX
	PUSH	CX
	PUSH	DX
	XOR	CX,CX		; 0 = POSITIVE, 1 = NEGATIVE
	XOR	AX,AX		; STORE THE INTERMEDIATE SUM IN AX
	PUSH	AX
	CALL	ICHR
	CMP	AL,13		; CR MEANS USE DEFAULT
	JNZ	RNUM1
	POP	AX
	MOV	AL,0		; 0 MEANS DEFAULT
	JMP	RPOS
RNUM1:	CMP	AL,"-"		; IF FIRST CHARACTER IS NOT "-"
	JNE	RLOOP		; THEN THE NUMBER IS POSITIVE
	MOV	CX,1		; ELSE THE NUMBER IS NEGATIVE
	CALL	ICHR
RLOOP:	CMP	AL,"0"		; CHECK TO SEE IF INPUT IS A DIGIT
	JL	REND
	CMP	AL,"9"
	JG	REND
	SUB	AL,"0"		; CONVERT DIGIT TO THE EQUIVALENT NUMBER
	MOV	BX,AX		; SAVE THIS DIGIT
	POP	AX		; GET THE PARTIAL SUM
	MUL	RADIX
	ADD	AX,BX
	PUSH	AX		; SAVE THE PARTIAL SUM
	CALL	ICHR
	JMP	RLOOP
REND:	POP	AX		; PLACE THE RESULT IN AX
	JCXZ	RPOS		; IF THE FIRST CHARACTER IS "-"
	NEG	AX		; THEN NEGATE THE RESULT
RPOS:	POP	DX
	POP	CX
	POP	BX
	RET
RNUM	ENDP

	; PRINT A CARRIAGE RETURN AND LINE FEED
OCRLF	PROC

	PUSH	DX
	MOV	DL,13		; THIS IS <CR> OR "^M"
	CALL	OCHR
	MOV	DL,10		; THIS IS <LF> OR "^J"
	CALL	OCHR
	POP	DX
	RET
OCRLF	ENDP

	; PRINT A STRING, POINTER (TO DATA SEGMENT) IN BX
OSTR	PROC
	PUSH	DX		; SAVE DX
OSTR1:	MOV	DL,[BX]		; GET NEXT CHARACTER
	CMP	DL,0		; IS PREVIOUS CHARACTER THE LAST CHARACTER?
	JE	OSTR3		; YES
	CALL	OCHR		; PRINT CHARACTER
	INC	BX		; POINT TO NEXT CHARACTER
	JMP	OSTR1		; REPEAT
OSTR3:	POP	DX		; RESTORE BX
	RET
OSTR	ENDP

	; READ A CHARACTER INTO AX, WAITING UNTIL ONE IS AVAILABLE
ICHR	PROC
	MOV	AH,CCONIN	; WAIT, READ ONE CHAR, AND PRINT CHAR READ
	INT	21H
	SUB	AH,AH
	RET
ICHR	ENDP

	; PRINT THE CHARACTER IN DL
OCHR	PROC
	PUSH	AX
	MOV	AH,CCONIO	; PRINT A CHARACTER
	INT	21H
	POP	AX
	RET
OCHR	ENDP

CODE_SG	ENDS

	.LIST

	END	START