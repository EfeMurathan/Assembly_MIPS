.data
# Beethoven - Ode to Joy melody mapping
# 1=DO, 2=RE, 3=MI, 4=FA, 5=SOL, 6=LA
#
# Melody:
# MI MI FA SOL | SOL FA MI RE | DO DO RE MI | MI RE RE
# MI MI FA SOL | SOL FA MI RE | DO DO RE MI | RE DO DO

# Interrupt communication flags
pressed_key: .word 0    # ASCII value of the pressed key
has_new_key: .word 0    # 1 if a new key is detected, 0 otherwise

.eqv MAX_SCORE 48

# Level 1: 8 notes
level1_keys: .word 51, 51, 52, 53, 53, 52, 51, 50

# Level 2: 15 notes
level2_keys: .word 51, 51, 52, 53, 53, 52, 51, 50, 49, 49, 50, 51, 51, 50, 50

# Level 3: 25 notes
level3_keys: .word 51, 51, 52, 53, 53, 52, 51, 50, 49, 49, 50, 51, 51, 50, 50, 51, 51, 52, 53, 53, 52, 51, 50, 49, 49

.text
.globl main

main:
    li $t0, 0xFFFF0000
    li $t1, 2              # interrupt enable bit
    sw $t1, 0($t0)

    # enable CPU interrupts globally
    mfc0 $t0, $12          # read status register
    ori $t0, $t0, 0x01     # set interrupt enable bit
    mtc0 $t0, $12          # write back to status reg
    
    # initialize game state variables
    li $s0, 0          # score
    li $s1, 1          # current level
    li $s6, 0          # prev pressed key
    li $s7, 0          # prev target key

    # warmup MIDI system to prevent initial delay
    li $v0, 31
    li $a0, 60
    li $a1, 1       # 1ms duration barely audible
    li $a2, 0
    li $a3, 0       # volume 0, silent
    syscall

    jal draw_start_screen

wait_start:
    lw $t1, has_new_key
    beq $t1, $zero, wait_start  # poll until key pressed

    lw $t2, pressed_key         # read the key
    sw $zero, has_new_key       # clear interrupt flag
    bne $t2, 32, wait_start     # check if SPACE (ASCII 32)

level_start:
    beq $s1, 1, level1
    beq $s1, 2, level2
    beq $s1, 3, level3
    j game_over

level1:
    la $s3, level1_keys
    li $s4, 0
    li $s5, 8
    li $s6, 0
    li $s7, 0
    jal draw_piano
    jal draw_level_circles
    jal draw_score_bar
    sw $zero, has_new_key       # clear any buffered keys from transition
    j game_loop

level2:
    la $s3, level2_keys
    li $s4, 0
    li $s5, 15
    li $s6, 0
    li $s7, 0
    jal draw_piano
    jal draw_level_circles
    jal draw_score_bar
    sw $zero, has_new_key       # clear any buffered keys from transition
    j game_loop

level3:
    la $s3, level3_keys
    li $s4, 0
    li $s5, 25
    li $s6, 0
    li $s7, 0
    jal draw_piano
    jal draw_level_circles
    jal draw_score_bar
    sw $zero, has_new_key       # clear any buffered keys from transition
    j game_loop

game_loop:
    beq $s4, $s5, next_level

    move $a0, $s7
    jal restore_key

    move $a0, $s6
    jal restore_key

    lw $s2, 0($s3)
    move $s7, $s2

    move $a0, $s2
    li $a1, 1
    jal color_key

wait_key:
    jal get_time_limit
    move $t7, $v0          # remaining time

wait_key_loop:
    beq $t7, $zero, missed_note

    lw $t1, has_new_key
    beq $t1, $zero, no_key_pressed  # decrement timer if no key

    # key detected:
    lw $t2, pressed_key         # fetch key
    sw $zero, has_new_key       # clear flag

    beq $t2, 49, valid_key
    beq $t2, 50, valid_key
    beq $t2, 51, valid_key
    beq $t2, 52, valid_key
    beq $t2, 53, valid_key
    beq $t2, 54, valid_key

