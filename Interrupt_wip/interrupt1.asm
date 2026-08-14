#Burda interrupt ogrenicez 
#$12 status dedigi interrupt enable disable 
#$13 cause interruptin nerden geldigi
#$14 epc Exception Program Counter bu da interrupt sonrasi donme addresi
#caproc1 floating numbersla alakali

#0xFFFF0000 addresi 2. biti interrupt enable, 1. biti ready
#0xFFFF0004 addresi data 
#.ktext 0x80000180 Kernelde interrupt islemi yapildiginda direkt bunu yap sonra geri git demek yani pollingle ugrasma

.text
.globl main
main:
   #Config ayarlari
   #burda FFFF0000 addresini tamamen degistirmemek onemli o yuzden registerda islemlerimi yapicam
   li $t0,0xFFFF0000
   lw $t1,0($t0) #lw $t1,0xFFFF0000 yapamiyoruz bit kalmiyo
   ori $t1,$t1,0x0002  #ikinci bit 0010 
   sw $t1,0($t0)
   
idle:
	b idle

.ktext 0x80000180
	#push popa simdilik gerek yok ama normalde onemli
	li $t0,0xFFFF0004
	lw $a0,0($t0) #a0 bastirmada kullancagimiz register
	
	li $v0, 11 #print chracter
	syscall
	#not: burda addi $v0,10 yapmiyoruz yoksa direkt program kapanir eret ile donuyoruz
	eret #exception return
	
	
	
