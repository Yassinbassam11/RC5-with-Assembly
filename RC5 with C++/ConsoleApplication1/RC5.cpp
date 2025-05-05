//#include <iostream>
//#include <vector>
//#include <cstdint>
//
//using namespace std;
//
//// Constants
//const uint16_t P16 = 0xB7E1; // Magic constant P16
//const uint16_t Q16 = 0x9E37; // Magic constant Q16
//const int ROUNDS = 8;        // Number of rounds
//const int T = 18;            // Size of expanded key table (S[0..17])
//const int B = 12;            // Number of bytes in the secret key
//const int C = 6;             // Number of words in the secret key
//const int N = 54;            // Number of iterations for key expansion
//
//// Global variables
//vector<uint16_t> S(T); // Expanded key table
//vector<uint16_t> L(C); // Secret key array
//
//// Helper function: Rotate left
//uint16_t rotate_left(uint16_t value, uint16_t shift) {
//    shift = shift % 16; // Handle shifts greater than 16
//    return (value << shift) | (value >> (16 - shift));
//}
//
//// Helper function: Rotate right
//uint16_t rotate_right(uint16_t value, uint16_t shift) {
//    shift = shift % 16; // Handle shifts greater than 16
//    return (value >> shift) | (value << (16 - shift));
//}
//
//// Key Expansion Module
//void key_expansion(const vector<uint8_t>& key) {
//    // Step 1: Copy secret key K into L
//    for (int i = 0; i < B; i++) {
//        L[i / 2] = (L[i / 2] << 8) + key[i];
//        cout <<"L["<<i/2<<"]=" <<hex<< L[i / 2] << endl;
//    }
//    cout << endl;
//
//    // Step 2: Initialize S array
//    S[0] = P16;
//    for (int i = 1; i < T; i++) {
//        S[i] = S[i - 1] + Q16;
//        cout << "S[" << i << "]=" << hex << S[i] << endl;
//    }
//    cout << endl;
//
//    // Step 3: Mix secret key into S
//    uint16_t A = 0, B = 0;
//    int i = 0, j = 0;
//    for (int k = 0; k < N; k++) {
//        A = S[i] = rotate_left(S[i] + A + B, 3);
//        B = L[j] = rotate_left(L[j] + A + B, A + B);
//        i = (i + 1) % T;
//        j = (j + 1) % C;
//        cout << "A: " << hex << A<<endl;
//        cout << "B: " << hex << B<<endl;
//        cout << "S[" <<i<<"]= " << hex << S[i] << endl;
//        cout << "L[" << j << "]= " << hex << L[j] << endl;
//        cout << "i: " << i<<endl;
//        cout << "j: " << j<<endl;
//        cout << endl;
//    }
//}
//
//// Encryption Module
//void encrypt(uint16_t& A, uint16_t& B) {
//    A += S[0];
//    B += S[1];
//    for (int i = 1; i <= ROUNDS; i++) {
//        A = rotate_left(A ^ B, B) + S[2 * i];
//        B = rotate_left(B ^ A, A) + S[2 * i + 1];
//    }
//}
//
//// Decryption Module
//void decrypt(uint16_t& A, uint16_t& B) {
//    for (int i = ROUNDS; i >= 1; i--) {
//        B = rotate_right(B - S[2 * i + 1], A) ^ A;
//        A = rotate_right(A - S[2 * i], B) ^ B;
//    }
//    B -= S[1];
//    A -= S[0];
//}
//
//
//int main() {
//    // Secret key (12 bytes)
//    vector<uint8_t> key = { 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98 };
//
//    // Plaintext (16-bit blocks)
//    uint16_t A = 0x1234; // Example plaintext
//    uint16_t B = 0x5678;
//
//    // Perform key expansion
//    key_expansion(key);
//    cout << "Subkeys: ";
//    for(int i=0;i<S.size();i++){
//        cout << hex<<S[i]<<" ";
//    }
//    cout << endl;
//
//    // Encrypt plaintext
//    encrypt(A, B);
//    cout << "Encrypted: A = " << hex << A << ", B = " << B << endl;
//
//    // Decrypt ciphertext
//    decrypt(A, B);
//    cout << "Decrypted: A = " << hex << A << ", B = " << B << endl;
//
//    return 0;
//}

#include <iostream>
#include <vector>
#include <cstdint>

using namespace std;

