#if instruction
.data 
message_t0_greater: .asciiz  "t0 is greater than t1"
message_t1_greater: .asciiz  "t0 is greater than t1"

.text
.globl main

main:	
	li $t0,7
	li $t1,6
	# if (t0 > t1): t3 = 1 else t3 = 2
	sgt $s0, $t0,$t1 
	bne $s0, $zero, t0_greater
	
	li $v0,4
	la $a0, message_t1_greater
	syscall
	
	j end
	
t0_greater:
	li $v0,4
	la $a0,message_t0_greater
	syscall
	
	j end

end:
	li $v0,10
	syscall
	 
	
	
