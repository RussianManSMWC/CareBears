.db "NES",$1A
.db $02				;16KB PRG banks
.db $01				;8KB CHR banks
.db $43				;horizontal mirroring, MMC3, SRAM
.db $00,$00,$00,$00,$00,$00,$00,$00,$00

.incsrc Banks/Bank1.asm

FrameCounter = $14

RunGameFlag = $15			;

Player1Input = $16
Player1InputOnce = $17
Player2Input = $18
Player2nputOnce = $19

GameMode = $1A
Reg2000Backup = $1B
Reg2001Backup = $1C
GenericTimer = $1D

CursorPosition = $32
CursorPosition1 = $32
CursorPosition2 = $33			;for copying and deletion
CursorPosition3 = $34
TitleScreenTask = $35
ShowCursorFlag = $36

BackgroundColor = $78

PaletteTask = $96				;what palettes to update, bitwise
Current8000Bank = $97			;to be used when get MMC3 setup right
CurrentA000Bank = $98			;
PaletteBuffer = $0300			;32 bytes
StringBuffer = $0500			;Max 256 bytes, should be more than enough

;SRAM - 256 bytes each file (for now)
;$6000-$60FF - file 1
;$6100-$61FF - file 2
;$6200-$62FF - file 3

;buttons are necessary

A_Button = $80
B_Button = $40
Select_Button = $20
Pause_Button = $10

Up_Button = $08
Down_Button = $04
Left_Button = $02
Right_Button = $01

.org $E000
Reset:
;general reset initialization copy-pasted from my other work - bricky
   SEI
   CLD

   BIT $2002
vblankloop1:
   BIT $2002
   BPL vblankloop1

   LDX #$00
   STX $2000
   STX $2001
   STX $4010
   STX $4015
   DEX
   TSX

   LDY #$07
   STY $01

   LDY #$00
   ;LDA #$00
   STY $00

ResetRAMLoop:
   STA ($00),y

   DEY
   BNE ResetRAMLoop

   DEC $01
   BPL ResetRAMLoop

;;;

   BIT $2002
vblankloop2:
   BIT $2002
   BPL vblankloop2
   
   JSR ClearScreen
   JSR InitOAM
   JSR ClearAttributes
   
   ;LDA #$02
   ;STA $8000				;to be used when expanded for more banks
   
   LDA #$80+$20				;enable 8x16 sprites and NMI
   STA $2000
   STA Reg2000Backup
   
   LDA #$1E					;enable display
   STA $2001
   STA Reg2001Backup
   
   LDA #$80
   STA $A001				;allow PRG RAM writes aka sram
   
GameLoop:
	LDA RunGameFlag
	BEQ GameLoop

	DEC RunGameFlag
	JSR HandleGame
	
	JMP GameLoop

;mostly harmless NMI
NMI:

;STA $96
;STY $97
;STX $98

;LDA $96
;LDY $97
;LDX $98

;vs

;PHA
;TYA
;PHA
;TXA
;PHA

;PLA
;TAX
;PLA
;TAY
;PLA

