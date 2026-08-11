# How to Run the Piano Game Project in MARS Simulator

This project contains several versions of the piano game. The main file to run is:

- Piano_Tiles_Game.asm

If you want to try older or experimental versions, you can also look at the other files in this folder, but the recommended file to open is Piano_Tiles_Game.asm.

Since the game relies on hardware interrupts and direct memory mapping for visuals and inputs, MARS Tools must be properly installed before running it.

**Prerequisites:**

- MARS must be installed on your system.

### Step 1: Load the Source Code

1. Open the MARS simulator.
2. Go to File -> Open and select the main game file: Piano_Tiles_Game.asm.

### Step 2: Configure Bitmap Display

1. In the top menu, go to Tools -> Bitmap Display.
2. Configure the tool with the following parameters to ensure the graphics are rendered correctly:

- **Unit Width:** 8
- **Unit Height:** 8
- **Display Width:** 512
- **Display Height:** 512
- **Base Address for Display:** `0x10008000 ($gp)`

3. Click the "Connect to MIPS" button in the lower left corner of the tool window.

### Step 3: Configure Keyboard Input

1. In the top menu, go to Tools -> Keyboard & Screen MMIO Simulator.
2. Click the "Connect to MIPS" button in the lower left corner of the tools window.

> Note: Both Bitmap Display and Keyboard & Screen MMIO Simulator windows must remain open while the game is running.

### Step 4: Assemble and Run

1. Click the Assemble button.
2. Click the Run button.

### Step 5: Game Controls

- **Start the Game:** Click the white text box at the bottom of the Keyboard & Screen MMIO Simulator window and press the space bar.
- **Playing Notes:** Press the corresponding highlighted piano keys using the 1, 2, 3, 4, 5, 6 keys on your keyboard.
- **Level Transition:** After successfully completing a level's sequence of notes, a blue transition screen will appear. Press the space bar to start the next level.

### End of the Game

- With each correct answer, the score bar will increase by 1 toward the green section, and with each incorrect answer, it will decrease by 1 toward the red section.
- At the end of the game, if the score on the green section is higher, a green musical score screen will appear; if the score on the red section is higher, a red musical score screen will appear.

###Step 2: Configure Bitmap Display

1. In the top menu, go to Tools -> Bitmap Display.

2. Configure the tool with the following parameters to ensure the graphics are rendered correctly:

- **Unit Width:** 8
   - **Unit Height:** 8
   - **Display Width:** 512
   - **Display Height:** 512
   - **Base Address for Display:** `0x10008000 ($gp)`

3. Click the "Connect to MIPS" button in the lower left corner of the tool window.

###Step 3: Configure Keyboard Input

1. In the top menu, go to Tools -> Keyboard & Screen MMIO Simulator.

2. Click the "Connect to MIPS" button in the lower left corner of the tools window.

(Note: Both Bitmap Screen and MMIO Simulator windows must remain open while the game is running).

###Step 4: Assemble and Run

1. Click the Assemble button.

2. Click the Run button.

###Step 5: Game Controls

- **Start the Game:** Click the white text box at the bottom of the Keyboard & Screen MMIO Simulator window and press the space bar.

- **Playing Notes:** Press the corresponding highlighted piano keys using the 1, 2, 3, 4, 5, 6 keys on your keyboard.

- **Level Transition:** After successfully completing a level's sequence of notes, a blue transition screen will appear. Press the space bar to start the next level.

###End of the game

- With each correct answer, the score bar will increase by 1 towards the green section, and with each incorrect answer, it will decrease by 1 towards the red section. At the end of the game, if the score on the green section is higher (win), a green musical score screen will appear; if the score on the red section is higher (lose), a red musical score screen will appear.