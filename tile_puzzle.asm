#	The MIT License (MIT)
#
#	Copyright (c) 2014 Samuel Babalola
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in
#	all copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#	THE SOFTWARE.
#
#
# File:		$Id$
# Author:	Samuel Babalola
# Contributors:	P. White, W. Carithers, K. Reek
#
# Description: 	This program is a 15 puzzle board game
#				in which the user gets to input the board and then
#				rearranges the number into a sequential board
#
# Revisions:	$Log$


# CONSTANTS
#
# syscall codes
PRINT_INT = 	1
PRINT_STRING = 	4
READ_INT = 	5
EXIT = 		10


	.data

input_array:
	.word 0
#
# Memory for allocating up to 6400 words.
#
next:
	.word	pool
pool:
	.space	25600	# room for the "dynamic" memory allocation
pool_end:		# a marker for the end of the free space
	.word	0

	.align 0

star:
	.asciiz		"*"
newline:
	.asciiz 	"\n"
plus:
	.asciiz 	"+"
dash:
	.asciiz 	"-"
vertical:
	.asciiz 	"|"
space:
	.asciiz		" "
tile_puzzle:
	.asciiz 	"**     Tile Puzzle     **\n"
prompt1:
	.asciiz 	"Enter the size of the board: "

prompt2:
	.asciiz 	"Begin entering the initial values on the tiles.  Start in the upper\nleft corner, and enter the tiles from left - right, top - bottom.\n"

error1:
	.asciiz 	"Error, board size must be greater than one.\n"

error2:
	.asciiz 	"Error, more than one empty spot in the puzzle.\n"

error3:
	.asciiz 	"Error, no empty spot in the puzzle.\n"

error4:
	.asciiz 	"Error, only numbers between -128 and 127 inclusively are acceptable.\n"

new_error:
	.asciiz		"Out of memory during memory allocating.\n"

prompt3:
	.asciiz 	"Enter move (1=up, 2=down, 3=left, 4=right, -1=quit): "

illegal1:
	.asciiz 	"Illegal move, not a legal move value.\n"

illegal2:
	.asciiz 	"Illegal move, no tile can move in that direction.\n"

won_message:
	.asciiz		"**    You have won!    **"

quit_message:
	.asciiz		"\nYou have quit.\n"

	.text					# this is program code
	#printing constant
	.align	2				# instructions must be on word boundaries
	.globl	main			# main is a global label

main:
	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)


	jal 	make_newline

	#print welcome message
	la 		$a0, star
	li 		$a1, 25
	jal 	print_multiple
	jal 	make_newline

	la 		$a0, tile_puzzle
	jal 	print_text

	la 		$a0, star
	li 		$a1, 25
	jal 	print_multiple
	#end welcome message

	#newline
	jal 	make_newline
	jal 	make_newline

	#prompt for size
	la 		$a0, prompt1
	jal 	print_text

	li 		$v0, READ_INT
	syscall
	#end prompt

	#store board size
	move 	$s0, $v0

	#newline
	jal 	make_newline

	#check if size is invalid
	li 		$t1, 2
	slt 	$t0, $s0, $t1
	bne 	$zero, $t0, invalid_board
	#end check

	mult 	$s0, $s0
	mflo 	$t5   			#number of total spots

	#make array
	move 	$a0, $t5
	jal 	allocate_mem
	la 		$t1, input_array
	sw 		$v0, 0($t1)

	#the array
	move 	$t1, $v0



prompt_num:
	#prompt for numbers
	la 		$a0, prompt2
	jal 	print_text

	li 		$t0, 0 			#i = 0
	li 		$t4, 0 			#zero checker
	li 		$a2, 0 			#highest number of digit

enter_numbers_loop:
	beq 	$t0, $t5, enter_done  	#i == n

	li 		$v0, READ_INT 	# read one int
	syscall

	move 	$t2, $v0
	sw 		$t2, 0($t1)

	#check for zero and act
	beq 	$t2, $zero, zero

	#checek the number of digits in a int
	move 	$a0, $t2
	jal 	number_of_digits

	slt 	$t3, $a2, $v0
	bne 	$t3, $zero, change
	j 		enter_numbers_loop_cont

change:
	move 	$a2, $v0

