	PAGE
	SBTTL "--- HARDWARE EQUATES: CBM64 ---"


	; ---------
	; CONSTANTS
	; ---------

EZIPID	EQU	8	; ID BYTE STATING THIS IS A C-64 EZIP
VERSID	EQU	'A'	; VERSION OF INTERPRETER

YSIZE	EQU	24
XSIZE	EQU	39
TOPSIZ	EQU	40	; LC-A TOP SCREEN IS 1 LARGER

KERNAL	EQU	%00000010	; ORA IT IN TO TURN KERNAL (ROM) ON $E000-$FFFF
RAM	EQU	%11111101	; AND IT IN TO TURN RAM ON INSTEAD OF KERNAL
XWRITE	EQU	252		; CODE TO WRITE TO EXPANSION RAM
XREAD	EQU	253		; AND TO READ FROM IT

; THE FIRST 43.5K (SIDE1) MUST
; BE RAM RESIDENT (394=$18A PAGES)

PSIDE1	EQU	175		; 43.75 K IS ON SIDE 1 OF DISK

; PBEGIN IS FIRST PAGENG BUFFER (RAM PAGE UNDER KERNAL)

SWAPMEM	EQU	$E0		; SPEEDUP
PBEGIN	EQU	$FA 		; (LC-A)
NUMBUFS	EQU	$FF-$FA		; (LC-A)

EOL	EQU	$0D		; EOL CHAR
SPACE	EQU	$20		; SPACE CHAR
BACKSP	EQU	$14		; BACKSPACE
LF	EQU	$0A		; LINE FEED
LEFT	EQU	$9D		; ARROW KEYS
RIGHT	EQU	$1D
UP	EQU	$91
DOWN	EQU	$11

	; -----------------
	; MONITOR VARIABLES
	; -----------------

QUOTMOD	EQU	$D4		; QUOTES SENT TO SCREEN TURN ON STRANGE
				; MODE, THIS FLAG SET TO 0 SHOULD
				; TURN THAT MODE OFF ($D4 = LZIP)

	; ---------
	; ZERO-PAGE
	; ---------

D6510	EQU	$00		; 6510 DATA DIRECTION REGISTER
R6510	EQU	$01		; 6510 I/O PORT
RAMFLG	EQU	$01		; IT SETS ON RAM OR ROM
FAST	EQU	$02		; FAST-READ AVAILABLE FLAG
STKEY	EQU	$91		; STOP KEY FLAG
MSGFLG	EQU	$9D		; KERNAL MESSAGE CONTROL FLAG
TIME	EQU	$A2		; SYSTEM JIFFY TIMER
LSTX	EQU	$C5		; LAST KEY PRESSED
NDX	EQU	$C6		; # CHARS IN KEYBOARD BUFFER
RVS	EQU	$C7		; REVERSE CHARACTER FLAG
SFDX	EQU	$CB		; CURRENT KEYPRESS
BLNSW	EQU	$CC		; CURSOR BLINK SWITCH
PNTR	EQU	$D3		; CURSOR COLUMN IN LOGICAL LINE
TBLX	EQU	$D6		; CURRENT CURSOR ROW
LDTB1	EQU	$D9		; 25-BYTE LINE LINK TABLE
KEYTAB	EQU	$F5		; KEYBOARD DECODE TABLE VECTOR

FDATA	EQU	$FB		; FAST-READ DATA BUFFER
FINDEX	EQU	$FC		; FAST-READ BUFFER INDEX
FASTEN	EQU	$FD		; FAST-READ ENABLED FLAG

	; -----------
	; PAGES 2 & 3
	; -----------

LBUFF	EQU	$0200		; 89-BYTE LINE BUFFER
KEYD	EQU	$0277		; KEYBOARD QUEUE
COLOR	EQU	$0286		; FOREGROUND COLOR FOR TEXT
HIBASE	EQU	$0288		; TOP PAGE OF SCREEN RAM
XMAX	EQU	$0289		; MAXIMUM KEYBOARD QUEUE SIZE
RPTFLG	EQU	$028A		; KEY REPEAT FLAG
SHFLAG	EQU	$028D		; SHIFT KEY FLAG
KEYLOG	EQU	$028F		; VECTOR TO KEY-TABLE SETUP ROUTINE
MODE	EQU	$0291		; CHARSET MODE SWITCH
CINV	EQU	$0314		; SYSTEM 60HZ IRQ VECTOR
CBINV	EQU	$0316		; BRK INSTRUCTION VECTOR
NMINV	EQU	$0318		; NMI INTERRUPT VECTOR
SPRT13	EQU	$0340
CURSOR	EQU	SPRT13		; CURSOR RAM
SCREEN	EQU	$0400		; SCREEN RAM
COLRAM	EQU	$D800		; COLOR RAM
SPT0	EQU	$07F8


	; ------
	; VIC-II
	; ------

	; SPRITE POSITION REGISTERS

