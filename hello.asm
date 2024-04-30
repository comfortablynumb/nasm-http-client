%include "utils.asm"

; ==============================================
; External Functions
; ==============================================

extern printf
extern sprintf
extern strstr
extern strlen
extern strcmp
extern strcpy
extern strncpy
extern strchr
extern get_sockaddr_in_for_hostname

; ==============================================
; Structs
; ==============================================

struc addrinfo_struct
    .a_flags        resd 1
    .a_family       resd 1
    .a_socktype     resd 1
    .a_protocol     resd 1
    .a_addrlen      resd 1
    .a_sockaddr     resq 1
    .a_canonname    resq 1
    .a_next         resq 1
endstruc

; ==============================================
; Data Section
; ==============================================

section .data
    
    ; ==============================================
    ; Variables
    ; ==============================================
    
    ; Syscalls + options
    
    SYSCALL_SOCKET                      equ 41
    SYSCALL_CONNECT                     equ 42
    SYSCALL_READ                        equ 0
    SYSCALL_WRITE                       equ 1
    
    SOCKET_AF_INET                      equ 2
    SOCKET_SOCK_STREAM                  equ 1
    SOCKET_NO_FLAGS                     equ 0
    
    ; Misc
            
    NL                                  equ 10
    
    ; Debug strings
    
    str_socket_calling                  db      " - Creating socket...",NL,0
    str_socket_result                   db      " - Socket result: %d",NL,0
    str_connect_calling                 db      " - Connecting (FD: %d)...",NL,0
    str_connect_result                  db      " - Connect result: %d",NL,0
    str_write_calling                   db      " - Sending request (FD: %d)...",NL,0
    str_write_result                    db      " - Write result: %d",NL,0
    str_read_calling                    db      " - Receiving response (FD: %d)...",NL,0
    str_read_result                     db      " - Read result: %s (%d bytes)",NL,0

    ; addrinfo_hints struct instance
    
    addrinfo_hints istruc addrinfo_struct
        at addrinfo_struct.a_flags,        dd    0
        at addrinfo_struct.a_family,       dd    SOCKET_AF_INET
        at addrinfo_struct.a_socktype,     dd    SOCKET_SOCK_STREAM
        at addrinfo_struct.a_protocol,     dd    0
        at addrinfo_struct.a_addrlen,      dd    0
        at addrinfo_struct.a_sockaddr,     dq    0
        at addrinfo_struct.a_canonname,    dq    0
        at addrinfo_struct.a_next,         dq    0
    iend
    
    ; Request
    
    request_body_template                  db      "%s %s HTTP/1.1",NL,"Host: %s",NL,NL,0
    request_default_uri                    db      "/",0
    
    ; Response
    
    response_buf_len                       equ 100000
    
    ; HTTP Methods (most common ones supported only :D)
    
    http_get_method                 db      "GET",0
    http_post_method                db      "POST",0
    http_put_method                 db      "PUT",0
    http_delete_method              db      "DELETE",0
    http_options_method             db      "OPTIONS",0
    
    ; Protocols
    
    http_service                    db      "http",0
    http_protocol                   db      "http://",0
    http_protocol_len               equ     $-http_protocol-1
    https_protocol                  db      "https://",0
    
    ; Options
    
    option_prefix                   db      "--",0
    http_get_method_option          db      "--GET",0
    http_post_method_option         db      "--POST",0
    http_put_method_option          db      "--PUT",0
    http_delete_method_option       db      "--DELETE",0
    http_options_method_option      db      "--OPTIONS",0
    
    ; Errors
    
    str_err_invalid_url_received            db      " - ERROR: Invalid URL received. It has to be in the following format (HTTPS not supported yet): http://somehost/some-uri-if-needed",NL,0
    str_err_cant_create_socket              db      " - ERROR: Could NOT create socket. Result: %d",NL,0
    str_err_cant_connect                    db      " - ERROR: Could NOT connect to the desired host. Result: %d",NL,0
    str_err_cant_write                      db      " - ERROR: Could NOT send request to the desired host. Result: %d",NL,0
    str_err_cant_read                       db      " - ERROR: Could NOT receive response from the desired host. Result: %d",NL,0
    str_err_invalid_argument                db      " - ERROR: An argument received is invalid. Check that it's not an empty string or an unknown option flag.",NL,0
    str_err_could_not_resolve_hostname      db      " - ERROR: Could NOT resolve hostname. Result: %d",NL,0
    str_err_could_not_prepare_request_body  db      " - ERROR: Could NOT prepare request body. Result: %d",NL,0
    
    ; Other messages
    
    str_done                        db      " - Done!",NL,0
    str_option_received             db      " - Option received: %s",NL,0
    str_uri_received                db      " - URI received: %s",NL,0
    str_request_to_send             db      " - Request to send: %s",NL,0
    
    ; Misc
    
    slash                           db      '/'

; ==============================================
; BSS Section
; ==============================================

