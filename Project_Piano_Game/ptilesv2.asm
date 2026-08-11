.data
# Beethoven - Ode to Joy / 9. Senfoni
# Interrupt haberleşme değişkenleri
pressed_key: .word 0    
has_new_key: .word 0    

.eqv MAX_SCORE 48

# --- YENİ EKLENEN OPTİMİZASYON DİZİLERİ (LOOKUP TABLES) ---
level_ptrs:  .word level1_keys, level2_keys, level3_keys
level_lens:  .word 8, 15, 25
midi_notes:  .word 60, 62, 64, 65, 67, 69                    # DO, RE, MI, FA, SOL, LA
key_offsets: .word 0, 11, 22, 33, 44, 55                     # Tuşların X başlangıç koordinatları
key_widths:  .word 10, 10, 10, 10, 10, 9                     # Tuşların genişlikleri

# Notalar
level1_keys: .word 51, 51, 52, 53, 53, 52, 51, 50
level2_keys: .word 51, 51, 52, 53, 53, 52, 51, 50, 49, 49, 50, 51, 51, 50, 50
level3_keys: .word 51, 51, 52, 53, 53, 52, 51, 50, 49, 49, 50, 51, 51, 50, 50, 51, 51, 52, 53, 53, 52, 51, 50, 49, 49

.text
.globl main

main:
    li $t0, 0xFFFF0000
    li $t1, 2              
    sw $t1, 0($t0)         # Receiver Interrupt Enable

    mfc0 $t0, $12          
    ori $t0, $t0, 0x01     
    mtc0 $t0, $12          # Global Interrupt Enable
    
    li $s0, 0              # Skor
    li $s1, 1              # Level
    li $s6, 0              # Önceki basılan tuş
    li $s7, 0              # Önceki hedef tuş

    jal draw_start_screen

wait_start:
    lw $t1, has_new_key
    beq $t1, $zero, wait_start  

    lw $t2, pressed_key         
    sw $zero, has_new_key       
    bne $t2, 32, wait_start     # SPACE (32) basılana kadar bekle

level_start:
    bgt $s1, 3, game_over    # Level 3'ü geçtiyse oyunu bitir

    # --- KOD TEKRARINI ÖNLEYEN DİNAMİK LEVEL YÜKLEME ---
    sub $t0, $s1, 1          # (Level - 1) = Dizi İndeksi
    sll $t0, $t0, 2          # *4 byte offset

    la $t1, level_ptrs
    add $t1, $t1, $t0
    lw $s3, 0($t1)           # $s3 = Aktif seviyenin dizi adresi

    la $t1, level_lens
    add $t1, $t1, $t0
    lw $s5, 0($t1)           # $s5 = Aktif seviyenin nota sayısı

    li $s4, 0                # İndeks = 0
    li $s6, 0
    li $s7, 0

    jal draw_piano
    jal draw_level_circles
    jal draw_score_bar

game_loop:
    beq $s4, $s5, next_level

    move $a0, $s7
    jal restore_key
    move $a0, $s6
    jal restore_key

    lw $s2, 0($s3)           # Yeni hedefi yükle
    move $s7, $s2

    move $a0, $s2
    li $a1, 1                # Sarı (1)
    jal color_key

wait_key:
    jal get_time_limit
    move $t7, $v0            # $t7 = Geri sayım sayacı

wait_key_loop:
    beq $t7, $zero, missed_note

    lw $t1, has_new_key
    beq $t1, $zero, no_key_pressed

    lw $t2, pressed_key         
    sw $zero, has_new_key       

    # Girdi doğrulaması (49-54 arası mı?)
    blt $t2, 49, no_key_pressed
    bgt $t2, 54, no_key_pressed
    j valid_key

no_key_pressed:
    addi $t7, $t7, -1
    j wait_key_loop

valid_key:
    move $s6, $t2
    beq $s6, $s2, correct
    j wrong

correct:
    addi $s0, $s0, 1
    jal draw_score_bar
    
    move $a0, $s6
    li $a1, 2                # Yeşil (2)
    jal color_key
    move $a0, $s6
    jal play_note
    jal delay
    j next_note

