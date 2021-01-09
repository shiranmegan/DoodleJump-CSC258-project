#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: SHI RAN, 1004793495
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Realistic physics (falling becomes faster, jump becomes slower)
# 2. Dynamic on-screen notifications
# Milestone 4 features:
# 3. Retry option: enter s to restart the game
# 4. ScoreBoard: score will be displayed after game is over
#
# Any additional information that the TA needs to know:
# - Player wins after reaching a score greater than 11
#
#####################################################################

.data
 	#colors
	doodleColor:.word 0xA7C044	#body green
	doodleColor2:.word 0x3F681F	#body deeper green
	bgColor:.word 0xfff0f6 #background pink
	platformColor:.word 0x006400 #platform green
	blue: .word 0x5f87ff
	
	#screen
	displayAddress:	.word	0x10008000
	
	jump: .word 10 # height doodle can jump
	desiredX: .word 15
	doodleX: .word 15
	doodleY: .word 13 # initial position of doodle
	targetX: .word 12
	targetY: .word 8 # initial position of "target" platform
	currX: .word 12
	currY: .word 15 # initial position of "current" platform
	topX: .word 12
	topY: .word 1
	dis: .word 4 # distance moved by keyboard input
	
	keyboardAddr: .word 0xffff0000
	sleep: .word 100
	
	platforms: .word 12:4 # X of platforms
	
	count: .word 0 # level
	
	
	
.text

main:
	lw $a0, displayAddress
	lw $a1, bgColor
	addi $a2, $a0, 4096 # end address of screen
	# initialize platforms
	add $t9, $zero, 12
	sw $t9, currX
	sw $t9, targetX
	sw $t9, topX
	add $t9, $t9, 1
	sw $t9, doodleY
	add $t9, $t9, 2
	sw $t9, doodleX
	sw $t9, desiredX
	add $t9, $zero, $zero
	sw $t9, count
	
Background:
	# draw background
	beq $a0, $a2, MainLoop
	sw $a1, 0($a0)
	addiu $a0, $a0, 4
	j Background
	