section .bss

    request_body            resb 2000   ; Arbitrary length
    response_buf            resb response_buf_len
    fd                      resd 1
    
    ; URL
    
    hostname                resb 253    ; Reserve maximum length for the hostname
    hostname_on_request     resb 253
    uri_only                resb 2000   ; Arbitrary max length for the URI :)
    url_without_protocol    resb 2253   ; Everything without the protocol
    
    
    ; Options

    http_method             resq 1

    ; sockaddr_in struct (required for the "connect" syscall

    sockaddr                resq 1

; ==============================================
; Text Section
; ==============================================

section .text

    ; ==============================================
    ; Functions
    ; ==============================================
    
    global main
    
    main:
        push rbp
        mov rbp, rsp
        
        ; Parse arguments
        
        call _parse_arguments

        ; Create socket
        
        call _socket
        
        mov [fd], rax
        
        ; Connect
        
        mov rdi, [fd]
        
        call _connect
        
        ; Send request
        
        mov rdi, [fd]
        
        call _write
        
        ; Receive response
        
        mov rdi, [fd]
        
        call _read
        
        ; Done!
        
        exit str_done, 0
    
    _parse_arguments:
        
        push rbp
        mov rbp, rsp
        
        ; Initialize variables
        
        mov r15, http_get_method
        mov [http_method], r15 ; GET == Default HTTP Method
        mov r12, rdi ; argc
        mov r13, rsi ; argv
        
        ; Skip first argument, which is the binary file being called
        
        mov r14, 1 ; counter
        
        _parse_argument:
        
            cmp r14, r12
        
            jge _leave
        
            mov r15, [r13+8*r14]
            
            inc r14
            
            ; Check length
            
            mov rdi, r15
            
            call strlen
            
            cmp rax, 0
            
            je _error_invalid_argument
            
            ; Check if this is an option
            
            push r15
            
            mov rdi, r15
            
            call _parse_option
            
            mov rdi, r15
            
            pop r15
            
            cmp rax, 1
            
            je _parse_argument
            
            ; If not an option, check if this is the URL

            call _parse_url
            
            jmp _parse_argument
        
        _leave:
        
            cmp byte [sockaddr], 0
            
            je _error_invalid_url_received

            custom_printf str_uri_received, uri_only

            leave
            ret
    
    _parse_url:
    
        push rbp
        mov rbp, rsp
        
        ; Save URL
        
        mov r15, rdi
        
        ; Check protocol first (rdi is already the URL)
        
        mov rsi, http_protocol
        
        call strstr
        
        cmp rax, 0
        
        je _error_invalid_url_received
        
        ; Copy URL without protocol
        
        mov rdi, url_without_protocol       ; Destination
        
        lea rsi, [r15+http_protocol_len]    ; URL without protocol
        
        call strcpy
        
        ; Calculate URL without protocol length
        
        mov rdi, url_without_protocol
            
        call strlen
        
        mov r15, rax ; Save it in r15

        ; Find first occurrence of "/" (if any). If it has it, then that's the end of the hostname
        
        mov rdi, url_without_protocol       ; URL without protocol
        
        mov rsi, [slash]                    ; Find "/"
        
        call strchr
        
        cmp rax, 0
        
        je _set_default_uri
        
        mov rdi, uri_only
        
        mov rsi, rax
        
        call strcpy
        
        ; Calculate hostname length (url_without_protocol length - uri_only length)
        
        mov rdi, uri_only
            
        call strlen
        
        sub r15, rax
        
        jmp _extract_hostname
        
        _set_default_uri:
            
            mov rdi, [request_default_uri]
        
            mov [uri_only], rdi
            
            mov rdi, url_without_protocol
            
            mov [hostname], rdi
            
        _extract_hostname:
        
            mov rdi, hostname
            
            mov rsi, url_without_protocol
            
            mov rdx, r15
            
            call strncpy

            ; @TODO: Somewhere my "hostname" is being deleted. For now, let's just backup in another variable
            ;        this value... :facepalm

            mov rdi, hostname_on_request

            mov rsi, hostname

            mov rdx, r15

            call strncpy
            
            _resolve_hostname:
            
                ; Resolve hostname
                
                mov rdi, hostname

                mov rsi, 80 ; @TODO: Extract port from url!
                
                call get_sockaddr_in_for_hostname

                cmp rax, 0
                
                je _error_could_not_resolve_hostname

                mov qword [sockaddr], rax ; sockaddr_in , which has the resolved IP address
        
        _leave_parse_url:
       
            leave
            ret
    
    _parse_option:
    
        push rbp
        mov rbp, rsp
        
        ; rdi is already the argument
        
        mov rsi, option_prefix
        
        call strstr
        
        cmp rax, 0
        
        je _leave_parse_option
        
        mov r15, rdi
        
        custom_printf str_option_received, r15
        
        ; Check which option was received
        
        ; Is it a GET?
        
        mov rdi, r15
        
        mov rsi, http_get_method_option
        
        call strcmp
        
        cmp rax, 0
        
        je _set_http_get_method
        
        ; Is it a POST?
        
        mov rdi, r15
        
        mov rsi, http_post_method_option
        
        call strcmp
        
        cmp rax, 0
        
        je _set_http_post_method
      
        ; Is it a PUT?
        
        mov rdi, r15
        
        mov rsi, http_put_method_option
        
        call strcmp
        
        cmp rax, 0
        
        je _set_http_put_method
        
        ; Is it a DELETE?
        
        mov rdi, r15
        
        mov rsi, http_delete_method_option
        
        call strcmp
        
        cmp rax, 0
        
        je _set_http_delete_method
        
         ; Is it an OPTIONS?
        
        mov rdi, r15
        
        mov rsi, http_options_method_option
        
        call strcmp
        
        cmp rax, 0
        
        je _set_http_options_method
        
        ; Unknown flag? Return error
        
        jmp _error_invalid_argument
        
        _set_http_get_method:
        
            mov qword [http_method], http_get_method
            
            mov rax, 1
        
            jmp _leave_parse_option
            
        _set_http_post_method:
        
            mov qword [http_method], http_post_method
            
            mov rax, 1
        
            jmp _leave_parse_option
        
        _set_http_put_method:
        
            mov qword [http_method], http_put_method
        
            mov rax, 1
        
            jmp _leave_parse_option
        
        _set_http_delete_method:
        
            mov qword [http_method], http_delete_method
            
            mov rax, 1
        
            jmp _leave_parse_option
        
        _set_http_options_method:
        
            mov qword [http_method], http_options_method
            
            mov rax, 1
        
            jmp _leave_parse_option
        
        _leave_parse_option:

            leave
            ret
    
    _socket:
    
        push rbp
        mov rbp, rsp
        
        ; Create socket

        mov rax, SYSCALL_SOCKET
        mov rdi, SOCKET_AF_INET
        mov rsi, SOCKET_SOCK_STREAM
        mov rdx, SOCKET_NO_FLAGS
        
        syscall
        
        ; If error, exit with error code
        
        cmp rax, 0

        jl _error_socket

        leave
        ret
    
    _connect:
    
        push rbp
        mov rbp, rsp
        
        ; Save rdi
        
        mov r12, rdi
        
        ; Print what we're doing
        
        custom_printf str_connect_calling, r12
        
        ; Connect

        mov rax, SYSCALL_CONNECT
        mov rdi, r12                ; FD
        mov rsi, [sockaddr]
        mov rdx, 16
        
        syscall
        
        ; If error, exit with error code
        
        cmp rax, 0
        jl _error_connect
        
        ; Print result
        
        push rax
        
        custom_printf str_connect_result, rax
        
        pop rax
        
        leave
        ret
        
    _write:
    
        push rbp
        mov rbp, rsp
        
        ; Save rdi
        
        mov r12, rdi
        
        ; Print what we're doing
        
        custom_printf str_write_calling, r12
        
        ; Prepare request body
        
        mov rdi, request_body
        
        mov rsi, request_body_template
        
        mov rdx, [http_method]
        
        mov rcx, uri_only

        mov r8, hostname_on_request
        
        call sprintf
        
        cmp rax, 0
        
        jl _error_could_not_prepare_request_body

        cmp r11, rax

        custom_printf str_request_to_send, request_body
        
        ; Write
        
        mov rax, SYSCALL_WRITE
        mov rdi, r12                ; FD
        mov rsi, request_body
        mov rdx, r11
        
        syscall
        
        ; If error, exit with error code
        
        cmp rax, 0
        
        jl _error_write
        
        ; Print result
        
        push rax
        
        custom_printf str_write_result, rax
        
        pop rax
        
        leave
        ret
    
    _read:
        push rbp
        mov rbp, rsp
        
        ; Save rdi
        
        mov r12, rdi
        
        ; Print what we're doing
        
        custom_printf str_read_calling, r12
        
        ; Read
        
        mov rax, SYSCALL_READ
        mov rdi, r12                ; FD
        mov rsi, response_buf
        mov rdx, response_buf_len
        
        syscall
        
        ; If error, exit with error code
        
        cmp rax, 0
        jl _error_read
        
        ; Print result
        
        push rax
        
        custom_printf str_read_result, response_buf, rax
        
        pop rax
        
        leave
        ret
    
    _error_invalid_url_received:
    
        exit str_err_invalid_url_received, 1
    
    _error_invalid_argument:
    
        exit str_err_invalid_argument, 1
    
    _error_could_not_prepare_request_body:
    
        exit str_err_could_not_prepare_request_body, rax, 1
    
    _error_could_not_resolve_hostname:
    
        exit str_err_could_not_resolve_hostname, rax, 1
    
    _error_socket:
        
        exit str_err_cant_create_socket, rax, 1

    _error_connect:
        
        exit str_err_cant_connect, rax, 1
        
    _error_write:
        
        exit str_err_cant_write, rax, 1
    
    _error_read:
        
        exit str_err_cant_read, rax, 1