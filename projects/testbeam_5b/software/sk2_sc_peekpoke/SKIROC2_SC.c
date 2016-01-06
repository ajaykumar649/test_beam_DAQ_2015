#include "SKIROC2_SC.h"
#include "SKIROC2_SC_hw.h"

#include "bitsets.h"

uint640_t control_register_instance;
uint640_t * control_register = &control_register_instance;
const char * control_register_file = "sk2_sc_cur_state";

// Read or write functions
inline void volatile_write_byte(void *base, unsigned int offset, unsigned char value)
{
    *((volatile unsigned char *)(base + offset)) = value;
}

inline unsigned char volatile_read_byte(void *base, unsigned int offset)
{
    return *((volatile unsigned char *)(base + offset));
}

inline void volatile_write_word(void *base, unsigned int offset, unsigned int value)
{
    *((volatile unsigned int *)(base + offset)) = value;
}

inline unsigned int volatile_read_word(void *base, unsigned int offset)
{
    return *((volatile unsigned int *)(base + offset));
}

// Print in binary format
void print_binary(unsigned int number)
{
    printf("0b");
    if (number == 0) {
        printf("0");
    } else {
        int places = 32 - CLZ(number);  // if number is 0, CLZ is undefined
        while(places > 0) {
            //printf("%d", (number & (1 << places)));
            printf((number & (1 << (places-1))) ? "1" : "0");
            places--;
        }
    }
}

void print_binary_8bits(unsigned int number)
{
    printf("0b");

    int places = 8;
    while(places > 0) {
        //printf("%d", (number & (1 << places)));
        printf((number & (1 << (places-1))) ? "1" : "0");
        places--;
    }
}

void print_binary_32bits(unsigned int number)
{
    printf("0b");

    int places = 32;
    while(places > 0) {
        //printf("%d", (number & (1 << places)));
        printf((number & (1 << (places-1))) ? "1" : "0");
        places--;
    }
}

// Conversion string <--> uint640
// from: http://en.cppreference.com/w/c/string/byte/strtoul
void string_to_uint640(const char * string, uint640_t * data) {
    const char * p = string;
    char * end;
    //long i;
    int i=0, j=0, jmax=SKIROC2_SC_NWORDS;

    for (i = strtoul(p, &end, 16); p != end; i = strtoul(p, &end, 16), j++) {
        if (j >= jmax)
            return;

        p = end;
        while (isspace(*p))
            p++;
        if (errno == ERANGE) {
            fprintf(stderr, "range error, got i=%d\n", i);
            errno = 0;
        }
        data->data[jmax-j-1] = i;
    }
}

void uint640_to_string(uint640_t * data, char * string, int length) {
    char * p = string;
    int i=0, j=0, jmax=SKIROC2_SC_NWORDS;

    for (j=0; j<jmax; j++) {
        if (j%4 != 3) {
            i = snprintf(p, length, "0x%08X ", data->data[jmax-j-1]);
            //printf("0x%08X ", data->data[jmax-j-1]);
        } else {
            i = snprintf(p, length, "0x%08X \n", data->data[jmax-j-1]);
            //printf("0x%08X \n", data->data[jmax-j-1]);
        }
        p += i;
        length -= i;
    }

    //printf("actual length: %d.\n", length);
}

// Look up using binary search
const item_t * skiroc2_slow_control_lookup_item(const char *key)
{
    int len = LOOKUP_TABLE_SIZE;  // skip the last item, which is NULL
    int half_len;
    int cmp;

    const item_t * first = (item_t *) (&lookup_table[0]);
    const item_t * last = first + len;
    const item_t * middle;

    while (len > 0) {
        half_len = len/2;
        middle = first + half_len;
        cmp = strcmp(key, middle->name);
        if (cmp == 0) {
            return middle;
        } else if (cmp > 0) {
            first = ++middle;
            len -= (half_len + 1);
        } else {
            len = half_len;
        }
    }
    return last;
}

