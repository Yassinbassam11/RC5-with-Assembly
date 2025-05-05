.include "m328pdef.inc"

; RC5 Constants for 16-bit implementation
.equ P16 = 0xB7E1       ; P magic number for 16-bit words  
.equ Q16 = 0x9E37       ; Q magic number for 16-bit words
.equ ROUNDS = 8         ; 8 encryption rounds
.equ const_t = 18       ; Expanded key table size (18 words)
.equ const_b = 12       ; Secret key size in bytes (12)
.equ const_c = 6        ; Secret key size in words (6)
.equ const_n = 54       ; Key expansion iterations (3*max(t,c))

.dseg
.org 0x0100
S: .byte 2 * const_t    ; Expanded key table S[0..17]
L: .byte 2 * const_c    ; Secret key array L[0..5]  
A: .byte 2              ; Plaintext/ciphertext word A
B: .byte 2              ; Plaintext/ciphertext word B

.cseg
.org 0x0000
    rjmp main           ; Reset vector jumps to main

; Example 96-bit secret key (12 bytes)
K: .db 0x23, 0x01, 0x67, 0x45, 0xAB, 0x89, 0xEF, 0xCD, 0xDC, 0xFE, 0x98, 0xBA   

main:
    ; Initialize stack pointer
    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    ; Initialize example plaintext (A=0x1234, B=0x5678)
    ldi ZL, low(A)
    ldi ZH, high(A)
    ldi r16, 0x34       ; A low byte
    st Z+, r16
    ldi r16, 0x12       ; A high byte
    st Z+, r16
    
    ldi ZL, low(B)
    ldi ZH, high(B)
    ldi r16, 0x78       ; B low byte
    st Z+, r16
    ldi r16, 0x56       ; B high byte
    st Z+, r16
    
    rcall key_expansion ; Expand key into S table
    rcall encrypt       ; Encrypt plaintext
    rcall decrypt       ; Decrypt ciphertext
    
    main_loop:          ; Infinite loop after completion
        rjmp main_loop

; Key expansion routine
key_expansion:
    ; Step 1: Copy secret key K into L array
    ldi ZL, low(K*2)   
    ldi ZH, high(K*2)
    ldi YL, low(L)
    ldi YH, high(L)
    ldi r16, const_b
copy_key_loop:
    lpm r17, Z+
    st Y+, r17
    dec r16
    brne copy_key_loop

    ; Step 2: Initialize S array with magic constants
    ldi ZL, low(S)
    ldi ZH, high(S)
    ldi r16, const_t
    ldi r17, low(P16)
    ldi r18, high(P16)
init_s_loop:
    st Z+, r17
    st Z+, r18
    ldi r19, low(Q16)
    add r17, r19
    ldi r19, high(Q16)
    adc r18, r19
    dec r16
    brne init_s_loop

    ; Step 3: Mix secret key into expanded key table
    ldi r16, const_n
    mov r15, r16        
    clr r16             ; i = 0
    clr r17             ; j = 0
    clr r18             ; A = 0
    clr r19             
    clr r20             ; B = 0
    clr r21             
    clr r22             ; Temp for S[i].low
    clr r23             ; Temp for S[i].high
    clr r24             ; Temp for L[j].low
    clr r25             ; Temp for L[j].high
mix_loop:
    ; Process S[i] = (S[i] + A + B) <<< 3
    ldi ZL, low(S)
    ldi ZH, high(S)
    add ZL, r16
    adc ZH, r1
    add ZL, r16         ; Word offset
    adc ZH, r1
    ld r22, Z           
    ldd r23, Z+1        
    
    add r22, r18        
    adc r23, r19
    add r22, r20
    adc r23, r21

    ; Rotate left 3 bits
    ldi r26,3
    rotate_s:
    lsl r22
    rol r23
    in r14,SREG
    bst r14,0
    bld r22,0
    dec r26
    brne rotate_s

    clr r14
    
    st Z+, r22
    st Z+, r23

    mov r18, r22
    mov r19, r23

    ; Process L[j] = (L[j] + A + B) <<< (A+B)
    ldi YL, low(L)
    ldi YH, high(L)
    add YL, r17
    adc YH, r1
    add YL, r17         ; Word offset
    adc YH, r1
    ld r24, Y           
    ldd r25, Y+1        
    
    add r24, r18        
    adc r25, r19
    add r24, r20        
    adc r25, r21        
    
    ; Rotate left by (A+B) mod 16
    mov r26, r18
    add r26, r20
    andi r26, 0x0F      
rotate_l_loop:
    tst r26
    breq rotate_l_done
    lsl r24
    rol r25
    in r14,SREG
    bst r14,0
    bld r24,0
    add r23, r1
    dec r26
    rjmp rotate_l_loop

step4jump:
    jmp mix_loop

rotate_l_done:
    clr r26
    clr r14

    st Y+, r24
    st Y+, r25

    mov r20, r24
    mov r21, r25

    ; Update indices i and j
    inc r16             
    cpi r16, const_t
    brlo skip_i_reset
    clr r16
skip_i_reset:
    inc r17             
    cpi r17, const_c
    brlo skip_j_reset
    clr r17
skip_j_reset:
    dec r15
    brne step4jump
    ret

