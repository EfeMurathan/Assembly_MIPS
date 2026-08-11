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
	lw $t1, 0($t0) #Syntax hatasi yuzunden 0 offset kullandim BIDE t0 DEGERI DEGISMESIN
	#Simdi burda t1deki least significant biti almam lazim 
	#1 ile bitwise and yaparsam 1010....10111101 and  00000000..01 sana sadece sonuncuyu verir
	andi $t1, $t1, 1
	beq $t1, $zero,check #eger basilmamissa bi seye basa don
	
	#Eger tusa basildiysa basilan degeri 0xFFFF0004de oku
	lw $t2,4($t0)
	beq $t2, 49, do_note
	beq $t2, 50, re_note
	beq $t2, 51, mi_note
	beq $t2, 52, fa_note
	beq $t2, 53, sol_note
	beq $t2, 54, la_note
	beq $t2, 55, si_note
	beq $t2, 56, do_minor_note
	beq $t2, 57, re_minor_note
	
	j check

do_note:
	li $a0, 60 # Orta Do notası (60)
	j play
re_note:
	li $a0, 62 # Orta Do notası (60)
	j play
mi_note:
	li $a0, 64 # Orta Do notası (60)
	j play
fa_note:
	li $a0, 65 # Orta Do notası (60)
	j play
sol_note:
	li $a0, 67 # Orta Do notası (60)
	j play
la_note:
	li $a0, 69 # Orta Do notası (60)
	j play
si_note:
	li $a0, 71 # Orta Do notası (60)
	j play
do_minor_note:
	li $a0, 72 # Orta Do notası (60)
	j play
re_minor_note:
	li $a0, 74 # Orta Do notası (60)
	j play

	
play:
	li $v0, 31 # 31 ses çal ama asekron yoksa donuyo program
   	li $a1, 5000# 5000 milisaniye çal
    	li $a2,24 # Akustik Piyano
	li $a3, 100# Ses seviyesi
 	syscall	
    	j check
