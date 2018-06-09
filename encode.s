section .bss

  array resq 256              ; holds character frequency
  array2 resb 256             ; characters to encode
  array2Size resq 1           ; number of characters to encode
  arrayCodeAddress resq 256   ; addresses where character coded begin in arraystatistic
  arrayStatistic resb 5000    ; holds codes fo characters
  textLength resq 1           ; length of text to encode

section .data

  newline db 0xa
  dash    db 0x2d   ; to display -

section .text
  global encode

; rdi - table with text, rsi - length of text, rdx - table for encoded text
encode:

  push rbp
  mov  rbp, rsp

  mov rax, rdi
  mov r9, textLength
  mov qword[r9], rsi

loopReadText:

  xor rbx, rbx
  mov bl, byte[rax]         ; read character
  shl rbx, 3                ; it's code *8, will be position for frequency

  push rax
  mov  rax, array
  mov  rcx, qword[rax+rbx]  ; get frequency
  inc  rcx
  mov  qword[rax+rbx], rcx  ; store back increased by 1
  pop  rax
  inc  rax

  mov rcx, rax
  sub rcx, rdi              ; address differences, byte takes one place,
                            ; so it will be number of charactera read
  cmp rcx, rsi
  jl loopReadText

endLoopForReadText:

  mov rax, array
  mov rbx, array2
  xor rcx, rcx
  mov r14, rsp              ; remember stack beginning
  mov r9,  rax

loopToFindLetters:

  mov r8, qword[rax]        ; load frequency

  cmp r8, 0                 ; if >0 write create a leaf
  jnz storeCharacterAndCreateLeaf
  add rax, 8                ; next frequency is 8 bits further

  mov r10, rax
  sub r10, r9

  cmp r10, 2048             ; 256 characters max, 256*8bytes = 2048
  jge beforeCreateTree
  jmp loopToFindLetters

storeCharacterAndCreateLeaf:

;this block will be a single leaf
  mov qword[rsp-8], r8      ; frequency
  mov qword[rsp-16], rcx    ; 0 - leaf isn't used, 1 - will be stored later while binding leaves into nodes
  mov qword[rsp-24], 0      ; 0 - has no children, because it's a leaf
  mov qword[rsp-32], 0      ; as above
  sub rsp, 32

  push rax
  sub  rax, r9
  shr  rax, 3
  mov  byte[rbx], al         ; store character in array2
  pop  rax

  inc rbx                   ; next position in array2
  add rax, 8                ; next frequency in array
  mov r10, rax
  sub r10, r9
                            ; if looped over all possible 256 characters
  cmp r10, 2048
  jl loopToFindLetters

beforeCreateTree:

  mov r11, array2
  sub rbx, r11
  mov r10, array2Size
  mov qword[r10], rbx

createTree:

  mov r11, r14              ; store stack address
  xor r9,  r9               ; first min frequency
  xor r10, r10              ; address of first min
  xor r12, r12              ; second min frequency
  xor r13, r13              ; address of second min

loopToFindFirstMin:         ; looking for lowest frequency(min)

  cmp r11, rsp              ; if we went through all leaves to actual stack
  je findSecondMin          ; pointer -> checked all leaves and found min

  mov rax, qword[r11-8]     ; load frequency
  mov rbx, qword[r11-16]    ; load value 0 - free to use, 1 - in use
  mov rcx, r11

  cmp rbx, 0                ; if it's used, check next one
  jnz incrementLoopToFindFirstMin

  cmp r9,  0
  jnz compareMinAndTemp

  mov r9,  rax
  mov r10, rcx
  sub r11, 32               ; next block(leaf)
  jmp loopToFindFirstMin

incrementLoopToFindFirstMin:

  sub r11, 32
  jmp loopToFindFirstMin

compareMinAndTemp:

  cmp rax, r9
  jge incrementLoopToFindFirstMin

  mov r9,  rax              ; new min saved to r9
  mov r10, rcx              ; save address
  sub r11, 32
  jmp loopToFindFirstMin

findSecondMin:

  mov r8, qword[r10-16]
  inc r8
  mov qword[r10-16], r8
  mov r11, r14

loopToFindSecMin:

  cmp r11, rsp
  je createNode

  mov rax, qword[r11-8]
  mov rbx, qword[r11-16]
  mov rcx, r11

  cmp rbx, 0
  jnz incrementLoopToFindSecMin

  cmp r12, 0
  jnz compareMinAndTemp2

  mov r12, rax
  mov r13, rcx
  sub r11, 32
  jmp loopToFindSecMin