;1. 3*6 = 18 cycles (LDA ZP and STA ZP each cost 3 cycles
;2. 3*3+3*4+2*4 = 9+12+8 = 29 cycles

;first variant is more effective cycle-wise, saving 11 cycles but it takes 2 extra bytes of space and 3 bytes of ram (zero page)
;using absolute addressing it saves 5 cycles but uses 6 more bytes of space.

PHA
TYA
PHA
TXA
PHA
   
LDA #$02						;upload entire 0200 page as OAM
STA $4014
   
JSR UpdatePalette

JSR DrawStrings
;LDA PaletteBuffer+$10		;may or may not be usefull
;STA BackgroundColor			;
   
LDX #$00					;
STX $2005					;camera back to normal
STX $2005					;
   
   ;LDA #$1E
   ;STA $2001
INX
STX RunGameFlag
   
;LDA #$01
;STA RunGameFlag

   
	INC FrameCounter
	
   PLA
   TAX
   PLA
   TAY
   PLA
   RTI
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Screen Clean.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearScreen:
   LDA $2002

   LDA #$20				;
   STA $2006			;
   
   LDA #$00				;
   STA $2006			;
   
   LDA #$1F				;fill screen (and more) with empty tiles
   ;LDY #$00			;
   TAY
   LDX #$09				;
   ;JMP FillLoop
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Screen Filler
;
;Fills Screen (specific area) with tile value stored in A.
;Input:
;$2006 - Starting Position
;X - Number of screens to fill tiles
;Y - Number of tiles to draw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
Fill_Loop:
	STA $2007
	DEY
	BNE Fill_Loop
	DEX
	BNE Fill_Loop
	RTS
	
InitOAM:
   LDA #$FF						;put sprites in hide area
   LDY #$00						;
@Loop
   STA $0200,y					;
   INY							;
   BNE @Loop					;
   RTS							;
   
ClearAttributes:
	LDA $2002

	LDA #$23
	STA $2006

	LDA #$C0
	STA $2006
	LDX #$40
@Loop
	;LDA AttrTable,x
	LDA #$00
	STA $2007
	DEX
	;CPX #$03
	BNE @Loop
	RTS
	
UpdatePalette:
	LDA PaletteTask		;
	BEQ @Return
	
	LDX #$00

@RollLoop
	LDY #$00
	LDA $2002
	LDA #$3F				;
	STA $2006				;prepare write for palette
	LDA PaletteTask			;
	BEQ @Return				;
	AND #$01				;
	BEQ @NextPal			;
	TXA						;
	STA $2006				;

@PaletteLoop
	LDA $0300,x
	STA $2007
	
   	INX
	INY
	CPY #$04
	BNE @PaletteLoop
	LSR $96
	JMP @RollLoop
	
@Return
	RTS
	
@NextPal
	LSR $96
	INX
	INX
	INX
	INX
	BNE @RollLoop
	
DrawStrings:
LDA StringBuffer
BEQ @Re

LDA $2002

LDY #$00
@BufferLoop
LDA StringBuffer,y
;CMP #$FF
;BEQ @Re
STA $2006
INY

LDA StringBuffer,y
STA $2006
INY

@DrawLoop
LDA StringBuffer,y
CMP #$FF
BEQ @Re
CMP #$FE
BEQ @ChangeVRAM

STA $2007

INY
BNE @DrawLoop

@ChangeVRAM
INY
BNE @BufferLoop

@Re
RTS

HandleGame:
LDA GameMode
JSR ExecutePointers

.dw InitTitleScreen
.dw TitleScreen
.dw Cutscene
.dw Overworld
.dw LoadLevel
.dw Level

ExecutePointers:
ASL						;
TAY						;
INY						;

PLA 
STA $00

PLA
STA $01

LDA ($00),y
STA $02
INY

LDA ($00),y
STA $03

JMP ($0002)

DisableDisplay:
LDA #$80
STA $2000						;

LDA #$00
STA $2001						;no display
BEQ WaitNMI

EnableDisplay:
LDA Reg2000Backup
STA $2000

LDA Reg2001Backup
STA $2001

WaitNMI:
NOP								;i'm still not sure if htis is really necessary

@Loop
LDA RunGameFlag
BEQ @Loop
RTS

;care bears sprites
;previously for testing
;LDA #$40
;STA $00
;  
;LDA #$40
;STA $01
;  
;LDX #$09
;@DrawBear
;LDA $00
;CLC
;ADC TileDispY,x
;STA $0200,y
;
;LDA $01
;CLC
;ADC TileDispX,x
;STA $0203,y
;  
;LDA Tilemap,x
;STA $0201,y
;   
;LDA TileProp,x
;STA $0202,y
;  
;INY 
;INY
;INY
;INY
;DEX
;BPL @DrawBear
;Return:
;RTS
;
;TileDispY:
;db $00,$00,$10,$10,$10
;db $00,$00,$10,$10,$10
;
;TileDispX:
;db $00,$08,$00,$08,$05
;db $78,$70,$78,$70,$72
;
;TileProp:
;db $00,$00,$00,$00,$01
;db $42,$42,$42,$42,$43
;
;Tilemap:
;db $00,$02,$20,$22,$24
;db $00,$02,$20,$22,$26
   

DrawScreen:
LDY #$00
LDA $2002

@Loop
LDA ($00),y
CMP #$FF
BEQ @Re
CMP #$FE
BEQ @ChangeVRAM
;CMP #$FD
;BEQ @DiffLoop		;to be added... maybe
STA $2007

JSR IncreaseInderect1
JMP @Loop

@ChangeVRAM
JSR IncreaseInderect1
LDA ($00),y
STA $2006

JSR IncreaseInderect1
LDA ($00),y
STA $2006

JSR IncreaseInderect1
JMP @Loop

@Re
RTS


;This routine increases inderect addressing value by one ($00 and $01)
IncreaseInderect1:
LDA $00
CMP #$FF
INC $00
BNE @NoHiByte

INC $01

@NoHiByte
RTS

;sae as above bt with $02 and $03
IncreaseInderect2:
LDA $02
CMP #$FF
INC $02
BNE @NoHiByte

INC $03

@NoHiByte
RTS

HandleButtonInput:
;From NESEDEV, modified to take presses into account
LDA Player1Input
STA $02

LDA Player2Input
STA $03

lda #$01
sta $4016
sta Player2Input  ; player 2's buttons double as a ring counter
lsr a         ; now A is 0
STA $4016

@loop
lda $4016
and #%00000011  ; ignore bits other than controller
cmp #$01        ; Set carry if and only if nonzero
rol Player1Input    ; Carry -> bit 0; bit 7 -> Carry
lda $4017     ; Repeat
and #%00000011
cmp #$01
rol Player2Input    ; Carry -> bit 0; bit 7 -> Carry
bcc @loop

LDX #$01
@loop2
LDA $02,x
EOR #%11111111
AND Player1Input,x
STA Player1InputOnce,x

DEX
BPL @loop2
RTS

;Draws 16x16 tile from graphic data
;INPUT:
;$00 - Y-position
;$01 - X-position
;$02 - bottom-left sprite tile value of 16x16 sprite
;$03 - property
;Y - OAM offset
Draw16x16Sprite:
LDA $00						;init cursor
STA $0200,y					;tiles
STA $0204,y

LDA $02
STA $0201,y
CLC
ADC #$02
STA $0205,y

LDA $03
STA $0202,y
STA $0206,y

LDX #$F8
LDA $03
AND #$40
BNE @Flip

LDX #$08

@Flip
TXA
CLC 
ADC $01						;X-pos
STA $0207,y

LDA $01
STA $0203,y
RTS

FlipValue:
db $40,$00
	
.org $FFFA

.dw NMI
.dw Reset
.dw Reset						;unused IRQ
   
.incbin CareBare.bin