enter_numbers_loop_cont:
	#check if between -128 and 127
	slti 	$t3, $t2, -128
	bne 	$t3, $zero, out_of_limit
	slti 	$t3, $t2, 128
	beq 	$t3, $zero, out_of_limit

	addi 	$t0, $t0, 1
	addi 	$t1, $t1, 4
	j 		enter_numbers_loop


zero:
	bne 	$t4, $zero, excess_zero
	addi 	$t4, $t4, 1
	move	$a3, $t0
	j 		enter_numbers_loop_cont

excess_zero:
	jal 	make_newline

	la		$a0, error2
	jal 	print_text

	#newline
	jal 	make_newline

	j 		main_done

no_zero:
	jal 	make_newline

	la 		$a0, error3
	jal 	print_text

	#newline
	jal 	make_newline

	j 		main_done

out_of_limit:
	jal 	make_newline

	la 		$a0, error4
	jal 	print_text

	#newline
	jal 	make_newline

	j 		main_done

invalid_board:
	la 		$a0, error1
	jal 	print_text

	#newline
	jal 	make_newline

	j 		main_done

enter_done:

	#check for empty spot
	beq 	$t4, $zero, no_zero

	la 		$a0, input_array
	move 	$a1, $s0
	move	$s2, $a2
	move	$s3, $a3


	#print the board

	jal 	print_board

	la 		$a0, input_array
	move 	$a1, $s0
	move	$a2, $s2
	move	$a3, $s3

	jal		play

	j 		main_done


#
# All done -- exit the program!
#
main_done:
  	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr 		$ra


#
# Name:		print_multiple
#
# Description:	prints out a string as much as specified next to each other
#				without spaces
#
# Arguments:	a0 	the address of the string
#				a1	the amount of times to print
#
# Returns:	none
#
print_multiple:
	addi 	$sp, $sp, -4  	# allocate space for the return address
	sw 		$ra, 0($sp)		# store the ra on the stack

	li 		$t8, 0



print_multiple_loop:
	beq 	$t8, $a1, print_multiple_done

	li 		$v0, PRINT_STRING
	syscall

	addi 	$t8, $t8, 1
	j 		print_multiple_loop

print_multiple_done:

	lw 		$ra, 0($sp)
	addi 	$sp, $sp, 4

	jr $ra


#
# Name:		make_newline
#
# Description:	prints out a new line
#
#
# Returns:	none
#
make_newline:
	addi 	$sp, $sp, -4  	# allocate space for the return address
	sw 		$ra, 0($sp)		# store the ra on the stack

	la 		$a0, newline
	li 		$v0, PRINT_STRING
	syscall

	lw 		$ra, 0($sp)
	addi 	$sp, $sp, 4

	jr 		$ra

#
# Name:		print_text
#
# Description:	prints a string
#
# Arguments:	a0 the address of the string
#
# Returns:	none
#
print_text:
	addi 	$sp, $sp, -4  	# allocate space for the return address
	sw 		$ra, 0($sp)		# store the ra on the stack

	li 		$v0, PRINT_STRING
	syscall

	lw 		$ra, 0($sp)
	addi 	$sp, $sp, 4

	jr 		$ra

#
# Name:		print_board
#
# Description:	prints the puzzle in a formatted manner
#
# Arguments:	a0 	the address of the location which contains the
#		   			root pointer of the array
#				a1	size of the array
#				a2  highest digit
#				a3  zero spot
#
# Returns:	none
#

print_board:
	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)


	move 	$s0, $a0		# s0 is pointer to array
	move 	$s1, $a1		# s1 size of the board
	move 	$s2, $a2		# s2 highest digit
	move 	$s3, $a3		# s3 zero location

	jal		make_newline
	move 	$a0, $s1
	move	$a1, $s2
	jal 	stars_line

	lw 		$s0, 0($s0)
	li 		$t0, 0			# i=0;
	mult 	$s1, $s1
	mflo 	$s4

print_board_loop:

	beq 	$t0, $s4, print_board_done	# done if i==n


	addi 	$t4, $t0, 1
	div 	$t4, $s1
	mfhi 	$t4

	li 		$t5, 1
	beq 	$t4, $t5, first
	beq		$t4, $zero, last
	j		middle


print_board_loop_done:
	addi 	$s0, $s0, 4		# update pointer
	addi 	$t0, $t0, 1		# and count
	j 		print_board_loop