incrementLoopToFindSecMin:

  sub r11, 32
  jmp loopToFindSecMin

compareMinAndTemp2:

  cmp rax, r12
  jge incrementLoopToFindSecMin

  mov r12, rax
  mov r13, rcx
  sub r11, 32
  jmp loopToFindSecMin

createNode:

  cmp r12, 0                      ; if no second min found, because one
  jz  finishedTree                ;  node is left( the root)

  mov r8, qword[r13-16]
  inc r8
  mov qword[r13-16], r8           ; setting the 0/1 - not used/used for second min

  add r9, r12                     ; sum of the two frequencies
  mov qword[rsp-8],  r9           ; creating a node out of two leaves, or nodes
  mov qword[rsp-16],  0           ; as with leaves, store 0 - not used, 1 - used
  mov qword[rsp-24], r10          ; address of first child
  mov qword[rsp-32], r13          ; address of second child
  sub rsp, 32
  jmp createTree

finishedTree:

  mov r12, r10

statistic:
  ; here we write coded of characters into arrayStatistic like:
  ; '2''1''1''0''2''0''0''0''2'... , where '2' is a break between different codes
  xor rcx, rcx

  sub rsp, 32
  mov qword[rsp+24], 0          ; 0 to signal
  mov qword[rsp+16], rcx        ; write index in arrayStatistic
  mov qword[rsp+8],  r12        ; root
  mov qword[rsp],    rcx        ; write index in arrayStatistic

  mov r15, arrayStatistic
  mov byte[r15+rcx], '2'
  inc rcx

  mov r8, qword[r12-24]

loopPutToStack:

  cmp r8, 0                              ; when r8 is one of the
  jz display                             ; character-leaves without children

  mov rax, qword[rsp]                    ; take previous index
  sub rsp, 16
  mov qword[rsp+8], r8
  mov qword[rsp],   rcx

loopToPreviousCode:

  xor rbx, rbx
  mov bl, byte[r15+rax]

  cmp bl, '2'
  je endOfPreviousCode

  mov byte[r15+rcx], bl

  inc rax
  inc rcx
  jmp loopToPreviousCode

endOfPreviousCode:

  mov byte[r15+rcx], '0'
  inc rcx
  mov byte[r15+rcx], '2'
  inc rcx

  mov r9,  r8
  mov r10, qword[r8-24]
  mov r8, r10
  jmp loopPutToStack

display:

    ; display character
  push rax
  push rdi
  push rsi
  push rdx
  push rcx
  push r11

  mov r10, r14
  sub r10, r9
  shr r10, 5

  mov r11, array2
  add r11, r10
  xor rbx, rbx
  mov bl, byte[r11]

  mov rax, 1
  mov rdi, 1
  mov rsi, r11
  mov rdx, 1
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, dash
  mov rdx, 1
  syscall

  pop r11
  pop rcx
  pop rdx
  pop rsi
  pop rdi
  pop rax

  mov rax, qword[rsp]
  shl rbx, 3

  push rcx
  mov  rcx, arrayCodeAddress
  mov  qword[rcx+rbx], rax
  pop  rcx

  xor r12, r12

loopToWriteCode:

  mov r13, r15
  add r13, rax

  cmp byte[r13], '2'
  je endOfCode

    ; display code
  push rbx
  push rax
  push rdi
  push rsi
  push rdx
  push rcx
  push r11

  mov rax, 1
  mov rdi, 1
  mov rsi, r13
  mov rdx, 1
  syscall

  pop r11
  pop rcx
  pop rdx
  pop rsi
  pop rdi
  pop rax
  pop rbx

  inc rax
  inc r12
  jmp loopToWriteCode

endOfCode:

  push rbx
  push rax
  push rdi
  push rsi
  push rdx
  push rcx
  push r11

  mov rax, 1
  mov rdi, 1
  mov rsi, newline
  mov rdx, 1
  syscall

  pop r11
  pop rcx
  pop rdx
  pop rsi
  pop rdi
  pop rax
  pop rbx

  add rsp, 16
  mov r9,  qword[rsp+8]       ; parent
  mov rax, qword[rsp]         ; index of parent

  cmp r9, 0
  jz codeFile

  mov r10, qword[r9-32]       ; right son
  mov qword[rsp+8], r10       ; save right son to parent place on stack
  mov qword[rsp],   rcx       ; save index of right son

