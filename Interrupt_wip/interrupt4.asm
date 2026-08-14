
.data 
.eqv bosluk 32
tile_do: .asciiz "Hedef: DO  (Tus: 1)\n"
tile_re: .asciiz "Hedef: RE  (Tus: 2)\n"
tile_mi: .asciiz "Hedef: MI  (Tus: 3)\n"
notes: .word tile_do, tile_re, tile_mi, tile_do

.text
.globl main

main:
	#config
	li $t0,0xFFFF0000
	lw $t1,0($t0)
	ori $t1,$t1,0x0002
	sw $t1,0($t0)
	
	li $s0,0 #sayac
	li $t4,0 #puan 
	la $t5,notes
	li $t6,0 #baslangic
	li $t7,4 #bitis
	li $t3,0


ekrana_yaz:
	beq $t7,$t6, end
	li $s0,0
	li $v0,4 #11 sadece bi harf 4 cumle icin
	lw $a0,0($t5)
	addi $t5,$t5,4
	addi $t6,$t6,1
	syscall
		
uyut:
	li $v0,32 
	li $a0,50 
	syscall
	add $s0,$s0,1
	bne $s0,20,uyut
	j ekrana_yaz
	
end:
	b end
	
.ktext 0x80000180 
    # 1. PUSH (7 Register için tam 28 byte yer aç)
    subi $sp, $sp, 28   
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $a0, 8($sp)
    sw $a1, 12($sp)
    sw $a2, 16($sp)
    sw $a3, 20($sp)
    sw $v0, 24($sp)

    # 2. Okuma
    li $t0, 0xFFFF0004
    lw $t1, 0($t0)
    
    # 3. Dallanma
    beq $t1, 49, cal_do
    beq $t1, 50, cal_re
    beq $t1, 51, cal_mi
    beq $t1, 52, cal_fa
    j interrupt_end
    
cal_do:
    li $a0, 60         
    j ses_cal           

cal_re:
    li $a0, 62        
    j ses_cal

cal_mi:
    li $a0, 64         
    j ses_cal

cal_fa:
    li $a0, 65          
    j ses_cal
 
ses_cal:                # ETİKET İSMİ DÜZELTİLDİ
    li $v0, 31          # MIDI çalma komutu
    li $a1, 1500         # Süre: 500 milisaniye
    li $a2, 0           # Enstrüman: 0 (Akustik Piyano)
    li $a3, 100         # Ses seviyesi: 100 (Max 127)
    syscall

interrupt_end:
    # 4. POP (7 Register'ı geri yükle ve Stack'i kapat)
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $a0, 8($sp)
    lw $a1, 12($sp)
    lw $a2, 16($sp)
    lw $a3, 20($sp)
    lw $v0, 24($sp)
    addi $sp, $sp, 28   
    
    eret
	
			
	