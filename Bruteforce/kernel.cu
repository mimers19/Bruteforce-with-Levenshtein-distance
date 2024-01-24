#include "device_launch_parameters.h"

#include <stdio.h>
#include <cuda_runtime.h>
#include <cstdint>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <algorithm>
#include <vector>

uint8_t array1[] = {
        0x21, 0x46, 0x93, 0xA8, 0x02, 0x48, 0xB3, 0x49,
        0x9E, 0xA7, 0xD3, 0x9E, 0xA7, 0xD3, 0x8E, 0xA3,
        0x1D, 0xA3, 0x7D, 0xAF, 0xD6, 0xB5, 0xE5, 0xBC,
        0xDB, 0xDE, 0xF7, 0x5B, 0xDA, 0x6F, 0xB7, 0x8C,
        0x17, 0x7B, 0xD8, 0x5F, 0x31, 0xA6, 0xA5
};

uint8_t array2[] = {
    0x21, 0x46, 0x58, 0x57, 0xFE, 0xBB, 0x02, 0x56,
    0x14, 0x41, 0x82, 0x0A, 0x28, 0x28, 0x2A, 0xA8,
    0xA8, 0xA8, 0xA4, 0x4A, 0x21, 0x42, 0x63, 0x1B,
    0xD0, 0xD0, 0xD1, 0x21, 0x42, 0x0D, 0xA1, 0x3D,
    0x57, 0x91, 0xE2, 0x37, 0x9D, 0x76, 0xB5
};

__device__ int min3(int a, int b, int c) {
    if (a < b && a < c) return a;
    if (b < a && b < c) return b;
    return c;
}

// Function to find Levenshtein Distance between string1 and string2
__device__ int countLevenshteinDistance(const char* str1, const char* str2) {
    const int len1 = 78, len2 = 78;
    int cost[len1 + 1][len2 + 1];

    // Initializing cost array
    for (int i = 0; i <= len1; i++) cost[i][0] = i;
    for (int j = 0; j <= len2; j++) cost[0][j] = j;

    // Calculating costs
    for (int i = 1; i <= len1; i++) {
        for (int j = 1; j <= len2; j++) {
            int costOfSubstitution = (str1[i - 1] == str2[j - 1]) ? 0 : 1;
            cost[i][j] = min3(
                cost[i - 1][j] + 1,                 // Deletion
                cost[i][j - 1] + 1,                 // Insertion
                cost[i - 1][j - 1] + costOfSubstitution  // Substitution
            );
        }
    }

    return cost[len1][len2];
}

//Remember to reserve 2*size+1 bytes for the output!!!
__device__ void arrToHex(const uint8_t* arr, size_t size, char* output) {
    const char* cyfryHex = "0123456789ABCDEF";
    for (size_t i = 0; i < size; ++i) {
        output[i * 2] = cyfryHex[(arr[i] >> 4) & 0xF];
        output[i * 2 + 1] = cyfryHex[arr[i] & 0xF];
    }
    output[size * 2] = '\0'; //The end of the string
}

__device__ void numberToByteArr(uint32_t number, uint8_t output[4]) {
    for (int i = 0; i < 2; ++i) {
        output[i] = (number >> (i * 8)) & 0xFF;
    }
}

__device__ void codeXOR(const uint8_t* arr, const uint8_t* key, uint8_t output[39]) {
    for (size_t i = 0; i < 39; ++i) {
        output[i] = arr[i] ^ key[i % 2];
    }
}

__global__ void decrypt(uint8_t* arr1, uint8_t* arr2, uint8_t* out_score) {
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int j = blockIdx.y * blockDim.y + threadIdx.y;
    uint8_t key1[2];
    uint8_t key2[2];
    numberToByteArr(i, key1);
    numberToByteArr(j, key2);
    uint8_t arr1XOR[39];
    uint8_t arr2XOR[39];
    codeXOR(arr1, key1, arr1XOR);
    codeXOR(arr2, key2, arr2XOR);
    char arr1XORstring[79];
    char arr2XORstring[79];
    arrToHex(arr1XOR, 39, arr1XORstring);
    arrToHex(arr2XOR, 39, arr2XORstring);
    int score = countLevenshteinDistance(arr1XORstring, arr2XORstring);
    if (score < 20) {
        out_score[0] = score;
        out_score[1] = key1[0];
        out_score[2] = key1[1];
        out_score[3] = key1[2];
        out_score[4] = key1[3];
        out_score[5] = key2[0];
        out_score[6] = key2[1];
        out_score[7] = key2[2];
        out_score[8] = key2[3];

    }
}


int main() {
    printf("Start\n");

    // Rozpoczęcie pomiaru czasu
    float time;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);


    //Alokacja pamięci na urządzeniu
    size_t size = 39 * sizeof(uint8_t);
    uint8_t* d_array1;
    cudaMalloc(&d_array1, size);
    uint8_t* d_array2;
    cudaMalloc(&d_array2, size);

    uint8_t score[9];
    size_t size_u = 9 * sizeof(uint8_t);   //  {calculated_distance, 1p1b, 1p2b, 2p1b, 2p2b}
    uint8_t* d_score;
    cudaMalloc(&d_score, size_u);


    //Kopiowanie zmiennych do GPU
    cudaMemcpy(d_array1, array1, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_array2, array2, size, cudaMemcpyHostToDevice);

    // Uruchomienie kernela
    dim3 thredsPerBlock(32, 32, 1);
    dim3 numBlocks(2048, 2048, 1);
    decrypt << <numBlocks, thredsPerBlock >> > (d_array1, d_array2, d_score);

    cudaDeviceSynchronize();

    cudaMemcpy(score, d_score, size_u, cudaMemcpyDeviceToHost);

    // Zakończenie pomiaru czasu
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&time, start, stop);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    printf("Czas trwania: %f ms\n", time);
    printf("Najmniejsza odleglosc: %d\n", score[0]);
    printf("Klucz 1: %02X%02X%02X%02X\nKlucz 2: %02X%02X%02X%02X\n", score[1], score[2], score[3], score[4], score[5], score[6], score[7], score[8]);

// Zwolnienie pamięci
    cudaFree(d_array1);
    cudaFree(d_array2);
    cudaFree(d_score);

    return 0;
}