MainLoop:
	# use stored information to draw platform
	lw $a1, currY
	lw $a2, currX
	jal Retrieve_Address
	move $a3, $v0
	jal DrawPlatform
	lw $a1, targetY
	lw $a2, targetX
	jal Retrieve_Address
	move $a3, $v0
	jal DrawPlatform
	lw $a1, topY
	lw $a2, topX
	jal Retrieve_Address
	move $a3, $v0
	jal DrawPlatform
	
	# use stored information to draw doodle
	lw $a2, doodleX
	lw $a1, doodleY
	jal Retrieve_Address
	move $a3, $v0
	jal DrawDoodle
	
	# doodle jumps using value jump
	THEN:
	lw $s0, jump
	JUMP:
		
		# make the program sleep
		lw $a0, sleep
		jal Sleep
		
		# delete original doodle
		lw $a1, doodleY
		lw $a2, doodleX
		jal Retrieve_Address
		move $a3, $v0
		jal DeleteDoodle
		# redraw target platform
		lw $a1, targetY
		lw $a2, targetX
		jal Retrieve_Address
		move $a3, $v0
		jal DrawPlatform
		
		# animation of left/right movement
		lw $a2, doodleX
		lw $t8, desiredX
		beq $t8, $a2, LABEL
		bgt $t8, $a2, RIGHT
		add $a2, $a2, -1
		sw $a2, doodleX
		j LABEL
		RIGHT:
		add $a2, $a2, 1
		sw $a2, doodleX
		
	LABEL:
		
		# check key
		lw $t8, 0xffff0000
		beq $t8, 1, keyboard_input
		j CONT
	keyboard_input:
		lw $s2, doodleX
		lw $t7, 0xffff0004
		beq $t7, 0x6a, respond_to_j
		beq $t7, 0x6b, respond_to_k
		j CONT
		
	respond_to_j: # doodle turns left for 4 positions
		add $s2, $s2, -4
		bge $s2, 0, END1
		add $s2, $zero, $zero
		END1:
		sw $s2, desiredX
		j CONT

	respond_to_k: # doodle turns right for 4 positions
		add $s2, $s2, 4
		ble $s2, 29, END2
		add $s2, $zero, 29
		END2:
		sw $s2, desiredX
		
	CONT:
		
		# fall if reaches max height
		beqz $s0, FALL
		
		# redraw doodle with one position higher (case Jump)
		lw $a1, doodleY
		lw $a2, doodleX
		add $a1, $a1, -1
		add $s0, $s0, -1
		sw $a1, doodleY
		jal Retrieve_Address
		move $a3, $v0
		jal DrawDoodle
		# speed
		subiu $a0, $s0, 6
		mul $a0, $a0, 15
		add $a0, $a0, 100
		jal Sleep 
		j JUMP
		
		# redraw doodle with one position lower (case Fall)
		
		FALL:
		lw $a1, doodleY
		lw $a2, doodleX
		add $a1, $a1, 1
		sw $a1, doodleY
		jal Retrieve_Address
		move $a3, $v0
		jal DrawDoodle
		# check collision
		beq $a1, 6, COLLIDE1
		beq $a1, 13, COLLIDE2
		beq $a1, 15, GAME_OVER
		j JUMP
		
		GAME_OVER:
		jal DrawRetry
		
		lw $t2, count
		beq $t2, 0, ZERO
		beq $t2, 1, ONE
		beq $t2, 2, TWO
		beq $t2, 3, THREE
		beq $t2, 4, FOUR
		beq $t2, 5, FIVE
		beq $t2, 6, SIX
		beq $t2, 7, SEVEN
		beq $t2, 8, EIGHT
		beq $t2, 9, NINE
		beq $t2, 10, TEN
		bge $t2, 11, WIN
		j Retry
		ZERO: jal Draw0
		jal DrawScore
		j Retry
		ONE:
		jal DrawScore
		jal Draw1
		j Retry
		TWO:
		jal DrawScore
		jal Draw2
		j Retry
		THREE: 
		jal DrawScore
		jal Draw3
		j Retry
		FOUR: 
		jal DrawScore
		jal Draw4
		j Retry
		FIVE:
		jal DrawScore
		jal Draw5
		j Retry
		SIX:
		jal DrawScore
		jal Draw6
		j Retry
		SEVEN:
		jal DrawScore
		jal Draw7
		j Retry
		EIGHT: 
		jal DrawScore
		jal Draw8
		j Retry
		NINE: 
		jal DrawScore
		jal Draw9
		j Retry
		TEN: 
		jal DrawScore
		jal Draw1
		add $a0, $a0, 12
		jal Draw0
		j Retry
		WIN:
		add $t1, $zero, 0x468499
		jal DrawWin
		j Retry
		
		# need to redraw screen
		COLLIDE1:
		lw $t5, targetX
		blt $a2, $t5, JUMP
		add $t5, $t5, 6
		bgt $a2, $t5, JUMP
		add $a0, $zero, 150
		jal Sleep
		# update count
		lw $t6, count
		add $t6, $t6, 1
		sw $t6, count
		# Wow when score=3
		lw $t8, count
		beq $t8, 3, LABEL1
		beq $t8, 7, LABEL2
		beq $t8, 11, LABEL3
		j LABEL4
		LABEL1:
		jal DrawWow
		add $a0, $zero, 200
		jal Sleep
		jal DeleteWow
		j LABEL4
		# Good job when score=7
		LABEL2:
		jal DrawGood
		add $a0, $zero, 200
		jal Sleep
		jal DeleteGood
		j LABEL4
		# win when score=11
		LABEL3:
		add $t1, $zero, 0xd9534f
		jal DrawWin
		add $a0, $zero, 200
		jal Sleep
		jal DeleteWin
		# move all platforms 7 position lower
		LABEL4:
		
		add $t6, $zero, 0 # loop count
		LOOP:
		lw $a0, sleep
		mul $t4, $t6, 10
		add $a0, $a0, $t4
		jal Sleep
		
			lw $a1, currY
			lw $a2, currX
			add $a1, $a1, $t6
			jal Retrieve_Address
			move $a3, $v0
			jal DeletePlatform
			add $a1, $a1, 1
			jal Retrieve_Address
			move $a3, $v0
			jal DrawPlatform
			
			lw $a1, targetY
			lw $a2, targetX
			add $a1, $a1, $t6
			jal Retrieve_Address
			move $a3, $v0
			jal DeletePlatform
			add $a1, $a1, 1
			jal Retrieve_Address
			move $a3, $v0
			jal DrawPlatform
			
			lw $a1, topY
			lw $a2, topX
			add $a1, $a1, $t6
			jal Retrieve_Address
			move $a3, $v0
			jal DeletePlatform
			add $a1, $a1, 1
			jal Retrieve_Address
			move $a3, $v0
			jal DrawPlatform
			
			# redraw doodle
			lw $a1, doodleY
			lw $a2, doodleX
			jal Retrieve_Address
			move $a3, $v0
			jal DrawDoodle
		add $t6, $t6, 1
		bne $t6, 7, LOOP
		
		# store platforms, generate new platform
		lw $t9, targetX
		sw $t9, currX
		lw $t9, topX
		sw $t9, targetX
		jal RandomNum
		sw $a0, topX
		lw $a2, topX
		lw $a1, topY
		jal Retrieve_Address
		move $a3, $v0
		jal DrawPlatform
		add $s0, $zero, 3
		# adjust speed
		mul $a0, $t6, 20
		jal Sleep
		j JUMP
		
		# no need to redraw screen
		COLLIDE2:
		
		lw $t5, currX
		blt $a2, $t5, JUMP
		add $t5, $t5, 6
		bgt $a2, $t5, JUMP
		add $a0, $zero, 200
		jal Sleep
		lw $s0, jump
		j JUMP
		
	
	
	j Exit
	



	
