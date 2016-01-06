#ifndef SKIROC2_SC_H_
#define SKIROC2_SC_H_

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stddef.h>
#include <string.h>  // for strcmp
#include <ctype.h>  // for isspace
#include <errno.h>  // for strtol error

// Structs
typedef struct item_t { const char *name; unsigned int nbits; unsigned int subaddr; unsigned int dvalue; } item_t;

#define SKIROC2_SC_NBITS 616
#define SKIROC2_SC_NWORDS 20
typedef struct uint640_t { unsigned int data[SKIROC2_SC_NWORDS]; } uint640_t;

// Global variables
extern uint640_t * control_register;
extern const char * control_register_file;

// Functions

// Read or write functions
inline void volatile_write_byte(void *base, unsigned int offset, unsigned char value);

inline unsigned char volatile_read_byte(void *base, unsigned int offset);

inline void volatile_write_word(void *base, unsigned int offset, unsigned int value);

inline unsigned int volatile_read_word(void *base, unsigned int offset);

// Print in binary format
void print_binary(unsigned int number);

void print_binary_8bits(unsigned int number);

void print_binary_32bits(unsigned int number);

// Conversion string <--> uint640
void string_to_uint640(const char * string, uint640_t * data);

void uint640_to_string(uint640_t * data, char * string, int length);

// Look up using binary search
const item_t * skiroc2_slow_control_lookup_item(const char *key);

// Get and set functions
void skiroc2_slow_control_set(const item_t * item, unsigned int value);

unsigned int skiroc2_slow_control_get(const item_t * item);

// Peek and poke functions
void skiroc2_slow_control_poke(const char *key, unsigned int value);

unsigned int skiroc2_slow_control_peek(const char *key);

void skiroc2_slow_control_scan();

// Init functions
void skiroc2_slow_control_set_default();

void skiroc2_slow_control_init();  // from control_register_file

// Dump functions
void dump_table();

void dump_register();

void dump_register_to_file();  // to control_register_file

#endif  // SKIROC2_SC_H_
