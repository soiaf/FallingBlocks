; 
; FallingBlocks.asm 
;
; Copyright (c) 2015 Peter McQuillan 
; 
; All Rights Reserved. 
; 
; Distributed under the BSD Software License (see license.txt) 
; 
; 


org 24576
	; set up our own routines. Two elements, a table that points to where the interrupt code is
	; held and the actual interrupt code itself. Due to the strange way interrupts work on spectrum
	; our table is a series of the value 200. The idea is that an interrupt call would randomly jump
	; to somewhere in this table and read the values 200 (2 reads) 0 this gives a memory location of
	; (200*256) + 200 = 51400, which is where we will put our actual interrupt routine
	; We put our table out of the way, starting at 65024 (which is 256 * 254)
	
	di					; we are setting up out own interrupt routine, disable while doing this
	ld a,254			; high byte of pointer table location (256 * 254 gives 65024).
	ld i,a				; set high byte.
	im 2				; select interrupt mode 2.
	ei					; enable interrupts.
	jp START

graphics 
		defb 254, 126, 190, 94, 174, 86, 170, 0	; basic block
		defb 126, 129, 189, 165, 165, 189, 129, 126 ; old side wall graphic
		defb 231, 231, 231, 231, 231, 231, 231, 231	;vertical pipe
		defb 60, 126, 126, 231, 231, 231, 231, 231 	;pipe end (top)
		defb 231, 231, 231, 231, 231, 126, 126, 60	; pipe end (bottom)
		defb 255, 255, 255, 0, 0, 255, 255, 255		;horizontal pipe
		defb 231, 231, 227, 224, 240, 255, 127, 63	; pipe corner bottom left
		defb 63, 127, 255, 240, 224, 227, 231, 231	; pipe corner top left
		defb 231, 231, 199, 7, 15, 255, 254, 252	; pipe corner bottom right
		defb 252, 254, 255, 15, 7, 199, 231, 231	; pipe corner top right
		
;Port array used for the redefine keys routine
port_array:		defb $7f ; B-SPACE
			defb $bf ; H-ENTER
			defb $df ; Y-P
			defb $ef ; 6-0
			defb $f7 ; 1-5
			defb $fb ; Q-T
			defb $fd ; A-G
			defb $fe ; CAPS-V

key_music_port:		defb $7f
key_music_pattern:	defb 4
key_left_port: 		defb $df
key_left_pattern: 	defb 2
key_right_port: 	defb $df
key_right_pattern: 	defb 1
key_anticlockwise_port: 		defb $7f
key_anticlockwise_pattern: 	defb 1
key_clockwise_port: 	defb $bf
key_clockwise_pattern: 	defb 16
key_drop_port: 		defb $fd
key_drop_pattern: 	defb 4			
key_ghost_port:		defb $fd
key_ghost_pattern:	defb 16
key_swap_port:		defb $fd
key_swap_pattern:	defb 2


ROM_CLS:		EQU 3435
CHAN_OPEN:		EQU 5633
CC_INK:			EQU 16
CC_PAPER:		EQU 17
CC_AT:			EQU 22	
	
msg_left: 		defm CC_INK,4,CC_AT,7,8,"Left ?",255
msg_right: 		defm CC_INK,4,CC_AT,8,8,"Right ?",255
msg_anticlockwise: 	defm CC_INK,4,CC_AT,9,8,"Anti Clockwise ?",255
msg_clockwise: 		defm CC_INK,4,CC_AT,10,8,"Clockwise ?",255
msg_drop: 		defm CC_INK,4,CC_AT,11,8,"Drop ?",255
msg_ghost: 		defm CC_INK,4,CC_AT,12,8,"Ghost ?",255
msg_swap:		defm CC_INK,4,CC_AT,13,8,"Swap/Save ?",255
msg_music:		defm CC_INK,4,CC_AT,14,8,"Music On/Off ?",255
msg_define:		defm CC_INK,4,CC_AT,1,7,"Press key for ...",255	

msg_gameover_score: 	defm CC_INK,7,CC_AT,17,10,"Your score",255

msg_gameover_newhighscore	defm	CC_INK,4,CC_AT,21,0,"Congratulations! New high score",255
	
msg_newscreen_level		defm CC_INK,7,CC_AT,12,12,"Level ",255	
	
startx	defb	0	; all blocks start at this position
starty	defb	15	; all blocks start at this position

upsidedownstartx	defb	20	; starting x position if upside down

nextblockx	defb	11	;x position of the next block space
nextblocky	defb	25	;y position of the next block space
scorex		defb	4	;x position where we write the score
scorey		defb	25	; y position where we write the score
highscorex	defb	4	; x position where we write the high score
highscorey	defb	3	; y position where we write the high score
savedblockx	defb	11	;x position of the saved block space
savedblocky	defb	4	;y position of the saved block space
ghostx		defb	0	;x position of the ghost shape
ghosty		defb	15	;y position of the ghost shape
linesx		defb	18	; x position of where we write the lines completed
linesy		defb	25	; y position of where we write the lines completed

shootingstarx		defb	0	; x position of the star
shootingstary		defb	0	; y position of the star

; holds the row that will be shifted one column left or right
slidingrow		defb	0

; sliding attempt counter. We try 20 times to find a row to slide, but if not we exit
; this is to prevent the (unlikely) case of no pieces currently being on the playarea
slidingcounter	defb 0

; when we slide a row we wrap around the blocks, this holds the value of the wrapped around block
slidingwraparoundcolour	defb	0

; this is the temp holder for colours used in the sliding floors routine
slidingtempcolour	defb	0

; This holds the colour of the ghost shape (bright white)
ghostcolour		defb	71

; this is used for determining whether the ghost is actually showing, for example may not be
; due to shape being too near the top of the piled blocks

ghostshowing defb	0

; This defines the top line starting position, this is used when erasing the line
; after a winning line is detected
playareatoplinex	defb	0
playareatopliney	defb	12

upsidedownplayareatoplinex	defb	21	; top line when upside down
	
plx    defb 4              ; player's x coordinate.
ply    defb 4              ; player's y coordinate.

tmpx	defb 16
tmpy	defb 16

wallpos	defb 3


shapedata	
	defb 15,0	; shape 1
	defb 68,68
	defb 15,0	
	defb 68,68	
	defb 142,0	; shape 2
	defb 68,192	
	defb 14,32	
	defb 200,128	
	defb 46,0	;shape 3
	defb 196,64	
	defb 232,0	
	defb 136,192	
	defb 204,0	;shape 4
	defb 204,0	
	defb 204,0	
	defb 204,0	
	defb 108,0	; shape 5
	defb 140,64 
	defb 108,0 
	defb 140,64 
	defb 78,0 ; shape 6
	defb 76,64 
	defb 14,64  
	defb 140,128 
	defb 198,0 ; shape 7
	defb 76,128 
	defb 198,0 
	defb 76,128 ; this is the end of the standard blocks
	defb 72,0	;shape 8
	defb 132,0
	defb 72,0
	defb 132,0
	defb 200,192	;shape 9
	defb 174,0
	defb 196,192
	defb 14,160
	defb 12,0	; shape 10
	defb 68,0
	defb 12,0 
	defb 68,0
	defb 164,0 	; shape 11
	defb 132,128
	defb 74,0 
	defb 72,64
	defb 78,64	; shape 12
	defb 78,64
	defb 78,64
	defb 78,64

	
; this holds the offset for ghost. Basically it is the number of increments you would
; need to take for a shape to be no longer blocking itself

ghostoffset
	defb 1,4,1,4
	defb 2,3,2,3 
	defb 2,3,2,3 
	defb 2,2,2,2 
	defb 2,2,2,2
	defb 2,3,2,3 
	defb 2,2,2,2
	defb 1,1,1,1
	defb 3,2,3,2
	defb 1,2,1,2
	defb 1,3,1,3
	defb 3,3,3,3
	
; this table helps find the correct ghost offset

ghostlookuptable	defb  0,4,8,12,16,20,24,28,32,36,40,44

; ghost offset value pointer

ghostpointer	defb 0
	
; this gives the colour of each of the shapes	
colourlookuptable defb 5,1,67,6,4,3,2,66,68,69,70,65

blockshapes	defb 142,0

; this holds the current shape being shown
currentshape	defb	3

; this holds the next shape that will be played
nextshape	defb	2

; this holds the saved shape
savedshape	defb	0

currentorientation	defb 0

blockpointer	defb 0

blocklookuptable	defb	0,8,16,24,32,40,48,56,64,72,80,88

; this is the number of complete lines required to win each level
linesneededperlevel	defb	10,6,6,5,4,8,5,5,4,25
;linesneededperlevel	defb	1,3,4,1,1,1,1,1,1,1

; this holds what level the player is currently on
currentlevel	defb	1

; this holds the total number of lines completed so far this level
totalrowscompleted		defb	 '00'

; this holds the total number of lines completed so far this level (as a number)
totalrowscompletednum		defb	 0

; this holds the lines target for this level (as a string)
targetlinesforthislevel	defb	'00'

; this holds the lines target for this level (as a number)
targetlinesforthislevelnum	defb	0

; this is the colour of the shape currently being played
blockcolour	defb	5

; this is the colour used by showshape when showing a shape onscreen
drawcolour	defb	0

; this holds the current number of complete lines we have made this level
completedlines	defb	0

; this is set to 1 when a winning/complete line is detected
winningline		defb	0

; when flashing a winning line, or then erasing it, this sets the colour
winninglinecolour	defb	130	; flashing red

; holds the score
score  defb '000000'

; holds the high score
highscore	defb	'001250'

; shows whether a new high score has been set
newhighscore defb	0

; this holds whether the level is upside down (i.e. falls up rather than usual down)
upsidedown defb 0

; a value of 1 means allowed move
allowedmove defb 1

; a player is only allowed swap once (till the next shape is automatically picked)
; a value of 1 means they are allowed swap, otherwise they are not
allowedswap	defb 1

; rows completed holds the number of rows filled, bonus points for 4
rowscompleted	defb	0

; this holds the number of pieces played this level
piecesthislevel	defb	0

; ghost active. 0 is off, 1 is on. This determines whether the ghost shape is shown
; The ghost shape shows where the shape would go if the player pressed drop
ghostactive	defb	0

; this holds whether Kempston joystick support is enabled or not. Can cause
; issues if activated when, say, emulator is not set to support it.
; 0 - disabled, 1 - enabled, 2 - not available

kemsptonactivated	defb	0

; this holds the difficulty level, 0 is normal, 1 is hard

difficulty	defb	0

; timer used when deciding to auto drop the block
pretim defb 0

; this shows if we are in-game or not. Used to determine whether to play the in-game music
; or not, 1 means we are currently in-game

ingame	defb	0

; this holds whether in game music is wanted/enabled (by the player)
ingamemusicenabled	defb	1

randomtable:
    db   82,97,120,111,102,116,20,12
	
; holds a value for last action/key pressed. 
; 0 means no key, 1 means clockwise, 2 anticlockwise
; 3 left, 4 right, 5 ghost, 7 drop, 9 music
lastkeypressed	defb	0

msg_menu_copyright:		defm CC_INK,7,CC_AT,13,4,"(c)2015 Peter McQuillan",255
msg_menu_startgame: 	defm CC_INK,7,CC_AT,18,4,"1 Start Game",255
msg_menu_definekeys: 	defm CC_INK,7,CC_AT,19,4,"2 Define Keys",255
msg_menu_kempston: 	defm CC_INK,7,CC_AT,20,4,"3 Kempston Joystick",255
msg_menu_difficulty:	defm CC_INK,7,CC_AT,21,4,"4 Difficulty",255
msg_menu_kempston_on:	defm CC_INK,4,CC_AT,20,23,"(On) ",255
msg_menu_kempston_off:	defm CC_INK,2,CC_AT,20,23,"(Off)",255
msg_menu_kempston_na:	defm CC_INK,2,CC_AT,20,23,"(n/a)",255	; we detect if a kempston joystick is present, if not show this
msg_menu_difficulty_normal:	defm CC_INK,4,CC_AT,21,16,"(Normal) ",255
msg_menu_difficulty_hard:	defm CC_INK,2,CC_AT,21,16,"(Hard)   ",255

msg_game_score:		defm CC_INK,7,CC_AT,2,25,"Score",255
msg_game_highscore:	defm CC_INK,7,CC_AT,2,3,"High",255
msg_game_nextpiece:	defm CC_INK,7,CC_AT,9,25,"Next",255
msg_game_savedpiece:	defm CC_INK,7,CC_AT,9,3,"Saved",255
msg_game_line:	defm CC_INK,7,CC_AT,16,25,"Lines",255
msg_game_ghost:	defm CC_INK,7,CC_AT,16,3,"Ghost",255

