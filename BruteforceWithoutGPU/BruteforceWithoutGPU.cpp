#include <stdio.h>
#include <cstdint>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <algorithm>
#include <vector>
#include <chrono>

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

uint8_t minScore = 40; // Initialize with max possible value
uint16_t bestKey1 = 0, bestKey2 = 0;

// Replace CUDA __device__ function with a regular function
int min3(int a, int b, int c) {
    return std::min({ a, b, c });
}

// Function to find Levenshtein Distance between string1 and string2
int countLevenshteinDistance(const char* str1, const char* str2) {
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

void arrToHex(const uint8_t* arr, size_t size, char* output) {
    const char* cyfryHex = "0123456789ABCDEF";
    for (size_t i = 0; i < size; ++i) {
        output[i * 2] = cyfryHex[(arr[i] >> 4) & 0xF];
        output[i * 2 + 1] = cyfryHex[arr[i] & 0xF];
    }
    output[size * 2] = '\0'; //The end of the string
}

void numberToByteArr(uint32_t number, uint8_t output[4]) {
    for (int i = 0; i < 4; ++i) {
        output[i] = (number >> (i * 8)) & 0xFF;
    }
}

void codeXOR(const uint8_t* arr, const uint8_t* key, uint8_t output[39]) {
    for (size_t i = 0; i < 39; ++i) {
        output[i] = arr[i] ^ key[i % 2];
    }
}

void decrypt(uint8_t* arr1, uint8_t* arr2) {

    for (uint32_t i = 0; i <= 0xFFFF; ++i) {
        for (uint32_t j = 0; j <= 0xFFFF; ++j) {
            uint8_t key1[2], key2[2];
            numberToByteArr(i, key1);
            numberToByteArr(j, key2);
            uint8_t arr1XOR[39], arr2XOR[39];
            codeXOR(arr1, key1, arr1XOR);
            codeXOR(arr2, key2, arr2XOR);
            char arr1XORstring[79], arr2XORstring[79];
            arrToHex(arr1XOR, 39, arr1XORstring);
            arrToHex(arr2XOR, 39, arr2XORstring);
            int score = countLevenshteinDistance(arr1XORstring, arr2XORstring);
            if (score < minScore) {
                minScore = score;
                bestKey1 = i;
                bestKey2 = j;
            }
        }
    }

}

int main() {
    printf("Start\n");

    auto start = std::chrono::high_resolution_clock::now();

    decrypt(array1, array2);

    auto stop = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(stop - start);

    printf("Czas trwania: %lld ms\n", duration.count());
    printf("Najmniejsza odleglosc: %d\n", minScore);
    printf("Klucz 1: %04X\nKlucz 2: %04X\n", bestKey1, bestKey2);

    return 0;
}
