#pragma once

// vid.h: Common video manipulation functions and text output

typedef char vga_attr; 

typedef enum {
	vga_color_black = 0,
	vga_color_blue = 1,
	vga_color_green = 2,
	vga_color_cyan = 3,
	vga_color_red = 4,
	vga_color_magenta = 5,
	vga_color_brown = 6,
	vga_color_light_gray = 7,
	vga_color_dark_gray = 0+8,
	vga_color_light_blue = 1+8,
	vga_color_light_green = 2+8,
	vga_color_light_cyan = 3+8,
	vga_color_light_red = 4+8,
	vga_color_light_magenta = 5+8,
	vga_color_light_yellow = 6+8,
	vga_color_white = 7+8
} vga_color;

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
extern void vid_set_attribute(vga_attr attribute);

/**
 * Sets the current foreground color to draw with
 */
extern void vid_set_fg(vga_color color);

/**
 * Sets the current background color to draw with
 */
extern void vid_set_bg(vga_color color);

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