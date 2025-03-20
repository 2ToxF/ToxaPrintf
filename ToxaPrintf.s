;!==============================================================
;! ToxaPrintf.s
;! My implementation of C standard lib printf() function
;!
;! Compilation: nasm -f elf64 ToxaPrintf.s
;!              ld -s -o ToxaPrintf.out ToxaPrintf.o
;!==============================================================

; CODE _________________________________________________________
section .text

global _start
global ToxaPrintf

PRINTF_BUFFER_SIZE  equ 512     ; Formatted print buffer size
NUMBERS_BUFFER_SIZE equ 65      ; Size of buffer for calculating numbers

SPECIFIER_CHAR      equ '%'     ; Character-specifier
STR_END_CHAR        equ 0       ; End of null-terminated strings

%macro BUFFER_PUTCHAR 1             ; Macro to print one character in standard output
    mov al, [%1]
    mov [rdi], al
    inc rdi
%endmacro

%macro CHECK_CALL_SPEC 3            ; Macro to not duplicate specifier check and calling specifier function
                                    ; (arg1 = specifier character, arg2 = label name, arg3 = specifier function)
    mov cl, %1
    cmp [rsi], cl       ; String specifier
    jne %2
        mov rbx, [rbp]  ; Extract arg from stack
        add rbp, 8      ; Go to next arg
        call %3
        inc rsi
        jmp .Loop
%2:
%endmacro

_start:
                lea rcx, [string]
                lea rdx, [another_string]
                mov r8,  'R'
                mov r9,  '3'
                call ToxaPrintf

                lea rcx, [another_string]
                call ToxaPrintf

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
                ; mov r10, rsp        ; Save stack pointer in R10

                push r9             ; Save first args in stack (except string addr)
                push r8
                push rdx

                push rbp
                push rsi
                push rdi

                mov rsi, rcx        ; Load first arg to source reg
                lea rdi, [buffer]   ; Pointer to buffer

                mov rbp, rsp
                add rbp, 8*3        ; Last 3 stack elements aren't args

                ; xor rcx, rcx

                mov r8b, STR_END_CHAR
                mov r9b, SPECIFIER_CHAR

.Loop:
                cmp [rsi], r8b
                je .EndLoop            ; if ([rsi] == STR_END_CHAR) break

                cmp [rsi], r9b
                je .Specifier           ; if ([rsi] != SPECIFIER_CHAR) putchar([rsi])
              ;{
                BUFFER_PUTCHAR rsi
                inc rsi             ; Move to next character
                jmp .Loop
              ;}
.Specifier:                         ; else {figure kind of specifier out}
              ;{
                inc rsi             ; Move to character after character-specifier

                ; CHECK_CALL_SPEC 'd', .NotDecimal, PrintDecimal
                ; CHECK_CALL_SPEC 'x', .NotHex, PrintHex
                ; CHECK_CALL_SPEC 'b', .NotBin, PrintBin
                ; CHECK_CALL_SPEC 'o', .NotOctal, PrintOctal

                mov cl, 'c'
                cmp [rsi], cl       ; String specifier
                jne .NotChar
                    BUFFER_PUTCHAR rbp  ; Put current stack element in buffer
                    inc rsi

                    add rbp, 8      ; Go to next arg
                    jmp .Loop
            .NotChar:

                mov cl, '%'
                cmp [rsi], cl       ; String specifier
                jne .NotPercent
                    BUFFER_PUTCHAR rsi  ; Put current string character ('%') in buffer
                    inc rsi
                    jmp .Loop
            .NotPercent:

                CHECK_CALL_SPEC 's', .NotString, PrintString
              ;}

.EndLoop:

                mov rdx, rdi
                lea rsi, [buffer]
                sub rdx, rsi        ; Calculate number of characters in buffer

                mov rax, 1          ; write(rdi, rsi, rdx)
                mov rdi, 1          ; Standard output
                syscall

                ; mov rax, rcx        ; Return value

.Exit:
                pop rdi
                pop rsi
                pop rbp

                add rsp, 8*3        ; Skip added 3 argument-registers
                push r10            ; Return func ret addr
                ret


;---------------------------------------------------------------
; Print R8B-terminated string
;
; Entry:    RBX = number to print
;           RDI = buffer
;
; Exit:     RDI = RDI + {number of printed characters}
; Destr:    RAX RCX {NEED_TO_UPDATE}
;---------------------------------------------------------------
PrintHex:

.Loop:
                push rbx

                and dl, 0x0f     ; Get last hex-digit (4 bits)
                add dl, '0'
                cmp dl, '9'
                jnz .DecDigit
                add dl, 'A' - '9' - 1
    .DecDigit:
                pop rbx
                shr rbx, 4
                jmp .Loop

.EndLoop:

.Exit:
                ret


;---------------------------------------------------------------
; Print R8B-terminated string
;
; Entry:    RBX = string to print
;           RDI = buffer
;           R8B = string termination character
;
; Exit:     RDI = RDI + {number of printed characters}
; Destr:    none
;---------------------------------------------------------------
PrintString:

.Loop:
                cmp [rbx], r8b
                je .EndLoop         ; while ([rbx] == r8b) ...
                BUFFER_PUTCHAR rbx
                inc rbx
                jmp .Loop

.EndLoop:

.Exit:
                ret


; DATA _________________________________________________________
section .data
string db "Hello (%s), World (%c%c)!", 0xa, 0   ; Null-terminated example format-string
another_string db "TOXA!!!", 0                  ; Just simple string

numbers_buffer times NUMBERS_BUFFER_SIZE db 0   ; Buffer for calculating numbers
buffer times PRINTF_BUFFER_SIZE db 0            ; Buffer for formatted print