msg_game_ghost_active:	defm CC_INK,4,CC_AT,18,2," Active ",255
msg_game_ghost_inactive:	defm CC_INK,2,CC_AT,18,2,"Inactive",255

msg_game_level1:	defm CC_INK,7,CC_AT,1,8,"1 - Nice and Easy",255
msg_game_level2:	defm CC_INK,7,CC_AT,1,9,"2 - Spice it up ",255
msg_game_level3:	defm CC_INK,7,CC_AT,1,10,"3 - G'day Mate",255
msg_game_level4:	defm CC_INK,7,CC_AT,1,8,"4 - Shooting Star",255
msg_game_level5:	defm CC_INK,7,CC_AT,1,10,"5 - More Stars",255
msg_game_level6:	defm CC_INK,7,CC_AT,1,11,"6 - Letter F",255
msg_game_level7:	defm CC_INK,7,CC_AT,1,12,"7 - Mirror",255
msg_game_level8:	defm CC_INK,7,CC_AT,1,8,"8 - Sliding Floor",255
msg_game_level9:	defm CC_INK,7,CC_AT,1,10,"9 - Mix it up",255
msg_game_level10:	defm CC_INK,7,CC_AT,1,9,"10 - Rising Fall",255

; date for the main falling blocks logo on the main menu page. 254 means end of line, 255 means end of data

fallingblockslogo  
defb 0,0,67,67,67,0,254
defb 0,0,67,0,0,0,0,7,0,0,7,0,0,0,7,0,0,0,7,7,7,0,7,7,0,0,0,7,7,254
defb 0,0,0 ,0,0,0,7,0,3,0,5,0,0,0,7,0,0,0,0,7,0,0,7,0,5,0,7,0,0,254
defb 0,0,7 ,7,0,0,7,3,3,0,5,0,0,0,7,0,0,0,0,7,0,0,7,0,5,0,7,0,2,254
defb 0,0,7 ,0,0,0,7,0,3,0,5,0,0,0,7,0,0,0,0,7,0,0,7,0,5,0,7,0,2,254
defb 0,0,7 ,0,0,0,7,0,7,0,5,7,7,0,7,7,7,0,7,7,7,0,7,0,5,0,0,2,2,254
defb 254
defb 0,0,0,0,7,7,0,0,7,0,0,0,0,7,0,0,0,7,7,0,7,0,7,0,0,7,7,254
defb 0,0,0,0,7,0,7,0,7,0,0,0,7,0,7,0,7,0,0,0,3,0,7,0,7,0,0,254
defb 0,0,0,0,67,7,0,0,7,0,0,0,7,0,7,0,7,0,0,0,3,3,0,0,0,7,0,254
defb 0,0,0,0,67,0,7,0,2,0,0,0,7,0,7,0,7,0,0,0,3,0,7,0,0,0,7,254
defb 0,0,0,0,67,67,0,0,2,2,2,0,0,7,0,0,0,7,7,0,7,0,7,0,7,7,0,254
defb 255

gameoverlogo
defb 254,254,254	;skip a few lines
defb 0,0,0,0,0,0,0,0,7,7,0,0,7,0,0,7,0,0,0,7,0,7,7,7,254
defb 0,0,0,0,0,0,0,7,0,0,0,7,0,7,0,7,7,0,7,7,0,7,0,0,254
defb 0,0,0,0,0,0,0,7,0,7,0,7,7,7,0,7,0,7,0,7,0,7,7,0,254
defb 0,0,0,0,0,0,0,7,0,7,0,7,0,7,0,7,0,0,0,7,0,7,0,0,254
defb 0,0,0,0,0,0,0,0,7,7,0,7,0,7,0,7,0,0,0,7,0,7,7,7,254
defb 254
defb 0,0,0,0,0,0,0,0,0,7,0,0,7,0,7,0,7,7,7,0,7,7,0,254
defb 0,0,0,0,0,0,0,0,7,0,7,0,7,0,7,0,7,0,0,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,7,0,7,0,7,0,7,0,7,7,0,0,7,7,0,254
defb 0,0,0,0,0,0,0,0,7,0,7,0,0,7,0,0,7,0,0,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,7,0,0,0,7,0,0,7,7,7,0,7,0,7,254
defb 255

youwinlogo
defb 254,254,254
defb 0,0,0,0,0,0,0,0,0,0,7,0,7,0,0,7,0,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,0,7,0,7,0,7,0,7,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,0,0,7,0,0,7,0,7,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,0,0,7,0,0,7,0,7,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,7,0,0,0,7,0,254
defb 254
defb 0,0,0,0,0,0,0,0,0,7,0,0,0,7,0,7,7,7,0,7,7,0,254
defb 0,0,0,0,0,0,0,0,0,7,0,0,0,7,0,0,7,0,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,7,0,7,0,7,0,0,7,0,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,7,7,0,7,7,0,0,7,0,0,7,0,7,254
defb 0,0,0,0,0,0,0,0,0,7,0,0,0,7,0,7,7,7,0,7,0,7,254
defb 255

START
    ; Set up the graphics.

	ld de,(23675)	; address of user-defined graphics data.
	ld hl, graphics
	ld bc,80
	ldir

BEGIN
	xor a             ; black ink (0) on black paper (0*8).
	ld (23693),a        ; set our screen colours.
	call 3503           ; clear the screen.	
	; We also want to change the border colour
	xor a              ; 0 is the code for black.
	call 8859           ; set border colour.

	;open the upper screen for printing (channel 2)
	ld a,2
	call 5633
		
	; before we start the main menu we need to see if a kempston joystick is 
	; actually there. Otherwise you can have a situation where the user enables
	; kempston support but they don't actually have one and strange things happen
	; during the game :) This is due to floating bus values
	halt
	in a,(31) ;read kempston joystick port directly after HALT
	and 31

	ld b,a	; backup value of a in register b for later usage
	and 3
	cp 3	; this is equal to both left and right being active at same time, obviously should not happen with real joystick
	jr z, nojoy
	ld a,b	; get back that value we saved earlier
	and 12
	cp 12	; 12 (8+4) is both up and down, again should not be possible
	jr z, nojoy
	jr mainmenu	; all good, go to main menu
nojoy
	ld a,2
	ld (kemsptonactivated),a	; set value to not available


mainmenu

	ld hl,fallingblockslogo
	call printwordswithblocks
	
	ld hl,msg_menu_copyright
	call print_message

	ld hl,msg_menu_startgame
	call print_message
	ld hl,msg_menu_definekeys
	call print_message
	ld hl, msg_menu_kempston
	call print_message
	
	ld hl,msg_menu_difficulty
	call print_message
	
	ld a,(difficulty)
	cp 0
	jr nz,mm12	; 0 is normal difficulty
	
	ld hl,msg_menu_difficulty_normal
	call print_message
	jr mm11

mm12	
	ld hl,msg_menu_difficulty_hard
	call print_message
	
mm11	
	ld a,(kemsptonactivated)
	cp 0
	jr z,mm6
	cp 2
	jr z, mm9
	ld hl, msg_menu_kempston_on
	call print_message
	jp mm1
mm6	
	ld hl, msg_menu_kempston_off
	call print_message
	jr mm1
mm9
	; kempston is not available
	ld hl, msg_menu_kempston_na
	call print_message	
	
mm1
	;IN 63486 reads the half row 1 to 5
	ld bc,63486
	in a,(c)
	bit 0,a
	jr nz,mm2

	jr mm5	;1 key pressed, start game
mm2
	bit 1,a
	jr nz,mm3
	call do_the_redefine
	jp BEGIN
mm3
	bit 2,a
	jr nz,mm7
	ld a,(kemsptonactivated)
	cp 0
	jr z,mm8
	cp 2
	jr z,mm10
	; if here then currently support enabled, so disable
	xor a
	ld (kemsptonactivated),a
	ld hl, msg_menu_kempston_off
	call print_message
	call mediumdelay
	jp mm13
mm8	
	; if here then currently support disabled, so enable
	ld a,1
	ld (kemsptonactivated),a
	ld hl, msg_menu_kempston_on
	call print_message
	call mediumdelay
	jr mm13
mm10
	; if we are set to n/a for kempston we ignore '3' keypresses
	jr mm13
	
mm7	
	bit 3,a		; check for keypress of number 4
	jr nz,mm13
	
	ld a,(difficulty)
	cp 0
	jr nz,mm14
	
	; difficulty is currently 0 (normal), set to 1
	ld a,1
	ld (difficulty),a
	ld hl,msg_menu_difficulty_hard
	call print_message
	call mediumdelay
	jr mm13	
mm14
	; difficulty is currently 1 (hard), set to 0
	xor a
	ld (difficulty),a
	ld hl,msg_menu_difficulty_normal
	call print_message
	call mediumdelay
	jr mm13		

mm13	
	jr mm1
mm5
	call 3503

maingame
	
	;seed our random number generator

	ld a,(23672)
	and 63
	ld b,a
seedgen
	push bc	; have to push bc to stack as rnd changes value
	call rnd
	pop bc
	djnz seedgen
	
	; Need to reset the score
	ld hl,score
	ld (hl),'0'
	inc hl
	ld (hl),'0'
	inc hl
	ld (hl),'0'
	inc hl
	ld (hl),'0'
	inc hl
	ld (hl),'0'
	inc hl
	ld (hl),'0'	
	
	; ghost is set to off
	xor a
	ld (ghostactive),a
	
	; set the current level to 1 (starting)
	ld a,1
	ld (currentlevel),a
	
	; reset the saved shape to 0 (long bar)
	xor a
	ld (savedshape),a
	
	; lets draw the screen
	call newlevel


	; main game loop
L7

	;check key pressed
	call get_keys
	;The bits in A after checking keys are as follows:  A = mlracdgs
	
main1	
	cp 0
	jr z,nokeypressed
	jr main2
nokeypressed	
	; we set no key pressed here unless joystick mode is active (which will be dealt with below)
	push af
	ld a,(kemsptonactivated)
	cp 1
	jr z,main9
	xor a
	ld (lastkeypressed),a
main9	
	pop af
main2	 
	;check key for right pressed
	bit 5,a
	jr z,l1
	; move right if valid move
	push af
	ld a,(lastkeypressed)
	cp 4
	jr z,main5	
	call moveright
	ld a,4
	ld (lastkeypressed),a	
	call smalldelay
	pop af
	jr l1
main5
	; if last key was right, we do not move right, but we change last key to 8
	; effectively this means that right move can be made on next call, so we have
	; key repeat but at a slower rate
	ld a,8
	ld (lastkeypressed),a	
	call smalldelay
	pop af
l1
	bit 6,a
	jr z,l2
	; move left if valid move
	push af
	ld a,(lastkeypressed)
	cp 3
	jr z,main6	
	call moveleft
	ld a,3
	ld (lastkeypressed),a	
	call smalldelay
	pop af
	jr l2
main6
	ld a,6
	ld (lastkeypressed),a	
	call smalldelay
	pop af
l2
	bit 0,a
	jr z,l3
	; swap shape if valid move
	push af
	call swapshape
	call smalldelay	
	pop af
l3
	bit 1,a
	jr z,l4
	push af
	ld a,(lastkeypressed)
	cp 5
	jr z,main7	
	call changeghostsetting
	ld a,5
	ld (lastkeypressed),a	
	call smalldelay	
	pop af
	jr l4
main7
	pop af
l4
	bit 3,a	
	jr z,l5
	push af
	ld a,(lastkeypressed)
	cp 1
	jr z, main4	; if the last key pressed was moving clockwise then we don't turn clockwise again
	call moveclockwise
	ld a,1
	ld (lastkeypressed),a
	call smalldelay
	pop af
	jr l5
main4
	pop af
l5
	bit 4,a	
	jr z,l6
	push af
	ld a,(lastkeypressed)
	cp 2
	jr z,main3
	call moveanticlockwise
	ld a,2
	ld (lastkeypressed),a
	call smalldelay
	pop af
	jr l6
main3
	pop af
l6	
	bit 2,a
	jr z,main10
	push af
	ld a,(lastkeypressed)
	cp 7
	jr z,main8
	call droppiece
	ld a,7
	ld (lastkeypressed),a
	call smalldelay	
	pop af
	jr main10
main8
	pop af

main10
	bit 7,a
	jr z,joycon
	push af
	ld a,(lastkeypressed)
	cp 9
	jr z,main11
	call switchmusiconoff
	ld a,9
	ld (lastkeypressed),a
	call smalldelay
	pop af
	jr joycon
