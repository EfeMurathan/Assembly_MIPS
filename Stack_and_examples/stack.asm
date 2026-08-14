#Stack yapisinda asagiya dogru yer ac = addi $sp,$sp,-4
#Ondan sonra orayi kullanabilirsin sw $ra, 0($sp) burasi sunu yapiyo $ra yi yeni actigin yere koyuyo
#jal yap
#Geri geldiginde artik yuklemen lazim bunu
#lw $ra,0($sp) ra yi artik yukluyorum memoryden
#addi $sp,$sp,4 ile bi sonraki kullanima hazirliyorum
#jr $ra ile gidebilirim artik

.globl main

main:
	jal first
	
	li $v0,10
	syscall
	
first:
	addi $sp,$sp,-4
	sw $ra, 0($sp)
	li $t1,1
	
	jal second
	
	lw $ra, 0($sp)
	addi $sp,$sp,4	
	jr $ra
	
second:
	addi $sp,$sp,-4
	sw $ra, 0($sp)
	li $t2,1
	
	jal third
	
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
third:
	li $t3,1
	jr $ra
	
	
	