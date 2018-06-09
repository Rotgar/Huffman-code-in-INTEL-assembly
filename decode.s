  section .bss
    array resb 256          ; array to hold characters
    extraChar resb 1        ; character coded as 0's only, used at end

  section .data
    newLineChar db 0xa

  section .text
    global decode

  decode:
      ; rdi - encoded text, rsi - number of byte encoded,
      ; rdx - address to write decoded text to

    push rbp
    mov  rbp, rsp

    xor rax, rax
    xor rcx, rcx            ; counter for characters in header
    xor r8,  r8             ; counter to read encoded bytes
    xor r9,  r9             ; counter to store info

    mov al, byte[rdi+r8]    ; number of characters
    inc r8
    mov byte[rdx+r9], al
    inc r9

  loopForHeader:

    cmp rcx, rax
    je loopForText

    xor rbx, rbx
    mov bl, byte[rdi+r8]          ; read a character
    inc r8
    inc rcx                       ; +1 to number of characters read
    mov byte[rdx+r9], bl
    inc r9

    xor rbx, rbx
    mov bl, byte[rdi+r8]          ; read code length
    inc r8
    mov byte[rdx+r9], bl
    inc r9

    xor r13, r13                  ; counter for code length
    xor r15, r15
    mov r15b, bl                  ; remember code length

  readBits:

    xor r14, r14                  ; counter for bits
    xor rbx, rbx
    mov bl, byte[rdi+r8]          ; read byte of code
    inc r8

  loopForCode:

    cmp r13, r15
    je loopForHeader

    cmp r14, 8
    je readBits
    inc r14
    inc r13

    mov r12, 128                    ; 128 = 1000 0000 is a mask to get first
    and r12, rbx                    ; bit, either 0 or 1
    shl rbx, 1                      ; to get next bit of code

    cmp r12, 0                      ; if the bit was 0
    jz storeZero

    mov byte[rdx+r9], '1'           ; if the bit was 1
    inc r9
    jmp loopForCode

  storeZero:

    mov byte[rdx+r9], '0'
    inc r9
    jmp loopForCode

  loopForText:

    cmp r8, rsi                   ; loop till all bytes are read
    je decodeHeader

    xor rbx, rbx
    mov bl, byte[rdi+r8]          ; get encoded byte of characters
    inc r8

    xor r10, r10                  ; counter of bits

  readBits1:

    cmp r10, 8                    ; when byte was read
    je loopForText

    mov r12, 128
    and r12, rbx
    shl rbx, 1

    cmp r12, 0
    jz storeZero1

    mov byte[rdx+r9], '1'
    inc r9
    inc r10
    jmp readBits1

  storeZero1:

    mov byte[rdx+r9], '0'
    inc r9
    inc r10
    jmp readBits1

  decodeHeader:

    xor r8, r8                    ; counter for reading text`
    xor r9, r9                    ; counter for array to keep characters in

    mov r15, array
    xor rax, rax
    mov al, byte[rdx+r8]          ; counter of characters
    inc r8

    sub rsp, 24                   ; block for root
    mov r14, rsp                  ; remember root address
    mov qword[r14], 0             ; will be address of character in array in block of children
    mov qword[r14+8], 0           ; address of left child
    mov qword[r14+16], 0          ; address of right child

  loopForDecodingCharacters:

    cmp rax, 0                    ; all characters read, and tree created
    jz endBuildTree

    dec rax
    xor rbx, rbx
    mov bl, byte[rdx+r8]          ; read character
    inc r8
    mov byte[r15+r9], bl          ; store it in array

    mov r11, r15
    add r11, r9                   ; in r11 address of character
    inc r9

    xor rbx, rbx
    mov bl, byte[rdx+r8]          ; read length of code
    inc r8

    mov r12, r14                  ; root

  loopForReadingCode:

    cmp rbx, 0
    jz loopForDecodingCharacters

    dec rbx
    xor rcx, rcx
    mov cl, byte[rdx+r8]
    inc r8

    cmp cl, '1'
    je checkRight

    mov r13, qword[r12+8]           ; left child address

    cmp r13, 0
    jz createNewLeftNode

    mov r12, r13
    jmp loopForReadingCode

  checkRight:

    mov r13, qword[r12+16]          ; right child address

    cmp r13, 0
    jz createNewRightNode

    mov r12, r13
    jmp loopForReadingCode

  createNewLeftNode:

    sub rsp, 24                     ; create left child
    mov qword[r12+8],  rsp          ; remeber it's address
    mov qword[rsp],    0            ; character address
    mov qword[rsp+8],  0            ; left child address
    mov qword[rsp+16], 0            ; right child address
    mov r12, rsp

    cmp rbx, 0
    jnz loopForReadingCode
                                    ; if code was read, then this is the
    mov qword[r12], r11             ; leaf of a single character
    jmp loopForDecodingCharacters

  createNewRightNode:

    sub rsp, 24
    mov qword[r12+16], rsp
    mov qword[rsp],    0
    mov qword[rsp+8],  0
    mov qword[rsp+16], 0
    mov r12, rsp

    cmp rbx, 0
    jnz loopForReadingCode

    mov qword[r12], r11
    jmp loopForDecodingCharacters

  endBuildTree:

    mov r12, r14
    xor r11, r11
    xor rcx, rcx

  loopDecodingText:

    xor rax, rax
    mov al, byte[rdx+r8]

    cmp al, 0                     ; if it's the end, and text was decoded
    jz beforeCheck

    inc r8

    cmp al, '1'
    je goRight

    mov rbx, qword[r12+8]

    cmp rbx, 0
    jz readLetterL

    mov r12, rbx
    jmp loopDecodingText

  goRight:

    inc rcx
    mov rbx, qword[r12+16]

    cmp rbx, 0
    jz readLetterR

    mov r12, rbx
    jmp loopDecodingText

  readLetterL:

    mov r9, qword[r12]
    xor rbx, rbx
    mov bl, byte[r9]
    mov byte[rdx+r11], bl
    inc r11

    mov r12, qword[r14+8]

    cmp rcx, 0
    jz storeExtraChar
    xor rcx, rcx

    jmp loopDecodingText

  storeExtraChar:
                                ; the extraChar with only 0's in code is stored for later
    mov r15, extraChar
    mov byte[r15], bl

    xor rcx, rcx
    jmp loopDecodingText

  readLetterR:

    mov r9, qword[r12]
    xor rbx, rbx
    mov bl, byte[r9]
    mov byte[rdx+r11], bl
    inc r11

    xor rcx, rcx
    mov r12, qword[r14+16]
    jmp loopDecodingText

  beforeCheck:
    ; Here we check if too many characters were sotred in decoded text.
    ; It can happen if last encoded byte was full of 0's and a character
    ; can be coded as such. The newSpace is at the end always. It may be
    ; coded as 00100 for example and sotred in encoded text on last two
    ; bytes for example xxxx0010 00000000 - one 0 must be placed on
    ; an extra last byte, and the rest of it is filled with 0.
    ; A character which is coded as 0's, would be stored at the end of
    ; decoded text then. Here we check if such situation occured, and
    ; decrease the text length for all unwanted characters.

    mov rax, r11        ; r11 points to 0
    dec rax             ; rax point to last letter saved in text

    mov r15, extraChar
    mov r14, newLineChar

  checkIfTooMuch:

    cmp rax, 0
    jl exit

    xor rbx, rbx
    mov bl, byte[rdx+rax]
    dec rax

    cmp bl, byte[r15]
    je checkIfTooMuch

  newLine:

    cmp bl, byte[r14]
    jne checkIfTooMuch

    add rax, 2

  exit:
                          ; in rax length of decoded text
    mov rsp, rbp
    pop rbp
    ret
