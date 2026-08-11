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
    
# =========================
# BITMAP / VISUAL FUNCTIONS
# =========================

draw_rect:
    move $t0, $a0        # $t0 = starting x coordinate of the rectangle
    move $t1, $a1        # $t1 = starting y coordinate of the rectangle
    move $t2, $a2        # $t2 = rectangle width
    move $t3, $a3        # $t3 = rectangle height
    move $t4, $t9        # $t4 = color value

    li $t5, 0            # $t5 = row counter, starts at 0

rect_row:
    beq $t5, $t3, rect_done   # if row counter reaches height, drawing is finished
    li $t6, 0                 # $t6 = column counter, reset for each new row

rect_col:
    beq $t6, $t2, rect_next_row   # if column counter reaches width, go to next row

    add $t7, $t0, $t6        # calculate current pixel x coordinate
    add $t8, $t1, $t5        # calculate current pixel y coordinate

    sll $t8, $t8, 6          # multiply y by 64 (screen width = 64 pixels)
    add $t8, $t8, $t7        # calculate pixel index: y * 64 + x
    sll $t8, $t8, 2          # multiply by 4 because each pixel uses 4 bytes

    li $t7, 0x10008000       # bitmap display base memory address
    add $t8, $t8, $t7        # calculate final memory address of the pixel

    sw $t4, 0($t8)           # store color value into bitmap memory

    addi $t6, $t6, 1         # increment column counter
    j rect_col               # continue drawing next column pixel

rect_next_row:
    addi $t5, $t5, 1         # increment row counter
    j rect_row               # continue with next row

rect_done:
    jr $ra                   # return to caller
    
draw_start_screen:
    addi $sp, $sp, -4        # Make space on the stack to save the return address
    sw $ra, 0($sp)           # Save return address because this function calls draw_rect using jal

    # Draw the full background of the start screen
    li $a0, 0                # x = 0, start from the left edge
    li $a1, 0                # y = 0, start from the top edge
    li $a2, 64               # width = 64 pixels
    li $a3, 64               # height = 64 pixels
    li $t9, 0x00101030       # dark blue color
    jal draw_rect            # draw full-screen dark blue rectangle

    # Draw small star dots at the top area
    li $a0, 5                # star x position
    li $a1, 5                # star y position
    li $a2, 2                # star width
    li $a3, 2                # star height
    li $t9, 0x00FFFFFF       # white color
    jal draw_rect            # draw first small white star

    li $a0, 20               #another star
    li $a1, 8                
    li $a2, 2                
    li $a3, 2                
    li $t9, 0x00FFFFFF       # white color
    jal draw_rect            

    li $a0, 40               #another star
    li $a1, 4                
    li $a2, 2
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect            

    li $a0, 55               # another star
    li $a1, 10               
    li $a2, 2
    li $a3, 2
    li $t9, 0x00FFFFFF
    jal draw_rect            

    li $a0, 10               # blue star
    li $a1, 14               
    li $a2, 2
    li $a3, 2
    li $t9, 0x00AAAAFF       # light blue color
    jal draw_rect            

    li $a0, 50               # another blue star
    li $a1, 3                
    li $a2, 2
    li $a3, 2
    li $t9, 0x00AAAAFF       # light blue color
    jal draw_rect            

    # Draw the big music note in the center of the start screen
    # Draw the note head
    li $a0, 22               
    li $a1, 38               
    li $a2, 14               
    li $a3, 8                
    li $t9, 0x00FFFFFF       # white color
    jal draw_rect            

    # Draw the dark inner part of the note head to create a hole effect
    li $a0, 25               
    li $a1, 40               
    li $a2, 6                
    li $a3, 4                
    li $t9, 0x00101030       # same dark blue as background
    jal draw_rect            # draw inner hole by covering part of the note head

    # Draw the vertical stem of the note
    li $a0, 34               
    li $a1, 16               
    li $a2, 2                
    li $a3, 22               
    li $t9, 0x00FFFFFF       # white color
    jal draw_rect            

    # Draw the first/top flag of the note
    li $a0, 34               
    li $a1, 16               
    li $a2, 10               
    li $a3, 3                
    li $t9, 0x00FFFFFF       # white color
    jal draw_rect            # draw top flag main rectangle

    li $a0, 36               
    li $a1, 19               
    li $a2, 7                
    li $a3, 2                
    li $t9, 0x00FFFFFF
    jal draw_rect            # draw lower part of top flag to make the shape more musical

    # Draw the second/bottom flag of the note
    li $a0, 34               
    li $a1, 23               
    li $a2, 10               
    li $a3, 3                
    li $t9, 0x00FFFFFF
    jal draw_rect            # draw bottom flag main rectangle

    li $a0, 36               
    li $a1, 26               
    li $a2, 7                
    li $a3, 2                
    li $t9, 0x00FFFFFF
    jal draw_rect            # draw lower part of bottom flag

    # Draw the yellow prompt line near the bottom of the screen
    li $a0, 16             
    li $a1, 55               
    li $a2, 32              
    li $a3, 2               
    li $t9, 0x00FFFF00       # yellow color
    jal draw_rect            # draw bottom prompt line

    # Draw small yellow blocks that visually represent the "SPACE" prompt
    li $a0, 18              
    li $a1, 52               
    li $a2, 6               
    li $a3, 2                
    li $t9, 0x00FFFF00       # yellow color
    jal draw_rect            # draw first small prompt block

    li $a0, 27               # x position of second small prompt block
    li $a1, 52
    li $a2, 6
    li $a3, 2
    li $t9, 0x00FFFF00
    jal draw_rect            # draw second small prompt block

    li $a0, 36               # x position of third small prompt block
    li $a1, 52
    li $a2, 6
    li $a3, 2
    li $t9, 0x00FFFF00
    jal draw_rect            # draw third small prompt block

    lw $ra, 0($sp)           # Restore the saved return address
    addi $sp, $sp, 4         # Release the stack space
    jr $ra                   # Return to the caller