; Encryption routine
encrypt:
    push r16
    push r17
    push r18
    push r19
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH

    ; Load plaintext A and B
    ldi ZL, low(A)
    ldi ZH, high(A)
    ld r16, Z+          
    ld r17, Z+          
    ldi ZL, low(B)
    ldi ZH, high(B)
    ld r18, Z+          
    ld r19, Z+          

    ; Initial key addition
    ldi ZL, low(S)
    ldi ZH, high(S)
    ld r20, Z+          
    ld r21, Z+          
    add r16, r20        
    adc r17, r21
    ld r20, Z+          
    ld r21, Z+          
    add r18, r20        
    adc r19, r21

    ; Main encryption rounds
    ldi r22, 1          
encrypt_loop:
    ; Calculate S[2*i] address
    push ZL
    push ZH
    ldi ZL, low(S)
    ldi ZH, high(S)
    mov r20, r22
    lsl r20             
    lsl r20             
    add ZL, r20
    adc ZH, r1          

    ; A = ((A XOR B) <<< B) + S[2*i]
    eor r16, r18        
    eor r17, r19        

    ; Rotate left by B mod 16
    mov r23, r18
    andi r23, 0x0F      
rotate_left_a:
    tst r23
    breq rotate_a_done
    lsl r16
    rol r17
    in r14,SREG
    bst r14,0
    bld r16,0
    clr r14
    dec r23
    rjmp rotate_left_a
rotate_a_done:

    ld r20, Z+          
    ld r21, Z+          
    add r16, r20        
    adc r17, r21

    ; B = ((B XOR A) <<< A) + S[2*i+1]
    eor r18, r16        
    eor r19, r17        

    ; Rotate left by A mod 16
    mov r23, r16
    andi r23, 0x0F      
rotate_left_b:
    tst r23
    breq rotate_b_done
    lsl r18
    rol r19
    adc r18, r1
    dec r23
    rjmp rotate_left_b
rotate_b_done:

    ld r20, Z+          
    ld r21, Z+          
    add r18, r20        
    adc r19, r21

    pop ZH
    pop ZL

    inc r22             
    cpi r22, ROUNDS+1   
    brlo encrypt_loop   

    ; Store ciphertext
    ldi ZL, low(A)
    ldi ZH, high(A)
    st Z+, r16
    st Z+, r17
    ldi ZL, low(B)
    ldi ZH, high(B)
    st Z+, r18
    st Z+, r19

    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    ret

; Decryption routine
decrypt:
    push r16
    push r17
    push r18
    push r19
    push r20
    push r21
    push r22
    push r23
    push r24
    push r25
    push ZL
    push ZH

    ; Load ciphertext A and B
    ldi ZL, low(A)
    ldi ZH, high(A)
    ld r16, Z+          
    ld r17, Z+          
    ldi ZL, low(B)
    ldi ZH, high(B)
    ld r18, Z+          
    ld r19, Z+          

    ; Main decryption rounds
    ldi r22, ROUNDS     
decrypt_loop:
    ; Calculate S[2*i+1] address
    push ZL
    push ZH
    ldi ZL, low(S)
    ldi ZH, high(S)
    mov r20, r22
    lsl r20             
    lsl r20             
    adiw ZL, 2          
    add ZL, r20
    adc ZH, r1          

    ; B = (B - S[2*i+1]) >>> A) XOR A
    ld r20, Z+          
    ld r21, Z+          
    sub r18, r20        
    sbc r19, r21

    ; Rotate right by A mod 16
    mov r23, r16
    andi r23, 0x0F      
rotate_right_b:
    tst r23
    breq rotate_rb_done
    lsr r19
    ror r18
    brcc rotate_rb_skip
    ori r19, 0x80       
rotate_rb_skip:
    dec r23
    rjmp rotate_right_b
rotate_rb_done:

    eor r18, r16        
    eor r19, r17        

    ; Calculate S[2*i] address
    ldi ZL, low(S)
    ldi ZH, high(S)
    mov r20, r22
    lsl r20             
    lsl r20             
    add ZL, r20
    adc ZH, r1          

    ; A = (A - S[2*i]) >>> B) XOR B
    ld r20, Z+          
    ld r21, Z+          
    sub r16, r20        
    sbc r17, r21

    ; Rotate right by B mod 16
    mov r23, r18
    andi r23, 0x0F      
rotate_right_a:
    tst r23
    breq rotate_ra_done
    lsr r17
    ror r16
    brcc rotate_ra_skip
    ori r17, 0x80       
rotate_ra_skip:
    dec r23
    rjmp rotate_right_a
rotate_ra_done:

    eor r16, r18        
    eor r17, r19        

    pop ZH
    pop ZL

    dec r22
    brne decrypt_loop

    ; Final key subtraction
    ldi ZL, low(S)
    ldi ZH, high(S)
    ld r20, Z+          
    ld r21, Z+          
    sub r16, r20        
    sbc r17, r21
    ld r20, Z+          
    ld r21, Z+          
    sub r18, r20        
    sbc r19, r21

    ; Store plaintext
    ldi ZL, low(A)
    ldi ZH, high(A)
    st Z+, r16
    st Z+, r17
    ldi ZL, low(B)
    ldi ZH, high(B)
    st Z+, r18
    st Z+, r19

    pop ZH
    pop ZL
    pop r25
    pop r24
    pop r23
    pop r22
    pop r21
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    ret
