#Input int alma $v0, 5
#Aldigin inputu kenarda sakla kapatmadan once
.data 
	mesaj: .asciiz "please enter a number: "

.text
.globl main

main:
	jal take_input
	li $v0, 5
	syscall
	
	addi $t0,$v0,0
	
	jal take_input
	li $v0, 5
	syscall

	add $t0,$t0,$v0
	jal output
	
	li $v0, 10
	syscall
	
take_input:
	li $v0, 4
	la $a0,mesaj
	syscall
	
	jr $ra

output:
	li $v0, 1
	addi $a0, $t0,0
	syscall
	jr $ra
	
	 

