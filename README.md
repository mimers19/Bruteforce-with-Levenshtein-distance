# Bruteforce with Levenshtein distance

This CUDA C++ code demonstrates an efficient parallel approach to decrypting data and evaluating the similarity between two decrypted arrays using the Levenshtein distance algorithm. The core functionality is encapsulated in a CUDA kernel, which allows for high-performance computation on NVIDIA GPUs.

## Key Components:

1. Array Initialization: Two arrays, array1 and array2, are statically filled with hexadecimal values. These arrays represent encrypted data.

2. Levenshtein Distance Calculation: A device function countLevenshteinDistance computes the Levenshtein distance between two strings, which quantifies their difference by counting the minimum number of operations required to transform one string into the other.

3. Hexadecimal Conversion: The arrToHex device function converts byte arrays into their hexadecimal string representations, facilitating the comparison of their contents.

4. XOR Decryption: The codeXOR device function applies an XOR operation to the arrays with given keys, simulating a simple decryption mechanism.

5. Parallel Decryption and Comparison: The decrypt global function orchestrates the decryption process using different keys for each pair of array elements, converts them into hexadecimal strings, and computes the Levenshtein distance between these strings. It identifies pairs with a distance less than a specified threshold, suggesting a higher similarity (or a successful decryption attempt).

## Memory Management:

The code dynamically allocates and deallocates memory on the GPU for the input arrays and the output scores, ensuring efficient resource management.

## Performance Measurement:

It includes CUDA events for timing the execution, providing insights into the performance of the decryption and comparison operations.

## Execution:

The main function initializes CUDA events for timing, allocates memory on the GPU for input and output data, copies the input data from the host to the device, launches the decrypt kernel with a specified configuration of blocks and threads, and finally, copies the results back to the host. It concludes by printing the execution time, the lowest Levenshtein distance found, and the corresponding decryption keys for both arrays.

## Testing devices:
#### GPU Device:
Device Number: 0	
Device name: NVIDIA GeForce GTX 1650 Ti
Memory Clock Rate (KHz): 6001000
Memory Bus Width (bits): 128
Peak Memory Bandwidth (GB/s): 192.032
Total global memory: 4095MB
Total shared memory per block: 48KB
Total registers per block: 65536
Warp size: 32
Max threads per block: 1024
Max threads dimensions: (1024, 1024, 64)
Max grid dimensions: (2147483647, 65535, 65535)


#### CPU Device:
Intel Core 10th gen i7-10750H
Litography: 14nm
Cores: 6
Threads: 12
Max Turbo Frequency 5.00 GHz 
Intel® Thermal Velocity Boost Frequency 5.00 GHz 
Intel® Turbo Boost Max Technology 3.0 Frequency 4.80 GHz 
Processor Base Frequency 2.60 GHz


## Comparison:
To evaluate the efficiency of parallel computing with CUDA, I developed an equivalent program in C++ that operates without parallelization. The objective was to compare its performance against the CUDA implementation. The results are detailed below:

| CUDA | CPU |
|-|-|
| 1h 40min 6s 236,5ms | ~680h (After around 18 hours of running program was stopped to chech how much values was calculated and checked and based on that I calculated estimated time) |

These findings highlight the significant speedup achieved through parallel computing with CUDA compared to a traditional, non-parallel CPU approach.