## functions


# draw doodle at address $a3, facing right
DrawDoodle:
	lw $t1, doodleColor
	sw $t1, 128($a3)
	sw $t1, 132($a3)
	sw $t1, 136($a3)
	sw $t1, 256($a3)
	sw $t1, 264($a3)
	sw $t1, 384($a3)
	sw $t1, 392($a3)
	lw $t1, doodleColor2
	sw $t1, 0($a3)
	sw $t1, 8($a3)
	sw $t1, 260($a3)
	jr $ra
	
DeleteDoodle:
	lw $t1, bgColor
	sw $t1, 128($a3)
	sw $t1, 132($a3)
	sw $t1, 136($a3)
	sw $t1, 256($a3)
	sw $t1, 260($a3)
	sw $t1, 264($a3)
	sw $t1, 384($a3)
	sw $t1, 392($a3)
	sw $t1, 0($a3)
	sw $t1, 8($a3)
	jr $ra

# Draw platform at $a3
DrawPlatform:
	lw $t1, platformColor
	sw $t1, 0($a3)
	sw $t1, 4($a3)
	sw $t1, 8($a3)
	sw $t1, 12($a3)
	sw $t1, 16($a3)
	sw $t1, 20($a3)
	sw $t1, 24($a3)
	sw $t1, 28($a3)
	jr $ra

# delete platform at address a3	
DeletePlatform:
	lw $t1, bgColor
	sw $t1, 0($a3)
	sw $t1, 4($a3)
	sw $t1, 8($a3)
	sw $t1, 12($a3)
	sw $t1, 16($a3)
	sw $t1, 20($a3)
	sw $t1, 24($a3)
	sw $t1, 28($a3)
	jr $ra