// Constants
const uint16_t P16 = 0xB7E1; // Magic constant P16
const uint16_t Q16 = 0x9E37; // Magic constant Q16
const int ROUNDS = 8;        // Number of rounds
const int T = 18;            // Size of expanded key table (S[0..17])
const int B = 12;            // Number of bytes in the secret key
const int C = 6;             // Number of words in the secret key
const int N = 54;            // Number of iterations for key expansion

// Global variables
vector<uint16_t> S(T); // Expanded key table
vector<uint16_t> L(C, 0); // Secret key array initialized to zeros

// Helper function: Rotate left
uint16_t rotate_left(uint16_t value, uint16_t shift) {
    shift %= 16; // Handle shifts greater than 16
    return (value << shift) | (value >> (16 - shift));
}

// Helper function: Rotate right
uint16_t rotate_right(uint16_t value, uint16_t shift) {
    shift %= 16; // Handle shifts greater than 16
    return (value >> shift) | (value << (16 - shift));
}

// Key Expansion Module
void key_expansion(const vector<uint8_t>& key) {
    // Step 1: Copy secret key K into L
    for (int i = 0; i < B; i++) {
        L[i / 2] = (L[i / 2] << 8) | key[i];
        cout << "L[" << i / 2 << "]=" << hex << L[i / 2] << endl;
    }
    cout << endl;

    // Step 2: Initialize S array
    S[0] = P16;
    cout << "S[" << 0 << "]=" << hex << S[0] << endl;
    for (int i = 1; i < T; i++) {
        S[i] = S[i - 1] + Q16;
        cout << "S[" << i << "]=" << hex << S[i] << endl;
    }
    cout << endl;

    // Step 3: Mix secret key into S
    uint16_t A = 0, B = 0;
    int i = 0, j = 0;
    for (int k = 0; k < N; k++) {
        A = S[i] = rotate_left(S[i] + A + B, 3);
        B = L[j] = rotate_left(L[j] + A + B, A + B);

        cout << "A: " << hex << A << endl;
        cout << "B: " << hex << B << endl;
        cout << "S[" << i << "]= " << hex << S[i] << endl;
        cout << "L[" << j << "]= " << hex << L[j] << endl;

        i = (i + 1) % T;
        j = (j + 1) % C;
        
        cout << "i: " << i<<endl;
        cout << "j: " << j<<endl;
        cout << endl;
    }
}

// Encryption Module
void encrypt(uint16_t& A, uint16_t& B) {
    A += S[0];
    B += S[1];
    cout << "A= " << hex << A << endl;
    cout << "B= " << hex << B << endl;
    cout << endl;
    for (int i = 1; i <= ROUNDS; i++) {
        cout << "A^B= " << hex <<( A ^ B) <<endl;
        cout << "(A^B)<<"<<B<<" =" << hex << rotate_left(A ^ B, B) << endl;
        cout << "S["<<2*i<<"]= " << hex << S[2*i] << endl;
        A = rotate_left(A ^ B, B) + S[2 * i];
        B = rotate_left(B ^ A, A) + S[2 * i + 1];
        cout << "A= " << hex << A << endl;
        cout << "B= " << hex << B << endl;
        cout << endl;
    }
}

// Decryption Module
void decrypt(uint16_t& A, uint16_t& B) {
    for (int i = ROUNDS; i >= 1; i--) {
        B = rotate_right(B - S[2 * i + 1], A) ^ A;
        A = rotate_right(A - S[2 * i], B) ^ B;
    }
    B -= S[1];
    A -= S[0];
}

int main() {
    // Secret key (12 bytes)
    vector<uint8_t> key = { 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98 };

    // Plaintext (16-bit blocks)
    uint16_t A = 0x1234; // Example plaintext
    uint16_t B = 0x5678;

    // Perform key expansion
    key_expansion(key);
    cout << "Subkeys: ";
    for (int i = 0; i < S.size(); i++) {
        cout << hex << S[i] << " ";
    }
    cout << endl;

    // Encrypt plaintext
    uint16_t original_A = A, original_B = B;
    encrypt(A, B);
    cout << "Encrypted: A = " << hex << A << ", B = " << B << endl;

    // Decrypt ciphertext
    decrypt(A, B);
    cout << "Decrypted: A = " << hex << A << ", B = " << B << endl;

    // Verify
    if (A == original_A && B == original_B) {
        cout << "Decryption successful - matches original plaintext!" << endl;
    }
    else {
        cout << "Decryption failed!" << endl;
    }

    return 0;
}