no_key_pressed:
    addi $t7, $t7, -1
    j wait_key_loop

valid_key:
    move $s6, $t2

    beq $s6, $s2, correct
    j wrong

correct:
    move $a0, $s6
    jal play_note               # play sound immediately, no delay

    addi $s0, $s0, 1
    jal draw_score_bar
    
    move $a0, $s6
    li $a1, 2              # green
    jal color_key

    jal delay
    j next_note

missed_note:
    addi $s0, $s0, -1
    jal draw_score_bar

    move $a0, $s2
    li $a1, 3              # target key turns red
    jal color_key

    jal draw_score_bar
    jal delay
    j next_note

wrong:
    move $a0, $s6
    jal play_note               # play sound immediately

    addi $s0, $s0, -1
    jal draw_score_bar

    move $a0, $s6
    li $a1, 3               # red
    jal color_key

    jal delay
    j next_note

next_note:
    addi $s3, $s3, 4
    addi $s4, $s4, 1
    j game_loop

next_level:
    beq $s1, 3, game_over              # if level 3 done, end game

    jal draw_level_clear_screen        # show level clear screen

wait_next_level:
    lw $t1, has_new_key
    beq $t1, $zero, wait_next_level   # wait for input

    lw $t2, pressed_key
    sw $zero, has_new_key             # clear flag
    bne $t2, 32, wait_next_level      # loop if not space

    addi $s1, $s1, 1
    j level_start

game_over:
    jal draw_end_screen

end:
    j end

# Sound

# a0 = key ASCII
play_note:
    beq $a0, 49, sound_do
    beq $a0, 50, sound_re
    beq $a0, 51, sound_mi
    beq $a0, 52, sound_fa
    beq $a0, 53, sound_sol
    beq $a0, 54, sound_la
    jr $ra

sound_do:
    li $a0, 60
    j sound_play

sound_re:
    li $a0, 62
    j sound_play

sound_mi:
    li $a0, 64
    j sound_play

sound_fa:
    li $a0, 65
    j sound_play

sound_sol:
    li $a0, 67
    j sound_play

sound_la:
    li $a0, 69
    j sound_play

sound_play:
    li $v0, 31
    li $a1, 1500
    li $a2, 0
    li $a3, 100
    syscall
    jr $ra

# Level clear screen

draw_level_clear_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # dark navy background
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00101030
    jal draw_rect

    # glowing gold outer border 
    li $a0, 6
    li $a1, 10
    li $a2, 52
    li $a3, 44
    li $t9, 0x00B8860B
    jal draw_rect

    # dark inner area
    li $a0, 8
    li $a1, 12
    li $a2, 48
    li $a3, 40
    li $t9, 0x00101030
    jal draw_rect

    # Left note
    # left note head
    li $a0, 12
    li $a1, 38
    li $a2, 10
    li $a3, 6
    li $t9, 0x00FFD700
    jal draw_rect

    # left note inner (hole)
    li $a0, 14
    li $a1, 40
    li $a2, 4
    li $a3, 3
    li $t9, 0x00101030
    jal draw_rect

    # left stem
    li $a0, 20
    li $a1, 18
    li $a2, 2
    li $a3, 20
    li $t9, 0x00FFD700
    jal draw_rect

    # Right note
    # right note head
    li $a0, 34
    li $a1, 38
    li $a2, 10
    li $a3, 6
    li $t9, 0x00FFD700
    jal draw_rect

    # right note inner (hole)
    li $a0, 36
    li $a1, 40
    li $a2, 4
    li $a3, 3
    li $t9, 0x00101030
    jal draw_rect

    # right stem
    li $a0, 42
    li $a1, 18
    li $a2, 2
    li $a3, 20
    li $t9, 0x00FFD700
    jal draw_rect

    # top beam (connects notes)
    li $a0, 20
    li $a1, 18
    li $a2, 24
    li $a3, 3
    li $t9, 0x00FFD700
    jal draw_rect

    # second beam (lower)
    li $a0, 20
    li $a1, 23
    li $a2, 24
    li $a3, 3
    li $t9, 0x00FFD700
    jal draw_rect

    # top left star
    li $a0, 9
    li $a1, 14
    li $a2, 4
    li $a3, 4
    li $t9, 0x00FFD700
    jal draw_rect

    li $a0, 10
    li $a1, 13
    li $a2, 2
    li $a3, 6
    li $t9, 0x00FFD700
    jal draw_rect

    # top right star
    li $a0, 49
    li $a1, 14
    li $a2, 4
    li $a3, 4
    li $t9, 0x00FFD700
    jal draw_rect

    li $a0, 50
    li $a1, 13
    li $a2, 2
    li $a3, 6
    li $t9, 0x00FFD700
    jal draw_rect

    # bottom space prompt line
    li $a0, 18
    li $a1, 52
    li $a2, 28
    li $a3, 2
    li $t9, 0x00FFD700
    jal draw_rect

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



