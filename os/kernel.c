#include "sdos.h"

void kmain() {
	const char message[] = "Cee says hello!";
	vid_print_string_line(message);
	vid_print_string_line(message);
	
	sleep(100);
}