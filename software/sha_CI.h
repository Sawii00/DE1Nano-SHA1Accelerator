#ifndef SHA_HEADER
#define SHA_HEADER

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <system.h>

#define u64 uint64_t
#define u32 uint32_t
#define u16 uint16_t
#define u8 uint8_t

struct internal_state
{
    u32 A;
    u32 B;
    u32 C;
    u32 D;
    u32 E;
};

static void panic(const char* mex)
{
    printf(mex);
    exit(-1);
}


static void initialize_state(struct internal_state* s)
{
    s->A = 0x67452301;
    s->B = 0xEFCDAB89;
    s->C = 0x98BADCFE;
    s->D = 0x10325476;
    s->E = 0xC3D2E1F0;
}

void print_state(struct internal_state state)
{
    printf("%x", state.A);
    printf("%x", state.B);
    printf("%x", state.C);
    printf("%x", state.D);
    printf("%x\n", state.E);
}

static u32 round_constants[4] = {0x5A827999, 0x6ED9EBA1, 0x8F1BBCDC, 0xCA62C1D6};

u32 left_rotate(u32 word, u8 n)
{
    if(!n)return word;

    u32 temp = (word >> (32 - n));
    u32 res = (word << n) | temp;
    return res;
}

//Converts a little endian word in a big endian
u32 to_big_endian(u32 val)
{
    u32 res = 0;
    u8 mask = 0xFF;
    u8 leftmost = val >> 24;
    u8 left = (val >> 16) & mask;
    u8 right = (val >> 8) & mask;
    u8 rightmost = val & mask;
    return rightmost << 24 | right << 16 | left << 8 | leftmost;
}

//Executes the 80 rounds of hashing of a 512 bits block
static void sha1_block(u32* block, struct internal_state* state, int CI)
{

    u32 words[80];
    u32 temp;
    //Starts from the previous state
    u32 a = state->A;
    u32 b = state->B;
    u32 c = state->C;
    u32 d = state->D;
    u32 e = state->E;

    //Populates the first 16 words with those extracted from the block and converted in BigEndian
    for(u32 i = 0; i < 16; ++i)
    {
        if(CI)
        	words[i] = ALT_CI_BIGENDIANINSTR_0((*(block + i)), 0);
        else
        	words[i] = to_big_endian(*(block + i));
    }

    //Populates the remaining words that are calculated from the previous ones
    for(u32 i = 16; i < 80; ++i)
    {
        temp = words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16];
        if(CI)
            words[i] = ALT_CI_LEFTROTATEINSTR1_0(temp, 0);
        else
        	words[i] = left_rotate(temp, 1);

    }

    //Executes 80 rounds of hashing
    for(u32 i = 0; i < 80; ++i)
    {
        u32 k = round_constants[i / 20];
        u32 w = words[i];
        int f;
        //Depending on the round constants, words and function change
        if (i < 20)
            f = (b & c) | ((~b) & d);
        else if (i < 40)
            f = b ^ c ^ d;
        else if (i < 60)
            f = (b & c) | (b & d) | (c & d);
        else
            f = b ^ c ^ d;

        if(CI)
            temp = ALT_CI_LEFTROTATEINSTR5_0(a, 0) + f + e + w + k;
        else
        	temp = left_rotate(a, 5) + f + e + w + k;
        e = d;
        d = c;
        if(CI)
            c = ALT_CI_LEFTROTATEINSTR30_0(b, 0);
        else
        	c = left_rotate(b, 30);
        b = a;
        a = temp;
    }

    //The internal state is updated with that calculated for this block
    state->A += a;
    state->B += b;
    state->C += c;
    state->D += d;
    state->E += e;

}


//Computes the SHA1 Hash of a file of any size that will be padded to be multiple of 512 bits
struct internal_state sha1(u8* file, u32 size, int CI)
{
    struct internal_state state;
    //State is initialized to predefined constants
    initialize_state(&state);


    u32 block_count;
    u32 remaining_bytes;

    //Blocks have to be multiple of 512 bits (64 bytes)
    if (size % 64)
    {
        block_count = size / 64 + 1;
        remaining_bytes = 64 - size % 64;
    }
    else
    {
        block_count = size / 64;
        remaining_bytes = 0;
    }

    int extra_block = 0;
    u8* buf = NULL;
    
    //If there is not enough space for padding we have to create a new block
    //We need at least 9 bytes to store the first "1" followed by the 8 bytes with the size of the message
    if (remaining_bytes <= 8)
    {
        extra_block = 1;
        block_count++;
    }

    buf = (u8*) malloc((size + remaining_bytes + 64 * extra_block) * sizeof(u8));
    memset(buf, 0, size + remaining_bytes + 64 * extra_block);
    memcpy(buf, file, size);

    
    //10000000 00000000 -> Inserts a 1 as requested for the padding followed by zeros
    buf[size] = 0x80;
    //Message size in bits
    u64 temp = (8 * (u64)size);
    //Saves in BigEndian the size in bits of the message in the last 8 bytes
    for (int i = 0; i < 8; ++i)
    {
        buf[size + remaining_bytes + 64 * extra_block - (8 - i)] = (u8)(temp >> ((7 - i) * 8));
    }
    
    
    //Hashes each block starting from where the previous one left off.
    for(u32 i = 0; i < block_count; ++i)
    {
        sha1_block((u32*)(buf + 64 * i), &state, CI);
    }
    free(buf);
    return state;
}


#endif