loopToWriteParentCode:

  xor rbx, rbx
  mov bl, byte[r15+rax]

  cmp bl, '2'
  je  endOfParentCode

  mov byte[r15+rcx], bl
  inc rax
  inc rcx
  jmp loopToWriteParentCode

endOfParentCode:

  mov byte[r15+rcx], '1'
  inc rcx
  mov byte[r15+rcx], '2'
  inc rcx

  mov r9, r10
  mov r8, qword[r10-24]
  jmp loopPutToStack

codeFile:

  mov rbx, array2Size
  mov rsi, qword[rbx]
  xor rbx, rbx
  mov rax, rsi
  mov byte[rdx+rbx], al
  inc rbx
  xor rcx, rcx                  ; counter for characters

loopToAddLetterAndCode:

  mov r15, array2
  xor rax, rax
  mov al, byte[r15+rcx]         ; load character
  inc rcx

  cmp rcx, rsi
  jg  endOfCreatingHeader

  mov byte[rdx+rbx], al         ; store character in encoded text
  inc rbx                       ; counter for length of code

  mov r11, rbx
  inc r11                       ; counter to store code

  shl  rax, 3
  push r15
  mov  r15, arrayCodeAddress
  mov  r9,  qword[r15+rax]      ; index of code
  pop  r15

  xor rax, rax
  xor r12, r12
  xor r13, r13

loopWriteLetterCode:

  mov r15, arrayStatistic
  mov r10b, byte[r15+r9]
  inc r9

  cmp r10b, '2'
  je fillLastByte

  cmp r13, 7
  je addByte

  inc r13
  inc r12

  shl rax, 1

  cmp r10b, '0'
  je loopWriteLetterCode
  inc rax
  jmp loopWriteLetterCode

addByte:

  shl rax, 1

  cmp r10b, '0'
  je storeByte
  inc rax

storeByte:

  mov byte[rdx+r11], al
  xor rax, rax
  inc r11
  xor r13, r13
  inc r12
  jmp loopWriteLetterCode

fillLastByte:

  cmp r13, 0
  jz fillCodeLength

  mov r15, 8
  sub r15, r13

loopForSll:

  cmp r15, 0
  jz fillLastByteContinue

  shl rax, 1
  dec r15
  jmp loopForSll

fillLastByteContinue:

  cmp r13, 0
  jz fillCodeLength

  mov byte[rdx+r11], al
  inc r11

fillCodeLength:

  mov byte[rdx+rbx], r12b
  mov rbx, r11
  jmp loopToAddLetterAndCode

endOfCreatingHeader:

    ; in rbx position from where to encode
  mov r13, rbx ; now in r13

  xor rbx, rbx
  xor rax, rax
  mov r12, textLength
  mov rsi, qword[r12]
  xor r12, r12

loopToText:

  xor rcx, rcx
  mov cl, byte[rdi+rbx]
  inc rbx

  cmp rbx, rsi
  jg writeLastByte

  shl rcx, 3
  mov r15, arrayCodeAddress
  mov r8,  qword[r15+rcx]
  mov r11, r8
  mov r10, arrayStatistic
  add r10, r8

loopForCodeOfLetter:

  push r15
  mov  r15, arrayStatistic
  xor  r9,  r9
  mov  r9b, byte[r15+r8]
  pop  r15

  cmp r9b, '2'
  je loopToText
  inc r8

  cmp r12, 7
  je byteToCodedText

  shl rax, 1
  inc r12

  cmp r9b, '0'
  je loopForCodeOfLetter

  inc rax
  jmp loopForCodeOfLetter

byteToCodedText:

  shl rax, 1
  xor r12, r12

  cmp r9b, '0'
  je storeByte1
  inc rax

storeByte1:

  mov byte[rdx+r13], al
  inc r13
  xor rax, rax
  jmp loopForCodeOfLetter

writeLastByte:

  cmp r12, 0
  jz exit

  mov r15, 8
  sub r15, r12

loopForSll2:

  cmp r15, 0
  jz writeLastByteContinue

  shl rax, 1
  sub r15, 1
  jmp loopForSll2

writeLastByteContinue:

  mov byte[rdx+r13], al
  inc r13

exit:

  mov rax, r13
  mov rsp, rbp
  pop rbp
  ret
