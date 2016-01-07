#include "SKIROC2_SC.h"
#include "bitsets.h"


// Hardware definitions
#define SR_OUT 0x0
#define SR_EN  0x1
#define SR_CK  0x2
#define SR_IN  0x3

// Global variables
static unsigned int * destination;
static unsigned char dest_register[BITNSLOTS(8)];  // one byte

// Functions
inline void output_low(unsigned char bit) {
    BITCLEAR(dest_register, bit);
}

inline void output_high(unsigned char bit) {
    BITSET(dest_register, bit);
}

inline void write_to_destination() {
    volatile_write_byte(destination, 0, dest_register[0]);
}

// Transmit byte serially, MSB first
// from: https://en.wikipedia.org/wiki/Bit_banging
void send_8bit_serial_data(unsigned char data) {
    int i;

    // ?
    output_low(SR_OUT);

    // select device
    output_high(SR_EN);

    // send bits 7..0
    for (i = 0; i < 8; i++) {

        // consider leftmost bit
        // set line high if bit is 1, low if bit is 0
        if (data & 0x80)
            output_high(SR_IN);
        else
            output_low(SR_IN);

        // pulse clock to indicate that bit value should be read
        output_low(SR_CK);

        printf("-- write to destination: 0x%02X (", dest_register[0]);
        print_binary_8bits(dest_register[0]);
        printf(")\n");

        write_to_destination();

        // pulse clock to indicate that bit value should be read
        output_high(SR_CK);

        printf("-- write to destination: 0x%02X (", dest_register[0]);
        print_binary_8bits(dest_register[0]);
        printf(")\n");

        write_to_destination();

        // shift byte left so next bit will be leftmost
        data <<= 1;
    }

    // deselect device
    output_low(SR_EN);
}

// Adapted from send_8bit_serial_data()
void send_616bit_serial_data(uint640_t * data_full) {
    unsigned char data;  // data byte

    // p_data points to the most significant byte in data_full
    unsigned char * p_data = (unsigned char *) data_full;
    //p_data += (sizeof(uint640_t) - 1);
    p_data += (BITNSLOTS(616) - 1);

    int i;

    // ?
    output_low(SR_OUT);

    // select device
    output_high(SR_EN);

    // send 616 bits (640-616)..0
    for (i = 0; i < 616; i++) {

        // Move to next byte after 8 bits
        if ((i & 0x07) == 0) {  // faster equivalence of (i % 8 == 0)
            data = *p_data;
            --p_data;

            printf("Write byte: 0x%02X (", data);
            print_binary_8bits(data);
            printf(").\n");
        }

        // consider leftmost bit
        // set line high if bit is 1, low if bit is 0
        if (data & 0x80)
            output_high(SR_IN);
        else
            output_low(SR_IN);

        // pulse clock to indicate that bit value should be read
        output_low(SR_CK);

        printf("-- write to destination: 0x%02X (", dest_register[0]);
        print_binary_8bits(dest_register[0]);
        printf(")\n");

        write_to_destination();

        // pulse clock to indicate that bit value should be read
        output_high(SR_CK);

        printf("-- write to destination: 0x%02X (", dest_register[0]);
        print_binary_8bits(dest_register[0]);
        printf(")\n");

        write_to_destination();

        // shift byte left so next bit will be leftmost
        data <<= 1;
    }

    // deselect device
    output_low(SR_EN);
}

int main(int argc, char *argv[])
{
    int i;

    // Initialize
    skiroc2_slow_control_init();

    // Bit-bang (8 bits)

    int debug = 0;
    if (debug) {
        destination = (unsigned int *) malloc(sizeof(unsigned int));
        dest_register[0] = 0x0;

        int test_data[8] = {0, 255, 127, 128, 13, 82, 148, 223};

        for (i=0; i<8; i++) {
            printf("Writing 0x%02X (", test_data[i]);
            print_binary_8bits(test_data[i]);
            printf(") by bit-banging via 4 lines, MSB first.\n");
            printf("line  0  : sr_out\n");
            printf("line  1  : sr_en\n");
            printf("line  2  : sr_ck\n");
            printf("line  3  : sr_in\n");
            printf("lines 4-7: not connected\n");

            // Send serial data
            send_8bit_serial_data(test_data[i]);

            printf("Write finish\n");
        }

        free(destination);
    }

    // Bit-bang (616 bits)

    {
        destination = (unsigned int *) malloc(sizeof(unsigned int));
        dest_register[0] = 0x0;

        printf("Writing:\n");
        dump_register();
        printf("by bit-banging via 4 lines, MSB first.\n");
        printf("line  0  : sr_out\n");
        printf("line  1  : sr_en\n");
        printf("line  2  : sr_ck\n");
        printf("line  3  : sr_in\n");
        printf("lines 4-7: not connected\n");

        // Send serial data
        send_616bit_serial_data(control_register);

        printf("Write finish\n");

        free(destination);
    }

    return 0;
}
