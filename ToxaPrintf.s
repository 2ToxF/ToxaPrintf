;!==============================================================
;! ToxaPrintf.s
;! My implementation of C standard lib printf() function
;!
;! Compilation: nasm -f elf64 ToxaPrintf.s
;!              ld -s -o ToxaPrintf.out ToxaPrintf.o
;!==============================================================


; DATA _________________________________________________________
section .data

PRINTF_BUFFER_SIZE  equ 512     ; Formatted print buffer size
NUMBERS_BUFFER_SIZE equ 64      ; Size of buffer for calculating numbers
SPECIFIER_CHAR      equ '%'     ; Character-specifier
STR_END_CHAR        equ 0       ; End of null-terminated strings

string db "%% | d = %d | c = %c | x = %x | o = %o | b = %b | s = %s", 0xa, 0    ; Null-terminated example format-string
another_string db "TOXA!!!", 0                          ; Just simple string

numbers_buffer times NUMBERS_BUFFER_SIZE db 0   ; Buffer for calculating numbers
buffer times PRINTF_BUFFER_SIZE db 0            ; Buffer for formatted print



; RODATA _______________________________________________________
section .rodata
PrintfSwitch:
    dq L0       ; 'a'   EMPTY
    dq L2       ; 'b' - binary
    dq L3       ; 'c' - character
    dq L4       ; 'd' - decimal
    dq L0       ; 'e'   EMPTY
    dq L0       ; 'f'   EMPTY
    dq L0       ; 'g'   EMPTY
    dq L0       ; 'h'   EMPTY
    dq L0       ; 'i'   EMPTY
    dq L0       ; 'j'   EMPTY
    dq L0       ; 'k'   EMPTY
    dq L0       ; 'l'   EMPTY
    dq L0       ; 'm'   EMPTY
    dq L0       ; 'n'   EMPTY
    dq L15      ; 'o' - octal
    dq L0       ; 'p'   EMPTY
    dq L0       ; 'q'   EMPTY
    dq L0       ; 'r'   EMPTY
    dq L19      ; 's' - string
    dq L0       ; 't'   EMPTY
    dq L0       ; 'u'   EMPTY
    dq L0       ; 'v'   EMPTY
    dq L0       ; 'w'   EMPTY
    dq L24      ; 'x' - hex
    dq L0       ; 'y'   EMPTY
    dq L0       ; 'z'   EMPTY



; CODE _________________________________________________________
section .text

global _start
global ToxaPrintf

%macro BUFFER_PUTCHAR 1             ; Macro to print one character in standard output (arg = character)
    cmp rdi, buffer + PRINTF_BUFFER_SIZE
    jb %%NotFull

    push rax
    push rdx
    push rsi

    mov rdx, rdi
    lea rsi, [buffer]
    sub rdx, rsi        ; Calculate number of characters in buffer

    mov rax, 1          ; write(rdi, rsi, rdx)
    mov rdi, 1          ; Standard output
    syscall

    pop rsi
    pop rdx
    pop rax

    lea rdi, [buffer]

%%NotFull:
    mov al, %1
    mov [rdi], al
    inc rdi
    inc rcx
%endmacro

%macro CALL_SPEC_FUNC 1             ; Macro to not duplicate specifier check and calling specifier function
                                    ; (arg = specifier function)
    mov rbx, [rbp]  ; Extract arg from stack
    add rbp, 8      ; Go to next arg
    call %1
    inc rsi
    jmp LoopPrintf
%endmacro

_start:
                push another_string
                push 0b11100
                push 0o724
                mov r9,  0x6a4f
                mov r8,  'R'
                mov rdx, -1
                lea rcx, [string]
                call ToxaPrintf
                pop r9
                pop r9
                pop r9

                ; lea rcx, [another_string]
                ; call ToxaPrintf

                mov rax, 0x3c       ; exit64(rdi)
                xor rdi, rdi
                syscall