main11
	pop af

	
	; in addition to key support, we also support Kempston joystick. On zxspin the emulator uses
	; the cursor keys with CTRL (for fire)
joycon 
	ld a,(kemsptonactivated)
	cp 2	; if 2 (n/a) or 0 (deactivated) then skip
	jp z,l9	; if user has not activated kempston support then we skip this section
	or 0
	jp z,l9
	
	ld bc,31
	in a,(c)
	and 31	; bitmask 5 bits
	or 0
	jr nz, jc10
	xor a
	ld (lastkeypressed),a

jc10	
	ld bc,31            ; Kempston joystick port.
	in a,(c)            ; read input.
	and 2               ; check "left" bit.
	jr nz,jc1    		; move left.
	jr jc2
jc1
	ld a,(lastkeypressed)
	cp 3
	jr z,jc11
	call moveleft
	ld a,3
	ld (lastkeypressed),a	
	call smalldelay
	jr jc2
jc11
	ld a,6
	ld (lastkeypressed),a
	call smalldelay
jc2	
	ld bc,31
	in a,(c)            ; read input.
	and 1               ; test "right" bit.
	jr nz,jc3 		  ; move right.
	jr jc4
jc3
	ld a,(lastkeypressed)
	cp 4
	jr z,jc12
	call moveright
	ld a,4
	ld (lastkeypressed),a	
	call smalldelay
	jr jc4
jc12	
	ld a,8
	ld (lastkeypressed),a
	call smalldelay
jc4	
	ld bc,31
	in a,(c)            ; read input.
	and 8               ; check "up" bit.
	jr nz,jc5  			; move up.
	jr jc6
jc5
	ld a,(lastkeypressed)
	cp 1
	jr z,jc6
	call moveclockwise
	ld a,1
	ld (lastkeypressed),a
	call smalldelay
jc6	
	ld bc,31
	in a,(c)            ; read input.
	and 4               ; check "down" bit.
	jr nz,jc7
	jr jc8
jc7
	ld a,(lastkeypressed)
	cp 2
	jr z,jc8
	call moveanticlockwise
	ld a,2
	ld (lastkeypressed),a	
	call smalldelay
jc8	
	ld bc,31
	in a,(c)            ; read input.
	and 16              ; try the fire bit.
	jr nz,jc9	   ; fire pressed.
	jr l9
jc9
	ld a,(lastkeypressed)
	cp 7
	jr z,l9
	call droppiece
	ld a,7
	ld (lastkeypressed),a	
	call smalldelay
	
l9   
	ld a,(difficulty)
	cp 0
	jr nz,l14

	ld hl,pretim        ; previous time setting
	ld a,(23672)        ; current timer setting.
	sub (hl)            ; difference between the two.
	cp 45                ; have 45 frames elapsed yet?
	jr nc,l13
	jr l15
l14	
	; difficulty hard
	ld hl,pretim        ; previous time setting
	ld a,(23672)        ; current timer setting.
	sub (hl)            ; difference between the two.
	cp 15                ; have 15 frames elapsed yet?
	jr nc,l13
	jr l15	
	
l15	
	jp L7		;not time to drop piece yet, continue main loop
	
l13
	ld hl,pretim
	ld a,(23672) 
	ld (hl),a 
	
	call autodroppiece
	
	call checklevelcomplete
	
	jp L7

; random number generator
rnd:
	ld   hl,randomtable
rndidx:
	ld   bc,0       ; i
	add  hl,bc
	ld   a,c
	inc  a
	and  7
	ld   (rndidx+1),a  ; i = ( i + 1 ) & 7
	ld   c,(hl)     ; y = q[i]
	ex   de,hl
	ld   h,c        ; t = 256 * y
	ld   l,b
	sbc  hl,bc      ; t = 255 * y
	sbc  hl,bc      ; t = 254 * y
	sbc  hl,bc      ; t = 253 * y
car:
	ld   c,0        ; c
	add  hl,bc      ; t = 253 * y + c
	ld   a,h        ; c = t / 256
	ld   (car+1),a
	ld   a,l        ; x = t % 256
	cpl             ; x = (b-1) - x = -x - 1 = ~x + 1 - 1 = ~x
	ld   (de),a
	ret


drawblock
	ld a,22
	rst 16
	ld a,(tmpx)
	rst 16
	ld a,(tmpy)
	rst 16
	ld a,(blockcolour)                                     
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16              ; draw player.
	ret



;erases the current shape. Same as showcurrentshape except
;colour is hardcoded to 0 (black). So, this redraws over the current
; shape in black, erasing it
erasecurrentshape
	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	ld (tmpy),a
	xor a
	ld (drawcolour),a
	
	jp showshape

	
; shows the current shape
showcurrentshape
	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	ld (tmpy),a
	ld a,(blockcolour)
	ld (drawcolour),a
	
	jp showshape

; this draws the ghost shape. It only draws if ghost is active
; and if calculateghostposition determines it is possible/safe to draw
showghostshape
	ld a,(ghostactive)
	or a
	ret z	; if equal to 0 (ghost not active) then return
	
sgs1	
	call calculateghostposition
	; now determine if possible to show ghost
	ld a,(ghostshowing)
	or a
	ret z	; return if not possible to show ghost
	ld a,(ghostx)
	ld (tmpx),a
	ld a,(ghosty)
	ld (tmpy),a
	ld a,(ghostcolour)
	ld (drawcolour),a
	
	jp showshape
	
; this erases the ghost shape. It checks ghostshowing and if set to 1
; it erases it. Does not bother checking ghostactive as that is only relevant
; when drawing the ghost

eraseghostshape
	ld a,(ghostshowing)
	or a
	ret z	; return ias ghost not currently showing
	
	ld a,(ghostx)
	ld (tmpx),a
	ld a,(ghosty)
	ld (tmpy),a
	xor a
	ld (drawcolour),a
	
	xor a
	ld (ghostshowing),a		; we set to not showing as should only be set by calculateghostposition
	
	jp showshape	

	
; showshape draws a shape on screen, it is passed a tmpx and tmpy
; The colour used is passed in as drawcolour
; It draws the shape pointed to in blockshapes

showshape	
	
	ld a,(tmpx)	; instead of referring to tmpx and tmpy through this routine, we copy the values to d and e registers and use those
	ld d,a
	ld a,(tmpy)
	ld e,a

	ld a,(blockshapes)
	
	bit 7,a
	jp z, ss1
	ld b,d
	ld a,(tmpy)
	ld c,a
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss1	
	inc e
	ld a,(blockshapes)
	bit 6,a
	jp z, ss2
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss2
	inc e
	ld a,(blockshapes)
	bit 5,a
	jp z, ss3
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss3
	inc e
	ld a,(blockshapes)
	bit 4,a
	jp z, ss4
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss4
	inc d
	ld a,(blockshapes)
	bit 0,a
	jp z, ss5
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss5
	dec e
	ld a,(blockshapes)
	bit 1,a
	jp z, ss6
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss6
	dec e
	ld a,(blockshapes)
	bit 2,a
	jp z, ss7
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss7
	dec e
	ld a,(blockshapes)
	bit 3,a
	jp z, ss8
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss8
	inc d
	ld a,(blockshapes+1)
	bit 7,a
	jp z, ss9
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss9	
	inc e
	ld a,(blockshapes+1)
	bit 6,a
	jp z, ss10
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss10
	inc e
	ld a,(blockshapes+1)
	bit 5,a
	jp z, ss11
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss11
	inc e
	ld a,(blockshapes+1)
	bit 4,a
	jp z, ss12
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss12
	inc d
	ld a,(blockshapes+1)
	bit 0,a
	jp z, ss13
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss13
	dec e
	ld a,(blockshapes+1)
	bit 1,a
	jp z, ss14
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss14
	dec e
	ld a,(blockshapes+1)
	bit 2,a
	
	jp z, ss15
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss15
	dec e
	ld a,(blockshapes+1)
	bit 3,a
	jp z, ss16
	ld b,d
	ld c,e
	call atadd
	ld a,(drawcolour)
	ld (hl),a
ss16
	ret

; moves the block right if allowed. First deletes the shape and
; then checks the new location
moveright
	call eraseghostshape	; always try to erase ghost, if not showing this call will not do anything
	call erasecurrentshape		

	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	inc a	; we are trying to move right
	ld (tmpy),a

	call checkmove
	ld a,(allowedmove)
	or 0
	jr z,mr1
	ld a,(ply)	; move is valid so increment y
	inc a
	ld (ply),a	


mr1	
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	call showghostshape

	ret

; moves the block left if allowed. First deletes the shape and
; then checks the new location
moveleft
	call eraseghostshape	; always try to erase ghost, if not showing this call will not do anything
	call erasecurrentshape		

	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	dec a	; we are trying to move left
	ld (tmpy),a

	call checkmove
	ld a,(allowedmove)
	or 0
	jr z,ml1
	ld a,(ply)	; move is valid so decrement y
	dec a
	ld (ply),a	


ml1		
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	call showghostshape
	
	ret
	
; drop the piece till it cannot go any further
; this is a loop, the exit being when no more moves are available, when dp1 is 
; called which exits
droppiece
	call eraseghostshape	; always try to erase ghost, if not showing this call will not do anything
	call erasecurrentshape		

	ld a,(upsidedown)
	cp 1
	jr z,dp4
	
	ld a,(plx)
	inc a		; we are trying to move down
	ld (tmpx),a
	jr dp5

dp4
	ld a,(plx)
	dec a		; we are trying to move up (as upside down)
	ld (tmpx),a	
dp5	
	ld a,(ply)
	ld (tmpy),a
	
	call checkmove
	ld a,(allowedmove)
	or 0
	jr z,dp1
	
	ld a,(upsidedown)
	cp 1
	jr z,dp6
	
	ld a,(plx)	; move is valid so increment x
	inc a
	ld (plx),a
	jr dp7
dp6
	ld a,(plx)	; move is valid so decrement x (as upside down)
	dec a
	ld (plx),a	
	
dp7	
	call dp2
	;delay loop to make the drop seem less sudden, but still a very fast drop
	ld hl, 500
dp3
	dec hl
	ld a,h
	or l
	jr nz,dp3	
	
	; we get bonus points for dropping, 5 points per square dropped
	ld hl,score+5       ; point to ones column.
	ld b,5              ; 5 ones = 5.
	call uscor          ; up the score.
	call printscore		;print this new score
	   
	jp droppiece

dp1
	call dp2
	ret		; so, if can't make any more moves then we call dp2 and then return


dp2
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)	
	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	
	ret
	
; this is where we calculate the ghost x and y position
; we do this by first offsetting till no collision (against the actual current shape)
; then dropping down till we hit the top of the already placed pieces
calculateghostposition

	; copy the player x and y to the tmp x and y
	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	ld (tmpy),a
	
	
	ld hl, ghostlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)	; this now gives us the offset in the ghost offset table
	ld (ghostpointer),a

	ld hl,ghostoffset
	ld de,(ghostpointer)
	ld d,0
	add hl,de
	
	ld de,(currentorientation)
	ld d,0
	add hl,de
	
	ld a,(hl)	; a now holds the number of blocks to skip
	ld d,a	; save value to d
	
	ld a,(upsidedown)
	cp 1
	jr z,cgp5
	
	ld a,(tmpx)
	add a,d	
	ld (tmpx),a
	cp 22
	jp nc,cgp2	; if a greater or equal to 22 we exit
	jr cgp1

cgp5
	ld a,(tmpx)
	sub d
	ld (tmpx),a
	cp 0
	jp c,cgp2
	
	
cgp1
	; we have gone the minimum distance required by the ghost offset
	; we check if there is an immediate collision, if there is, we exit	
	
	call checkmove
	ld a,(allowedmove)
	or 0
	jp nz,cgp3	; if no collision then determine ghost location
			
	
cgp2
	; if in here this not possible to determine ghost x and y, set the ghostshowing to 0
	xor a
	ld (ghostshowing),a
	ret

cgp3
	; if here then found empty space, now keep dropping, this will be where the ghost shape will be shown
	ld a,(upsidedown)
	cp 1
	jr z,cgp6
	
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	jr cgp7
cgp6
	ld a,(tmpx)
	dec a	; as we are upside down
	ld (tmpx),a
	
cgp7	
	call checkmove
	ld a,(allowedmove)
	or 0
	jp nz,cgp3
	