# retrieve address given position input (a2, a1)
Retrieve_Address:
	add $v0, $zero, 64
	mul $v0, $v0, $a1	
	add $v0, $v0, $a2	
	mul $v0, $v0, 4	# multiply by 4
	add $v0, $v0, $gp
	jr $ra 
	
# sleep for $a0 miliseconds
Sleep:
	li $v0, 32
	syscall
	jr $ra
	
# generate random integer between 0 and 24=$a0
RandomNum:
	li $v0, 42
	li $a0, 0
	li $a1, 24
	syscall
	jr $ra
	
DrawRetry:
	lw $a1, bgColor
	add $a0, $gp, $zero
	add $a2, $a0, 4096
	Draw:
	sw $a1, 0($a0)
	add $a0, $a0, 4
	bne $a0, $a2, Draw

	lw $t1, blue
	add $a1, $gp, $zero
	sw $t1, 1312($a1)
	sw $t1, 1440($a1)
	sw $t1, 1568($a1)
	sw $t1, 1316($a1)
	
	sw $t1, 1068($a1)
	sw $t1, 1072($a1)
	sw $t1, 1196($a1)
	sw $t1, 1324($a1)
	sw $t1, 1328($a1)
	sw $t1, 1324($a1)
	sw $t1, 1452($a1)
	sw $t1, 1580($a1)
	sw $t1, 1584($a1)
	
	sw $t1, 1208($a1)
	sw $t1, 1212($a1)
	sw $t1, 1216($a1)
	sw $t1, 1340($a1)
	sw $t1, 1468($a1)
	sw $t1, 1596($a1)
	
	sw $t1, 1352($a1)
	sw $t1, 1480($a1)
	sw $t1, 1608($a1)
	sw $t1, 1356($a1)
	
	sw $t1, 1236($a1)
	sw $t1, 1364($a1)
	sw $t1, 1244($a1)
	sw $t1, 1372($a1)
	sw $t1, 1492($a1)
	sw $t1, 1496($a1)
	sw $t1, 1500($a1)
	sw $t1, 1628($a1)
	sw $t1, 1756($a1)
	sw $t1, 1752($a1)
	sw $t1, 1748($a1)
	
	sw $t1, 1124($a1)
	sw $t1, 1128($a1)
	sw $t1, 1132($a1)
	sw $t1, 1260($a1)
	sw $t1, 1388($a1)
	sw $t1, 1384($a1)
	sw $t1, 1380($a1)
	sw $t1, 1508($a1)
	sw $t1, 1764($a1)
	jr $ra
	
DrawScore:
	add $t1, $zero, 0x5fc2ff
	add $a0, $gp, $zero
	sw $t1, 2056($a0)
	sw $t1, 2060($a0)
	sw $t1, 2184($a0)
	sw $t1, 2312($a0)
	sw $t1, 2316($a0)
	sw $t1, 2444($a0)
	sw $t1, 2568($a0)
	sw $t1, 2572($a0)
	
	sw $t1, 2068($a0)
	sw $t1, 2072($a0)
	sw $t1, 2196($a0)
	sw $t1, 2324($a0)
	sw $t1, 2452($a0)
	sw $t1, 2580($a0)
	sw $t1, 2584($a0)
	
	sw $t1, 2080($a0)
	sw $t1, 2084($a0)
	sw $t1, 2088($a0)
	sw $t1, 2208($a0)
	sw $t1, 2216($a0)
	sw $t1, 2336($a0)
	sw $t1, 2344($a0)
	sw $t1, 2464($a0)
	sw $t1, 2472($a0)
	sw $t1, 2592($a0)
	sw $t1, 2596($a0)
	sw $t1, 2600($a0)
	
	sw $t1, 2096($a0)
	sw $t1, 2100($a0)
	sw $t1, 2104($a0)
	sw $t1, 2224($a0)
	sw $t1, 2232($a0)
	sw $t1, 2352($a0)
	sw $t1, 2356($a0)
	sw $t1, 2360($a0)
	sw $t1, 2480($a0)
	sw $t1, 2484($a0)
	sw $t1, 2608($a0)
	sw $t1, 2616($a0)
	
	sw $t1, 2112($a0)
	sw $t1, 2116($a0)
	sw $t1, 2240($a0)
	sw $t1, 2368($a0)
	sw $t1, 2372($a0)
	sw $t1, 2496($a0)
	sw $t1, 2624($a0)
	sw $t1, 2628($a0)
	
	sw $t1, 2380($a0)
	sw $t1, 2636($a0)
	jr $ra
	