;---------------------------------------------------------------
; Format printing (check README.md)
;
; Entry:    according to "fastcall":
;           RCX         = string to format
;           RDX, R8, R9 = 2nd, 3d, 4th args
;           Other args in stack (from right to left)
;
; Exit:     RAX = number of printed characters {NOT DONE}
; Destr:    R10 {NEED_TO_UPDATE}
;---------------------------------------------------------------
ToxaPrintf:
                pop r10             ; Save func ret addr in R11

                push r9             ; Save first args in stack (except string addr)
                push r8
                push rdx

                push rbx
                push rbp
                push rsi
                push rdi            ; Save immutable registers
                push r10            ; Save ret func addr

                mov rsi, rcx        ; Load first arg to source reg
                lea rdi, [buffer]   ; Pointer to buffer

                mov rbp, rsp
                add rbp, 8*5        ; Last 5 stack elements aren't args

                xor rcx, rcx

                mov r8b, STR_END_CHAR
                mov r9b, SPECIFIER_CHAR

LoopPrintf:
                cmp [rsi], r8b
                je EndLoopPrintf        ; if ([rsi] == STR_END_CHAR) break

                cmp [rsi], r9b
                je .Specifier           ; if ([rsi] != SPECIFIER_CHAR) putchar([rsi])
              ;{
                BUFFER_PUTCHAR [rsi]
                inc rsi             ; Move to next character
                jmp LoopPrintf
              ;}
.Specifier:                         ; else {figure kind of specifier out}
              ;{
                inc rsi             ; Move to character after character-specifier

                mov r10b, '%'
                cmp [rsi], r10b
                je L27

                mov r10b, 'a'
                cmp [rsi], r10b
                jb L0

                mov r10b, 'z'
                cmp [rsi], r10b
                ja L0

                xor r10, r10
                mov r10b, [rsi]
                sub r10, 'a'
                shl r10, 3
                add r10, PrintfSwitch   ; Calculate addr in jump-table
                mov r10, [r10]          ; Get addr from jump-table
                jmp r10
                ; switch
                L2:
                    CALL_SPEC_FUNC PrintBin

                L3:
                    BUFFER_PUTCHAR [rbp]    ; Print current stack element
                    inc rsi
                    add rbp, 8              ; Go to next arg
                    jmp LoopPrintf

                L4:
                    CALL_SPEC_FUNC PrintDecimal

                L15:
                    CALL_SPEC_FUNC PrintOctal

                L19:
                    CALL_SPEC_FUNC PrintString

                L24:
                    CALL_SPEC_FUNC PrintHex

                L27:
                    BUFFER_PUTCHAR [rsi]    ; Print current string character ('%')
                    inc rsi
                    jmp LoopPrintf

                L0:
                    inc rsi                 ; Skip unknown specifier
                    jmp LoopPrintf
                ; end switch
              ;}

EndLoopPrintf:

                mov rdx, rdi
                lea rsi, [buffer]
                sub rdx, rsi        ; Calculate number of characters in buffer

                mov rax, 1          ; write(rdi, rsi, rdx)
                mov rdi, 1          ; Standard output
                syscall

                mov rax, rcx        ; Return value = number of printed characters

.Exit:
                pop r10             ; Get ret func addr
                pop rdi             ; Load immutable registers
                pop rsi
                pop rbp
                pop rbx

                add rsp, 8*3        ; Skip added 3 argument-registers
                push r10            ; Return func ret addr
                ret


;---------------------------------------------------------------
; Print decimal number
;
; Entry:    RBX = number to print
;           RDI = buffer
;
; Exit:     RDI = new buffer pointer
;           RCX = RCX + {number of printed characters}
;
; Destr:    RAX RDX R10 R11 {NEED_TO_UPDATE}
;---------------------------------------------------------------
PrintDecimal:

                xor r11, r11
                mov rax, rbx
                lea rbx, [numbers_buffer]
                mov r10, 10     ; Notation base

                cmp rax, 0
                jge .Loop       ; if (rax < 0) rax = -rax
                push rax
                BUFFER_PUTCHAR '-'
                pop rax
                neg rax

.Loop:
                cmp rax, 0
                je .EndLoop     ; while (rbx != 0) ...

                xor rdx, rdx
                div r10
                add dl, '0'
                mov [rbx + r11], dl
                inc r11

                jmp .Loop
