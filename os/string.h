#pragma once

/**
 * Copies the values of num bytes from the location pointed to by source directly to the memory block pointed to by destination.
 */
extern void memcpy(void* destination, const void* source, size_t num);