missed_note:
    addi $s0, $s0, -1
    jal draw_score_bar

    move $a0, $s2
    li $a1, 3                # Kırmızı (3)
    jal color_key
    jal draw_score_bar
    jal delay
    j next_note

wrong:
    addi $s0, $s0, -1
    jal draw_score_bar

    move $a0, $s6
    li $a1, 3                # Kırmızı (3)
    jal color_key
    move $a0, $s6
    jal play_note
    jal delay
    j next_note

next_note:
    addi $s3, $s3, 4
    addi $s4, $s4, 1
    j game_loop

next_level:
    addi $s1, $s1, 1         # Leveli 1 artır
    bgt $s1, 3, game_over    # 3. leveli bitirdiyse oyunu tamamen bitir

    # Yeni seviye öncesi geçiş (Level Up) ekranını çiz
    jal draw_level_up_screen

wait_next_level:
    # Kullanıcının SPACE (ASCII 32) tuşuna basmasını bekle
    lw $t1, has_new_key
    beq $t1, $zero, wait_next_level  
    lw $t2, pressed_key         
    sw $zero, has_new_key       
    
    bne $t2, 32, wait_next_level     # Eğer basılan tuş SPACE değilse beklemeye devam et
    
    # SPACE'e basıldıysa yeni seviyeyi yükle ve piyano ekranına dön
    j level_start

game_over:
    jal draw_end_screen
end:
    j end


# -------------------------
# OPTİMİZE SES (LOOKUP TABLE İLE)
# -------------------------
play_note:
    sub $t0, $a0, 49         # ASCII'yi index'e çevir (Örn: '1' -> 0)
    bltz $t0, play_end
    bgt $t0, 5, play_end
    sll $t0, $t0, 2          # Index * 4

    la $t1, midi_notes
    add $t1, $t1, $t0
    lw $a0, 0($t1)           # MIDI numarasını diziden al (O(1) hızında)

    li $v0, 31               # Syscall 31: MIDI out
    li $a1, 1500
    li $a2, 0
    li $a3, 100
    syscall
play_end:
    jr $ra


# -------------------------
# OPTİMİZE RENKLENDİRME (LOOKUP TABLE İLE)
# -------------------------
restore_key:
    beq $a0, $zero, r_end
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $a1, 0                # Beyaza (0) boya
    jal color_key
    lw $ra, 0($sp)
    addi $sp, $sp, 4
r_end:
    jr $ra

color_key:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Renk Seçimi
    beq $a1, 0, c_white
    beq $a1, 1, c_yellow
    beq $a1, 2, c_green
    li $t9, 0x00FF0000       # Kırmızı (Default)
    j c_paint
c_white:  
li $t9, 0x00FFFFFF
j c_paint
c_yellow: 
li $t9, 0x00FFFF00
j c_paint
c_green:  li $t9, 0x0000FF00

c_paint:
    # Koordinat ve Genişliği Diziden Al
    sub $t0, $a0, 49
    bltz $t0, c_end
    bgt $t0, 5, c_end
    sll $t0, $t0, 2

    la $t1, key_offsets
    add $t1, $t1, $t0
    lw $a0, 0($t1)           # x = key_offsets[index]

    la $t1, key_widths
    add $t1, $t1, $t0
    lw $a2, 0($t1)           # w = key_widths[index]

    li $a1, 18               # y
    li $a3, 46               # h
    jal draw_rect
    jal draw_separators
c_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# -------------------------
# OPTİMİZE ÇİZİM MOTORU (POINTER ARİTMETİĞİ)
# -------------------------
# a0=x, a1=y, a2=w, a3=h, t9=renk
draw_rect:
    # Başlangıç Adresini 1 Kere Hesapla: 0x10008000 + (y*64 + x)*4
    sll $t0, $a1, 6          # y * 64
    add $t0, $t0, $a0        # (y * 64) + x
    sll $t0, $t0, 2          # * 4
    li $t1, 0x10008000
    add $t0, $t0, $t1        # t0 = Mutlak Bellek Adresi

    # Satır bitiminde bir alt satıra geçmek için atlanacak boşluk (Padding)
    li $t1, 64
    sub $t1, $t1, $a2        # 64 - w
    sll $t1, $t1, 2          # t1 = (64 - w)*4

    move $t2, $zero          # y sayacı
