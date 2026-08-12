
.globl main
 
 main:
 	li $t1,18 #Bolunen
 	li $t2,4 #Bolen
 	li $t3,0 #Bolum, bunu surekli 1 arttircaz

 
 division:
 	slt $t4, $t1,$t2
 	bne $t4,$zero, end
 	
 	sub $t1,$t1,$t2
 	addi $t3, $t3,1
 	j division
 	
 end:
 	li $v0,10
 	syscall
 	#t1 kalan
 	#t3 bolum