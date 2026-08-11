.data
do_note_h: .asciiz "Do\n"
re_note_h: .asciiz "Re\n"
mi_note_h: .asciiz "Mi\n"
do_note: .asciiz "Do uzun\n"
re_note: .asciiz "Re uzun\n"
mi_note: .asciiz "Mi uzun\n"

	notes: .word do_note_h, re_note_h, mi_note_h, do_note, re_note, mi_note

.text
.globl main

main:
	la $s0,notes
	jal play_do_half
	jal play_re_half      
	jal play_mi_half      
	jal play_do
	jal play_re
	jal play_mi
	
	li $v0,10
	syscall
	

		
######################################

play_do_half:
	lw $a0, 0($s0)
	li $v0,4
	syscall
	
	li $v0,32
	li $a0, 400
	syscall
	
	jr $ra

play_re_half:
	lw $a0, 4($s0)
	li $v0,4
	syscall
	
	li $v0,32
	li $a0, 400
	syscall

	jr $ra
play_mi_half:
	lw $a0, 8($s0)
	li $v0,4
	syscall
	
	li $v0,32
	li $a0, 400
	syscall

	jr $ra
play_do:
	lw $a0, 12($s0)
	li $v0,4
	syscall
	
	li $v0,32
	li $a0, 800
	syscall

	jr $ra
play_re:
	lw $a0, 16($s0)
	li $v0,4
	syscall
	
	li $v0,32
	li $a0, 800
	syscall
	
	jr $ra
play_mi:
	lw $a0, 20($s0)
	li $v0,4
	syscall
	
	li $v0,32
	li $a0, 800
	syscall
	
	jr $ra

	
