;Contains game mode handling (Title screen for now)
;$8000-$9FFF

.org $8000
InitTitleScreen:
;initialize palette

LDA #$FF						;update all palettes (to be used in NMI)
STA PaletteTask					;
STA TitleScreenTask				;initialize selected option (none)
STA CursorPosition2				;>just in case
STA CursorPosition3				;i didn't initialize third cursor propertly

LDX #$00						;
   
@initBuffer
LDA TitleScreenPal,x		
STA PaletteBuffer,x
INX
CPX #$20
BNE @initBuffer

;initialize strings

JSR DisableDisplay

LDA #>TitleScreenScreenData
STA $01

LDA #<TitleScreenScreenData
STA $00

JSR DrawScreen

;additional sprites (duh)
LDX #$09
LDY #$00

@SprLoop
LDA AdditionalTitleSprYPos,x	;bears would look incomplete without these
STA $0200,y

LDA AdditionalTitleSprXPos,x
STA $0203,y

LDA AdditionalTitleSprTile,x
STA $0201,y

TXA
BNE @Same
LDA #$41
BNE @Store

@Same
LDA #$01

@Store
STA $0202,y

INY
INY
INY
INY

DEX
BPL @SprLoop

JSR UpdateFiles

;end initialization

JSR EnableDisplay

INC GameMode
RTS

TitleScreenPal:
db $0F,$0F,$30,$2C				;BG 1
db $0F,$0F,$30,$32				;BG 2
db $0F,$0F,$0F,$0F				;BG 3
db $0F,$0F,$0F,$0F				;BG 4 

db $3C,$0F,$30,$0F				;Spr 1
db $0F,$0F,$27,$25				;Spr 2
db $0F,$0F,$30,$34				;Spr 3
db $0F,$0F,$25,$14				;spr 4