SP0X	EQU	$D000		; SPRITE #0 X-POS
SP0Y	EQU	$D001		; SPRITE #0 Y-POS

MSIGX	EQU	$D010		; HIGH BITS OF SPRITE X-POSITIONS

	; VARIOUS CONTROL REGISTERS

SCROLY	EQU	$D011		; Y-SCROLL & VIDEO CONTROL
RASTER	EQU	$D012		; RASTER COMPARE
SPENA	EQU	$D015		; SPRITE ENABLE
SCROLX	EQU	$D016		; X-SCROLL & VIDEO CONTROL
YXPAND	EQU	$D017		; SPRITE Y-EXPANSION
VMCSB	EQU	$D018		; MEMORY CONTROL
VICIRQ	EQU	$D019		; CHIP INTERRUPT FLAGS
IRQMSK	EQU	$D01A		; IRQ MASKS
SPBGPR	EQU	$D01B		; SPRITE/FOREGROUND PRIORITY
SPMC	EQU	$D01C		; MULTICOLOR SPRITE CONTROL
XXPAND	EQU	$D01D		; SPRITE X-EXPANSION

	; COLOR REGISTERS

EXTCOL	EQU	$D020		; BORDER COLOR
BGCOLO	EQU	$D021		; BACKGROUND COLOR
SP0COL	EQU	$D027


	; ---
	; SID
	; ---

	; VOICE #1 REGISTERS

FRELO1	EQU	$D400		; FREQ
FREHI1	EQU	$D401		; FREQ HIGH BIT
PWLO1	EQU	$D402		; PULSE WIDTH
PWHI1	EQU	$D403		; PULSE WIDTH HIGH NIBBLE
VCREG1	EQU	$D404		; CONTROL
ATDCY1	EQU	$D405		; ATTACK/DECAY
SUREL1	EQU	$D406		; SUSTAIN/RELEASE


	; VOICE #2 REGISTERS

FRELO2	EQU	$D407		; FREQ
FREHI2	EQU	$D408		; FREQ HIGH BIT
PWLO2	EQU	$D409		; PULSE WIDTH
PWHI2	EQU	$D40A		; PULSE WIDTH HIGH NIBBLE
VCREG2	EQU	$D40B		; CONTROL
ATDCY2	EQU	$D40C		; ATTACK/DECAY
SUREL2	EQU	$D40D		; SUSTAIN/RELEASE

	; VOICE #3 REGISTERS

FRELO3	EQU	$D40E		; FREQ
FREHI3	EQU	$D40F		; FREQ HIGH BIT
PWLO3	EQU	$D410		; PULSE WIDTH
PWHI3	EQU	$D411		; PULSE WIDTH HIGH NIBBLE
VCREG3	EQU	$D412		; VOICE CONTROL
ATDCY3	EQU	$D413		; ATTACK/DECAY
SUREL3	EQU	$D414		; SUSTAIN/RELEASE

	; MISCELLANEOUS REGISTERS

CUTLO	EQU	$D415		; FILTER CUTOFF, LOW BITS
CUTHI	EQU	$D416		; FILTER CUTOFF, HIGH BYTE
RESON	EQU	$D417		; RESONANCE CONTROL
SIGVOL	EQU	$D418		; VOLUME/FILTER CONTROL
RAND	EQU	$D41B		; RANDOM NUMBER
CI2PRA	EQU	$DD00		; DATA PORT A

	; -------------------
	; KERNAL JUMP VECTORS
	; -------------------

CHKIN	EQU	$FFC6		; OPEN CHANNEL FOR INPUT
CHKOUT	EQU	$FFC9		; OPEN CHANNEL FOR OUTPUT
CHRIN	EQU	$FFCF		; INPUT CHARACTER FROM CHANNEL
CHROUT	EQU	$FFD2		; OUTPUT CHARACTER TO CHANNEL
CINT	EQU	$FF81		;; INIT SCREEN EDITOR
CLALL	EQU	$FFE7		; CLOSE ALL CHANNELS & FILES
CLOSE	EQU	$FFC3		; CLOSE A FILE
CLRCHN	EQU	$FFCC		; CLEAR CHANNEL
GETIN	EQU	$FFE4		; GET CHAR FROM KEYBOARD QUEUE
IOINIT	EQU	$FF84		;; INIT I/O
OPEN	EQU	$FFC0		; OPEN A FILE
PLOT	EQU	$FFF0		; READ/SET CURSOR POSITION
RAMTAS	EQU	$FF87		;; INIT RAM
READST	EQU	$FFB7		; READ I/O STATUS
SCNKEY	EQU	$FF9F		;; SCAN KEYBOARD
SETLFS	EQU	$FFBA		; SET FILE ATTRIBUTES
SETMSG	EQU	$FF90		;; SET KERNAL MESSAGES
SETNAM	EQU	$FFBD		; SET FILENAME

	END
