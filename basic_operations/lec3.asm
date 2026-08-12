
.globl main

main:
	li, $t1, 5
	li,$t2, 6
	#slt $t3,$t1,$t2 if t1 less than t2, set t3 to 1, sltu(set less than unsigned)
	slt  $t3,$t1,$t2
	bne $t3,$zero,t1_greater
	slti $t4,$t1,7 	#eger t1 kucukse 7den, t4e 1 yaz 	
	
	li $v0,10
	syscall
	
t1_greater: #Burda if (t2<t1) islemi yaptik
	li $t5,1
	li $v0,10
	syscall
	