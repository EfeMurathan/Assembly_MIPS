#diyelim ki 3 ve 6 aldin bu iki sayi arasindaki butun sayilari topla

.globl main
main:
	li,$t1,3
	li,$t2,6
	li $t3,0 #Buraya toplami koyucam
	j add_between
	
add_between:
	add $t3,$t3,$t1
	addi $t1,$t1,1
	
	sle $t5,$t1,$t2
	beq $t5,$zero,end
	j add_between
	
end: 
	li $v0,10
	syscall
	
	