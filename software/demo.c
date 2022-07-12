/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include <stdint.h>
#include <io.h>
#include <sha_CI.h>
#include <system.h>
#include <time.h>

//offset for slave
int read_add_offset = 0;
int write_add_offset = 4;
int num_blocks_offset = 8;
int start_offset = 12;
int complexity_offset = 16;
int nonce_incr_offset = 20;
int done_offset = 24;

//parameters for demo
int num_hash = 4;
int num_blocks = 4;
int complexities[4] = {1, 1, 1, 1};
int max_complexity = 16;
int nonce_incr[4] = {1, 3, 5, 7};
uint32_t base_addr[4] = {SHA1HASHER_0_BASE, SHA1HASHER_1_BASE, SHA1HASHER_2_BASE, SHA1HASHER_3_BASE};

uint32_t hash[6] = {0, 0, 0, 0, 0, 0};
uint32_t points[4] = {0, 0, 0, 0};


//write random blocks in memory
void write_blocks(){
	uint32_t i = 0;		
	for(; i < 64 * num_blocks; ++i)
	{
		IOWR_8DIRECT(ONCHIP_MEMORY2_0_BASE, i, rand()%256);
	}
	
}

//program hasher
void set_hasher(uint8_t num_hasher){

	uint32_t offset = num_blocks*64 + num_hasher*num_blocks*24;

	uint32_t* addr = base_addr[num_hasher];

	//read address
	IOWR_32DIRECT(addr, read_add_offset, ONCHIP_MEMORY2_0_BASE);

	//write address
	IOWR_32DIRECT(addr, write_add_offset, ONCHIP_MEMORY2_0_BASE + offset);

	//num of blocks
	IOWR_32DIRECT(addr, num_blocks_offset, num_blocks);

	//complexity
	IOWR_32DIRECT(addr, complexity_offset, complexities[num_hasher]);

	//increment of nonce
	IOWR_32DIRECT(addr, nonce_incr_offset, nonce_incr[num_hasher]);
}

//read resulting hashes from memory and check them with sha function
int read_from_memory(uint8_t num_hasher, uint32_t ind_curr_block){

	uint32_t offset = num_blocks*64 + num_hasher*num_blocks*24 + ind_curr_block*24;

	hash[0] = IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 4);

	hash[1] = IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 0);

	hash[2] = IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 12);

	hash[3] = IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 8);

	hash[4] = IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 20);

	hash[5] = IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 16);

	//check with function
	uint8_t input_hash[64];
	uint8_t ind;
	for(ind = 0; ind < 60; ind+=8){
		input_hash[ind] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind + 7);
		input_hash[ind + 1] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind + 6);
		input_hash[ind + 2] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind + 5);
		input_hash[ind + 3] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind + 4);
		input_hash[ind + 4] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind + 3);
		input_hash[ind + 5] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind + 2);
		input_hash[ind + 6] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind + 1);
		input_hash[ind + 7] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE, ind_curr_block*64 + ind);
	}

	input_hash[60] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 19);
	input_hash[61] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 18);
	input_hash[62] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 17);
	input_hash[63] = IORD_8DIRECT(ONCHIP_MEMORY2_0_BASE + offset, 16);

	struct internal_state res_sha = sha1(input_hash, 64, 0);

	return res_sha.A == hash[0] && res_sha.B == hash[1] && res_sha.C == hash[2] && res_sha.D == hash[3] && res_sha.E == hash[4];
}


int main()
{
	srand(time(NULL));

	//PIO initialization
	IOWR_8DIRECT(PIO_0_BASE, 4, 0xFF);
	IOWR_8DIRECT(PIO_0_BASE, 0, 0);

	write_blocks();

	while(complexities[0] < max_complexity){

		uint32_t i = 0;

		//set hashers
		for(i = 0; i < num_hash; i++){
			set_hasher(i);
		}

		//set GPIO pin
		IOWR_8DIRECT(PIO_0_BASE, 0, 1);

		//start first hasher
		IOWR_32DIRECT(SHA1HASHER_0_BASE, start_offset, 1);

		//set GPIO pin
		IOWR_8DIRECT(PIO_0_BASE, 0, 3);

		//start second hasher
		IOWR_32DIRECT(SHA1HASHER_1_BASE, start_offset, 1);

		//set GPIO pin
		IOWR_8DIRECT(PIO_0_BASE, 0, 7);

		//start third hasher
		IOWR_32DIRECT(SHA1HASHER_2_BASE, start_offset, 1);

		//set GPIO pin
		IOWR_8DIRECT(PIO_0_BASE, 0, 15);

		//start fourth hasher
		IOWR_32DIRECT(SHA1HASHER_3_BASE, start_offset, 1);

		while(!IORD_32DIRECT(SHA1HASHER_0_BASE, done_offset) && !IORD_32DIRECT(SHA1HASHER_1_BASE, done_offset) && !IORD_32DIRECT(SHA1HASHER_2_BASE, done_offset) && !IORD_32DIRECT(SHA1HASHER_3_BASE, done_offset));

		if(IORD_32DIRECT(SHA1HASHER_0_BASE, done_offset) == 1){
			int ok = 1;
			for(i = 0; i < num_blocks && ok; i++){
				ok &= read_from_memory(0, i);
			}
			if(ok)
				points[0]++;
		}
		else{
			if(IORD_32DIRECT(SHA1HASHER_1_BASE, done_offset) == 1){
				int ok = 1;
				for(i = 0; i < num_blocks && ok; i++){
					ok &= read_from_memory(1, i);
				}
				if(ok)
					points[1]++;
			}
			else{
				if(IORD_32DIRECT(SHA1HASHER_2_BASE, done_offset) == 1){
					int ok = 1;
					for(i = 0; i < num_blocks; i++){
						ok &= read_from_memory(2, i);
					}
					if(ok)
						points[2]++;
				}
				else{
					if(IORD_32DIRECT(SHA1HASHER_3_BASE, done_offset) == 1){
						int ok = 1;
						for(i = 0; i < num_blocks; i++){
							ok &= read_from_memory(3, i);
						}
						if(ok)
							points[3]++;
					}
				}
			}
		}

		//wait for all hashers to finish
		while(!IORD_32DIRECT(SHA1HASHER_0_BASE, done_offset) || !IORD_32DIRECT(SHA1HASHER_1_BASE, done_offset) || !IORD_32DIRECT(SHA1HASHER_2_BASE, done_offset) || !IORD_32DIRECT(SHA1HASHER_3_BASE, done_offset));

		//reset start registers and increase complexity
		for(i = 0; i < num_hash; i++){
			IOWR_32DIRECT(base_addr[i], start_offset, 0);
			complexities[i]++;
		}

		//reset PIO
		IOWR_8DIRECT(PIO_0_BASE, 0, 0);

	}

	//search for winners
	uint32_t j = 0;
	uint8_t win = 0;
	for(; j < num_hash; j++){
		if(points[j] > points[win])
			win = j;
	}

	//switch on led for winner
	IOWR_8DIRECT(PIO_0_BASE, 0, 1 << (win + 4));

	while(1);

  return 0;
}