draw_start_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # dark blue background
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00101030
    jal draw_rect

    # top star dots
    li $a0, 5
    li $a1, 5
    li $a2, 2
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    li $a0, 20
    li $a1, 8
    li $a2, 2
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    li $a0, 40
    li $a1, 4
    li $a2, 2
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    li $a0, 55
    li $a1, 10
    li $a2, 2
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    li $a0, 10
    li $a1, 14
    li $a2, 2
    li $a3, 2
    li $t9, 0x00AAAAFF
    jal draw_rect

    li $a0, 50
    li $a1, 3
    li $a2, 2
    li $a3, 2
    li $t9, 0x00AAAAFF
    jal draw_rect

    # Big note
    # note head (12x8 rect)
    li $a0, 22
    li $a1, 38
    li $a2, 14
    li $a3, 8
    li $t9, 0x00FFFFFF
    jal draw_rect

    # note inner hole (dark)
    li $a0, 25
    li $a1, 40
    li $a2, 6
    li $a3, 4
    li $t9, 0x00101030
    jal draw_rect

    # note stem (2x22, right)
    li $a0, 34
    li $a1, 16
    li $a2, 2
    li $a3, 22
    li $t9, 0x00FFFFFF
    jal draw_rect

    # note flag 1 (top)
    li $a0, 34
    li $a1, 16
    li $a2, 10
    li $a3, 3
    li $t9, 0x00FFFFFF
    jal draw_rect

    li $a0, 36
    li $a1, 19
    li $a2, 7
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    # note flag 2 (bottom)
    li $a0, 34
    li $a1, 23
    li $a2, 10
    li $a3, 3
    li $t9, 0x00FFFFFF
    jal draw_rect

    li $a0, 36
    li $a1, 26
    li $a2, 7
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect

    # bottom prompt line
    li $a0, 16
    li $a1, 55
    li $a2, 32
    li $a3, 2
    li $t9, 0x00FFFF00
    jal draw_rect

    # small blocks mimicking 'space' text
    li $a0, 18
    li $a1, 52
    li $a2, 6
    li $a3, 2
    li $t9, 0x00FFFF00
    jal draw_rect

    li $a0, 27
    li $a1, 52
    li $a2, 6
    li $a3, 2
    li $t9, 0x00FFFF00
    jal draw_rect

    li $a0, 36
    li $a1, 52
    li $a2, 6
    li $a3, 2
    li $t9, 0x00FFFF00
    jal draw_rect

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_end_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # dark navy background
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00101030
    jal draw_rect

    # pick note color based on score
    bltz $s0, end_red
    beq $s0, $zero, end_orange
    j end_green

end_red:
    li $t9, 0x00FF4040
    j draw_end_nota

end_orange:
    li $t9, 0x00FFA500
    j draw_end_nota

end_green:
    li $t9, 0x0000FF00

