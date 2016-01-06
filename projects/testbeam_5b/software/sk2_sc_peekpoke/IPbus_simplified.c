#include "IPbus_simplified.h"

#include <stdio.h>
#include <stdlib.h>
#include "stdint.h"


// Refers: uhal/TemplateDefinitions/ProtocolIPbus.hxx
int create_ipbus_write_txn(unsigned int start_addr, int nwords, unsigned int* data_words, unsigned int* buffer)
{
    static const int nwords_max = 0xFF;  // 255

    int i=0, j=0;

    unsigned int *p_buffer_begin = &(buffer[0]);
    unsigned int *p_buffer = p_buffer_begin;

    while (nwords > 0) {
        // At most 255 words fit inside one packet
        if (nwords > nwords_max) {
            // Header
            *p_buffer = create_ipbus_write_txn_header(start_addr, nwords_max);
            ++p_buffer;

            // Data
            for (i = 0; i < nwords_max; i++, j++) {
                *p_buffer = create_ipbus_write_txn_data(data_words[j]);
                ++p_buffer;
            }

        } else {
            // Header
            *p_buffer = create_ipbus_write_txn_header(start_addr, nwords);
            ++p_buffer;

            // Data
            for (i = 0; i < nwords; i++, j++) {
                *p_buffer = create_ipbus_write_txn_data(data_words[j]);
                ++p_buffer;
            }
        }

        nwords -= nwords_max;
    }

    return p_buffer - p_buffer_begin;  // buffer length
}

unsigned int create_ipbus_write_txn_header(unsigned int start_addr, int nwords)
{
    const uint8_t lVersion = 0x00000000;
    const uint8_t lType = 0x10;
    const uint8_t aInfoCode = 0xF;
    const uint32_t aTransactionId = start_addr;
    const uint32_t aWordCount = nwords;

    //return ( 0x20000000 | ( ( aTransactionId&0xfff ) <<16 ) | ( ( aWordCount&0xff ) <<8 ) | lType | ( aInfoCode&0xF ) );
    return ( lVersion | ( ( aTransactionId&0xfff ) <<16 ) | ( ( aWordCount&0xff ) <<8 ) | lType | ( aInfoCode&0xF ) );
}

unsigned int create_ipbus_write_txn_data(unsigned int data_word)
{
    return ( data_word & 0xFFFFFFFF );
}

void extract_ipbus_reply_txn(unsigned int* buffer, int buffer_len)
{

}