draw_end_screen:
    addi $sp, $sp, -4        # Allocate stack space to save return address
    sw $ra, 0($sp)           # Save return address because this function calls draw_rect

    # Draw dark navy background for the end screen
    li $a0, 0                # x = 0 (left edge)
    li $a1, 0                # y = 0 (top edge)
    li $a2, 64               # full screen width
    li $a3, 64               # full screen height
    li $t9, 0x00101030       # dark navy color
    jal draw_rect            # draw full background rectangle

    # Choose the theme color depending on the final score
    # Negative score  -> red
    # Zero score      -> orange
    # Positive score  -> green
    bltz $s0, end_red            # if score < 0, jump to red theme "Branch on Less Than Zero"
    beq $s0, $zero, end_orange   # if score == 0, jump to orange theme
    j end_green                  # otherwise use green theme

end_red:
    li $t9, 0x00FF4040       # load red color into $t9
    j draw_end_nota          # continue drawing end screen elements

end_orange:
    li $t9, 0x00FFA500       # load orange color into $t9
    j draw_end_nota

end_green:
    li $t9, 0x0000FF00       # load green color into $t9

draw_end_nota:
    # Draw large glowing outer border around the center area
    li $a0, 8                # border x position
    li $a1, 8                # border y position
    li $a2, 48               # border width
    li $a3, 48               # border height
    jal draw_rect            # draw colored border rectangle

    # Draw dark INNER rectangle to create frame effect
    li $a0, 10               # x
    li $a1, 10               # y
    li $a2, 44               # inner width
    li $a3, 44               # inner height
    li $t9, 0x00101030       # dark background color
    jal draw_rect            # draw inner dark rectangle

    # draw_rect changed $t9, so reload the theme color
    bltz $s0, reload_red
    beq $s0, $zero, reload_orange
    j reload_green

reload_red:
    li $t9, 0x00FF4040       # reload red theme color
    j draw_big_note

reload_orange:
    li $t9, 0x00FFA500       # reload orange theme color
    j draw_big_note

reload_green:
    li $t9, 0x0000FF00       # reload green theme color