rect_row:
    beq $t2, $a3, rect_done
    move $t3, $zero          # x sayacı
rect_col:
    beq $t3, $a2, rect_next_row
    
    sw $t9, 0($t0)           # Belleğe rengi bas
    addi $t0, $t0, 4         # Sağdaki piksele geç (Pointer Aritmetiği)
    
    addi $t3, $t3, 1
    j rect_col

rect_next_row:
    add $t0, $t0, $t1        # İşaretçiyi alt satırın başına kaydır
    addi $t2, $t2, 1
    j rect_row

rect_done:
    jr $ra


# -------------------------
# ÇİZİM - DİĞER EKRANLAR (Aynı Bırakıldı)
# -------------------------
draw_piano:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00C0C0C0
    jal draw_rect
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 16
    li $t9, 0x00000000
    jal draw_rect
    li $a0, 0
    li $a1, 18
    li $a2, 64
    li $a3, 46
    li $t9, 0x00FFFFFF
    jal draw_rect
    jal draw_separators
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_separators:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $a0, 10
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect
    li $a0, 21
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect
    li $a0, 32
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect
    li $a0, 43
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect
    li $a0, 54
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_start_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00000000
    jal draw_rect
    li $a0, 10
    li $a1, 18
    li $a2, 44
    li $a3, 28
    li $t9, 0x00008000
    jal draw_rect
    li $a0, 14
    li $a1, 22
    li $a2, 36
    li $a3, 20
    li $t9, 0x0000FF00
    jal draw_rect
    li $a0, 22
    li $a1, 31
    li $a2, 20
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect
    li $a0, 10
    li $a1, 46
    li $a2, 44
    li $a3, 3
    li $t9, 0x00404040
    jal draw_rect
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_end_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00000000
    jal draw_rect
    bltz $s0, end_red
    beq $s0, $zero, end_orange
    j end_green
    draw_level_up_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Siyah arka plan
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00000000
    jal draw_rect

    # Büyük MAVİ kart (Seviye atlama teması)
    li $a0, 10
    li $a1, 18
    li $a2, 44
    li $a3, 28
    li $t9, 0x000000FF    # Parlak Mavi
    jal draw_rect

    # Beyaz dekor çizgisi (İç kısım)
    li $a0, 22
    li $a1, 31
    li $a2, 20
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    # Alt gölge
    li $a0, 10
    li $a1, 46
    li $a2, 44
    li $a3, 3
    li $t9, 0x00404040
    jal draw_rect

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
end_red:
    li $t9, 0x00FF0000
    j draw_end_box
end_orange:
    li $t9, 0x00FFA500
    j draw_end_box
end_green:
    li $t9, 0x0000FF00
draw_end_box:
    li $a0, 10
    li $a1, 18
    li $a2, 44
    li $a3, 28
    jal draw_rect
    li $a0, 22
    li $a1, 31
    li $a2, 20
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect
    li $a0, 10
    li $a1, 46
    li $a2, 44
    li $a3, 3
    li $t9, 0x00404040
    jal draw_rect
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_level_circles:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 8
    li $t9, 0x00000000
    jal draw_rect
    li $a0, 8
    li $a1, 1
    li $a2, 0
    jal draw_small_circle
    li $a0, 30
    li $a1, 1
    li $a2, 0
    jal draw_small_circle
    li $a0, 52
    li $a1, 1
    li $a2, 0
    jal draw_small_circle
    blt $s1, 1, circles_end
    li $a0, 8
    li $a1, 1
    li $a2, 1
    jal draw_small_circle
    blt $s1, 2, circles_end
    li $a0, 30
    li $a1, 1
    li $a2, 1
    jal draw_small_circle
    blt $s1, 3, circles_end
    li $a0, 52
    li $a1, 1
    li $a2, 1
    jal draw_small_circle