Draw0:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2152($a0)
	sw $t1, 2268($a0)
	sw $t1, 2280($a0)
	sw $t1, 2396($a0)
	sw $t1, 2408($a0)
	sw $t1, 2524($a0)
	sw $t1, 2536($a0)
	sw $t1, 2652($a0)
	sw $t1, 2656($a0)
	sw $t1, 2660($a0)
	sw $t1, 2664($a0)
	jr $ra
	
Draw1:
	sw $t1, 2144($a0)
	sw $t1, 2268($a0)
	sw $t1, 2272($a0)
	sw $t1, 2400($a0)
	sw $t1, 2528($a0)
	sw $t1, 2656($a0)
	sw $t1, 2652($a0)
	sw $t1, 2660($a0)
	jr $ra
	
Draw2:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2276($a0)
	sw $t1, 2404($a0)
	sw $t1, 2400($a0)
	sw $t1, 2396($a0)
	sw $t1, 2524($a0)
	sw $t1, 2652($a0)
	sw $t1, 2656($a0)
	sw $t1, 2660($a0)
	jr $ra
	
Draw3:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2276($a0)
	sw $t1, 2404($a0)
	sw $t1, 2400($a0)
	sw $t1, 2396($a0)
	sw $t1, 2532($a0)
	sw $t1, 2652($a0)
	sw $t1, 2656($a0)
	sw $t1, 2660($a0)
	jr $ra
	
Draw4:
	sw $t1, 2140($a0)
	sw $t1, 2148($a0)
	sw $t1, 2268($a0)
	sw $t1, 2276($a0)
	sw $t1, 2404($a0)
	sw $t1, 2400($a0)
	sw $t1, 2396($a0)
	sw $t1, 2532($a0)
	sw $t1, 2660($a0)
	jr $ra
	
Draw5:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2268($a0)
	sw $t1, 2404($a0)
	sw $t1, 2400($a0)
	sw $t1, 2396($a0)
	sw $t1, 2532($a0)
	sw $t1, 2652($a0)
	sw $t1, 2656($a0)
	sw $t1, 2660($a0)
	jr $ra
	
Draw6:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2268($a0)
	sw $t1, 2404($a0)
	sw $t1, 2400($a0)
	sw $t1, 2396($a0)
	sw $t1, 2524($a0)
	sw $t1, 2532($a0)
	sw $t1, 2652($a0)
	sw $t1, 2656($a0)
	sw $t1, 2660($a0)
	jr $ra
	
Draw7:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2276($a0)
	sw $t1, 2404($a0)
	sw $t1, 2532($a0)
	sw $t1, 2660($a0)
	jr $ra
	
Draw8:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2268($a0)
	sw $t1, 2276($a0)
	sw $t1, 2404($a0)
	sw $t1, 2400($a0)
	sw $t1, 2396($a0)
	sw $t1, 2524($a0)
	sw $t1, 2532($a0)
	sw $t1, 2652($a0)
	sw $t1, 2656($a0)
	sw $t1, 2660($a0)
	jr $ra

Draw9:
	sw $t1, 2140($a0)
	sw $t1, 2144($a0)
	sw $t1, 2148($a0)
	sw $t1, 2268($a0)
	sw $t1, 2276($a0)
	sw $t1, 2404($a0)
	sw $t1, 2400($a0)
	sw $t1, 2396($a0)
	sw $t1, 2532($a0)
	sw $t1, 2652($a0)
	sw $t1, 2656($a0)
	sw $t1, 2660($a0)
	jr $ra
	