draw_big_note:
    # Draw the large note head in the center
    li $a0, 18               
    li $a1, 36              
    li $a2, 14               
    li $a3, 9                
    jal draw_rect            # draw note head

    # Draw the dark inner hole of the note head
    li $a0, 21               
    li $a1, 38              
    li $a2, 6                
    li $a3, 5                
    li $t9, 0x00101030       # dark navy color
    jal draw_rect            # draw inner hole to create hollow note effect

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
    # Draw the vertical stem of the large music note
    li $a0, 30
    li $a1, 16
    li $a2, 2
    li $a3, 20
    jal draw_rect

    # Draw the first/top flag of the note
    li $a0, 30
    li $a1, 16
    li $a2, 12
    li $a3, 3
    jal draw_rect

    # Draw the lower curved-looking extension of the top flag
    li $a0, 32
    li $a1, 19
    li $a2, 9
    li $a3, 2
    jal draw_rect

    # Draw the second/bottom flag of the note
    li $a0, 30
    li $a1, 22
    li $a2, 12
    li $a3, 3
    jal draw_rect

    # Draw the lower extension of the bottom flag
    li $a0, 32
    li $a1, 25
    li $a2, 9
    li $a3, 2
    jal draw_rect

    # Reload theme color before drawing decorative corner stars
    bltz $s0, reload3_red
    beq $s0, $zero, reload3_orange
    j reload3_green

reload3_red:
    li $t9, 0x00FF4040       # reload red theme color
    j draw_stars

reload3_orange:
    li $t9, 0x00FFA500       # reload orange theme color
    j draw_stars

reload3_green:
    li $t9, 0x0000FF00       # reload green theme color

draw_stars:
    # Draw top-left decorative star
    li $a0, 12
    li $a1, 13
    li $a2, 3
    li $a3, 3
    jal draw_rect

    # Draw top-right decorative star
    li $a0, 49
    li $a1, 13
    li $a2, 3
    li $a3, 3
    jal draw_rect

    # Draw bottom-left decorative star
    li $a0, 12
    li $a1, 48
    li $a2, 3
    li $a3, 3
    jal draw_rect

    # Draw bottom-right decorative star
    li $a0, 49
    li $a1, 48
    li $a2, 3
    li $a3, 3
    jal draw_rect

    # Restore return address and exit function
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
draw_piano:
    addi $sp, $sp, -4        # Allocate stack space to save return address
    sw $ra, 0($sp)           # Save return address because this function calls other functions

    # Draw the full grey background of the game screen
    li $a0, 0                # x = 0
    li $a1, 0                # y = 0
    li $a2, 64               # full screen width
    li $a3, 64               # full screen height
    li $t9, 0x00C0C0C0       # light grey color
    jal draw_rect            # draw grey background

    # Draw the black header area at the top of the screen
    li $a0, 0                
    li $a1, 0                
    li $a2, 64               
    li $a3, 16              
    li $t9, 0x00000000       # black color
    jal draw_rect            # draw top black rectangle

    # Draw the white piano key area
    li $a0, 0                
    li $a1, 18               
    li $a2, 64               
    li $a3, 46               
    li $t9, 0x00FFFFFF       # white color
    jal draw_rect            # draw large white rectangle for piano keys

    # Draw black separator lines between piano keys
    jal draw_separators

    # Restore return address and exit function
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


