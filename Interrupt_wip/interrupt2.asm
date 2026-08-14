#timer diye bi interrrupt marsda yokmus 
.eqv Tharf 84

.text
.globl main

main:
	#config interrupt enable
	li $t0,0xFFFF0000
	lw $t1,0($t0)
	ori $t1,$t1,0x0002 #0010
	sw $t1,0($t0)
	
	
printT:
	li $v0, 11
	li $a0, Tharf
	syscall
	
	li $a0, 32 #bosluk
	syscall
		
#systemi uyutucam simdi
uyut:
	li $v0,32
	li $a0,50 #uyutma islemini cok yapmamak onemli kasiyomus gibi oluyo
	syscall
	b printT

.ktext 0x80000180 #interrupt gelirse
	#PUSH $t0 $a0 $v0
	subi $sp, $sp, 12
	sw $t0, 0($sp)
	sw $a0, 4($sp)
	sw $v0, 8($sp)
	
	li $t0, 0xFFFF0004
	lw $a0,0($t0)
	
	li $v0,11
	syscall
	
	
	#POP
	lw $t0, 0($sp)
	lw $a0, 4($sp)
	lw $v0, 8($sp)
	addi $sp, $sp, 12
	
	eret




