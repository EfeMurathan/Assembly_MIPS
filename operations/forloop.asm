#for loop
.data

message_for_aysenur: .asciiz "malsinkine\n"
.text
.globl main

main:
	#for i = 0; i<=5;i++: display message
	li $t0,0
	li $t1,5
	
	jal for_loop
	
	li $v0,10
	syscall

for_loop:
	beq $t0,$t1,end
	li $v0,4
	la $a0,message_for_aysenur
	syscall
	
	addi $t0,$t0,1
	j for_loop
	
end:
	jr $ra
	
	
	