draw_separators:
    addi $sp, $sp, -4        # Allocate stack space
    sw $ra, 0($sp)           # Save return address

    # Draw separator line between key 1 and key 2
    li $a0, 10               
    li $a1, 18               
    li $a2, 1                # separator width (thin vertical line)
    li $a3, 46               # separator height
    li $t9, 0x00000000       # black color
    jal draw_rect

    # Draw separator line between key 2 and key 3
    li $a0, 21
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    # Draw separator line between key 3 and key 4
    li $a0, 32
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    # Draw separator line between key 4 and key 5
    li $a0, 43
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    # Draw separator line between key 5 and key 6
    li $a0, 54
    li $a1, 18
    li $a2, 1
    li $a3, 46
    li $t9, 0x00000000
    jal draw_rect

    # Restore return address and exit function
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
# Level clear screen
draw_level_clear_screen:
    addi $sp, $sp, -4        # Allocate stack space to save return address
    sw $ra, 0($sp)           # Save return address because this function calls draw_rect

    # Draw dark navy background
    li $a0, 0                # x = 0
    li $a1, 0                # y = 0
    li $a2, 64               # full screen width
    li $a3, 64               # full screen height
    li $t9, 0x00101030       # dark navy color
    jal draw_rect            # draw full background

    # Draw glowing gold outer frame
    li $a0, 6                
    li $a1, 10               
    li $a2, 52              
    li $a3, 44              
    li $t9, 0x00B8860B       # gold color
    jal draw_rect            # draw outer golden rectangle

    # Draw dark inner rectangle to create frame effect
    li $a0, 8                
    li $a1, 12               
    li $a2, 48               
    li $a3, 40               
    li $t9, 0x00101030       # dark navy color
    jal draw_rect            # draw inner dark area

    # Draw left music note head
    li $a0, 12               
    li $a1, 38               
    li $a2, 10               
    li $a3, 6                
    li $t9, 0x00FFD700       # gold color
    jal draw_rect            # draw left note head

    # Draw inner hole of left note head
    li $a0, 14               
    li $a1, 40               
    li $a2, 4                
    li $a3, 3                
    li $t9, 0x00101030       # dark navy color
    jal draw_rect            # create hollow note effect

    # Draw left note stem
    li $a0, 20               
    li $a1, 18               
    li $a2, 2                
    li $a3, 20               
    li $t9, 0x00FFD700       # gold color
    jal draw_rect            

    # Draw right music note head
    li $a0, 34               
    li $a1, 38               
    li $a2, 10               
    li $a3, 6                
    li $t9, 0x00FFD700       # gold color
    jal draw_rect            

    # Draw inner hole of right note head
    li $a0, 36               
    li $a1, 40               
    li $a2, 4                
    li $a3, 3                
    li $t9, 0x00101030       # dark navy color
    jal draw_rect            # create hollow note effect

    # Draw right note stem
    li $a0, 42               
    li $a1, 18              
    li $a2, 2                
    li $a3, 20               
    li $t9, 0x00FFD700       # gold color
    jal draw_rect            # draw right stem

    # Draw top beam connecting both notes
    li $a0, 20               
    li $a1, 18               
    li $a2, 24               
    li $a3, 3                
    li $t9, 0x00FFD700       # gold color
    jal draw_rect            # draw upper beam

    # Draw second lower beam
    li $a0, 20               
    li $a1, 23               
    li $a2, 24               
    li $a3, 3                
    li $t9, 0x00FFD700       # gold color
    jal draw_rect            # draw lower beam

    # Draw decorative top-left star
    li $a0, 9
    li $a1, 14
    li $a2, 4
    li $a3, 4
    li $t9, 0x00FFD700
    jal draw_rect

    # Draw vertical extension of the top-left star
    li $a0, 10
    li $a1, 13
    li $a2, 2
    li $a3, 6
    li $t9, 0x00FFD700
    jal draw_rect

    # Draw decorative top-right star
    li $a0, 49
    li $a1, 14
    li $a2, 4
    li $a3, 4
    li $t9, 0x00FFD700
    jal draw_rect

    # Draw vertical extension of the top-right star
    li $a0, 50
    li $a1, 13
    li $a2, 2
    li $a3, 6
    li $t9, 0x00FFD700
    jal draw_rect

    # Draw bottom horizontal line representing the continue prompt
    li $a0, 18               
    li $a1, 52               
    li $a2, 28               
    li $a3, 2               
    li $t9, 0x00FFD700       # gold color
    jal draw_rect

    # Restore return address and exit function
    lw $ra, 0($sp)    # Load the previously saved return address back into $ra
    addi $sp, $sp, 4  # Restore the stack pointer by freeing the allocated stack space
    jr $ra            # Jump back to the instruction after the original function call
    
# a0 = key ASCII
restore_key:
    beq $a0, $zero, restore_end   # If there is no previous key, skip restoring

    addi $sp, $sp, -4            # Allocate stack space
    sw $ra, 0($sp)               # Save return address

    li $a1, 0                    # Color mode 0 = white (default piano key color)
    jal color_key                # Repaint the key back to white

    lw $ra, 0($sp)               # Restore return address
    addi $sp, $sp, 4             # Restore stack pointer

restore_end:
    jr $ra                       # Return from function


# a0 = key ASCII
# a1 = color mode
# 0=white, 1=yellow, 2=green, 3=red
color_key:
    addi $sp, $sp, -8            # Allocate stack space
    sw $ra, 0($sp)               # Save return address
    sw $a1, 4($sp)               # Save color mode because it will be reused later

    # Determine which piano key should be colored
    beq $a0, 49, key1            # ASCII 49 = key "1"
    beq $a0, 50, key2            # ASCII 50 = key "2"
    beq $a0, 51, key3
    beq $a0, 52, key4
    beq $a0, 53, key5
    beq $a0, 54, key6
    j color_key_end              # If invalid key, exit function