.EndLoop:

                mov rdx, rbx
                call PrintNumber

.Exit:
                ret


;---------------------------------------------------------------
; Print binary number
;
; Entry:    RBX = number to print
;           RDI = buffer
;
; Exit:     RDI = new buffer pointer
;           RCX = RCX + {number of printed characters}
;
; Destr:    AL RDX R11
;---------------------------------------------------------------
PrintBin:

                xor r11, r11

                BUFFER_PUTCHAR '0'
                BUFFER_PUTCHAR 'b'
                lea rdx, [numbers_buffer]

.Loop:
                cmp rbx, 0
                je .EndLoop    ; while (rbx != 0) ...

                push rbx

                and bl, 0x01    ; Get last bit
                add bl, '0'     ; Convert to digit

                mov [rdx + r11], bl
                inc r11

                pop rbx
                shr rbx, 1      ; Go to next bit
                jmp .Loop
.EndLoop:

                call PrintNumber

.Exit:
                ret


;---------------------------------------------------------------
; Print octal number
;
; Entry:    RBX = number to print
;           RDI = buffer
;
; Exit:     RDI = new buffer pointer
;           RCX = RCX + {number of printed characters}
;
; Destr:    AL RDX R11
;---------------------------------------------------------------
PrintOctal:

                xor r11, r11

                BUFFER_PUTCHAR '0'
                BUFFER_PUTCHAR 'o'
                lea rdx, [numbers_buffer]

.Loop:
                cmp rbx, 0
                je .EndLoop    ; while (rbx != 0) ...

                push rbx

                and bl, 0x07    ; Get last 3 bits
                add bl, '0'     ; Convert to digit

                mov [rdx + r11], bl
                inc r11

                pop rbx
                shr rbx, 3      ; Go to next 3 bits
                jmp .Loop
.EndLoop:

                call PrintNumber

.Exit:
                ret


;---------------------------------------------------------------
; Print hex number
;
; Entry:    RBX = number to print
;           RDI = buffer
;
; Exit:     RDI = new buffer pointer
;           RCX = RCX + {number of printed characters}
;
; Destr:    AL RDX R11
;---------------------------------------------------------------
PrintHex:

                xor r11, r11

                BUFFER_PUTCHAR '0'
                BUFFER_PUTCHAR 'x'
                lea rdx, [numbers_buffer]

.Loop:
                cmp rbx, 0
                je .EndLoop    ; while (rbx != 0) ...

                push rbx

                and bl, 0x0f    ; Get last hex-digit (4 bits)
                add bl, '0'     ; Convert to digit
                cmp bl, '9'
                jbe .DecDigit
                add bl, 'a' - '9' - 1   ; Convert to letter if neccessary
    .DecDigit:

                mov [rdx + r11], bl
                inc r11

                pop rbx
                shr rbx, 4      ; Go to next 4 bits
                jmp .Loop
.EndLoop:

                call PrintNumber

.Exit:
                ret


;---------------------------------------------------------------
; Print number from numbers buffer
;
; Entry:    RDX = numbers buffer
;           R11 = number of chars to move
;           RDI = printf buffer
;
; Exit:     RDI = new buffer pointer
;           RCX = RCX + {number of printed characters}
;           R11 = 0
;
; Destr:    AL
;---------------------------------------------------------------
PrintNumber:

.Loop2:
                cmp r11, 0
                je .EndLoop2    ; while (r11 != 0)

                dec r11
                BUFFER_PUTCHAR [rdx + r11]
                jmp .Loop2
.EndLoop2:

.Exit:
                ret



;---------------------------------------------------------------
; Print R8B-terminated string
;
; Entry:    RBX = string to print
;           RDI = buffer
;           R8B = string termination character
;
; Exit:     RDI = new buffer pointer
;           RCX = RCX + {number of printed characters}
;
; Destr:    AL
;---------------------------------------------------------------
PrintString:

.Loop:
                cmp [rbx], r8b
                je .EndLoop         ; while ([rbx] == r8b) ...
                BUFFER_PUTCHAR [rbx]
                inc rbx
                jmp .Loop

.EndLoop:

.Exit:
                ret