circles_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_small_circle:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $a2, 12($sp)
    beq $a2, 1, filled_small_circle
empty_small_circle:
    li $t9, 0x00FFFFFF
    lw $a0, 4($sp)
    addi $a0, $a0, 1
    lw $a1, 8($sp)
    li $a2, 2
    li $a3, 1
    jal draw_rect
    lw $a0, 4($sp)
    addi $a0, $a0, 1
    lw $a1, 8($sp)
    addi $a1, $a1, 3
    li $a2, 2
    li $a3, 1
    jal draw_rect
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 2
    jal draw_rect
    lw $a0, 4($sp)
    addi $a0, $a0, 3
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 2
    jal draw_rect
    j small_circle_done
filled_small_circle:
    li $t9, 0x0000FF00
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    li $a2, 4
    li $a3, 4
    jal draw_rect
small_circle_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra

draw_score_bar:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $a0, 4
    li $a1, 14
    li $a2, 56
    li $a3, 2
    li $t9, 0x00404040
    jal draw_rect
    li $a0, 32
    li $a1, 14
    li $a2, 1
    li $a3, 2
    li $t9, 0x00808080
    jal draw_rect
    beq $s0, $zero, score_done
    bgtz $s0, positive_score
negative_score:
    sub $t0, $zero, $s0
    li $t1, MAX_SCORE
    bgt $t0, $t1, neg_limit
    j neg_scale
neg_limit:
    li $t0, MAX_SCORE
neg_scale:
    li $t2, 28
    mul $t0, $t0, $t2
    li $t1, MAX_SCORE
    div $t0, $t1
    mflo $t0
    beq $t0, $zero, neg_min
    j draw_neg
neg_min:
    li $t0, 1
draw_neg:
    li $a0, 32
    sub $a0, $a0, $t0
    li $a1, 14
    move $a2, $t0
    li $a3, 2
    li $t9, 0x00FF0000
    jal draw_rect
    j score_done
positive_score:
    move $t0, $s0
    li $t1, MAX_SCORE
    bgt $t0, $t1, pos_limit
    j pos_scale
pos_limit:
    li $t0, MAX_SCORE
pos_scale:
    li $t2, 28
    mul $t0, $t0, $t2
    li $t1, MAX_SCORE
    div $t0, $t1
    mflo $t0
    beq $t0, $zero, pos_min
    j draw_pos
pos_min:
    li $t0, 1
draw_pos:
    li $a0, 33
    li $a1, 14
    move $a2, $t0
    li $a3, 2
    li $t9, 0x0000FF00
    jal draw_rect
score_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

get_time_limit:
    beq $s1, 1, time_level1
    beq $s1, 2, time_level2
    beq $s1, 3, time_level3
time_level1: 
li $v0, 600000
jr $ra
time_level2: li $v0, 500000
jr $ra
time_level3: li $v0, 400000
jr $ra

delay:
    beq $s1, 1, delay_level1
    beq $s1, 2, delay_level2
    beq $s1, 3, delay_level3
delay_level1: 
li $t0, 190000
j delay_loop
delay_level2: 
li $t0, 160000
j delay_loop
delay_level3: 
li $t0, 130000
j delay_loop
delay_loop:
    addi $t0, $t0, -1
    bgtz $t0, delay_loop
    jr $ra


# =========================================================
# GÜVENLİ KERNEL TEXT - INTERRUPT HANDLER 
# =========================================================
.ktext 0x80000180
    move $k0, $at 

    # 1. Hatanın Klavyeden Gelip Gelmediğini Doğrula
    # Receiver Control Register Bit 0 (Ready) kontrol edilir.
    li $k1, 0xFFFF0000
    lw $k1, 0($k1)
    andi $k1, $k1, 0x0001
    beq $k1, $zero, isr_end  # Veri yoksa (başka bir kesmeyse) işlemi iptal et

    # 2. Güvenli Okuma
    li $k1, 0xFFFF0004
    lw $k1, 0($k1)
    sw $k1, pressed_key

    li $k1, 1
    sw $k1, has_new_key

isr_end:
    move $at, $k0
    eret
