#while loop
.data
save: .word 10, 10, 10, 15, 20

.text
.globl main

main:
	#while save[i] == k;  i++  i is in $s3, k in $s5 , address is in $s6
	li $s3, 0 #Bu i 
	li $s5, 10
	la $s6,save #arrayin addressi
	add $t1,$zero,$s6
	
while_loop:
	lw $t0,0($s6)
	bne $t0,$s5,end
	addi $s3,$s3,1
	addi $s6,$s6,4

	j while_loop
	
end:
	add $s6,$zero,$t1
	li $v0,10
	syscall
	
	
	
	  