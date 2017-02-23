#include "sdos.h"

void kmain() {
	const char message[] = "Cee says hello!";
	vid_print_string(&message);
	
	sleep(100);
}