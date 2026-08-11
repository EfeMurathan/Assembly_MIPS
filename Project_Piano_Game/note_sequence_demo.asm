.data 
.eqv bosluk 32
tile_do: .asciiz "Hedef: DO  (Tus: 1)\n"
tile_re: .asciiz "Hedef: RE  (Tus: 2)\n"
tile_mi: .asciiz "Hedef: MI  (Tus: 3)\n"
notes: .word tile_do, tile_re, tile_mi, tile_do
expected_keys: .word 49, 50, 51, 49
hazirlik_mesaji: .asciiz "\n--- OYUN HAZIR ---\nBaslamak icin 'r' tusuna basin...\n\n"
puan_mesaji: .asciiz "\n--- OYUN BITTI ---\nPuaniniz: "
puan_son: .asciiz " / 4\n"

.text
.globl main
main:
    la $a0, hazirlik_mesaji
    li $v0, 4
    syscall

    li $t0, 0xFFFF0000

wait_to_start:
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beq $t1, $zero, wait_to_start
    lw $t2, 4($t0)
    bne $t2, 114, wait_to_start

    lw $t1, 0($t0)
    ori $t1, $t1, 0x0002
    sw $t1, 0($t0)

    li $s0, 0
    li $t4, 0
    la $t5, notes
    la $s2, expected_keys
    li $t6, 0
    li $t7, 4

ekrana_yaz:
    beq $t7, $t6, end
    li $s0, 0

    lw $s1, 0($s2)
    addi $s2, $s2, 4

    li $v0, 4
    lw $a0, 0($t5)
    addi $t5, $t5, 4
    addi $t6, $t6, 1
    syscall

uyut:
    li $v0, 32
    li $a0, 50
    syscall
    add $s0, $s0, 1
    bne $s0, 20, uyut

    # Son nota dahil her notadan sonra biraz daha bekle
    # ki interrupt son tusa basisi yakalayabilsin
    li $v0, 32
    li $a0, 500
    syscall

    j ekrana_yaz

end:
    li $v0, 4
    la $a0, puan_mesaji
    syscall

    li $v0, 1
    move $a0, $t4
    syscall

    li $v0, 4
    la $a0, puan_son
    syscall

    li $v0, 10
    syscall

.ktext 0x80000180
    subi $sp, $sp, 28
    sw $t0,  0($sp)
    sw $t1,  4($sp)
    sw $a0,  8($sp)
    sw $a1, 12($sp)
    sw $a2, 16($sp)
    sw $a3, 20($sp)
    sw $v0, 24($sp)

    li $t0, 0xFFFF0004
    lw $t1, 0($t0)

    bne $t1, $s1, dallan
    addi $t4, $t4, 1

dallan:
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

ses_cal:
    li $v0, 31
    li $a1, 1500
    li $a2, 0
    li $a3, 100
    syscall

interrupt_end:
    lw $t0,  0($sp)
    lw $t1,  4($sp)
    lw $a0,  8($sp)
    lw $a1, 12($sp)
    lw $a2, 16($sp)
    lw $a3, 20($sp)
    lw $v0, 24($sp)
    addi $sp, $sp, 28
    eret