DrawWin:
	add $a0, $gp, $zero
	sw $t1, 2076($a0)
	sw $t1, 2096($a0)
	sw $t1, 2204($a0)
	sw $t1, 2224($a0)
	sw $t1, 2332($a0)
	sw $t1, 2340($a0)
	sw $t1, 2344($a0)
	sw $t1, 2352($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	sw $t1, 2476($a0)
	sw $t1, 2480($a0)
	
	sw $t1, 2104($a0)
	sw $t1, 2232($a0)
	sw $t1, 2360($a0)
	sw $t1, 2488($a0)
	
	add $a0, $a0, 8
	sw $t1, 2104($a0)
	sw $t1, 2108($a0)
	sw $t1, 2124($a0)
	sw $t1, 2232($a0)
	sw $t1, 2240($a0)
	sw $t1, 2252($a0)
	sw $t1, 2360($a0)
	sw $t1, 2372($a0)
	sw $t1, 2380($a0)
	sw $t1, 2488($a0)
	sw $t1, 2504($a0)
	sw $t1, 2508($a0)
	
	add $a0, $a0, -16
	sw $t1, 2152($a0)
	sw $t1, 2280($a0)
	sw $t1, 2408($a0)
	sw $t1, 2664($a0)
	jr $ra
	
DeleteWin:
	lw $t1, bgColor
	add $a0, $gp, $zero
	sw $t1, 2076($a0)
	sw $t1, 2096($a0)
	sw $t1, 2204($a0)
	sw $t1, 2224($a0)
	sw $t1, 2332($a0)
	sw $t1, 2340($a0)
	sw $t1, 2344($a0)
	sw $t1, 2352($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	sw $t1, 2476($a0)
	sw $t1, 2480($a0)
	
	sw $t1, 2104($a0)
	sw $t1, 2232($a0)
	sw $t1, 2360($a0)
	sw $t1, 2488($a0)
	
	add $a0, $a0, 8
	sw $t1, 2104($a0)
	sw $t1, 2108($a0)
	sw $t1, 2124($a0)
	sw $t1, 2232($a0)
	sw $t1, 2240($a0)
	sw $t1, 2252($a0)
	sw $t1, 2360($a0)
	sw $t1, 2372($a0)
	sw $t1, 2380($a0)
	sw $t1, 2488($a0)
	sw $t1, 2504($a0)
	sw $t1, 2508($a0)
	
	add $a0, $a0, -16
	sw $t1, 2152($a0)
	sw $t1, 2280($a0)
	sw $t1, 2408($a0)
	sw $t1, 2664($a0)
	jr $ra
	
DrawWow:
	add $t1, $zero, 0xd9534f
	add $a0, $gp, $zero
	sw $t1, 2076($a0)
	sw $t1, 2096($a0)
	sw $t1, 2204($a0)
	sw $t1, 2224($a0)
	sw $t1, 2332($a0)
	sw $t1, 2340($a0)
	sw $t1, 2344($a0)
	sw $t1, 2352($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	sw $t1, 2476($a0)
	sw $t1, 2480($a0)
	
	sw $t1, 2104($a0)
	sw $t1, 2108($a0)
	sw $t1, 2112($a0)
	sw $t1, 2116($a0)
	sw $t1, 2232($a0)
	sw $t1, 2244($a0)
	sw $t1, 2360($a0)
	sw $t1, 2372($a0)
	sw $t1, 2488($a0)
	sw $t1, 2492($a0)
	sw $t1, 2496($a0)
	sw $t1, 2500($a0)
	
	sw $t1, 2124($a0)
	sw $t1, 2144($a0)
	sw $t1, 2252($a0)
	sw $t1, 2272($a0)
	sw $t1, 2380($a0)
	sw $t1, 2388($a0)
	sw $t1, 2392($a0)
	sw $t1, 2400($a0)
	sw $t1, 2508($a0)
	sw $t1, 2512($a0)
	sw $t1, 2524($a0)
	sw $t1, 2528($a0)
	
	sw $t1, 2152($a0)
	sw $t1, 2280($a0)
	sw $t1, 2408($a0)
	sw $t1, 2664($a0)
	jr $ra
	
DeleteWow:
	lw $t1, bgColor
	add $a0, $gp, $zero
	sw $t1, 2076($a0)
	sw $t1, 2096($a0)
	sw $t1, 2204($a0)
	sw $t1, 2224($a0)
	sw $t1, 2332($a0)
	sw $t1, 2340($a0)
	sw $t1, 2344($a0)
	sw $t1, 2352($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	sw $t1, 2476($a0)
	sw $t1, 2480($a0)
	
	sw $t1, 2104($a0)
	sw $t1, 2108($a0)
	sw $t1, 2112($a0)
	sw $t1, 2116($a0)
	sw $t1, 2232($a0)
	sw $t1, 2244($a0)
	sw $t1, 2360($a0)
	sw $t1, 2372($a0)
	sw $t1, 2488($a0)
	sw $t1, 2492($a0)
	sw $t1, 2496($a0)
	sw $t1, 2500($a0)
	
	sw $t1, 2124($a0)
	sw $t1, 2144($a0)
	sw $t1, 2252($a0)
	sw $t1, 2272($a0)
	sw $t1, 2380($a0)
	sw $t1, 2388($a0)
	sw $t1, 2392($a0)
	sw $t1, 2400($a0)
	sw $t1, 2508($a0)
	sw $t1, 2512($a0)
	sw $t1, 2524($a0)
	sw $t1, 2528($a0)
	
	sw $t1, 2152($a0)
	sw $t1, 2280($a0)
	sw $t1, 2408($a0)
	sw $t1, 2664($a0)
	jr $ra
	
DrawGood:
	add $t1, $zero, 0xd9534f
	add $a0, $gp, $zero
	sw $t1, 2056($a0)
	sw $t1, 2060($a0)
	sw $t1, 2064($a0)
	sw $t1, 2184($a0)
	sw $t1, 2312($a0)
	sw $t1, 2320($a0)
	sw $t1, 2440($a0)
	sw $t1, 2444($a0)
	sw $t1, 2448($a0)
	
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2080($a0)
	sw $t1, 1952($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2208($a0)
	sw $t1, 2080($a0)
	sw $t1, 1952($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2072($a0)
	sw $t1, 1944($a0)
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	jr $ra
	
DeleteGood:
	lw $t1, bgColor
	add $a0, $gp, $zero
	sw $t1, 2056($a0)
	sw $t1, 2060($a0)
	sw $t1, 2064($a0)
	sw $t1, 2184($a0)
	sw $t1, 2312($a0)
	sw $t1, 2320($a0)
	sw $t1, 2440($a0)
	sw $t1, 2444($a0)
	sw $t1, 2448($a0)
	
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2080($a0)
	sw $t1, 1952($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2208($a0)
	sw $t1, 2080($a0)
	sw $t1, 1952($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	
	add $a0, $a0, 16
	sw $t1, 2072($a0)
	sw $t1, 1944($a0)
	sw $t1, 2200($a0)
	sw $t1, 2204($a0)
	sw $t1, 2208($a0)
	sw $t1, 2328($a0)
	sw $t1, 2336($a0)
	sw $t1, 2456($a0)
	sw $t1, 2460($a0)
	sw $t1, 2464($a0)
	jr $ra

Retry:
	lw $t8, 0xffff0000
	bne $t8, 1, Retry
	lw $t7, 0xffff0004
	beq $t7, 0x73, main
	j Retry
	

Exit:
	li $v0, 10 # terminate the program gracefully
