#include "SKIROC2_SC.h"
#include "IPbus_simplified.h"

void dump_ipbus_buffer(unsigned int* buffer, int buffer_len)
{
    int i, j;

    for (i = 0, j = 0; i < buffer_len; i++) {
        if ((i & 0xFF) == 0) {  // faster equivalence of (i % 256 == 0)
            printf("--------------------------------\n");
            printf("IPbus packet header   : ");
            print_binary_32bits(buffer[i]);
            printf("\n");
            //printf(" (%d)\n", buffer[i]);

        } else {
            printf("IPbus packet data %4i: ", j);
            print_binary_32bits(buffer[i]);
            printf("\n");
            //printf(" (%d)\n", buffer[i]);

            j++;
        }
    }
}

int main(int argc, char *argv[])
{
    int i = 0;

    int ipbus_buffer_size = 256*4;  // (1 header + 255 data) * 4
    unsigned int* ipbus_buffer = (unsigned int*) malloc(ipbus_buffer_size * sizeof(unsigned int));
    int ipbus_buffer_len;  // variable length

    int debug = 1;
    if (debug) {
        //int nwords = 255*4;
        int nwords = 1000;
        unsigned int data_words[nwords];
        int start_addr = 0x12345678;

        for (i = 0; i < nwords; i++) {
            data_words[i] = i;
        }

        // Create transaction
        ipbus_buffer_len = create_ipbus_write_txn(start_addr, nwords, data_words, ipbus_buffer);

        // Print transaction
        extract_ipbus_reply_txns(ipbus_buffer, ipbus_buffer_len);
    }



    free(ipbus_buffer);

    return 0;
}
