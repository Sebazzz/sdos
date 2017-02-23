#pragma once

// vid.h: Common video manipulation functions and text output

/**
 * Clears the screen using the current set attribute. Resets cursor position.
 */
void vid_clear(void);

/**
 * Resets cursor position
 */
void vid_reset_cursor(void);

/**
 * Set the current attribute to draw the screen with
 */
void vid_set_attribute(unsigned int attribute);

/**
 * Advances the cursor as expected, to the new line if necessary
 */
void vid_advance_cursor(void);

/**
 * Output single character to current position on screen. Advances the cursor.
 */
void vid_put_char(char character);

/**
 * Output zero-terminated string to current position on screen.
 */
 void vid_print_string(const char* str);