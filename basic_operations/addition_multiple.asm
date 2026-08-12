#Input int alma $v0, 5
#Aldigin inputu kenarda sakla kapatmadan once
.data 
	mesaj_devam: .asciiz "Press 1 to enter a number: "
	mesaj: .asciiz "please enter a number: "
	finish: .asciiz "the sum of them are: "

.text
#t0 = addition

.globl main
main:
	li $t0,0
	li $t5,1
	jal ask_user


ask_user:
	li $v0,4 #Mesaji gosterdim
	la $a0,mesaj_devam
	syscall
	
	li $v0,5  #input aldim devam icin
	syscall
	add $t1,$zero,$v0
	
	beq $t1,$t5,one
	j end
	
one:
	jal take_input
	bne $t1,$zero,ask_user
	
take_input:
	li $v0,4
	la $a0, mesaj 
	syscall

	li $v0,5
	syscall
	add $t0,$t0,$v0
	jr $ra
	
end:
	li $v0,4
	la $a0, finish
	syscall
	
	add $a0,$t0,$zero
	li $v0,1
	syscall
	
	li $v0,10
	syscall
	 

