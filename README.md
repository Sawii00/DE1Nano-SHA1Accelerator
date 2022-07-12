# DE1Nano-SHA1Accelerator: Hardware Accelerator for SHA-1 and proof-of-work

This project for the course CS-476 (Real-time Embedded Systems) tries to construct a modular hardware accelerator for the computation of SHA1 hashes compliant with a user-specified complexity (number of leading zeros). Each deployed hasher can be programmed to follow a specific increment policy for the nonce to be tried, and keeps hashing until either stopped or a valid hash is found. 

The core of the project is to compare the performance of the complete hardware accelerator with a full software implementation on the Softcore NIOS-II. Furthermore, we have profiled the algorithms bottlenecks and tried to implement NIOS Custom Instructions to optimize the algorithm. 

## System Overview

Each node is made of a Controller, which handles the nonce increments and asserts the validity of the computed hash, and a hasher actually performing the operation.

![image](https://user-images.githubusercontent.com/23176335/178605344-ed3fdb2f-5e9e-4fb7-a4e5-058fb6ea2fb7.png)

## Results
Optimization of the Software version through custom instructions yields a 1.5-1.7x performance improvement.
The full hardware accelerator, capable of burst transfers for the block data, can achieve around a 400x performance improvement over the Software-only version.

![image](https://user-images.githubusercontent.com/23176335/178605399-14e44fc2-6fef-4abe-a029-91e6dc81a0ac.png)
