; ==============================================
; Printf related macros
; ==============================================

%macro custom_printf 1

    mov rdi, %1
    
    xor rax, rax
    
    call printf

%endmacro

%macro custom_printf 2

    mov rdi, %1
    mov rsi, %2
    
    xor rax, rax
    
    call printf

%endmacro

%macro custom_printf 3

    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    
    xor rax, rax
    
    call printf

%endmacro

%macro custom_printf 4

    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    mov rcx, %4
    
    xor rax, rax
    
    call printf

%endmacro

; ==============================================
; Exit
; ==============================================

%macro exit 2

    custom_printf %1
    
    mov rax, 60
    mov rdi, %2
    
    syscall

%endmacro

%macro exit 3

    custom_printf %1, %2
    
    mov rax, 60
    mov rdi, %3
    
    syscall

%endmacro