draw_end_nota:
    # glowing border (with color)
    li $a0, 8
    li $a1, 8
    li $a2, 48
    li $a3, 48
    jal draw_rect

    # dark inner
    li $a0, 10
    li $a1, 10
    li $a2, 44
    li $a3, 44
    li $t9, 0x00101030
    jal draw_rect

    # reload color to $t9 (lost after draw_rect)
    bltz $s0, reload_red
    beq $s0, $zero, reload_orange
    j reload_green

reload_red:
    li $t9, 0x00FF4040
    j draw_big_note

reload_orange:
    li $t9, 0x00FFA500
    j draw_big_note

reload_green:
    li $t9, 0x0000FF00

draw_big_note:
    # big note head (center)
    li $a0, 18
    li $a1, 36
    li $a2, 14
    li $a3, 9
    jal draw_rect

    # note inner hole
    li $a0, 21
    li $a1, 38
    li $a2, 6
    li $a3, 5
    li $t9, 0x00101030
    jal draw_rect

    # reload color again based on score
    bltz $s0, reload2_red
    beq $s0, $zero, reload2_orange
    j reload2_green

reload2_red:
    li $t9, 0x00FF4040
    j draw_note_stem

reload2_orange:
    li $t9, 0x00FFA500
    j draw_note_stem

reload2_green:
    li $t9, 0x0000FF00

draw_note_stem:
    # note stem
    li $a0, 30
    li $a1, 16
    li $a2, 2
    li $a3, 20
    jal draw_rect

    # flag 1
    li $a0, 30
    li $a1, 16
    li $a2, 12
    li $a3, 3
    jal draw_rect

    li $a0, 32
    li $a1, 19
    li $a2, 9
    li $a3, 2
    jal draw_rect

    # flag 2
    li $a0, 30
    li $a1, 22
    li $a2, 12
    li $a3, 3
    jal draw_rect

    li $a0, 32
    li $a1, 25
    li $a2, 9
    li $a3, 2
    jal draw_rect

    # corner stars (4 corners, small)
    bltz $s0, reload3_red
    beq $s0, $zero, reload3_orange
    j reload3_green

reload3_red:
    li $t9, 0x00FF4040
    j draw_stars

reload3_orange:
    li $t9, 0x00FFA500
    j draw_stars

reload3_green:
    li $t9, 0x0000FF00

draw_stars:
    li $a0, 12
    li $a1, 13
    li $a2, 3
    li $a3, 3
    jal draw_rect

    li $a0, 49
    li $a1, 13
    li $a2, 3
    li $a3, 3
    jal draw_rect

    li $a0, 12
    li $a1, 48
    li $a2, 3
    li $a3, 3
    jal draw_rect

    li $a0, 49
    li $a1, 48
    li $a2, 3
    li $a3, 3
    jal draw_rect

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Piano

draw_piano:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # background
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 64
    li $t9, 0x00C0C0C0
    jal draw_rect

    # top black header
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 16
    li $t9, 0x00000000
    jal draw_rect

    # white keys
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


# a0 = key ASCII
restore_key:
    beq $a0, $zero, restore_end

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $a1, 0
    jal color_key

    lw $ra, 0($sp)
    addi $sp, $sp, 4

restore_end:
    jr $ra


# a0 = key ASCII
# a1 = color mode
# 0=white, 1=yellow, 2=green, 3=red
color_key:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $a1, 4($sp)

    beq $a0, 49, key1
    beq $a0, 50, key2
    beq $a0, 51, key3
    beq $a0, 52, key4
    beq $a0, 53, key5
    beq $a0, 54, key6
    j color_key_end

key1:
    li $a0, 0
    li $t8, 10
    j choose_color

key2:
    li $a0, 11
    li $t8, 10
    j choose_color

key3:
    li $a0, 22
    li $t8, 10
    j choose_color

key4:
    li $a0, 33
    li $t8, 10
    j choose_color