cgp4
	; if we are here then have found the top of the place pieces, allocate ghost x and y
	ld a,(upsidedown)
	cp 1
	jr z,cgp8
	
	ld a,(tmpx)
	dec a	; we decrement one as we had gone one too far with previous loop
	ld (ghostx),a
	jr cgp9
cgp8
	ld a,(tmpx)
	inc a	; we increment one as we had gone one too far with previous loop
	ld (ghostx),a	
	
cgp9	
	ld a,(tmpy)
	ld (ghosty),a
	
	ld a,1
	ld (ghostshowing),a
			
	ret	

; this swaps the ghost setting from active to inactive (and vice versa)

changeghostsetting
	ld a,(ghostactive)
	or 0
	jr nz, cgs1
	
	; ghost is currently off, switch it on
	ld a,1
	ld (ghostactive),a
	
	ld hl,msg_game_ghost_active
	call print_message
	
	ret
		
cgs1
	; ghost is currently on, switch it off
	xor a
	ld (ghostactive),a
	
	ld hl,msg_game_ghost_inactive
	call print_message	
		
	ret
	
	
; This handles the swap piece functionality. A player is allowed swap once till a new shape is selected automatically
; by the drop process. We swap the current piece with the saved shape

swapshape
	ld a,(allowedswap)
	or 0
	jr nz, ssh1
	ret		;not allowed swap
	
ssh1	
	xor a
	ld (allowedswap),a	; stop any more swapping of this shape

	call eraseghostshape	; always try to erase ghost, if not showing this call will not do anything
	; erase our current shape
	call erasecurrentshape		
		
	ld a,(savedshape)
	push af		; save the shape to the stack
	
	ld a,(currentshape)
	ld (savedshape),a	
	
	call drawsavedshape
	
	pop af	; get the saved shape from the stack
	ld (currentshape),a	; now we have swapped shapes
	
	ld a,(startx)		; swapped piece starts from the top of the screen
	ld (plx),a
	ld a,(starty)
	ld (ply),a
	
	; if we are upside down we need to update the x position
	ld a,(upsidedown)
	cp 1
	jr z,ssh3
	jr ssh4
ssh3
	ld a,(upsidedownstartx)
	ld (plx),a
	
ssh4	
	; now we work out the colour for this shape
	
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockcolour),a	; now draw block in new position
	
	; need to transfer new shape position to tmpx and tmpy for checkmove to correctly work
	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	ld (tmpy),a
	
	; player has swapped, but maybe the piece will not fit at the top of the screen (and thus game over)
	call checkmove
	ld a,(allowedmove)
	or 0
	jr nz,ssh2	
	; move is not valid so its end game
	pop af	; this is popping to ensure stack is back to correct status. This pop is to match the push that is done in the main loop
	jp gameover
	
ssh2
	; ok, so we can draw the shape ok
	call setblockshapes
	call showcurrentshape
	call showghostshape
	
	ret
	
; This drops the piece down by one square if possible, if not possible then it starts a new piece	
autodroppiece	
	call eraseghostshape	; always try to erase ghost, if not showing this call will not do anything
	call erasecurrentshape		

	ld a,(upsidedown)
	cp 1
	jr z, adp3
	ld a,(plx)	
	inc a		; we are trying to move down
	ld (tmpx),a
	jr adp4
	
adp3
	; this is the section called if upside down
	ld a,(plx)	
	dec a		; we are trying to move up (as we are upside down)
	ld (tmpx),a
adp4	
	ld a,(ply)
	ld (tmpy),a

	call checkmove
	ld a,(allowedmove)
	or 0
	jr z,adp1
	
	ld a,(upsidedown)
	cp 1
	jr z,adp5
	
	ld a,(plx)	; move is valid so increment x
	inc a
	ld (plx),a	
	jr adp2
	
adp5
	ld a,(plx)	; move is valid so decrement x (as upside down)
	dec a
	ld (plx),a	
	jr adp2	
	

adp1	
	; if we are here then it was not possible to drop the block, choose a new block
	; first we redraw back the piece then choose our new one
	; we also add to the score
	; Add 50 to the score.

	ld hl,score+4       ; point to tens column.
	ld b,5              ; 5 tens = 50.
	call uscor          ; up the score.
	call printscore		;print this new score
	   
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	
	call checkplayarea	; now see if a winning line (or lines) exists
	
	call selectnewpiece
	
adp2
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)

	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	call showghostshape
	;call autodropnoise
	
	ret	



; Routine to pick a new block. Holds this in next shape and makes currentshape the old value of nextshape
; levels 2,5,7 amd 9 have extra shapes added
selectnewpiece
	ld a,(nextshape)
	push af		; save the nextshape to the stack, this will become currentshape
	
	ld a,(currentlevel)
	cp 2
	jr z,snp2
	cp 5
	jr z,snp2
	cp 7
	jr z,snp2
	cp 9
	jr z,snp2
	; if get to here then using the standard set

	;this picks the random numbers when just using standard set
snp1	
	call rnd
	and 7	;bitmask bits 0, 1 and 2 
	cp 7
	jp nc, snp1
	jr snp3		
	; this picks the random numbers when using the extended set
snp2	
	call rnd
	and 15	;bitmask bits 0, 1, 2 and 3 (7 for standard set)
	cp 12	; change to 7 for standard set
	jp nc, snp2
		
snp3	

	ld (nextshape),a
	
	call drawnextshape
	
	pop af
	ld (currentshape),a		; now retrieve from the stack
	
	ld a,(startx)
	ld (plx),a
	ld a,(starty)
	ld (ply),a
	
	; if upside down we need to update the starting x position
	ld a,(upsidedown)
	cp 1
	jr z,snp5
	jr snp6
snp5	
	ld a,(upsidedownstartx)
	ld (plx),a
	
snp6	
	; reset allowed swap
	ld a,1
	ld (allowedswap),a
			
	; reset last key pressed (if the last key pressed was not 'drop')
	ld a,(lastkeypressed)
	cp 7		;7 is drop
	jr z,snp7
	xor a
	ld (lastkeypressed),a
	
snp7	
	; now check if end game
	
	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	ld (tmpy),a
	call checkmove
	ld a,(allowedmove)
	or 0
	jr nz,snp4	
	; move is not valid so its end game
	jp gameover
	
snp4	
	xor a
	ld (currentorientation),a
	call setblockshapes
	
	ld hl,piecesthislevel
	inc (hl)

	jp 	levelspecialaction; this does the special action required per level (may not do anything)

; Moves the block anti clockwise if allowed

moveanticlockwise
	call eraseghostshape	; always try to erase ghost, if not showing this call will not do anything
	call erasecurrentshape		

	ld a,(currentorientation)
	inc a
	cp 4	;if 4 then need to set to 0
	jr nz, mac1
	xor a
mac1
	ld (currentorientation),a

	call setblockshapes
	
	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	ld (tmpy),a


	call checkmove
	ld a,(allowedmove)
	or 0
	jr nz,mac6	
	; move is not valid so need to reset blockpointer and blockshapes
	ld a,(currentorientation)
	or 0
	jr nz, mac5
	ld a,4	; we set to be 4 as we will decrememt by 1 giving us correct value 3
mac5
	dec a
	ld (currentorientation),a	;currentorientation not reset to previous value
	
	call setblockshapes


mac6
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	call showghostshape
	
	ret
	
; Moves the block clockwise if allowed

moveclockwise
	call eraseghostshape	; always try to erase ghost, if not showing this call will not do anything
	call erasecurrentshape		

	ld a,(currentorientation)
	or 0
	jr nz,mcw1
	ld a,4	; we set to be 4 as we will decrememt by 1 giving us correct value 3

mcw1
	dec a
	ld (currentorientation),a

	call setblockshapes
	
	ld a,(plx)
	ld (tmpx),a
	ld a,(ply)
	ld (tmpy),a


	call checkmove
	ld a,(allowedmove)
	or 0
	jr nz,mcw3	; move is valid	
	; move is not valid so need to reset blockpointer and blockshapes
	ld a,(currentorientation)
	inc a
	cp 4
	jr nz, mcw2
	xor a	; we set to be 4 as we will decrememt by 1 giving us correct value 3
mcw2
	ld (currentorientation),a	;currentorientation not reset to previous value
	
	call setblockshapes


mcw3
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	call showghostshape
	
	ret


;setblockshapes uses the currentorientation and currentshape to set the
; value of blockshapes i.e. the exact block to draw
setblockshapes
	xor a				;reset a to 0
	ld (blockpointer),a

	ld a,(currentshape)
	or 0
	jr z, sbs1
	
	; each shape is 8 bytes so have to increase by eight for each shape
	ld hl, blocklookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockpointer),a
	
sbs1
	ld a,(currentorientation)
	or 0
	jr z, sbs2
	ld b,a
sbsloop1
	ld a,(blockpointer)
	inc a
	inc a
	ld (blockpointer),a
	djnz sbsloop1
	
sbs2
	ld hl, shapedata
	ld de,(blockpointer)
	ld d,0	;blockpointer is always a 8 bit value
	add hl,de
	ld a,(hl)
	ld (blockshapes),a
	inc hl
	ld a,(hl)
	ld (blockshapes+1),a

	ret
	
;this draws the next piece that will be played in the right hand side
; we temporarily set the current piece to be this	
drawnextshape
	call erasenextshape

	ld a,(nextblockx)
	ld (tmpx),a
	ld a,(nextblocky)
	ld (tmpy),a
	xor a
	ld (currentorientation),a
	ld a,(nextshape)
	ld (currentshape),a
	
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (drawcolour),a
	
	call setblockshapes
	call showshape
	ret
	
; This erases the next shape area. There are three lines here to cope with all shapes
; in orientation 0
	
erasenextshape
	ld a,(nextblockx)
	ld (tmpx),a
	ld a,(nextblocky)
	ld (tmpy),a

	ld b,4
ens1
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),0
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz ens1

	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(nextblocky)
	ld (tmpy),a

	ld b,4
ens2
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),0
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz ens2
	
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(nextblocky)
	ld (tmpy),a

	ld b,4
ens3
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),0
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz ens3	

	ret
	
; This is the initial setup of the next shape area. 3 lines to handle
; all shapes in orientation 0

setupnextshape
	xor a
	ld (blockcolour),a
	ld a,(nextblockx)
	ld (tmpx),a
	ld a,(nextblocky)
	ld (tmpy),a

	ld b,4
sns1
	push bc
	call drawblock
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz sns1

	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(nextblocky)
	ld (tmpy),a

	ld b,4
sns2
	push bc
	call drawblock
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz sns2
	
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(nextblocky)
	ld (tmpy),a

	ld b,4
sns3
	push bc
	call drawblock
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz sns3	

	ret
	

; This erases the saved shape area
	
erasesavedshape
	ld a,(savedblockx)
	ld (tmpx),a
	ld a,(savedblocky)
	ld (tmpy),a

	ld b,4
ess1
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),0
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz ess1

	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(savedblocky)
	ld (tmpy),a

	ld b,4
ess2
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),0
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz ess2
	
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(savedblocky)
	ld (tmpy),a

	ld b,4
ess3
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),0
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz ess3	

	ret	
	
; This is the initial setup of the saved shape area

setupsavedshape
	xor a
	ld (blockcolour),a
	ld a,(savedblockx)
	ld (tmpx),a
	ld a,(savedblocky)
	ld (tmpy),a

	ld b,4
sss1
	push bc
	call drawblock
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz sss1

	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(savedblocky)
	ld (tmpy),a

	ld b,4
sss2
	push bc
	call drawblock
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz sss2
	
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(savedblocky)
	ld (tmpy),a

	ld b,4
sss3
	push bc
	call drawblock
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz sss3	

	ret	
	
;this draws the saved piece that on the left hand side
; we temporarily set the current piece to be this	
drawsavedshape
	call erasesavedshape

	ld a,(savedblockx)
	ld (tmpx),a
	ld a,(savedblocky)
	ld (tmpy),a
	xor a
	ld (currentorientation),a
	ld a,(savedshape)
	ld (currentshape),a
	
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (drawcolour),a
	
	call setblockshapes
	call showshape
	ret	
	
	
; this routine is used to erase the top line of the play area. We need this code
; as when we move everything down a line after a winning line, we need to clear the top line

erasetopline
	ld a,(upsidedown)
	cp 1
	jp z,etl2
	ld a,(playareatoplinex)
	ld (tmpx),a
	jp eraseline
etl2
	ld a,(upsidedownplayareatoplinex)	; different x if upside down
	ld (tmpx),a
	jp eraseline	