// Get and set functions
void skiroc2_slow_control_set(const item_t * item, unsigned int value) {
    if (item->nbits <= 0) {
        fprintf(stderr, "Invalid number of bits for register %s.\n", item->name);
        exit(EXIT_FAILURE);
    }

    int mask = (1 << item->nbits) - 1;
    mask <<= (item->subaddr % CHAR_BIT);
    int offset = BITSLOT(item->subaddr);

    value <<= (item->subaddr % CHAR_BIT);
    value &= mask;

    unsigned int byte = volatile_read_byte(control_register, offset);
    byte &= ~mask;  // clear
    byte |= value;  // set
    volatile_write_byte(control_register, offset, byte);

    // Note that the register value might cross 8-bit boundary
    if (mask > 0 && (32 - CLZ(mask)) > 8) {
        byte = volatile_read_byte(control_register, offset + 1);
        byte &= ~(mask >> 8);  // clear
        byte |= (value >> 8);  // set
        volatile_write_byte(control_register, offset + 1, byte);
    }
}

unsigned int skiroc2_slow_control_get(const item_t * item) {
    if (item->nbits <= 0) {
        fprintf(stderr, "Invalid number of bits for register %s.\n", item->name);
        exit(EXIT_FAILURE);
    }

    int mask = (1 << item->nbits) - 1;
    mask <<= (item->subaddr % CHAR_BIT);
    int offset = BITSLOT(item->subaddr);

    unsigned int byte = volatile_read_byte(control_register, offset);
    unsigned int value = (byte & mask);  // test

    // Note that the register value might cross 8-bit boundary
    if (mask > 0 && (32 - CLZ(mask)) > 8) {
        byte = volatile_read_byte(control_register, offset + 1);
        value |= ((byte << 8) & mask);  // test
    }

    value >>= (item->subaddr % CHAR_BIT);
    return value;
}

// Peek and poke functions
void skiroc2_slow_control_poke(const char *key, unsigned int value)
{
    const item_t * item = skiroc2_slow_control_lookup_item(key);

    if (item->name == NULL) {
        fprintf(stderr, "Cannot find register name %s.\n", key);
        exit(EXIT_FAILURE);
    } else {
        skiroc2_slow_control_set(item, value);
    }
}

unsigned int skiroc2_slow_control_peek(const char *key)
{
    const item_t * item = skiroc2_slow_control_lookup_item(key);
    unsigned int value = 0xFFFFFFFF;

    if (item->name == NULL) {
        fprintf(stderr, "Cannot find register name %s.\n", key);
        exit(EXIT_FAILURE);
    } else {
        value = skiroc2_slow_control_get(item);
    }
    return value;
}

void skiroc2_slow_control_scan()
{
    int i;
    const char * name;
    unsigned int value;

    for (i = 0; i < LOOKUP_TABLE_SIZE; i++) {
        name = lookup_table_names_ordered[i];
        value = skiroc2_slow_control_peek(name);

        printf("%s ", name);
        print_binary(value);
        printf("\n");
    }
}

// Init functions
void skiroc2_slow_control_set_default()
{
    int i;
    const item_t * item = &(lookup_table[0]);

    for (i = 0; i < LOOKUP_TABLE_SIZE; i++, item++) {
        skiroc2_slow_control_set(item, item->dvalue);
    }
}

void skiroc2_slow_control_init()
{
    int fd;
    fd = open(control_register_file, O_RDONLY);
    if (fd < 1) {
        printf("Invalid file: %s.\n", control_register_file);
        exit(-1);
    }

    int length = 226;  // (11*3 + 12)*5 + 1
    char string[length];
    read(fd, string, length);

    string_to_uint640(string, control_register);
    close(fd);
}

// Dump functions
void dump_table()
{
    int i;
    const item_t * item = &(lookup_table[0]);

    for (i = 0; i < LOOKUP_TABLE_SIZE; i++, item++) {
        printf("%s, %d, %d, %d\n", item->name, item->nbits, item->subaddr, item->dvalue);
    }
}

void dump_register()
{
    int length = 226;  // (11*3 + 12)*5 + 1
    char string[length];
    uint640_to_string(control_register, string, length);

    printf("%s", string);
}

void dump_register_to_file()
{
    int fd;
    fd = open(control_register_file, O_RDWR | O_CREAT | O_TRUNC, 0644);
    if (fd < 1) {
        printf("Invalid file: %s.\n", control_register_file);
        exit(-1);
    }

    int length = 226;  // (11*3 + 12)*5 + 1
    char string[length];
    uint640_to_string(control_register, string, length);

    write(fd, string, length-1);
    close(fd);
}
