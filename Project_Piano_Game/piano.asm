# MARS MIPS - Basit Piano Çizimi
# Bitmap Display:
# Base Address = 0x10008000
# Width = 512
# Height = 512
# Unit Size = 1x1

.data

black: .word 0x000000
white: .word 0x00FFFFFF

.text
.globl main

main:

# =========================
# Piano gövdesi
# =========================

li $t0, 120              # y

body_y:

li $t1, 100              # x

body_x:

# adres hesapla
# addr = base + ((y * 512) + x) * 4

mul $t2, $t0, 512
add $t2, $t2, $t1
mul $t2, $t2, 4

li $t3, 0x10008000
add $t2, $t2, $t3

lw $t4, black
sw $t4, 0($t2)

addi $t1, $t1, 1
blt $t1, 260, body_x

addi $t0, $t0, 1
blt $t0, 220, body_y

# =========================
# Beyaz tuşlar
# =========================

li $t0, 190

keys_y:

li $t1, 120

keys_x:

mul $t2, $t0, 512
add $t2, $t2, $t1
mul $t2, $t2, 4

li $t3, 0x10008000
add $t2, $t2, $t3

lw $t4, white
sw $t4, 0($t2)

addi $t1, $t1, 1
blt $t1, 240, keys_x

addi $t0, $t0, 1
blt $t0, 220, keys_y

# =========================
# Siyah tuş çizgileri
# =========================

li $t1, 130

black_keys:

li $t0, 190

black_y:

mul $t2, $t0, 512
add $t2, $t2, $t1
mul $t2, $t2, 4

li $t3, 0x10008000
add $t2, $t2, $t3

lw $t4, black
sw $t4, 0($t2)

addi $t0, $t0, 1
blt $t0, 205, black_y

addi $t1, $t1, 20
blt $t1, 230, black_keys

# Sonsuz döngü

end:
j end