; eraseline is used for clearing the playarea at the start of every level and is used
; during process for handling winning lines. tmpx is passed in (line to erase)

eraseline
	ld a,(playareatopliney)
	ld (tmpy),a
	
	ld b,10		;10 squares in width of play area
etl1
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),0	; set the attribute at this square to be 0, black
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz etl1
	
	ret
	
; this routine detects a winning line in the playarea. It checks the line defined in tmpx
; winningline will be set to 1 in the case of a winning line, otherwise 0

checkwinningline
	xor a
	ld (winningline),a	; winningline reset to 0
	
	; tmpx is already set, but set initial y value
	ld a,(playareatopliney)
	ld (tmpy),a

	ld b,10		;10 squares in width of play area
cwl1
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	or 0 ; check if it black/black i.e. empty square
	jp z, cwl2 ;square is empty, can return with winningline set to 0, not winning line
	
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz cwl1	
	
	; if get this far then winning line
	ld a,1
	ld (winningline),a
	ret

cwl2
	; not a winning line, but need to tidy the stack, then exit
	pop bc
	ret

	
; when a winning line is detected, this is the routine that flashes the line, by setting
; the attribute of each of the squares with a flash attribute	
; The line to flash will be passed in using tmpx
flashwinningline
	; tmpx is already set, but set initial y value
	ld a,(playareatopliney)
	ld (tmpy),a

	ld b,10		;10 squares in width of play area
fwl1
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld a,(winninglinecolour)
	ld (hl),a	; set the attribute at this square to be winninglinecolour
	
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz fwl1	
	
	ret
	
; this is the routine that checks the playarea for all winning lines, adding to
; the players score, flash the lines temporarily and then deleting them and moving 
; the playarea down
checkplayarea

	xor a
	ld (rowscompleted),a
	
	ld b,20
cpa1
	push bc		; b will be modified by later calls
	ld a,b
	ld (tmpx),a
	call checkwinningline
	ld a,(winningline)
	or 0
	jr z,cpa2	; if not a winning line then skip flashwinningline call
	call flashwinningline
	ld hl,score+4       ; point to tens column.
	ld b,5              ; 5 tens = 50.
	call uscor          ; up the score.
	ld hl,score+3       ; point to hundreds column.
	ld b,2              ; 2 hundreds = 200.
	call uscor          ; up the score.	 - so score increased by 250
	call printscore		;print this new score
	ld a,(rowscompleted)
	inc a
	ld (rowscompleted),a
	cp 4	; bonus points for 4 rows together (+1000 score)
	jr nz, cpa2
	ld hl,score+2       ; point to thousands column.
	ld b,1              ; 1 thousands = 1000.
	call uscor          ; up the score.
	call printscore		;print this new score
		
cpa2	
	pop bc
	djnz cpa1

	; now update the lines completed
	
	ld hl,totalrowscompleted+1       ; point to ones column.
	ld a,(rowscompleted)
	ld b,a
	call uscor          ; up the lines count
	call printlines		;print this new lines tally
	
	ld a,(rowscompleted)
	ld b,a
	ld a,(totalrowscompletednum)
	add a,b
	ld (totalrowscompletednum),a
	
	; at this stage we have any winning lines flashing and extra score has been added
	; if any winning lines need to now remove
	ld a,(rowscompleted)
	or 0
	ret z	; if no rows completed we can exit this routine

	; if there are rows we add a short delay so the player can see the flashing lines i.e.
	; they can see their winning lines
	ld hl, 50000
cpa3
	dec hl
	ld a,h
	or l
	jr nz,cpa3
	
	ld a,(upsidedown)
	cp 1
	jr z,cpa6
	
	
	ld b,20
cpa4
	push bc		; b will be modified by later calls
	ld a,b
	ld (tmpx),a
	call checkwinningline
	ld a,(winningline)
	or 0
	jr z,cpa5	; if not a winning line then skip eraseline
	call eraseline
	call dropplayarea
	; we now need to add 1 to b to ensure we delete all winning lines
	pop bc
	inc b
	push bc

cpa5	
	pop bc
	djnz cpa4
	call clearedlinenoise
	ret
	
	
cpa6
	ld b,1
cpa7
	push bc		; b will be modified by later calls
	ld a,b
	ld (tmpx),a
	call checkwinningline
	ld a,(winningline)
	or 0
	jr z,cpa8
	call eraseline
	call upsidedowndropplayarea
	; we now need to decrement 1 from b to ensure we delete all winning lines	
	pop bc
	dec b
	push bc
cpa8
	pop bc
	inc b
	ld a,b
	cp 22
	jr z,cpa9
	jp cpa7
cpa9	
	call clearedlinenoise
	ret
	
	
; move playarea down. When we get a winning line, we remove the winning line and this routine
; drops the playarea above that line down
; we pass in tmpx which is the winning line (drop everything above this)
dropplayarea
	ld a,(playareatopliney)
	ld (tmpy),a
	
	ld a,(tmpx)
	ld b,a	
dpa1
	push bc
	ld b,10		; inner loop
dpa2
	push bc	
	
	ld a,(tmpx)
	dec a	; we drop by 1 as we are copying the line above
	ld b,a
	
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (blockcolour),a	; this now contains the colour of the square directly above
	ld a,(tmpx)
	ld b,a
	call atadd
	ld a,(blockcolour)
	ld (hl),a
	ld a,(tmpy)		; next square in the row
	inc a
	ld (tmpy),a
	pop bc
	djnz dpa2
	; finished inner loop, i.e. that row, drop x by 1 and reset y
	
	ld a,(tmpx)
	dec a
	ld (tmpx),a
	ld a,(playareatopliney)
	ld (tmpy),a
		
	pop bc
	djnz dpa1
	
	; at this stage we have dropped everything, now just need to erase the top line
	
	jp erasetopline
	
; move playarea up. When we get a winning line, we remove the winning line and this routine
; drops the playarea above that line up (as this is the routine called when upside down)
; we pass in tmpx which is the winning line (drop everything below this)
upsidedowndropplayarea
	ld a,(playareatopliney)
	ld (tmpy),a
	
	ld a,(tmpx)	
uddpa1
	ld b,10		; inner loop
uddpa2
	push bc	
	
	ld a,(tmpx)
	inc a	; we increase by 1 as we are copying the line below
	ld b,a
	
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (blockcolour),a	; this now contains the colour of the square directly above
	ld a,(tmpx)
	ld b,a
	call atadd
	ld a,(blockcolour)
	ld (hl),a
	ld a,(tmpy)		; next square in the row
	inc a
	ld (tmpy),a
	pop bc
	djnz uddpa2
	; finished inner loop, i.e. that row, increase x by 1 and reset y
	
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(playareatopliney)
	ld (tmpy),a
		
	ld a,(tmpx)
	cp 22
	jr nz, uddpa1
	
	; at this stage we have dropped everything, now just need to erase the top line
	
	jp erasetopline	
	
; setupplayarea is used to draw a block (in black so not shown) in each square of the 
; playarea
setupplayarea

	xor a
	ld (blockcolour),a
	
	ld b,21
spa1
	push bc		; b will be modified by later calls
	ld a,b
	ld (tmpx),a
	call drawlineofblocks
	pop bc
	djnz spa1
	
	xor a	; now clear the very top line
	ld (tmpx),a
	call drawlineofblocks

	ret

;drawlineofblocks draws a line of blocks
; passed in tmpx, line at which to draw
drawlineofblocks
	ld a,(playareatopliney)
	ld (tmpy),a
	
	ld b,10		;10 squares in width of play area
dlb1
	push bc
	call drawblock

	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz dlb1
	
	ret
	
;checkmove. tmpx and tmpy will be set to the desired location
;and the current shape will be removed. This checks if there are
;any existing blocks at the new location

checkmove
	ld a,1
	ld (allowedmove),a	; default is move allowed
	ld a,(tmpx)	; instead of referring to tmpx and tmpy through this routine, we copy the values to d and e registers and use those
	ld d,a
	ld a,(tmpy)
	ld e,a

	ld a,(blockshapes)
	bit 7,a
	jp z, cm1
	ld b,d
	ld c,e
	call atadd
	or 0 ; check if it black/black i.e. empty square
	jp z, cm1 ;square is empty, can move
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm1
	ld a,(blockshapes)
	bit 6,a
	jp z, cm2
	ld b,d
	ld a,e
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm2
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move	
cm2
	ld a,(blockshapes)
	bit 5,a
	jp z, cm3
	ld b,d
	ld a,e
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm3
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm3
	ld a,(blockshapes)
	bit 4,a
	jp z, cm4
	ld b,d
	ld a,e
	inc a
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm4
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm4
	ld a,(blockshapes)
	bit 3,a
	jp z, cm5
	ld a,d
	inc a	
	ld b,a
	ld c,e
	call atadd
	or 0 ; check if it black/black i.e. empty square
	jp z, cm5
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm5
	ld a,(blockshapes)
	bit 2,a
	jp z, cm6
	ld a,d
	inc a	
	ld b,a
	ld a,e
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm6
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move	
cm6
	ld a,(blockshapes)
	bit 1,a
	jp z, cm7
	ld a,d
	inc a	
	ld b,a
	ld a,e
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm7
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm7
	ld a,(blockshapes)
	bit 0,a
	jp z, cm8
	ld a,d
	inc a	
	ld b,a
	ld a,e
	inc a
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm8
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm8
	ld a,(blockshapes+1)
	bit 7,a
	jp z, cm9
	ld a,d
	inc a
	inc a	
	ld b,a
	ld c,e
	call atadd
	or 0 ; check if it black/black i.e. empty square
	jp z, cm9
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm9
	ld a,(blockshapes+1)
	bit 6,a
	jp z, cm10
	ld a,d
	inc a
	inc a	
	ld b,a
	ld a,e
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm10
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move	
cm10
	ld a,(blockshapes+1)
	bit 5,a
	jp z, cm11
	ld a,d
	inc a
	inc a	
	ld b,a
	ld a,e
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm11
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm11
	ld a,(blockshapes+1)
	bit 4,a
	jp z, cm12
	ld a,d
	inc a
	inc a	
	ld b,a
	ld a,e
	inc a
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm12
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm12
	ld a,(blockshapes+1)
	bit 3,a
	jp z, cm13
	ld a,d
	inc a
	inc a
	inc a	
	ld b,a
	ld c,e
	call atadd
	or 0 ; check if it black/black i.e. empty square
	jp z, cm13
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm13
	ld a,(blockshapes+1)
	bit 2,a
	jp z, cm14
	ld a,d
	inc a
	inc a
	inc a	
	ld b,a
	ld a,e
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm14
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move	
cm14
	ld a,(blockshapes+1)
	bit 1,a
	jp z, cm15
	ld a,d
	inc a
	inc a
	inc a	
	ld b,a
	ld a,e
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cm15
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cm15
	ld a,(blockshapes+1)
	bit 0,a
	jp z, cmend
	ld a,d
	inc a
	inc a
	inc a	
	ld b,a
	ld a,e
	inc a
	inc a
	inc a
	ld c,a
	call atadd
	or 0
	jp z, cmend
	xor a
	ld (allowedmove),a	; cannot move
	ret	; exit as cannot move
cmend
	ret


; Calculate address of attribute for character at (b, c).

atadd 	
	ld a,b              ; x position.
	rrca                ; multiply by 32.
	rrca
	rrca
	ld l,a              ; store away in l.
	and 3               ; mask bits for high byte.
	add a,88            ; 88*256=22528, start of attributes.
	ld h,a              ; high byte done.
	ld a,l              ; get x*32 again.
	and 224             ; mask low byte.
	ld l,a              ; put in l.
	ld a,c              ; get y displacement.
	add a,l             ; add to low byte.
	ld l,a              ; hl=address of attributes.
	ld a,(hl)           ; return attribute in a.
	ret

; redefine keys routine written by John Young
get_keys:		
	ld de,0			; DE will hold the bits for the keys pressed
	ld hl,key_music_port	; address of the ports/patterns
	ld b,8			; 8 keys to check
	res 0,d
	dec hl
gk_loop:		
	inc hl
	rl d
	ld a,(hl)		; get the port row
	in a,(254)		; check that row
	cpl
	and 31
	inc hl			; point to the key bit pattern
	cp (hl)			; check if that key is pressed
	jr z,gk_key_is_pressed
	;key is not pressed
	res 0,d			; indicate key not pressed
	djnz gk_loop		; go check next key
	jr gk_exit
gk_key_is_pressed:	
	set 0,d			; indicate key is pressed
	djnz gk_loop		; go check next key
	; ok, all done, maybe, I hope, ahh pffffffffffffffffft