negate:
	li		$t8, 1
	j		first_cont

first:
	slt		$t8, $t0, $s3
	beq		$t0, $s3, negate
first_cont:
	add		$t6, $t0, $s1
	slt		$t6, $s3, $t6
	and		$t6, $t6, $t8
	bne		$t6, $zero, disappear



	li		$a2, -1
	move	$t9, $a2

first_appear:
	move 	$a0, $s2
	move 	$a1, $s1

	jal		next_line

	la 		$a0, star
	jal 	print_text

	lw 		$a0, 0($s0)
	move 	$a1, $s2
	jal		actual_number

	j 		print_board_loop_done

last:

	lw 		$a0, 0($s0)
	move 	$a1, $s2

	jal		actual_number

	la		$a0, star
	jal 	print_text

	jal		make_newline

	move 	$a0, $s2
	move 	$a1, $s1

	move	$a2, $t9
	jal		next_line

	li		$t9, -2

	j 		print_board_loop_done

middle:
	lw 		$a0, 0($s0)
	move 	$a1, $s2
	jal 	actual_number

	j 		print_board_loop_done

print_board_done:

	move 	$a0, $s1
	move	$a1, $s2
	jal 	stars_line


	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr 		$ra

disappear:
	div 	$s3, $s1
	mfhi 	$a2
	move	$t9, $a2
	j		first_appear


#
# Name:		actual_number
#
# Description:	prints the number in the puzzle in a formatted manner, with the appropriate number of spacing e.g | 2 |
#
# Arguments:	a0 	number
# 				a1	highest digit
#
# Returns:	none
#

actual_number:
	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)


	move 	$s0, $a0
	move 	$s1, $a1

	beq		$s0, $zero, empty_space1

	la 		$a0, vertical
	jal 	print_text

	move 	$a0, $s0
	jal		number_of_digits

	addi	$s1, $s1, 1
	sub		$a1, $s1, $v0
	la		$a0, space
	jal		print_multiple

	move 	$a0, $s0
	li 		$v0, PRINT_INT
	syscall

	la 		$a0, space
	jal		print_text
	la 		$a0, vertical
	jal 	print_text

actual_number_done:
	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr 		$ra

empty_space1:
	addi	$a1, $s1, 4
	la		$a0, space
	jal		print_multiple
	j		actual_number_done

#
# Name:		next_line
#
# Description:	prints the line between the different number lines. e.g *+---++---+*
#
# Arguments:	a0 	highest digit
#				a1	size of board
#				a2	zero location
#
# Returns:	none
#

next_line:
	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)


	move	$s2, $a0
	move	$s1, $a1
	move 	$s3, $a2

	la		$a0, star
	jal 	print_text
	li 		$t5, 0

next_line_loop:
	beq 	$t5, $s1, next_line_back
	beq		$t5, $s3, empty_space2

	la		$a0, plus
	jal 	print_text

	la		$a0, dash
	addi	$a1, $s2, 2
	jal		print_multiple

	la		$a0, plus
	jal 	print_text

next_line_loop_next:
	addi	$t5, $t5, 1
	j 		next_line_loop

next_line_back:
	la		$a0, star
	jal 	print_text
	jal 	make_newline

	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr 		$ra

empty_space2:
	addi	$a1, $s2, 4
	la		$a0, space
	jal		print_multiple
	j		next_line_loop_next

#
# Name:		stars_line
#
# Description:	prints the appropriate number of stars required by the
#				beginning and ending line of the formatted board
#
# Arguments:	a0 	size of board
# 				a1	highest digit
#
# Returns:	none
#


stars_line:
	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)


	move	$s1, $a0
	move 	$s2, $a1

	#number of stars
	addi 	$t2, $s2, 2
	mult 	$t2, $s1
	mflo 	$t2
	addi 	$t2, $t2, 2
	li		$t3, 2
	mult	$t3, $s1
	mflo 	$t3
	add 	$t2, $t3, $t2

	la 		$a0, star
	move 	$a1, $t2

	jal 	print_multiple
	jal 	make_newline		# print a new_line

	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr 		$ra

#
# Name:		number_of_digits
#
# Description:	Checks the number of digits in a number and negative counts
#				as an extra digit
#
# Arguments:	a0 	the integer
#
# Returns:	v0 the number of digits
#

