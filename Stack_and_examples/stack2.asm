#Burda da stacke veri atip alicam
#$s1 de degerli bi sayi var, 2 tane islem yapicaz ve bastaki sayiyi geri koyucaz
 

.globl main

main:
	li $s0,100
	jal calc
	
	li $v0,1
	add $a0,$zero,$t1
	syscall
	 
	li $v0,10
	syscall

calc: 
	#Burda bisi yapilmiycak diger adrese gidilcek ve geri iki kez atlama olucagi icin $ra yi da savelemek lazim
	#2 tane sayi var, ikisi de 4 byte stackde yer ayirt
	
	addi $sp,$sp,-8
	sw $s0, 0($sp) #stackde en altta s1 ustunde is ra var
	sw $ra, 4($sp)
	addi $s0,$zero,5 #artik s1 i kullanabilirim cunku yedegi stackde var
	
	jal take_double
	
	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp,$sp,8 #stack pointeri geri dondurelim
	jr $ra 
	
take_double:
	sll $t1,$s0,1  #add $s1,$s1,$s1	
	jr $ra
	
	
	
	
	
	
