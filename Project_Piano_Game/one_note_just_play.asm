.text
#Not klavye girdisi oxFFFF0000de tutuluyomus, eger klavyeye basilirsa 1 yoksa 0
#Not eger FFFF0000 1 ise asil tutulan sey FFFF0004 de tutulur ascii olarak

.globl main

main:
	lui $t0, 0xFFFF #simdi burda lui ile geri kalani 0 ile doldurcam ve FFFF0000 adresine gidebilicem
	#t0 = Klavye girdi
	#t1 = 1 mi 0 mi
	#t2 = ASCII 
	
check:
	#surekli calismasin diye sleep koydum
	li $v0,32
	li $a0,5
	syscall
	
	lw $t1, 0($t0) #Syntax hatasi yuzunden 0 offset kullandim
	#Simdi burda t1deki least significant biti almam lazim 
	#1 ile bitwise and yaparsam 1010....10111101 and  00000000..01 sana sadece sonuncuyu verir
	andi $t1, $t1, 1
	beq $t1, $zero,check #eger basilmamissa bi seye basa don
	
	#Eger tusa basildiysa basilan degeri 0xFFFF0004de oku
	lw $t2,4($t0)
	beq $t2, 49, do_note
	
	j check

do_note: 
	li $v0, 33              # Syscall 33: Ses çal
    	li $a0, 60              # Orta Do notası (60)
    	li $a1, 500             # 500 milisaniye çal (Yarım saniye)
    	li $a2, 0               # Akustik Piyano
    	li $a3, 100             # Ses seviyesi
    	syscall
    	
    	j check
	
	
	
	
	 
	
	


	
	