#Bu kodda interrrupti surekli yaparsan yani sye surekli basili tutarsan patlar
.eqv T_harf 84
.eqv bosluk 32
.text
.globl main
#s1 karsilastirma registeri 
#t3 ara eleman
#t4 puan registeri 
main:
	#config
	li $t0,0xFFFF0000
	lw $t1,0($t0)
	ori $t1,$t1,0x0002
	sw $t1,0($t0)
	
	li $s0,0 #s0 sayac tutsun
	li $t4,0 #puan

play:
	li $s0,0
	
	li $v0,11
	li $s1,T_harf
	li $a0,T_harf
	syscall
	li $a0,bosluk
	syscall 
	

		
	#simdi burda normalde 1000 uyutma yerine 50 kez 20 uyutma yapicaz ki araya interrupt kolay girsin
uyut:
	li $v0,32
	li $a0,50 #coook kucuk bi alanda 
	syscall
	add $s0,$s0,1 # 20 kez yaptircam
	bne $s0,20,uyut
	
	b play


.ktext 0x80000180 
    # PUSH 
    subi $sp, $sp, 20
    sw $t0, 0($sp)
    sw $a0, 4($sp)
    sw $v0, 8($sp)
    sw $t2, 12($sp)
    sw $t3, 20($sp)
    
    #okuma
    li $t0, 0xFFFF0004
    lw $a0, 0($t0)
    
    li $t2,T_harf
    
    seq $t3,$a0,$t2
    add $t4,$t4,$t3
    
    li $v0, 11
    syscall
    
    # POP
    lw $t0, 0($sp)
    lw $a0, 4($sp)
    lw $v0, 8($sp)
    lw $t2, 12($sp)
    sw $t3, 16($sp)
    addi $sp, $sp, 20
    
    eret

		