gk_exit:		
	ld a,d			; return the bit thingy			
	ret
			

; This is where we redefine the keys			
do_the_redefine:
	call ROM_CLS		; do the clear screen	
	xor a
	ld hl,msg_define
	call print_message

	call mediumdelay

	ld hl,msg_left
	call print_message
	ld hl,key_left_port
	call get_defined_key

	ld hl,msg_right
	call print_message
	ld hl,key_right_port
	call get_defined_key

	ld hl,msg_anticlockwise
	call print_message
	ld hl,key_anticlockwise_port
	call get_defined_key

	ld hl,msg_clockwise
	call print_message
	ld hl,key_clockwise_port
	call get_defined_key

	ld hl,msg_drop
	call print_message
	ld hl,key_drop_port
	call get_defined_key
			
	ld hl,msg_ghost
	call print_message
	ld hl,key_ghost_port
	call get_defined_key

	ld hl,msg_swap
	call print_message
	ld hl,key_swap_port
	call get_defined_key	
	
	ld hl,msg_music
	call print_message
	ld hl,key_music_port
	call get_defined_key	

	; ok, keys should have been saved, (/me hopes)
	ld bc,key_music_port			; return the keys data to calling program
	ret			

; ----------------------------------------------
; ROUTINE: print_message
;
; prints a string which is terminated with $ff
; On entry, HL = address of message
print_message:
	push hl			; save the message address
	ld a,2			; upper screen
	call CHAN_OPEN		; get the channel sorted
	pop hl			; get the message address back		

pm_do_it:		
	ld a,(hl)		; get the character to print
	inc hl			; point to next character
	cp 255			; end of the string
	ret z			; so exit
	rst 16			; print the character
	jr pm_do_it		; and do it all over again
	ret	

; ----------------------------------------------
; ROUTINE: get_defined_key
;
; check for key being pressed
; On entry, HL = key_xxx_port where xxx is the direction, eg up/down/left/right/fire/pause/quit
; On exit, the key_xxx_port and key_xxx_pattern will hold the values for the key pressed
;
get_defined_key:	
	ld de,port_array	; the array of rows
	ld b,8			; number of rows to check
gdk_loop:		
	ld a,(de)		; get row
	in a,(254)		; check for keys on that row
	cpl
	and 31			; mask off the 5 bits I want
	jr z,gdk_none		; nothing pressed? ok, go to next row
	inc hl			; point to the key_xxx_pattern byte
	ld (hl),a		; save the pattern byte
	dec hl			; go back to the key_xxx_port byte
	ld a,(de)		; get the port that the key was found on
	ld (hl),a		; save it
	; ok, details for the pressed key are saved, lets gtfo here
	call delay
	ret
gdk_none:		
	inc de			; next row in array
	djnz gdk_loop		; go check next row
	; hmm, no key pressed on keyboard, sooooo do it all again
	jr get_defined_key
	ret			; not executed, but it stops me from getting confused, :)

; -----------------------------------------------
delay:			
	ld bc,32768
	xor a
d_loop:			
	dec a
	out (254),a
	dec bc
	ld a,b
	or c
	jr nz,d_loop
	ret
	
; Update score routine by Jonathan Cauldwell

uscor  
	ld a,(hl)           ; current value of digit.
	add a,b             ; add points to this digit.
	ld (hl),a           ; place new digit back in string.
	cp 58               ; more than ASCII value '9'?
	ret c               ; no - relax.
	sub 10              ; subtract 10.
	ld (hl),a           ; put new character back in string.
uscor0 
	dec hl              ; previous character in string.
	inc (hl)            ; up this by one.
	ld a,(hl)           ; what's the new value?
	cp 58               ; gone past ASCII nine?
	ret c               ; no, scoring done.
	sub 10              ; down by ten.
	ld (hl),a           ; put it back
	jp uscor0           ; go round again.
	
; Print the score
printscore
	ld a,CC_INK
	rst 16
	ld a,7
	rst 16
	ld a,CC_AT
	rst 16
	ld a,(scorex)
	rst 16
	ld a,(scorey)
	rst 16
	
	ld hl, score
	ld b,6
ps1
	ld a,(hl)		; get the character to print
	inc hl			; point to next character
	rst 16			; print the character
	djnz ps1		; and do it all over again
	ret	

; Print the high score
printhighscore
	ld a,CC_INK
	rst 16
	ld a,7
	rst 16
	ld a,CC_AT
	rst 16
	ld a,(highscorex)
	rst 16
	ld a,(highscorey)
	rst 16
	
	ld hl, highscore
	ld b,6
phs1
	ld a,(hl)		; get the character to print
	inc hl			; point to next character
	rst 16			; print the character
	djnz phs1		; and do it all over again
	ret		
	
gameover
	; first switch off in-game music
	xor a
	ld (ingame),a
	
	call ROM_CLS		; do the clear screen

	;open the upper screen for printing (channel 2)
	ld a,2
	call 5633
	
	ld hl,gameoverlogo
	call printwordswithblocks
		
	ld hl, msg_gameover_score
	call print_message
	
	ld a,CC_INK
	rst 16
	ld a,7
	rst 16
	ld a,CC_AT
	rst 16
	ld a,19
	rst 16
	ld a,12
	rst 16
	
	ld hl, score
	ld b,6
go1
	ld a,(hl)		; get the character to print
	inc hl			; point to next character
	rst 16			; print the character
	djnz go1		; and do it all over again
	
	call checkhighscore
	
	ld a,(newhighscore)
	cp 0
	jr z,go3	; if equal to 0, no new high score
	
	ld hl, msg_gameover_newhighscore
	call print_message
	
go3	
	ld b,250            ; time to pause (50 frames a sec, 5 secs wait)
go2  
	halt                ; wait for an interrupt.
	djnz go2          ; repeat.
	
	jp BEGIN
	
; screen that gets called when you win	
youwin
	; first switch off in-game music
	xor a
	ld (ingame),a

	call ROM_CLS		; do the clear screen

	;open the upper screen for printing (channel 2)
	ld a,2
	call 5633
	
	ld hl,youwinlogo
	call printwordswithblocks
		
	ld hl, msg_gameover_score
	call print_message
	
	ld a,CC_INK
	rst 16
	ld a,7
	rst 16
	ld a,CC_AT
	rst 16
	ld a,19
	rst 16
	ld a,12
	rst 16
	
	ld hl, score
	ld b,6
yw1
	ld a,(hl)		; get the character to print
	inc hl			; point to next character
	rst 16			; print the character
	djnz yw1		; and do it all over again
	
	call checkhighscore
	
	ld a,(newhighscore)
	cp 0
	jr z,yw3	; if equal to 0, no new high score
	
	ld hl, msg_gameover_newhighscore
	call print_message	
	
yw3	
	ld b,250            ; time to pause (50 frames a sec, 5 secs wait)
yw2  
	halt                ; wait for an interrupt.
	djnz yw2          ; repeat.
	
	jp BEGIN	
	
	
; small delay loop used by main loop
smalldelay
	ld hl, 5000
sd1
	dec hl
	ld a,h
	or l
	jr nz,sd1
	ret
	
; medium delay loop used by main menu loop
mediumdelay
	ld hl, 15000
md1
	dec hl
	ld a,h
	or l
	jr nz,md1
	ret	
	
; This draws words onscreen using blocks to make up the parts of the letters	
; Each byte represents a colour for the block to draw
; 254 means end of line and 255 means end of data (stop drawing)
; hl is passed in, this is the address of the start of the data to print
printwordswithblocks
	xor a
	ld (tmpx),a
	ld (tmpy),a

pbl1	
	ld a,(hl)
	cp 254
	jr z,pbl2
	cp 255
	jr z,pbl3
	ld (blockcolour),a
	call drawblock
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	inc hl
	jp pbl1
pbl2
	; end of line reached, reset y and increment x
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	xor a
	ld (tmpy),a
	inc hl
	jp pbl1
pbl3	
	; if here then end of data reached
	
	ret
	
; this updates the lines completed area
printlines

	ld a,CC_INK
	rst 16
	ld a,7
	rst 16
	ld a,CC_AT
	rst 16
	ld a,(linesx)
	rst 16
	ld a,(linesy)
	rst 16
	
	ld hl, totalrowscompleted
	ld b,2
pl1
	ld a,(hl)		; get the character to print
	inc hl			; point to next character
	rst 16			; print the character
	djnz pl1		; and do it all over again

	; now print slash divider
	
	ld a,'/'
	rst 16
	
	ld hl, targetlinesforthislevel
	ld b,2
pl2
	ld a,(hl)		; get the character to print
	inc hl			; point to next character
	rst 16			; print the character
	djnz pl2		; and do it all over again	
	
	ret
	
; this determines the target number of lines for this level
calculatelinesforthislevel

	ld hl, linesneededperlevel
	ld de,(currentlevel)
	dec de
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)

	cp 10
	jr z,cll1
	cp 25
	jr z,cll2
	
	ld hl,targetlinesforthislevel+1       ; point to ones column.
	ld b,a
	call uscor          ; up the lines count
	ret
cll1
	ld hl,targetlinesforthislevel       ; point to tens column.
	ld b,1
	call uscor          ; up the lines count
	ret
cll2
	ld hl,targetlinesforthislevel       ; point to tens column.
	ld b,2
	call uscor          ; up the lines count
	ld hl,targetlinesforthislevel+1       ; point to ones column.
	ld b,5
	call uscor          ; up the lines count	
	ret
	
; routine for printing the name of the level at the bottom of the screen	
printlevelname

	ld a,1	; open channel 1
	call 5633
	
	ld a,(currentlevel)
	cp 1
	jr z,pln1
	cp 2
	jr z,pln2
	cp 3
	jr z,pln3
	cp 4
	jr z,pln4
	cp 5
	jr z,pln5
	cp 6
	jr z,pln6
	cp 7
	jr z,pln7
	cp 8
	jr z,pln8
	cp 9
	jr z,pln9
	cp 10
	jr z,pln10
	jr pln12	; no matches found, exit	
pln1	
	ld hl, msg_game_level1
	jr pln11
pln2	
	ld hl, msg_game_level2
	jr pln11
pln3	
	ld hl, msg_game_level3
	jr pln11
pln4	
	ld hl, msg_game_level4
	jr pln11
pln5	
	ld hl, msg_game_level5
	jr pln11
pln6	
	ld hl, msg_game_level6
	jr pln11
pln7	
	ld hl, msg_game_level7
	jr pln11
pln8	
	ld hl, msg_game_level8
	jr pln11
pln9	
	ld hl, msg_game_level9
	jr pln11
pln10	
	ld hl, msg_game_level10

pln11	
	call pm_do_it	; part of print_message
pln12	
	ld a,2	; re-open channel 2
	call 5633


	ret	
	
	
; sound effect when clearing lines
clearedlinenoise  
	ld e,200            ; repeat 200 times.
	ld hl,0             ; start pointer in ROM.
noise2 
	push de
	ld b,32             ; length of step.
noise0 
	push bc
	ld a,(hl)           ; next "random" number.
	inc hl              ; pointer.
	and 248             ; we want a black border.
	out (254),a         ; write to speaker.
	ld a,e              ; as e gets smaller...
	cpl                 ; ...we increase the delay.
noise1 
	dec a               ; decrement loop counter.
	jr nz,noise1        ; delay loop.
	pop bc
	djnz noise0         ; next step.
	pop de
	ld a,e
	sub 24              ; size of step.
	cp 30               ; end of range.
	ret z
	ret c
	ld e,a
	cpl
noise3 
	ld b,40             ; silent period.
noise4 
	djnz noise4
	dec a
	jr nz,noise3
	jr noise2	
	
	ret
	
; this is the noise used when the piece drops one square

autodropnoise
	ld hl,300           ; starting pitch.
	ld b, 2          ; length of pitch bend.
adn1   
	push bc
	push hl             ; store pitch.
	ld de,1             ; very short duration.
	call 949            ; ROM beeper routine.
	pop hl              ; restore pitch.
	inc hl              ; pitch going up.
	pop bc
	djnz adn1           ; repeat.	
	ret
	
; this is the routine that draws the screen

drawscreen
	call 3503	; clear the screen
		
	ld hl, msg_newscreen_level
	call print_message
	
	; now print the level
	
	ld a,CC_AT
	rst 16
	ld a,12	;x position         
	rst 16            
	ld a,18	;y position        
	rst 16
	ld a,7		;colour white 

	ld a,(currentlevel)
	cp 10
	jr z,ds20
	
	add a,48	; add ASCII to get correct character
	ld c,a
	rst 16
	jr ds21