number_of_digits:
	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)


	#find highest digits
	li 		$t7, 10
	li 		$t8, 100
	li 		$v0, 0
	li 		$t6, 0
	slt 	$t3, $a0, $zero
	bne 	$t3, $zero, negative


more_zero:
	slt 	$t3, $t7, $a0
	bne 	$zero, $t3, more_nine
	li 		$v0, 1
	j 		number_of_digits_done

more_nine:
	slt 	$t3, $t8, $a0
	bne 	$zero, $t3, more_ninety_nine
	li 		$v0, 2
	j 		number_of_digits_done


more_ninety_nine:
	li 		$v0, 3
	j 		number_of_digits_done

negative:
	li 		$t3, -1
	mult 	$t3, $a0
	mflo 	$a0
	addi 	$t6, $t6, 1
	j 		more_zero

number_of_digits_done:
	add 	$v0, $v0, $t6

	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr 		$ra


#
# Name:		allocate_mem:
#
# Description:	Allocate space from the pool of free memory.
#
# Arguments:	a0: the number of words to allocate
# Returns:	v0: the address of the newly allocated memory.
#

allocate_mem:
	#
	# See if there is any space left in the pool.
	#

	lw	$t0, next	# pointer to next available byte
	li	$t9, 4		# calculate number of bytes to allocate
	mult	$a0, $t9
	mflo	$t9
	add	$t8, $t0, $t9	# figure out where next would be if we
				# allocate the space
	la	$t1, pool_end

	slt	$t2, $t8, $t1	# Compare next addr to end of pool
	bne	$t2, $zero, new_mem_ok	#  if less then still have space

	#
	# No space left; write error message and exit.
	#

	li 	$v0, PRINT_STRING	# print error message
	la 	$a0, new_error
	syscall

	li 	$v0, EXIT		# terminate program
	syscall

new_mem_ok:
	#
	# There is space available.  Allocate the next chunk of mem
	#

	move	$v0, $t0	# set up to return spot for new mem block
	li	$t9, 4		# calculate number of bytes to allocate
	mult	$a0, $t9
	mflo	$t9
	add	$t0, $t0, $t9	# Adjust pointer for the allocated space
	sw	$t0, next

	jr	$ra

#
# Name:		play
#
# Description:	Play a Game.
#
# Arguments:	a0: the pointer to the array
#				a1: length of the array
#				a2: highest digit
#				a3: zero location

# Returns:	none.
#



play:

	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)



	move 	$s0, $a0
	move 	$s1, $a1
	move 	$s2, $a2
	move 	$s3, $a3

	move	$a0, $s0
	move	$a1, $s1
	move	$a2, $s3
	jal		check
	bne		$v0, $zero, won_game

play_loop:

	jal		make_newline


	la		$a0, prompt3
	jal		print_text

	li		$v0, READ_INT
	syscall

	move	$s4, $v0

	li		$t0, -2
	slt		$t0, $t0, $s4
	li		$t1, 5
	slt		$t1, $s4, $t1
	and		$t1, $t1, $t0
	beq		$t1, $zero, wrong_input

	li		$t0, -1
	beq		$s4, $t0, quit

	move 	$a0, $s0
	move 	$a1, $s1
	move 	$a2, $s3
	move 	$a3, $s4
	jal		swap
	li		$t0, -2
	beq		$v0, $t0, invalid_move
	move	$s3, $v0


	move 	$a0, $s0
	move 	$a1, $s1
	move 	$a2, $s2
	move 	$a3, $s3
	jal		print_board

	move	$a0, $s0
	move	$a1, $s1
	move	$a2, $s3
	jal		check
	bne		$v0, $zero, won_game

	j 		play_loop

wrong_input:
	jal		make_newline
	la 		$a0, illegal1
	jal 	print_text
	j		play_loop

invalid_move:
	jal		make_newline

	la 		$a0, illegal2
	jal 	print_text
	j		play_loop

quit:
	la 		$a0, quit_message
	jal 	print_text
	j		play_done


won_game:
	jal		make_newline
	la		$a0, star
	li		$a1, 25
	jal 	print_multiple
	jal		make_newline
	la 		$a0, won_message
	jal 	print_text
	jal		make_newline
	la		$a0, star
	li		$a1, 25
	jal 	print_multiple

	jal		make_newline

	j		play_done

