#pragma once

// vid.h: Common video manipulation functions and text output

/**
 * Clears the screen using the current set attribute. Resets cursor position.
 */
extern void vid_clear(void);

/**
 * Resets cursor position
 */
extern void vid_reset_cursor(void);

/**
 * Set the current attribute to draw the screen with
 */
extern void vid_set_attribute(unsigned int attribute);

/**
 * Advances the cursor as expected, to the new line if necessary
 */
extern void vid_advance_cursor(void);

/**
 * Output single character to current position on screen. Advances the cursor.
 */
extern void vid_put_char(char character);

/**
 * Output zero-terminated string to current position on screen.
 */
extern void vid_print_string(const char* str);

/**
 * Output zero-terminated string to current position on screen and advances to the next line.
 */
extern void vid_print_string_line(const char* str);

/**
*  Advances the cursor to the next line, resets X position.
*/
extern void vid_advance_line();