ds20
	;code for handling level 10
	ld a,49	; ASCII char for '1'
	rst 16
	ld a,48; ASCII char for '0'
	rst 16
	
ds21	
	ld b,75           ; time to pause (50 frames a sec, 1.5 secs wait)
ds19  
	halt                ; wait for an interrupt.
	djnz ds19          ; repeat.
	
	; to improve performance, we initially draw blocks whereever one of the shapes will be drawn
	; we then simply change their attribute colour to show or hide them
	
	call setupnextshape
	call setupsavedshape
	call setupplayarea

	; draw the saved shape
	call drawsavedshape
	
	; we call selectnewpiece twice so we have a value for current and next shape
	call selectnewpiece
	call selectnewpiece
	
	; reset the number of pieces played this level (to skip over the 2 select new piece calls above)
	xor a
	ld (piecesthislevel),a


	ld b,21

dsloop1
	ld a,CC_AT
	rst 16
	ld a,b         
	rst 16            
	ld a,11        
	rst 16
	ld a,2		;wall colour            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,146            ; ASCII code for User Defined Graphic 'C'.
	rst 16  
	djnz dsloop1

	ld b,21
dsloop2
	ld a,CC_AT
	rst 16
	ld a,b         
	rst 16            
	ld a,22		; y co-ordinate         
	rst 16
	ld a,2		;wall colour            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,146            ; ASCII code for User Defined Graphic 'C'.
	rst 16  
	djnz dsloop2

	ld a,12
	ld (wallpos),a
	
	ld d,21	; default position
	ld a,(upsidedown)
	cp 1
	jr z, ds1
	jr ds2	
ds1
	ld d,0

ds2	
	
	ld b,10
dsloop3
	ld a,CC_AT
	rst 16
	ld a,d        
	rst 16            
	ld a,(wallpos)	; y co-ordinate
	rst 16
	
	ld a,(wallpos)
	inc a
	ld (wallpos),a
	ld a,2		;wall colour            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,149            ; ASCII code for User Defined Graphic 'F'.
	rst 16  
	djnz dsloop3
	
	; now we draw the end of the pipes
	
	ld a,(upsidedown)
	cp 1
	jr z,ds12
ds11
	ld b,0	;end of pipes at top
	ld c,147	; ASCII code for User Defined Graphic 'D' 
	jr ds13
ds12
	ld b,21	;upside down so end of pipes at bottom
	ld c,148	; ASCII code for User Defined Graphic 'E' 
ds13	
	ld a,CC_AT
	rst 16
	ld a,b	;x position         
	rst 16            
	ld a,11	;y position        
	rst 16
	ld a,2		;colour red            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,c	; graphic
	rst 16

	ld a,CC_AT
	rst 16
	ld a,b         
	rst 16            
	ld a,22	;y position        
	rst 16
	ld a,2		;colour red            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,c		;graphic
	rst 16
	
ds14	
	; now we draw the corner pieces
	ld a,(upsidedown)
	cp 1
	jr z,ds16
ds15
	ld b,21	;corner of pipes at bottom
	ld c,150	; ASCII code for User Defined Graphic 'G' 
	ld d,152	; ASCII code for User Defined Graphic 'I' 
	jr ds17
ds16
	ld b,0	;corner of pipes at top
	ld c,151	; ASCII code for User Defined Graphic 'H' 
	ld d,153	; ASCII code for User Defined Graphic 'J' 
ds17	
	ld a,CC_AT
	rst 16
	ld a,b	;x position         
	rst 16            
	ld a,11	;y position        
	rst 16
	ld a,2		;colour red            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,c	; graphic
	rst 16

	ld a,CC_AT
	rst 16
	ld a,b	;x position         
	rst 16            
	ld a,22	;y position        
	rst 16
	ld a,2		;colour red            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,d	; graphic
	rst 16


ds18
	; now we check for any special cases
	
	ld a,(currentlevel)
	cp 4	; shooting stars
	jr z,ds3
	cp 5	; more stars
	jr z,ds4
	cp 6	; level letter F
	jr z,ds5
	cp 7	; mirror level
	jr z,ds6
	cp 9
	jr z,ds7
	jr ds8	; no matches to special cases
ds3
	; draw 2 stars on screen
	call shootingstar
	call shootingstar
	jr ds8
ds4	
	; draw 2 stars on screen
	call shootingstar
	call shootingstar
	jr ds8
ds5
	call drawletterf
	jr ds8
ds6	
	call drawmirror
	jr ds8
ds7
	; draw 2 stars on screen
	call shootingstar
	call shootingstar
ds8
	; print the score section
	ld hl,msg_game_score
	call print_message
	
	call printscore
	
	; print the high score section
	ld hl,msg_game_highscore
	call print_message
	
	call printhighscore
	
	; print ghost section
	ld hl, msg_game_ghost
	call print_message
	
	ld a,(ghostactive)
	cp 1
	jr z,ds9
	
	ld hl, msg_game_ghost_inactive
	jr ds10	
ds9
	ld hl, msg_game_ghost_active
ds10
	call print_message
	
	; print next shape wording
	ld hl, msg_game_nextpiece
	call print_message
	
	; print saved shape section
	ld hl, msg_game_savedpiece
	call print_message
	
	; print lines completed section
	ld hl,msg_game_line
	call print_message
	
	call printlines
	
	; print the name of the level
	call printlevelname
	
	;align shape to correct orientation
	call setblockshapes

	; now we draw our shape
	ld hl, colourlookuptable
	ld de,(currentshape)
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (blockcolour),a	; now draw block in new position

	call showcurrentshape
	
	; final action of setup, set ingame to 1 so music will play (if enabled by player)
	ld a,1
	ld (ingame),a
	xor a
	ld (noteindex),a	; so music plays at start of song
	
	
	ret
	
; level 6 is called the letter F. We draw a letter F on-screen
drawletterf

	ld c,20	; starting x position
	ld b,5

dlf1
	ld a,CC_AT
	rst 16
	ld a,c         
	rst 16            
	ld a,16	;y position        
	rst 16
	ld a,4		;colour green            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16  
	
	dec c	; drop c one square (up the screen)
	
	djnz dlf1

	ld a,CC_AT
	rst 16
	ld a,18         
	rst 16            
	ld a,17	;y position        
	rst 16
	ld a,4		;colour green            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16  
		
	ld a,CC_AT
	rst 16
	ld a,16         
	rst 16            
	ld a,17	;y position        
	rst 16
	ld a,4		;colour green            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16  
	
	ld a,CC_AT
	rst 16
	ld a,16         
	rst 16            
	ld a,18	;y position        
	rst 16
	ld a,4		;colour green            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16  
		
		


	ret
	
; level 7 is called Mirror, this draws a mirrored F on screen	
drawmirror	
	ld c,20	; starting x position
	ld b,5

dm1
	ld a,CC_AT
	rst 16
	ld a,c         
	rst 16            
	ld a,16	;y position        
	rst 16
	ld a,4		;colour green            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16  
	
	dec c	; drop c one square (up the screen)
	
	djnz dm1

	ld c,14
	ld b,5
dm2
	ld a,CC_AT
	rst 16
	ld a, 16        
	rst 16            
	ld a,c        
	rst 16
	ld a,4		;colour green            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16  
	
	inc c	
	
	djnz dm2	
	
	ld c,15
	ld b,3
dm3
	ld a,CC_AT
	rst 16
	ld a, 18        
	rst 16            
	ld a,c        
	rst 16
	ld a,4		;colour green            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16  
	
	inc c	
	
	djnz dm3	
	


	ret
	
; this sets up the variables for a new level
setuplevel
	xor a
	ld (upsidedown),a
	ld a,(currentlevel)
	cp 3
	jr z,sul1
	jr sul2
sul1
	ld a,1
	ld (upsidedown),a
sul2
	; reset allowed swap
	ld a,1
	ld (allowedswap),a
	
	;reset the lines completed
	ld hl,totalrowscompleted
	ld (hl),'0'
	inc hl
	ld (hl),'0'
	
	xor a
	ld (totalrowscompletednum),a
	
	; reset the number of pieces played this level
	xor a
	ld (piecesthislevel),a
	
	; calculate the lines required for this level
	ld hl,targetlinesforthislevel
	ld (hl),'0'
	inc hl
	ld (hl),'0'
	
	call calculatelinesforthislevel
	
	ld hl, linesneededperlevel
	ld de,(currentlevel)
	dec de
	ld d,0	;de is 16 bit, but we are actually trying to add an 8 bit to a 16bit so remove any possible extras
	add hl,de
	ld a,(hl)
	ld (targetlinesforthislevelnum),a

	; ensure block starts in start position
	ld a,(startx)	
	ld (plx),a
	ld a,(starty)
	ld (ply),a
	
	; if upside down we need to modify the x position
	ld a,(upsidedown)
	cp 1
	jr z,sul3
	jr sul4
sul3	
	ld a,(upsidedownstartx)
	ld (plx),a
sul4	
	ret
	
; this setups the variables for a new level and draws the screen
newlevel
	; switch off in-game music (will be re-activated later after new screen drawn)
	xor a
	ld (ingame),a
	
	call setuplevel
	call drawscreen
	
	ld hl,pretim
	ld a,(23672) 
	ld (hl),a

	ret
	
; this does the level special action
; for example put a random square on the screen or slide a floor level or
; rise the entire board. There are special actions for levels 4,5,8,9 and 10
levelspecialaction

	ld a,(currentlevel)
	cp 4
	jp z,lsa1
	cp 5
	jp z,lsa2
	cp 8
	jp z,lsa3
	cp 9
	jp z,lsa4
	cp 10
	jp z,lsa5

	ret
	
lsa1
	; level 4, needs shooting stars every 5 pieces
	ld a,(piecesthislevel)
	ld d,a
	ld e,5
	call getmodulo
	; a will be 0 if evenly divisible by 5
	cp 0
	ret nz
	
	call shootingstar

	ret
lsa2
	; level 5, needs shooting stars every 5 pieces
	ld a,(piecesthislevel)
	ld d,a
	ld e,5
	call getmodulo
	; a will be 0 if evenly divisible by 5
	cp 0
	ret nz
	
	call shootingstar
	ret
lsa3
	; level 8, sliding floor
	; a random level is moved either left or right every 4 pieces
	
	ld a,(piecesthislevel)
	ld d,a
	ld e,4
	call getmodulo
	; a will be 0 if evenly divisible by 4
	cp 0
	ret nz
	
	call slidingfloor
	
	ret
lsa4
	; level 9, needs shooting stars every 5 pieces and sliding floor
	ld a,(piecesthislevel)
	ld d,a
	ld e,5
	call getmodulo
	; a will be 0 if evenly divisible by 5
	cp 0
	jp nz,lsa6
	
	call shootingstar
	
lsa6	
	ld a,(piecesthislevel)
	ld d,a
	ld e,4
	call getmodulo
	; a will be 0 if evenly divisible by 4
	cp 0
	ret nz
	
	call slidingfloor
	
	ret
lsa5
	ld a,(piecesthislevel)
	ld d,a
	ld e,10
	call getmodulo
	; a will be 0 if evenly divisible by 10
	cp 0
	ret nz
	
	call risingfloor
	ret

	
	
; routine for calculating modulo
; Integer divides D by E
; Result in D, remainder in A
; Clobbers F, B
getmodulo
	xor a
	ld b,8
gm1  
	sla d
	rla
	cp e
	jr c,gm2
	sub e
	inc d
gm2  
	djnz gm1	
	ret
	
; shooting star. This puts a random square somewhere on the playarea. It puts it at least 4
; squares down from the top of the screen to give the player a chance
shootingstar
	call rnd
	and 15	;bitmask bits 0, 1, 2 and 3 
	
	add a,5 	; to ensure we do not put a block directly in starting position
	ld (shootingstarx),a
	
	; now that we have picked the row, need to pick the column
	; column must be between 12 and 21 (inclusive)

sst1
	call rnd
	and 15; bitmask 4 bits
	cp 10
	jp nc,sst1
sst3
	; we now have a value between 0 and 9
	add a,12
	ld c,a
	ld (shootingstary),a
	
	; now see if there is already a block at this position
	ld a,(shootingstarx)
	ld b,a
	
	call atadd
	or 0 ; check if it black/black i.e. empty square
	jp nz,sst1
	
	; at this stage we have picked a square and it is blank
	; lets draw it on-screen
	
	ld a,CC_AT
	rst 16
	ld a,(shootingstarx)
	rst 16            
	ld a,(shootingstary)        
	rst 16
	ld a,2		;colour red            
                          
	ld (23695),a        ; set our temporary screen colours.
	ld a,144            ; ASCII code for User Defined Graphic 'A'.
	rst 16
	
	ret
	
