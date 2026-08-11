.data
tile_do: .asciiz "Hedef: DO  (Tus: 1)\n"
tile_re: .asciiz "Hedef: RE  (Tus: 2)\n"
tile_mi: .asciiz "Hedef: MI  (Tus: 3)\n"
notes: .word tile_do, tile_re, tile_mi, tile_do
are_you_ready: .asciiz "Are you reaaaaady??????\n"
lets_go: .asciiz "LETS GO\n"

#ARRAYDAN NEXT NOTAYI CAL
#ZAMAN ARALIGI BELIRLE(HEDEF - SIMDIKI)

#DONGU:
	#KLAVYEYE BASILDIYSA CAL
	#TUSA BASILMADIYSA VE ARALIK SURESI DOLMADIYSA DONGU, DOLDUYSA DONGUDEN CIK



.text
.globl main
 
 main:
 	la $a0,are_you_ready
 	li $v0,4
 	syscall
 	li $v0,32
 	li $a0,2500
 	syscall
 	
 	la $a0,lets_go
 	li $v0,4
 	syscall
 	li $v0,32
 	li $a0,500
 	syscall

 	
 	lui $t0, 0xFFFF
 	la $s0,notes
 	li $s1,4
 	li $s2,0
 
 game:
 	beq $s1,$s2,end
 	#Notayi ekrana bas
 	lw $a0,0($s0)
 	li $v0,4
 	syscall
 	
 	#Aralik koy
 	li $v0,30 #sistem saatini $a0 a ver
 	syscall
 	add $t8, $a0,1500 #Bitis suresi t8 de
 
 keyboard:
 	lw $t1,0($t0)
 	andi $t1,$t1,1
 	beq $t1,$zero,timer #BURASI COKOMELLI EGER TUSA BASILMADIYSA CHECK TIME
 	#TUSA BASILDIYSA
 	lw $t2,4($t0) #Ekran dinleyicinin hemen sonrasinda ASCIIsi vardi ya yazan
 	beq $t2, 49, note_do   
	beq $t2, 50, note_re   
	beq $t2, 51, note_mi 
 	
 	j timer
 	
 
 timer:
 	li $v0,30 #sistem saatini $a0 a ver
 	syscall
 	
 	bge $a0,$t8,next_tile #Belirli sure dolduysa diger tilea gec
 	j keyboard #Eger dolmamissa tusa basildi mi diye geri git
 
 next_tile:
 	addi $s0,$s0,4
 	addi $s2,$s2,1
 	
 	j game
 
note_do:
	li $a0, 60
	j play_note
note_re:
	li $a0, 62
	j play_note
note_mi:
	li $a0, 64
	j play_note
	
play_note:
	li $v0, 31       
	li $a1, 1500      
	li $a2, 24       
	li $a3, 100      
	syscall
 
 	j timer
 end:
 	li $v0,10
 	syscall


 	
 	