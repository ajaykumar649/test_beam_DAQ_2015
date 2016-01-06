#ifndef IPBUS_SIMPLIFIED_H_
#define IPBUS_SIMPLIFIED_H_

// Transport Layer protocol - loosely based on the IPBus protocol
// with the "Transaction ID" field replaed with an "Address" field
//
// | 31 ... 28 | 27 ... 16 | 15 ...  8 |  7 ...  4 |  3 ...  0 |
// |-----------|-----------|-----------|-----------|-----------|
// | Protocol  | Starting  | Number of | Type ID   | Info code |
// | version   | address   | words     |           |           |
// | (4 bits)  | (12 bits) | (8 bits)  | (4 bits)  | (4 bits)  |
//
// - Protocol version: reserved, currently 0
// - Starting address: the intended address for this transaction
// - Number of words : length of the transaction (0-255, 8 bits)
// - Type ID         : 0x0 - read
//                     0x1 - write
// - Info code       : 0x0 - response
//                     0xF - request


// Functions
int create_ipbus_write_txn(unsigned int start_addr, int nwords, unsigned int* data_words, unsigned int* buffer);

unsigned int create_ipbus_write_txn_header(unsigned int start_addr, int nwords);

unsigned int create_ipbus_write_txn_data(unsigned int data_word);

void extract_ipbus_reply_txn(unsigned int* buffer, int buffer_len);

#endif  // IPBUS_SIMPLIFIED_H_