key5:
    li $a0, 44
    li $t8, 10
    j choose_color

key6:
    li $a0, 55
    li $t8, 9
    j choose_color

choose_color:
    lw $t0, 4($sp)

    beq $t0, 0, color_white
    beq $t0, 1, color_yellow
    beq $t0, 2, color_green
    beq $t0, 3, color_red

color_white:
    li $t9, 0x00FFFFFF
    j paint_key

color_yellow:
    li $t9, 0x00FFFF00
    j paint_key

color_green:
    li $t9, 0x0000FF00
    j paint_key

color_red:
    li $t9, 0x00FF0000
    j paint_key

paint_key:
    li $a1, 18
    move $a2, $t8
    li $a3, 46
    jal draw_rect
    jal draw_separators

color_key_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra

# Level circles

draw_level_circles:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # clear top area first
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 8
    li $t9, 0x00000000
    jal draw_rect

    # 3 empty circles
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

    # fill circles based on level
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


# a0=x, a1=y, a2=0(grey) or 1(green)
# double note shape: two notes + stems + beam
# bounds: 8w x 8h
draw_small_circle:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $a2, 12($sp)

    beq $a2, 1, filled_note

empty_note:
    li $t9, 0x00808080      # grey = incomplete level
    j draw_note_shape

filled_note:
    li $t9, 0x0000FF00      # green = complete level

draw_note_shape:
    # top beam (6x1) highest pos
    lw $a0, 4($sp)
    addi $a0, $a0, 2
    lw $a1, 8($sp)
    li $a2, 6
    li $a3, 1
    jal draw_rect

    # left stem (1x4)
    lw $a0, 4($sp)
    addi $a0, $a0, 2
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 4
    jal draw_rect

    # left note head (3x2)
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    addi $a1, $a1, 5
    li $a2, 3
    li $a3, 2
    jal draw_rect

    # right stem (1x4)
    lw $a0, 4($sp)
    addi $a0, $a0, 7
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 4
    jal draw_rect

    # right note head (3x2)
    lw $a0, 4($sp)
    addi $a0, $a0, 5
    lw $a1, 8($sp)
    addi $a1, $a1, 5
    li $a2, 3
    li $a3, 2
    jal draw_rect

note_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 16
    jr $ra

# Basic draw

draw_rect:
    move $t0, $a0
    move $t1, $a1
    move $t2, $a2
    move $t3, $a3
    move $t4, $t9

    li $t5, 0

rect_row:
    beq $t5, $t3, rect_done
    li $t6, 0

rect_col:
    beq $t6, $t2, rect_next_row

    add $t7, $t0, $t6
    add $t8, $t1, $t5

    sll $t8, $t8, 6
    add $t8, $t8, $t7
    sll $t8, $t8, 2

    li $t7, 0x10008000
    add $t8, $t8, $t7

    sw $t4, 0($t8)

    addi $t6, $t6, 1
    j rect_col

rect_next_row:
    addi $t5, $t5, 1
    j rect_row

rect_done:
    jr $ra
    
get_time_limit:
    beq $s1, 1, time_level1
    beq $s1, 2, time_level2
    beq $s1, 3, time_level3

time_level1:
    li $v0, 600000
    jr $ra

time_level2:
    li $v0, 500000
    jr $ra

time_level3:
    li $v0, 400000
    jr $ra

draw_score_bar:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # clear score bar area
    li $a0, 4
    li $a1, 14
    li $a2, 56
    li $a3, 2
    li $t9, 0x00404040
    jal draw_rect
    
    
    # neutral center marker (dim)
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
    
# Interrupt hanler
.ktext 0x80000180
    # backup $at to prevent corruption 
    move $k0, $at 

    # read key from MMIO
    li $k1, 0xFFFF0004
    lw $k1, 0($k1)

    # save key to memory
    sw $k1, pressed_key

    # set new key flag
    li $k1, 1
    sw $k1, has_new_key

    # restore $at and return
    move $at, $k0
    eret