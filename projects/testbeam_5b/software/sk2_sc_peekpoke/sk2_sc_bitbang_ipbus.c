#include "SKIROC2_SC.h"
#include "bitsets.h"
#include "IPbus_simplified.h"


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
    ++destination;
}

// Adapted from send_8bit_serial_data()
void send_616bit_serial_data_ipbus(uint640_t * data_full) {
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

            //printf("Write byte: 0x%02X (", data);
            //print_binary_8bits(data);
            //printf(").\n");
        }

        // consider leftmost bit
        // set line high if bit is 1, low if bit is 0
        if (data & 0x80)
            output_high(SR_IN);
        else
            output_low(SR_IN);

        // pulse clock to indicate that bit value should be read
        output_low(SR_CK);

        //printf("-- write to destination: 0x%02X (", dest_register[0]);
        //print_binary_8bits(dest_register[0]);
        //printf(")\n");

        write_to_destination();

        // pulse clock to indicate that bit value should be read
        output_high(SR_CK);

        //printf("-- write to destination: 0x%02X (", dest_register[0]);
        //print_binary_8bits(dest_register[0]);
        //printf(")\n");

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

    // IPbus buffer
    int ipbus_buffer_size = 256*8;  // (1 header + 255 data) * 8
    unsigned int* ipbus_buffer = (unsigned int*) malloc(ipbus_buffer_size * sizeof(unsigned int));
    int ipbus_buffer_len;  // variable length

    // Test IPbus

    int debug = 0;
    if (debug) {
        //int nwords = 255*4;
        int nwords = 616*2;                 // input to ipbus write txn
        unsigned int data_words[nwords];    // input to ipbus write txn
        int start_addr = 0x12345678;        // input to ipbus write txn

        for (i = 0; i < nwords; i++) {
            data_words[i] = i;
        }

        // Create transaction
        ipbus_buffer_len = create_ipbus_write_txn(start_addr, nwords, data_words, ipbus_buffer);

        // Extract transaction
        extract_ipbus_reply_txns(ipbus_buffer, ipbus_buffer_len);
    }

    // Initialize
    skiroc2_slow_control_init();

    // Bit-bang with IPbus (616 bits)

    {
        //int nwords = 255*4;
        int nwords = 616*2;                 // input to ipbus write txn
        unsigned int data_words[nwords];    // input to ipbus write txn
        int start_addr = 0x00000000;        // input to ipbus write txn

        destination = &(data_words[0]);
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
        send_616bit_serial_data_ipbus(control_register);

        // Create transaction
        ipbus_buffer_len = create_ipbus_write_txn(start_addr, nwords, data_words, ipbus_buffer);

        // Extract transaction
        extract_ipbus_reply_txns(ipbus_buffer, ipbus_buffer_len);

        printf("Write finish\n");
    }

    free(ipbus_buffer);

    return 0;
}
