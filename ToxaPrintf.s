;!==============================================================
;! ToxaPrintf.s
;! My implementation of C standard lib printf() function
;!
;! Available specificators:
;!  %d - signed decimal
;!  %b - binary representation of a number
;!  %o - octal representation of a number
;!  %x - hexadecimal representation of a number
;!  %c - character from ASCII-table
;!  %s - string
;!  %% - % character
;!==============================================================


; DATA _________________________________________________________
section .data

PRINTF_BUFFER_SIZE  equ 512     ; Formatted print buffer size
NUMBERS_BUFFER_SIZE equ 64      ; Size of buffer for calculating numbers
SPECIFIER_CHAR      equ '%'     ; Character-specifier
STR_END_CHAR        equ 0       ; End of null-terminated strings

numbers_buffer times NUMBERS_BUFFER_SIZE db 0   ; Buffer for calculating numbers
buffer times PRINTF_BUFFER_SIZE db 0            ; Buffer for formatted print



; RODATA _______________________________________________________
section .rodata
PrintfSwitch:
    dq ToxaPrintf.unknown_specifier     ; 'a'   EMPTY
    dq ToxaPrintf.binary_specifier      ; 'b' - binary
    dq ToxaPrintf.char_specifier        ; 'c' - character
    dq ToxaPrintf.decimal_specifier     ; 'd' - decimal
    dq ToxaPrintf.unknown_specifier     ; 'e'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'f'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'g'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'h'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'i'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'j'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'k'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'l'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'm'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'n'   EMPTY
    dq ToxaPrintf.octal_specifier       ; 'o' - octal
    dq ToxaPrintf.unknown_specifier     ; 'p'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'q'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'r'   EMPTY
    dq ToxaPrintf.string_specifier      ; 's' - string
    dq ToxaPrintf.unknown_specifier     ; 't'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'u'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'v'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'w'   EMPTY
    dq ToxaPrintf.hex_specifier         ; 'x' - hex
    dq ToxaPrintf.unknown_specifier     ; 'y'   EMPTY
    dq ToxaPrintf.unknown_specifier     ; 'z'   EMPTY



; CODE _________________________________________________________
section .text

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
    jmp .Loop
%endmacro


;---------------------------------------------------------------
; Format printing (check README.md)
;
; Entry:    according to "fastcall":
;           RDI = string to format
;           RSI, RDX, RCX, R8, R9 = 2-6 args
;           Other args in stack (from right to left)
;
; Exit:     RAX = number of printed characters {NOT DONE}
; Destr:    R10 R11
;---------------------------------------------------------------
ToxaPrintf:
                pop r10             ; Save func ret addr in R11

                push r9             ; Save first args in stack (except string addr)
                push r8
                push rcx
                push rdx
                push rsi

                push rbx
                push rbp
                push rsi
                push rdi            ; Save immutable registers
                push r10            ; Save ret func addr

                lea rsi, [rdi]      ; Load first arg
                lea rdi, [buffer]   ; Pointer to buffer

                mov rbp, rsp
                add rbp, 8*5        ; Last 5 stack elements aren't args

                xor rcx, rcx

                mov r8b, STR_END_CHAR
                mov r9b, SPECIFIER_CHAR

.Loop:
                cmp [rsi], r8b
                je .EndLoop             ; if ([rsi] == STR_END_CHAR) break

                cmp [rsi], r9b
                je .Specifier           ; if ([rsi] != SPECIFIER_CHAR) putchar([rsi])
              ;{
                BUFFER_PUTCHAR [rsi]
                inc rsi             ; Move to next character
                jmp .Loop
              ;}
.Specifier:                         ; else {figure kind of specifier out}
              ;{
                inc rsi             ; Move to character after character-specifier

                mov r10b, '%'
                cmp [rsi], r10b
                je .percent_specifier

                mov r10b, 'a'
                cmp [rsi], r10b
                jb .unknown_specifier

                mov r10b, 'z'
                cmp [rsi], r10b
                ja .unknown_specifier

                ;switch
                xor r10, r10
                mov r10b, [rsi]
                sub r10, 'a'
                shl r10, 3
                add r10, PrintfSwitch   ; Calculate addr in jump-table
                mov r10, [r10]          ; Get addr from jump-table
                jmp r10

                .binary_specifier:
                    CALL_SPEC_FUNC PrintBin

                .char_specifier:
                    BUFFER_PUTCHAR [rbp]    ; Print current stack element
                    inc rsi
                    add rbp, 8              ; Go to next arg
                    jmp .Loop

                .decimal_specifier:
                    CALL_SPEC_FUNC PrintDecimal

                .octal_specifier:
                    CALL_SPEC_FUNC PrintOctal

                .string_specifier:
                    CALL_SPEC_FUNC PrintString

                .hex_specifier:
                    CALL_SPEC_FUNC PrintHex

                .percent_specifier:
                    BUFFER_PUTCHAR '%'      ; Print current string character ('%')
                    inc rsi
                    jmp .Loop

                .unknown_specifier:
                    inc rsi                 ; Skip unknown specifier
                    jmp .Loop
                ; end switch
              ;}

.EndLoop:
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

                add rsp, 8*5        ; Skip added 5 argument-registers
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
; Destr:    RAX RDX R10 R11
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
