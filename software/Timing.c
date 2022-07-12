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
#include <stdlib.h>
#include <time.h>

int num_hash = 1;
int num_blocks = 1;
int max_blocks = 7;
int complexity = 1;
int max_compl = 9;
int nonce_incr = 1;
uint32_t base_addr[1] = {SHA1HASHER_0_BASE};
uint32_t* hash[6] = {0, 0, 0, 0, 0, 0};


void write_block(){
	uint32_t i = (num_blocks - 1)*64;
	for(; i < num_blocks * 64; ++i){
		IOWR_8DIRECT(ONCHIP_MEMORY2_0_BASE, i, rand() % 255);
	}
}

void set_hasher(uint8_t num_hasher){

	uint32_t offset = num_blocks*64 + num_hasher*num_blocks*24;

	uint32_t* addr = base_addr[num_hasher];

	//read address
	IOWR_32DIRECT(addr, 0, ONCHIP_MEMORY2_0_BASE);

	//write address
	IOWR_32DIRECT(addr, 4, ONCHIP_MEMORY2_0_BASE + offset);

	//num of blocks
	IOWR_32DIRECT(addr, 8, num_blocks);

	//complexity
	IOWR_32DIRECT(addr, 16, complexity);

	//increment of nonce
	IOWR_32DIRECT(addr, 20, nonce_incr);
}


int main()
{
	srand(time(NULL));

	while(num_blocks < max_blocks){

		//PIO initialization
		IOWR_8DIRECT(PIO_0_BASE, 4, 0xFF);
		IOWR_8DIRECT(PIO_0_BASE, 0, 0);

		//write block in memory
		write_block();

		//HASHER ACCELERATOR
		complexity = 1;

		while(complexity < max_compl){

			//set first hasher
			set_hasher(0);

			//set GPIO pin
			IOWR_8DIRECT(PIO_0_BASE, 0, 1);

			//start first hasher
			IOWR_32DIRECT(SHA1HASHER_0_BASE, 12, 1);

			while(!IORD_32DIRECT(SHA1HASHER_0_BASE, 24));

			//clear GPIO pin
			IOWR_8DIRECT(PIO_0_BASE, 0, 0);

			//clear start register
			IOWR_32DIRECT(base_addr[0], 12, 0);

			complexity++;
		}

		complexity = 1;

		//Software CI
		while(complexity < max_compl){

			uint32_t ind = 0;
			uint32_t i = 0;

			uint8_t input_hash[64];
			uint32_t nonce = 0;

			//set GPIO pin
			IOWR_8DIRECT(PIO_0_BASE, 0, 2);

			for(; i < num_blocks; i++){

				//read block from memory
				for(ind = 0; ind < 64; ind+=4){
					*(uint32_t*)(input_hash + ind) = ALT_CI_BIGENDIANINSTR_0(IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE, ind*i), 0);
				}

				struct internal_state res_sha = sha1(input_hash, 64, 1);

				//hash again until complexity is respected
				while(res_sha.A >> (32 - complexity)){
					nonce += nonce_incr;
					*(uint32_t*)(input_hash + 60) = ALT_CI_BIGENDIANINSTR_0(nonce, 0);
					res_sha = sha1(input_hash, 64, 1);
				}

			}

			//clear GPIO pin
			IOWR_8DIRECT(PIO_0_BASE, 0, 0);

			complexity++;
		}

		complexity = 1;


		//Software
		while(complexity < max_compl){

			uint32_t ind = 0;
			uint32_t i = 0;

			uint8_t input_hash[64];
			uint32_t nonce = 0;

			//set GPIO pin
			IOWR_8DIRECT(PIO_0_BASE, 0, 4);

			for(; i < num_blocks; i++){

				//read block from memory
				for(ind = 0; ind < 64; ind+=4){
					*(uint32_t*)(input_hash + ind) = to_big_endian(IORD_32DIRECT(ONCHIP_MEMORY2_0_BASE, ind*i));
				}

				struct internal_state res_sha = sha1(input_hash, 64, 0);

				//hash again until complexity is respected
				while(res_sha.A >> (32 - complexity)){
					nonce += nonce_incr;
					*(uint32_t*)(input_hash + 60) = to_big_endian(nonce);
					res_sha = sha1(input_hash, 64, 0);
				}

			}

			//clear GPIO pin
			IOWR_8DIRECT(PIO_0_BASE, 0, 0);

			complexity++;
		}

		num_blocks++;

	}

	return 0;
}