;to do: streamline format a bit (make it upload entire rows of tiles from graphics if necessary.
;if possible, of course
TitleScreenScreenData:
db $FE,$21,$2D					;FILE 1 -
db $05,$08,$0B,$04,$1F,$20,$1F,$1C
db $FE,$21,$6D					;FILE 2 -
db $05,$08,$0B,$04,$1F,$21,$1F,$1C
db $FE,$21,$AD					;FILE 3 -
db $05,$08,$0B,$04,$1F,$22,$1F,$1C
db $FE,$21,$ED					;COPY
db $02,$0E,$0F,$18
db $FE,$22,$2D					;ERASE
db $04,$11,$00,$12,$04

;TEST!
db $FE,$22,$6D
db $13,$04,$12,$13

;writing care bares
;bedtime
db $FE,$22,$66
db $23,$24,$25,$1F,$27
db $FE,$22,$82
db $D0,$D1,$30,$1F,$32,$33,$34,$35,$36,$37
db $FE,$22,$A2
db $E0,$E1,$40,$41,$42,$43,$44,$45,$46,$47
db $FE,$22,$C2
db $F0,$F1,$50,$51,$52,$53,$54,$55,$56,$57
db $FE,$22,$E2
db $F4,$F5,$60,$61,$62,$63,$64,$65,$66,$67
db $FE,$23,$03
db $E2,$70,$71,$72,$73,$74,$75,$76,$77
db $FE,$23,$23
db $F2,$80,$81,$82,$83,$84,$85,$86,$87
db $FE,$23,$44
db $90,$91,$92,$93,$94,$95,$96,$97
db $FE,$23,$64
db $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$D3
db $FE,$23,$84
db $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$E3
db $FE,$23,$A4
db $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$F3

;lavender
db $FE,$22,$75
db $29,$1F,$2B,$2C,$2D
db $FE,$22,$94
db $38,$39,$3A,$3B,$3C,$3D,$3E,$3F,$DA,$DB
db $FE,$22,$B4
db $48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$EA,$EB
db $FE,$22,$D4
db $58,$59,$5A,$5B,$5C,$5D,$5E,$5F,$FA,$FB
db $FE,$22,$F4
db $68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$F6,$F7
db $FE,$23,$14
db $78,$79,$7A,$7B,$7C,$7D,$7E,$7F,$E9
db $FE,$23,$34
db $88,$89,$8A,$8B,$8C,$8D,$8E,$8F,$F9
db $FE,$23,$54
db $98,$99,$9A,$9B,$9C,$9D,$9E,$9F
db $FE,$23,$73
db $D8,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
db $FE,$23,$93
db $E8,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
db $FE,$23,$B3
db $F8,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF

;attributes for lavender
db $FE,$23,$E5
;i'd insert custom command, $FD, but those aren't long enough to suspass size of command itself, which is 3 bytes
db $55,$55
db $FE,$23,$ED
db $55,$55,$55
db $FE,$23,$F4
db $55,$55,$55,$55
db $FE,$23,$FC
db $55,$55,$55
db $FF

;NEW Data
;because i cleaned up GFX aka removed duplicates
;db $FE,$22,$66
;db $23,$24,$25,$1F,$27
;db $FE,$22,$82
;db $D0,$D1,$30,$1F,$32,$33,$34,$35,$36,$37
;db $FE,$22,$A2
;db $E0,$E1,$40,$41,$42,$43,$44,$45,$46,$47
;db $FE,$22,$C2
;db $F0,$44,$50,$51,$52,$44,$54,$44,$44,$57
;db $FE,$22,$E2
;db $F4,$F5,$60,$61,$62,$63,$64,$65,$44,$67

AdditionalTitleSprYPos:
db $C7,$C7,$DF,$DF,$DF,$DF,$DF,$CF,$CF,$CF

AdditionalTitleSprXPos:
db $BF,$39,$3D,$B8,$C0,$C8,$D0,$B8,$C0,$C8

AdditionalTitleSprTile:
db $F7,$F7,$DF,$F9,$FB,$FD,$FF,$D9,$DB,$DD

LastOption = $06

TitleScreen:
JSR HandleButtonInput				;yeah, handle dem buttons (to be moved to NMI, maybe?)

;JSR HandleCursors					;

LDA TitleScreenTask					;if we didn't push a button, don't execute action
BMI @NoExecution

@Execute_Yes
JSR ExecutePointers
.dw File
.dw File
.dw File
.dw Copy_Erase
.dw Copy_Erase
.dw TEST

@NoExecution
LDA Player1InputOnce				;A press activates selected option
AND #A_Button						;
BNE @Pressed						;

LDA #$FF							;otherwise don't show second cursor
STA CursorPosition2					;
BNE @CheckPos						;

@Pressed
LDA CursorPosition1					;execute option by cursor position
STA TitleScreenTask					;

LDA #$00							;show second cursor
STA CursorPosition2					;
RTS									;

@CheckPos
LDX #$00							;handle cursor 1
LDA #LastOption						;wrap after delete option
JSR HandleCursorMovement			;

@Continue
JMP CommonCursorPrep				;had X = 00 before

;test function to test exits
TEST:
LDA #$01
STA $6000

LDA #$03
STA $6001
STA $6002

LDA #$FF
STA TitleScreenTask

JMP UpdateFiles

;
;Chose file - choose playr
;

;local table for second cursor's X-positions
PlayerChooseCursorXPos:
db $68,$90	

File:
LDA Player1InputOnce				;
AND #$40							;if B button's pressed, cancel selection
BEQ NoCancel						;

DisableSelection:
LDA #$FF							;
STA CursorPosition2					;
STA TitleScreenTask					;
STA $0200+($04*12)					;
STA $0200+($04*13)					;
RTS

NoCancel:
LDA Player1InputOnce				;pressed right
AND #Right_Button					;
BNE @Increase						;switch to another bear

LDA Player1InputOnce				;press left
AND #Left_Button					;
BEQ @Nothing						;

DEC CursorPosition2					;
JMP @Nothing						;

@Increase
INC CursorPosition2					;

@Nothing
JSR HandleBlinkingCursor1			;first cursor should blink

@Cursor2
LDY #$04*12							;kind of hardcoded cursor, unlike other cursors it ahs it's own position spots and stuff
LDA CursorPosition2					;
AND #$01							;
TAX									;
LDA PlayerChooseCursorXPos,x		;
STA $01								;

LDA #$B0							;
STA $00								;

LDA #$E1							;
STA $02								;

LDA FlipValue,x						;maybe global ($E000-$FFFF)
STA $03								;
JMP Draw16x16Sprite					;jump straight to draw routine						;

;
;Erase or copy
;

Copy_Erase:
JSR HandleBlinkingCursor1			;

LDA TitleScreenTask					;
CMP #$04							;
BNE Copy							;
JMP Erase							;a bit too far from here

Copy:
LDA CursorPosition3					;
BPL @HandleThird					;

@StillSecond
LDA Player1InputOnce				;cancel if must
AND #B_Button						;(on B button)
BNE DisableSelection				;

LDX #$01
JSR CommonCursorPrep

LDA Player1InputOnce
AND #A_Button
BEQ @HandleMovement

LDA #$00							;initialize thrid cursor
CMP CursorPosition2					;usually we place cursor on first option (File 1), but if it's occupied by another cursor, place on second file
BNE @StoreThirdPos

LDA #$01							;there can't be cursor on second file if it's on first file already

@StoreThirdPos
STA CursorPosition3					;
RTS									;

@HandleMovement
LDX #$01							;handle cursor 2
LDA #$03							;
JMP HandleCursorMovement			;
;JMP CommonCursorPrep				;

;just now i realize it can be a bit tricky with positions of cursor

@HandleThird
LDA Player1InputOnce				;cancel third cursor's selection
AND #B_Button						;
BNE @Cancel							;

LDX #$02
JSR CommonCursorPrep

LDA Player1InputOnce
AND #A_Button
BNE @CopyOperation

LDX #$02							;this time handle cursor 3
LDA #$03							;
JSR HandleCursorMovement			;

LDA CursorPosition3					;if cursor 2 and 3 match, move cursor 3 again
CMP CursorPosition2					;
BNE @Re								;

;LDA Player1InputOnce				;
;AND #Down_Button					;
;BNE @Increase						;

LDX #$02							;cursor drawing messes X
LDA #$03							;
JSR HandleCursorMovement			;move cursor again

@Re
RTS

@Cancel
LDA #$FF
STA $0200+($04*14)					;
STA $0200+($04*15)					;
STA CursorPosition3					;
RTS									;

@CopyOperation
LDA #$60
CLC
ADC CursorPosition2
STA $01

LDA #$60
CLC
ADC CursorPosition3
STA $03

LDA #$00
STA $00
STA $02
TAY
;TAX

@CopySRAMLoop
LDA ($00),y
STA ($02),y

INY
BNE @CopySRAMLoop
;RTS

;LDA CursorPosition3
JMP UpdateFiles

;;;;;;;;;;;;;;;;;;;;;;;;;;;

Erase:
LDA Player1InputOnce				;cancel if must
AND #B_Button						;(on B button)
BEQ @Continue						;
JMP DisableSelection				;

@Continue
LDA Player1InputOnce
AND #A_Button
BNE @StartErasing

;LDA Player1InputOnce
;AND #Down_Button
;BNE @Increase

;LDA Player1InputOnce
;AND #Up_Button
;BEQ @Nothing

;DEC CursorPosition2
;JMP @Nothing

@Increase
;INC CursorPosition2

@Nothing
;LDA CursorPosition2
;BMI @Wrap
;CMP #$03
;BNE @Re

;LDA #$00
;BEQ @Store

@Wrap
;LDA #$02

@Store
;STA CursorPosition2

LDX #$01							;show cursor no. 2
LDA #$03
JSR HandleCursorMovement
JMP CommonCursorPrep				;

@Re
RTS

@StartErasing
LDA #$60
CLC
ADC CursorPosition2
STA $01

LDA #$00
STA $00
TAY
;TAX

@ClearSRAMLoop
STA ($00),y

INY
BNE @ClearSRAMLoop
JMP UpdateFiles

HandleBlinkingCursor1:
LDA GenericTimer
BNE @ShowCursorOrNot

LDA #$10
STA GenericTimer

INC ShowCursorFlag

@ShowCursorOrNot
DEC GenericTimer
LDA ShowCursorFlag
AND #$01
BEQ @NoCursor

LDX #$00
BEQ CommonCursorPrep

@NoCursor
LDA #$FF
STA $0200+($04*10)
STA $0200+($04*11)
RTS

;DrawCursor1:
;LDY #$04*10
;
;DrawCursor:
;ASL
;ASL
;ASL
;ASL
;CLC
;ADC #$3B+8
;STA $00
;
;LDX #$00

;to do:
;turn this into 2 cursor sprites draw routine, where it checks if second cursor should display

;LDA #$4E+8
;STA $01

;LDA #$E1
;STA $02

;LDA #$00
;STA $03

;JMP Draw16x16Sprite				;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Supposed to obsolette DrawCursor
;obsoletted by different method
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;HandleCursors:
;LDX #$02				;can only be max of 3 - when copy option's used
;
;@CursorLoop
;TAX
;ASL
;ASL
;ASL
;CLC
;ADC #$04*10				;start from slot 10
;TAY						;Y - OAM slot start
;
;LDA CursorPosition,x
;BMI @NoShow
;ASL
;ASL
;ASL
;ASL
;CLC
;ADC #$43
;STA $00					;proper Y-pos... at least i think it is
;
;@NoShow
;STA $0200,y
;STA $0204,y
;
;@Next
;DEX
;BPL @CursorLoop
;RTS

;New CursorDraw routine
;Input:
;X - cursor no.

CursorPointPositions:
db $43,$53,$63,$73,$83,$93

CommonCursorPrep:
LDY CursorPosition,x
LDA CursorPointPositions,y
STA $00

LDA #$56
STA $01

LDA #$E1
STA $02

LDA #$00
STA $03

TXA
ASL
ASL
ASL
CLC
ADC #$04*10
TAY
JMP Draw16x16Sprite

;handle cursor movement with up/down (common)
;Input:
;X - cursor number
;A - position where it should wrap, after last option (-1) (e.g. #$04 - Erase option, wrap around to first if here).
HandleCursorMovement:
STA $00								;contains position value where it should wrap

LDA Player1InputOnce				;
AND #$04							;if pressed down, move down
BNE @MoveDown						;

LDA Player1InputOnce				;move up on up
AND #$08							;
BEQ @Check							;

DEC CursorPosition,x				;
JMP @Check

@MoveDown
INC CursorPosition,x				;

@Check
LDA CursorPosition,x				;
BMI @WrapToLast
CMP $00								;
BCC @Re								;

@WrapToZero
LDA #$00
STA CursorPosition,x

@Re
RTS

@WrapToLast
LDY $00
DEY
TYA
STA CursorPosition,x
RTS

;Show exit number for each file/EMPTY
;Input:
;
;
;$00 and $01 - file number from SRAM, flag indicating this file was used, inderect addressing
;$02 and $03 - string buffer, indirect addressing
;$04 - temporarily hold X register
;$05 - used to offset VRAM address for string buffer

EMPTYString:
db $04,$0C,$0F,$13,$18
;db "EMPTY"

;0-9
NumberTiles:
db $FF,$20,$21,$22,$FF,$FF,$FF,$FF,$FF,$FF

UpdateFiles:
LDA #$60
STA $01

LDA #$00
STA $00
STA $02
TAY						;Y is zero

LDA #$05				;high byte for string buffer
STA $03

;LDA #$00
;STA $0500

LDA #$36
STA $05

LDX #$02
BNE @InitLoop

@MaybeLoop
LDA #$FE					;change VRAM location to draw
STA ($02),y					;
JSR IncreaseInderect2		;

LDA $05
CLC
ADC #$40
STA $05

@InitLoop
LDA #$21
STA ($02),y
JSR IncreaseInderect2

LDA $05
STA ($02),y
JSR IncreaseInderect2

LDA ($00),y				;check if file was used
BNE @NotEmpty			;if not, draw number of exits

STX $04

LDX #$00

@EMPTYLoop
LDA EMPTYString,x
STA ($02),y
JSR IncreaseInderect2
INX
CPX #$05
BNE @EMPTYLoop

LDX $04
BPL @NextFile

@NotEmpty
JSR IncreaseInderect1
STX $04

LDA ($00),y				;
AND #$0F				;
;LSR						;
;LSR						;
;LSR						;
;LSR						;
TAX
LDA NumberTiles,x
STA ($02),y				;

JSR IncreaseInderect1
JSR IncreaseInderect2

LDA ($00),y
AND #$0F
TAX
LDA NumberTiles,x
STA ($02),y
JSR IncreaseInderect2

LDA #$1F
STA ($02),y				;in case of copy
JSR IncreaseInderect2

LDA #$1F
STA ($02),y
JSR IncreaseInderect2


LDA #$1F
STA ($02),y
JSR IncreaseInderect2

JSR IncreaseInderect2

LDX $04						;restore X

@NextFile
LDA #$00					;reset low byte of SRAM address to check flag
STA $00						;

INC $01						;
DEX							;next file
BPL @MaybeLoop				;

LDA #$FF					;
STA ($02),y					;stop command for string buffer
RTS

Cutscene:
LoadLevel:
Level:
Overworld:
INC GameMode
RTS