play_done:
  	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr 		$ra
#
# Name:		check
#
# Description:	Checks if the board is fully arranged or not
#
# Arguments:	a0: the pointer to the array
#				a1: length of the array
#				a2: zero location

# Returns:		v0: 0- not winning state 1- winning state
#

check:
	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)

	move 	$s0, $a0
	move 	$s1, $a1
	move 	$s2, $a2

	mult	$s1,$s1
	mflo	$s1
	addi	$s1, $s1, -1


	bne		$s2, $s1, not_winning

	lw		$s0, 0($s0)
	li		$t0, 0

check_loop:
	beq		$t0, $s1, winning

	beq		$t0, $zero, first_check

	lw		$t2, 0($s0)

	li		$t4, 0
	slt		$t3, $t1, $t2
	beq		$t2, $t1, check_equals

check_cont:
	or		$t3, $t3, $t4
	beq		$t3, $zero, not_winning

	lw		$t1, 0($s0)

check_loop_done:
	addi	$t0, $t0, 1
	addi	$s0, $s0, 4
	j		check_loop

first_check:
	lw		$t1, 0($s0)
	j 		check_loop_done

check_equals:
	li		$t4, 1
	j		check_cont

not_winning:
	li		$v0, 0
	j		check_done

winning:
	li		$v0, 1
	j		check_done


check_done:
	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

	jr $ra

#
# Name:		swap
#
# Description:	Moves the tile to the specified location based on the direction
#				specified
#
# Arguments:	a0: the pointer to the array
#				a1:	length of the row or column
#				a2: zero location
#				a3: direction (1=up, 2=down, 3=left, 4=right)

# Returns:		v0: the new zero location, negative value for error.
#


swap:

	addi    $sp,$sp,-40     # allocate stack frame (on doubleword boundary)
    sw      $ra, 32($sp)    # store the ra & s reg's on the stack
    sw      $s7, 28($sp)
    sw      $s6, 24($sp)
    sw      $s5, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)

	move 	$s0, $a0
	move 	$s1, $a1
	move 	$s2, $a2
	move 	$s3, $a3

	li 		$t0, 1
	beq		$s3, $t0, up
	li 		$t0, 2
	beq		$s3, $t0, down
	li 		$t0, 3
	beq		$s3, $t0, left
	li 		$t0, 4
	beq		$s3, $t0, right


down:
	sub		$t0, $s2, $s1
	slt		$t1, $t0, $zero
	bne		$t1, $zero, error
	j		swap_change


up:
	add		$t0, $s2, $s1

	mult	$s1, $s1
	mflo	$t2

	slt		$t1, $t0, $t2
	beq		$t1, $zero, error
	j		swap_change


right:

	div		$s2, $s1
	mfhi	$t0

	addi	$t0, $t0, -1

	slt		$t1, $t0, $zero
	bne		$t1, $zero, error
	addi	$t0, $s2, -1
	j		swap_change

left:

	div		$s2, $s1
	mfhi	$t0

	addi	$t0, $t0, 1

	slt		$t1, $t0, $s1
	beq		$t1, $zero, error
	addi	$t0, $s2, 1
	j		swap_change

error:
	li 		$v0, -2
	j		swap_done

swap_change:
	lw		$t2, 0($s0)

	li		$t9, 4
	mult	$t0, $t9
	mflo	$t9

	add		$t3, $t2, $t9

	lw		$t4, 0($t3)

	li		$t9, 0
	sw		$t9, 0($t3)

	lw		$t2, 0($s0)

	li		$t9, 4
	mult	$s2, $t9
	mflo	$t9

	add		$t3, $t2, $t9

	sw		$t4, 0($t3)

	move	$v0, $t0


swap_done:

	lw      $ra, 32($sp)    # restore the ra & s reg's from the stack
    lw      $s7, 28($sp)
    lw      $s6, 24($sp)
    lw      $s5, 20($sp)
    lw      $s4, 16($sp)
    lw      $s3, 12($sp)
    lw      $s2, 8($sp)
    lw      $s1, 4($sp)
    lw      $s0, 0($sp)
    addi    $sp,$sp,40      # clean up stack

    jr		$ra

#***** END OF PROGRAM *****************************