; finds a row (that has a square already on that row) and slides it one square left or right
slidingfloor
	xor a
	ld (slidingcounter),a

sf1
	call rnd
	and 15	;bitmask bits 0, 1, 2 and 3 
	
	add a,5 ; so picking a level safely below start point
	
	ld (slidingrow),a
	
	; now that we have picked a row, need to ensure there is at least one square already on that
	; row, otherwise we will need to pick a new row
	
	; set tmpx to the row to check
	ld (tmpx),a
	
	ld a,(playareatopliney)
	ld (tmpy),a

	ld b,10		;10 squares in width of play area
sf2
	push bc
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	or 0 ; check if it black/black i.e. empty square
	jp nz, sf3 ; found a non black square
	
	ld a,(tmpy)
	inc a
	ld (tmpy),a
	pop bc
	djnz sf2
	; if got here then no squares on the line, pick a new row
	ld a,(slidingcounter)
	inc a
	cp 20
	ret z	; if 20 attempts to find a row, give up
	ld (slidingcounter),a
	jr sf1
sf3
	; so we have found a row with at least one block on it, now lets shift it
	;pick whether to go left (0) or right (1)
	pop bc	; to handle first push within sf2	

	call rnd
	and 15; bitmask 4 bits
	
	ld d,a
	ld e,2
	call getmodulo
	cp 1
	jp z,sf4	; going right
	
	;we are going left so get value at column 12
	ld c,12
	ld a,(slidingrow)
	ld b,a
	call atadd
	ld (slidingwraparoundcolour),a
	
	ld a,12	; starting point is column 12
	ld (tmpy),a
	ld b,9	; one less than normal
sf5
	push bc	
	
	ld a,(slidingrow)
	ld b,a
	
	ld a,(tmpy)
	inc a
	ld c,a
	call atadd
	ld (slidingtempcolour),a	; this now contains the colour of the square directly to the right
	ld a,(tmpy)
	ld c,a
	call atadd
	ld a,(slidingtempcolour)
	ld (hl),a
	ld a,(tmpy)		; next square in the row
	inc a
	ld (tmpy),a
	pop bc
	djnz sf5
sf6
	; now place the wrap around colour, place at column 21
	ld a,(slidingrow)
	ld b,a
	ld c,21
	call atadd
	ld a,(slidingwraparoundcolour)
	ld (hl),a
	
	ret	;finished
	
	
	
sf4	
	;get the value at column 21
	ld c,21
	ld a,(slidingrow)
	ld b,a
	call atadd
	ld (slidingwraparoundcolour),a	
	
	ld a,21	; starting point is column 21
	ld (tmpy),a
	ld b,9	; one less than normal
sf7
	push bc	
	
	ld a,(slidingrow)
	ld b,a
	
	ld a,(tmpy)
	dec a
	ld c,a
	call atadd
	ld (slidingtempcolour),a	; this now contains the colour of the square directly to the left
	ld a,(tmpy)
	ld c,a
	call atadd
	ld a,(slidingtempcolour)
	ld (hl),a
	ld a,(tmpy)		; next square in the row
	dec a
	ld (tmpy),a
	pop bc
	djnz sf7
sf8
	; now place the wrap around colour, place at column 12
	ld a,(slidingrow)
	ld b,a
	ld c,12
	call atadd
	ld a,(slidingwraparoundcolour)
	ld (hl),a

	ret
	
; this is the special action for level 10. Every 10 pieces the playarea raises one level
; and random squares are added to that level
risingfloor
	ld a,(playareatopliney)
	ld (tmpy),a
	
	xor a
	ld (tmpx),a

rf1
	ld b,10		; inner loop
rf2
	push bc	
	
	ld a,(tmpx)
	inc a	; we increase by 1 as we are copying the line below
	ld b,a
	
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (blockcolour),a	; this now contains the colour of the square directly above
	ld a,(tmpx)
	ld b,a
	call atadd
	ld a,(blockcolour)
	ld (hl),a
	ld a,(tmpy)		; next square in the row
	inc a
	ld (tmpy),a
	pop bc
	djnz rf2
	; finished inner loop, i.e. that row, increase x by 1 and reset y
	
	ld a,(tmpx)
	inc a
	ld (tmpx),a
	ld a,(playareatopliney)
	ld (tmpy),a
		
	ld a,(tmpx)
	cp 20	; at 21 we are at the bottom of the screen, 20 would try to read from the bricks (+1)
	jr nz, rf1
	
	; at this stage we have dropped everything, now now erase the bottom line
	ld a,20
	ld (tmpx),a
	call eraseline
	
	; now fill this line with random squares
	ld a,(playareatopliney)
	ld (tmpy),a
	
	ld b,10		;10 squares in width of play area
rf3
	push bc
	
	call rnd
	and 15; bitmask 4 bits
	
	ld d,a
	ld e,2
	call getmodulo
	cp 1
	jp z,rf5	
	
rf4	
	ld a,(tmpx)
	ld b,a
	ld a,(tmpy)
	ld c,a
	call atadd
	ld (hl),5	; set the attribute at this square to be 5, cyan
rf5
	ld a,(tmpy)
	inc a
	ld (tmpy),a	
	pop bc
	djnz rf3
	
	ret
	
	
; this checks if we have completed the level or won the game	
checklevelcomplete	
	ld a,(targetlinesforthislevelnum)
	ld b,a
	ld a,(totalrowscompletednum)
	cp b
	jr nc,clc1
	ret	; target for level nor reached, can exit routine
	
clc1
	ld a,(currentlevel)
	inc a
	ld (currentlevel),a
	
	cp 11
	jp nc,youwin
	
	; add delay
	ld hl, 50000
clc2
	dec hl
	ld a,h
	or l
	jr nz,clc2
	
	jp newlevel
	
;checks the score against the high score and sets the score to be the high score if larger	
checkhighscore
	xor a
	ld (newhighscore),a

	ld hl,highscore
	ld c,(hl)
	ld hl,score
	ld a,(hl)
	cp c
	jr z,chs2	;if equal we check next digit
	jr nc,chs1	; accumulator (score) is greater than high score
	ret	; otherwise high score is still bettter
chs2
	inc hl	; advance score pointer
	ld a,(hl)
	ld hl,highscore+1
	ld c,(hl)
	cp c
	jr z,chs3
	jr nc,chs1
	ret
chs3
	inc hl	;advance high score pointer
	ld c,(hl)
	ld hl,score+2
	ld a,(hl)
	cp c
	jr z,chs4
	jr nc,chs1
	ret
chs4
	inc hl	; advance score pointer
	ld a,(hl)
	ld hl,highscore+3
	ld c,(hl)
	cp c
	jr z,chs5
	jr nc,chs1
	ret
chs5
	inc hl	;advance high score pointer
	ld c,(hl)
	ld hl,score+4
	ld a,(hl)
	cp c
	jr z,chs6
	jr nc,chs1
	ret
chs6
	inc hl	; advance score pointer
	ld a,(hl)
	ld hl,highscore+5
	ld c,(hl)
	cp c
	jr nc,chs1
	ret		;if reach here score is less than high score
	
chs1
	ld a,1
	ld (newhighscore),a		;new high score
	
	ld de,highscore
	ld hl,score
	ld bc,6
	ldir
	
	ret
	
	; this allows the player to switch the music on off
switchmusiconoff	
	ld a,(ingamemusicenabled)
	cp 0
	jr nz,smo1
	; if here then music is currently on, switch off
	ld a,1
	ld (ingamemusicenabled),a
	ret
smo1
	; if here then music is currently on, we switch off
	xor a
	ld (ingamemusicenabled),a
	ret

	
; the in-game music section	
org 40000

	; music is 'Fur Elise', use cp value of 12 in playmusic
;ingamemusic
;	defb 30,32,30,32,30,40,34,38
;	defb 45,45,45,76,61,45,40,40
;	defb 96,61,48,40,38,38,38,61
;	defb 30,32,30,32,30,40,34,38
;	defb 45,45,45,76,61,45,40,40
;	defb 96,61,38,40,48,48,48,255


	;music 'In the Hall of the Mountain King' from Manic Miner
	;set cp value to 8 in playmusic to use
;ingamemusic
;	defb 128,114,102,96,86,102,86,86,81,96,81,81,86,102,86,86  
;	defb 128,114,102,96,86,102,86,86,81,96,81,81,86,86,86,86  
;	defb 128,114,102,96,86,102,86,86,81,96,81,81,86,102,86,86  
;	defb 128,114,102,96,86,102,86,64,86,102,128,102,86,86,86,86,255

	;alternative version 'In the Hall of the Mountain King'
	;set cp value to 6 in playmusic to use
ingamemusic
	defb 48,48,43,43,40,40,36,36,32,32,40,40,32,32
	defb 32,32
	defb 34,34,43,43,34,34,34,34,36,36,45,45,36,36,36,36
	defb 48,48,43,43,40,40,36,36,32,32,40,40,32,32	
	defb 24,24,27,27,32,32,40,40,32,32,27,27,27,27,27,27
	defb 27,27
	defb 128,128,114,114,102,102,96,96,86,86,102,102,86,86
	defb 86,86,81,81,102,102,81,81,81,81,86,86,102,102,86,86
	defb 86,86
	defb 128,128,114,114,102,102,96,96,86,86,102,102,86,86
	defb 86,86,81,81,102,102,81,81,81,81,86,86,86,86
	defb 86,86,86,86,255


	; music for the game tetris
	;set cp value to 10 in playmusic to use
;ingamemusic
;	defb 18,24,23,20,23,24,27,27
;	defb 23,18,20,23,24,23,20,18
;	defb 23,27,27,27,24,23,20,17
;	defb 13,15,17,18,23,18,20,23
;	defb 24,24,23,20,18,23,27,27
;	defb 1,18,23,20,24,23,27,28
;	defb 24,1,18,23,20,24,23,18
;	defb 13,14,255

	; 'If I were a rich man' from Jet Set Willy
;ingamemusic
;	defb 86,96,86,96,102,102,128,128,128,128,102,96,86,96,86,96  
;	defb 102,96,86,76,72,76,72,76,86,86,86,86,86,86,86,86  
;	defb 64,64,64,64,68,68,76,76,86,96,102,96,86,86,102,102  
;	defb 81,86,96,86,81,81,96,96,64,64,64,64,64,64,64,64,255

	
noteindex	defb	0
musicpauseindex		defb	0


playmusic
	ld a,(ingame)
	cp 0
	ret z
	
	; now see if player wants music
	ld a,(ingamemusicenabled)
	cp 0
	ret z
	
	ld a,(musicpauseindex)
	inc a
	ld (musicpauseindex),a
	cp 6
	jr nc,pm1
	ret
pm1
	xor a
	ld (musicpauseindex),a
	jp playnote
	

	; this music routine adapted from manic miner code
playnote
	ld a,(noteindex)	
	ld e,a
	ld d,0
	ld hl,ingamemusic
	add hl,de
	ld a,(hl)
	cp 255
	jr z,pn3
	; not end of song, increase index
	ld a,(noteindex)
	inc a
	ld (noteindex),a
	jr pn4
pn3	
	xor a
	ld (noteindex),a
	jr playnote
pn4	
	xor a	; set border colour to 0
	ld e,(hl)
	ld bc,3
pn1	
	out (254),a
	dec e
	jr nz,pn2
	ld e,(hl)
	xor 24
pn2	
	djnz pn1
	dec c
	jr nz,pn1
	ret
	

	
org 51400	; location of our interrupt routine

Interrupt    
	di				; disable interrupts
	push af             ; preserve registers.
	push bc
	push hl
	push de
	push ix
	
	; here is where we put the calls to the routines we want to execute during interrupts
	; e.g. play music etc.
	; we increment the frames counter as this is used to determine the rate of drop of the 
	; main game piece

	ld hl,23672         ; frames counter.
	inc (hl)            ; move it along.
	
	call playmusic
	
	; end of our routines
	   
	pop ix              ; restore registers.
	pop de
	pop hl
	pop bc
	pop af
	ei                  ; always re-enable interrupts before returning.
	reti                ; done (return from interrupt)

org 65024

	; pointers to interrupt routine.
	; 257 instances of '200'
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200,200,200,200,200,200,200,200
	defb 200	
	
end 24576	; assembler directive, says this is the end of the code and where the entry point is

	