key1:
    li $a0, 0                    # x position of first piano key
    li $t8, 10                   # width of first piano key
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
    lw $t0, 4($sp)         # Reload saved color mode from stack

    # Select the actual bitmap color based on color mode
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
    li $a1, 18                   # ALL piano key y position
    move $a2, $t8                # piano key width
    li $a3, 46                   # ALL piano key height
    jal draw_rect                # Draw the colored piano key

    jal draw_separators          # Redraw separator lines because coloring can cover them

color_key_end:
    lw $ra, 0($sp)               # Restore return address
    addi $sp, $sp, 8             # Restore stack pointer
    jr $ra                       # Return from function
    
# Level circles
draw_level_circles:
    addi $sp, $sp, -4        # Allocate stack space
    sw $ra, 0($sp)           # Save return address

    # Clear the top status area
    li $a0, 0
    li $a1, 0
    li $a2, 64
    li $a3, 8
    li $t9, 0x00000000       # black color
    jal draw_rect

    # Repaint level indicators in green depending on the current level number

    blt $s1, 1, circles_end      # If current level is less than 1, do not fill any indicator

    li $a0, 8                    # x position of first level indicator
    li $a1, 1                    # y position
    li $a2, 1                    # mode 1 = green/completed indicator
    jal draw_small_circle        # repaint first indicator in green


    blt $s1, 2, circles_end      # If current level is less than 2, stop after first indicator

    li $a0, 30                   # x position of second level indicator
    li $a1, 1
    li $a2, 1                    # green/completed mode
    jal draw_small_circle        # repaint second indicator in green


    blt $s1, 3, circles_end      # If current level is less than 3, stop after second indicator

    li $a0, 52                   # x position of third level indicator
    li $a1, 1
    li $a2, 1                    # green/completed mode
    jal draw_small_circle        # repaint third indicator in green

circles_end:
    lw $ra, 0($sp)           # Restore return address
    addi $sp, $sp, 4         # Restore stack pointer
    jr $ra                   # Return from function

# a0=x, a1=y, a2=0(grey) or 1(green)
draw_small_circle:
    addi $sp, $sp, -16       # Allocate stack space
    sw $ra, 0($sp)           # Save return address
    sw $a0, 4($sp)           # Save x position
    sw $a1, 8($sp)           # Save y position
    sw $a2, 12($sp)          # Save mode (grey or green)

    beq $a2, 1, filled_note  # If mode == 1, use green color

empty_note:
    li $t9, 0x00808080       # Grey color = incomplete level
    j draw_note_shape

filled_note:
    li $t9, 0x0000FF00       # Green color = completed/current level

draw_note_shape:
    # Draw the top horizontal beam that visually connects the two small music notes
    lw $a0, 4($sp)           # Reload original x position from stack
    addi $a0, $a0, 2         # Shift x slightly right so the beam is centered above the notes
    lw $a1, 8($sp)           # Reload original y position from stack
    li $a2, 6                # Beam width = 6 pixels
    li $a3, 1                # Beam height = 1 pixel (thin horizontal line)
    jal draw_rect            # Draw the beam rectangle
    
    # Draw left note stem
    lw $a0, 4($sp)
    addi $a0, $a0, 2
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 4
    jal draw_rect

    # Draw left note head
    lw $a0, 4($sp)
    lw $a1, 8($sp)
    addi $a1, $a1, 5
    li $a2, 3
    li $a3, 2
    jal draw_rect

    # Draw right note stem
    lw $a0, 4($sp)
    addi $a0, $a0, 7
    lw $a1, 8($sp)
    addi $a1, $a1, 1
    li $a2, 1
    li $a3, 4
    jal draw_rect

    # Draw right note head
    lw $a0, 4($sp)
    addi $a0, $a0, 5
    lw $a1, 8($sp)
    addi $a1, $a1, 5
    li $a2, 3
    li $a3, 2
    jal draw_rect

