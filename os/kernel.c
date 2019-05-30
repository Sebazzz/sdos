#include "sdos.h"

const char* message = "Cee says hello!";

void header() {
	vid_set_fg(vga_color_cyan);
	vid_print_string_line("   _____  _____    ____    _____  ");
	vid_print_string_line("  / ____||  __ \\  / __ \\  / ____| ");
	vid_print_string_line(" | (___  | |  | || |  | || (___   ");
	vid_print_string_line("  \\___ \\ | |  | || |  | | \\___ \\   Experimental OS");
	vid_print_string_line("  ____) || |__| || |__| | ____) | ");
	vid_print_string_line(" |_____/ |_____/  \\____/ |_____/  ");
    vid_advance_line();
	vid_advance_line();
}

void kmain() {
	header();
	vid_set_fg(vga_color_white);
	vid_print_string("Press any key to continue...");
	wait_key();
	vid_clear();
	header();
	
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
	
	while (1) {
		vid_print_string(". -");
		sleep(1000);
	}
	
	vga_color colors[] = {vga_color_red, vga_color_magenta, vga_color_light_cyan, vga_color_light_green};
	const char* strings[] = {"Scrolling #1", "Scrolling #2", "Scrolling #3", "Scrolling #4"};
	
	const char* currentString;
	vga_color currentColor;
	
	int colorLength = 4;
	for (int i=0; i<80; i++) {
		currentColor = colors[i % colorLength];
		currentString = strings[i % colorLength];
		
		vid_set_fg(currentColor);
		vid_print_string_line(currentString);
		
		sleep(10);
	}
	
	vid_set_fg(vga_color_white);
	vid_print_string("Done!");
	
	sleep(500);
}