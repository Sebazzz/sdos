#include "sdos.h"

const char* message = "Cee says hello!";

void kmain() {
	vid_print_string_line("Waiting for keyboard...");
	
	get_scancode();
	
	vid_print_string_line(message);
	
	vid_set_fg(vga_color_red);
	vid_print_string("Red");
	vid_advance_cursor();
	
	vid_set_fg(vga_color_light_green);
	vid_print_string("Green");
	vid_advance_cursor();
	
	vid_set_bg(vga_color_brown);
	vid_print_string("Green on brown");
	vid_advance_cursor();
	
	vid_set_bg(vga_color_blue);
	vid_set_fg(vga_color_white);
	vid_print_string("--------> We're going to wrap around! Wrap wrap wrap wrap....");
	vid_print_string("And wrapped!");
	vid_advance_line();
	
	for (int i=0; i<80; i++) {
		vid_print_string_line("Scrolling...");
		sleep(50);
	}
	
	sleep(500);
}