note_done:
    lw $ra, 0($sp)           # Restore return address
    addi $sp, $sp, 16        # Restore stack pointer
    jr $ra                   # Return from function

draw_score_bar:
    addi $sp, $sp, -4        # Allocate stack space
    sw $ra, 0($sp)           # Save return address

    # Clear the previous score bar area with dark grey background
    li $a0, 4
    li $a1, 14
    li $a2, 56
    li $a3, 2
    li $t9, 0x00404040   # gray
    jal draw_rect
    
    
    # Draw the neutral center marker
    li $a0, 32             # center x position of the screen/bar
    li $a1, 14             # same y position as the score bar
    li $a2, 1              # marker width = 1 pixel
    li $a3, 2              # marker height = same as score bar
    li $t9, 0x00808080     # grey marker color
    jal draw_rect          # draw center marker
 
    beq $s0, $zero, score_done    # If score is 0, only show center marker
    bgtz $s0, positive_score      # If score > 0, jump to positive score logic
    
negative_score:
    sub $t0, $zero, $s0           # Make negative score positive (0-n
    li $t1, MAX_SCORE             # Load maximum allowed score value, here 48
    bgt $t0, $t1, neg_limit       # If score magnitude is bigger than 48, limit it
    j neg_scale                   # Otherwise continue to scaling

neg_limit:
    li $t0, MAX_SCORE             # Clamp value to MAX_SCORE

neg_scale:
    # Convert the negative score magnitude into a drawable bar width.
    # Formula: scaled_width = score_magnitude * 28 / MAX_SCORE
    # 28 is used because the left side of the bar has 28 pixels available.
    li $t2, 28
    mul $t0, $t0, $t2             # $t0 = score_magnitude * 28
    li $t1, MAX_SCORE             # $t1 = maximum score value used for scaling
    div $t0, $t1                  # divide by MAX_SCORE
    mflo $t0                      # Retrieve the division result from the lo and  place it in $t0.

    beq $t0, $zero, neg_min       # If scaled width t0 is 0, force it to 1 pixel
    j draw_neg                    # Otherwise draw the negative bar

neg_min:
    li $t0, 1                     # Minimum visible bar width = 1 pixel

draw_neg:
    # Draw the red bar to the LEFT of the center marker.
    # Since draw_rect needs a starting x position and positive width,
    # we move x left by the scaled width.
    li $a0, 32                    # Start from center x position
    sub $a0, $a0, $t0             # New x = center - scaled_width
    li $a1, 14                    # y position of score bar
    move $a2, $t0                 # width = scaled_width
    li $a3, 2                     # height = 2 pixels
    li $t9, 0x00FF0000            # red color for negative score
    jal draw_rect                 # Draw negative score bar
    j score_done                  # Finish function

positive_score:
    move $t0, $s0                 # Copy positive score into $t0
    li $t1, MAX_SCORE             # Load maximum score limit
    bgt $t0, $t1, pos_limit       # If score > MAX_SCORE, clamp it
    j pos_scale                   # Otherwise continue scaling

pos_limit:
    li $t0, MAX_SCORE             # Clamp positive score to MAX_SCORE

pos_scale:
    # Convert positive score into a drawable bar width.
    # Formula: scaled_width = score * 28 / MAX_SCORE
    # 28 is the available width on the right side of the center marker.
    li $t2, 28
    mul $t0, $t0, $t2             # $t0 = score * 28
    li $t1, MAX_SCORE
    div $t0, $t1                  # divide by MAX_SCORE
    mflo $t0                      # $t0 = scaled bar width
    beq $t0, $zero, pos_min       # If result is 0, make at least 1 pixel visible
    j draw_pos                    # Otherwise draw positive bar

pos_min:
    li $t0, 1                     # Minimum visible bar width = 1 pixel

draw_pos:
    # Draw the green bar to the RIGHT of the center marker.
    li $a0, 33                    # Start just after the center marker
    li $a1, 14                    # y position of score bar
    move $a2, $t0                 # width = scaled_width
    li $a3, 2                     # height = 2 pixels
    li $t9, 0x0000FF00            # green color for positive score
    jal draw_rect                 # Draw positive score bar

score_done:
    lw $ra, 0($sp)                # Restore return address
    addi $sp, $sp, 4              # Free stack space
    jr $ra                        # Return to caller
    
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
