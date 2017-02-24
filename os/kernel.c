#include "sdos.h"

const char* message = "Cee says hello!";

void kmain() {
	vid_print_string_line(message);
	vid_print_string_line(message);
	
	sleep(100);
}