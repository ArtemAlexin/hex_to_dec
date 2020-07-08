section         .text
 
                global          print
 
print:
                pushad
 
                xor     ebp,  ebp
 
                sub             esp, 16
 
                mov             edi, esp
 
                mov             ecx, 4
 
                mov             esi, [esp + 24 + 32] ; esi <- src
 
                call            read_long_hex ; read esi -> edi
 
                call        correct
 
                mov             esi, [esp + 20 + 32] ; esi <- dst
 
                mov             al, byte[esi]
 
                call        write_minus ; write '-' -> esi
 
                call            write_long_dec ; write edi -> esi
 
 
                mov             eax, 0
 
                call            write_char
 
 
                add             esp, 16
 
                popad
 
                ret
 
 
; checks if a long number is a zero
 
;    edi -- argument (long number)
 
;    ecx -- length of long number in qwords
 
; result:
 
;    ZF=1 if zero
 
is_zero:
 
                push            eax
 
                push            edi
 
                push            ecx
 
                xor             eax, eax
 
                rep scasd
 
 
                pop             ecx
 
                pop             edi
 
                pop             eax
 
                ret
 
write_minus:
 
                cmp     ebp, 0
 
                jz      .label1
 
                call            is_zero
 
                jz      .label1
 
                push    ecx
 
                mov     al,  "-"
 
                call            write_char
 
                pop     ecx
.label1:
 
                ret
 
correct:
                push            edx
                push            ebx
 
                push            ecx
;ebx -> 2^31
                mov     ebx, 2147483648
 
                mov     ecx, 3
 
                call            is_zero
 
                jnz     .not__int128_t_min
 
                mov     edx, [edi + 12]
 
                cmp     edx, ebx
 
                jne     .not__int128_t_min
 
                mov     ebp, 1
 
                pop     ecx
 
                jmp     .correct
 
.not__int128_t_min:
 
                mov     edx, [edi + 12]
 
                test            edx, ebx
 
                pop     ecx
 
                jz              .correct
 
                call            negate
.correct:
                pop     ebx
                pop     edx
                ret
 
; negate number in two"s compliment code
 
;   edi -- address of long number
 
;   ecx -- length of number
 
;   ebp -- sign
 
negate:
 
                ;~number
 
                push            edi
 
                push            ecx
 
.loop:
 
                mov             eax, [edi]
 
                not             eax
 
                mov             [edi], eax
 
                add     edi,   4
 
                dec             ecx
 
                jnz             .loop
 
                pop             ecx
 
                pop             edi
 
                clc
 
                ;number + 1
 
                mov             eax, 1
 
                call            add_long_short
 
                not             ebp
 
                ret
 
 
; adds 32-bit number to long number
 
;    edi -- address of summand #1 (long number)
 
;    eax -- summand #2 (32-bit unsigned)
 
;    ecx -- length of long number in qwords
 
; result:
 
;    sum is written to rdi
 
add_long_short:
 
                push            edi
 
                push            ecx
 
                push            edx
 
                xor             edx, edx
 
.loop:
 
                add             [edi], eax
 
                adc             edx, 0
 
                mov             eax, edx
 
                xor             edx, edx
 
                add             edi, 4
 
                dec             ecx
 
                jnz             .loop
 
                pop             edx
 
                pop             ecx
 
                pop             edi
 
                ret
 
 
 
; multiplies long number by a short
 
;    edi -- address of multiplier #1 (long number)
 
;    ebx -- multiplier #2 (32-bit unsigned)
 
;    ecx -- length of long number in qwords
 
; result:
 
;    product is written to edi
 
mul_long_short:
 
                push            eax
 
                push            edi
 
                push            ecx
 
                push            esi
 
                xor             esi, esi
 
.loop:
 
                mov             eax, [edi]
 
                mul             ebx
 
                add             eax, esi
 
                adc             edx, 0
 
                mov             [edi], eax
 
                add             edi, 4
 
                mov             esi, edx
 
                dec             ecx
 
                jnz             .loop
 
                pop             esi
 
                pop             ecx
 
                pop             edi
 
                pop             eax
 
                ret
 
 
 
; divides long number by a short
 
;    edi -- address of dividend (long number)
 
;    ebx -- divisor (32-bit unsigned)
 
;    ecx -- length of long number in qwords
 
; result:
 
;    quotient is written to edi
 
;    edx -- remainder
 
div_long_short:
 
                push            edi
 
                push            eax
 
                push            ecx
 
                lea             edi, [edi + 4 * ecx - 4]
 
                xor             edx, edx
 
.loop:
 
                mov             eax, [edi]
 
                div             ebx
 
                mov             [edi], eax
 
                sub             edi, 4
 
                dec             ecx
 
                jnz             .loop
 
                pop             ecx
 
                pop             eax
 
                pop             edi
 
                ret
 
 
; assigns a zero to long number
 
;    edi -- argument (long number)
 
;    ecx -- length of long number in dwords
 
set_zero:
 
                push            eax
 
                push            edi
 
                push            ecx
 
                xor             eax, eax
 
                rep stosd
 
                pop             ecx
 
                pop             edi
 
                pop             eax
 
                ret
 
; convert eax to digit
 
convert_to_digit:
 
                cmp             eax, "0"
 
                jb              .invalid_char
 
                cmp             eax, "9"
 
                jbe             .digit
 
                cmp             eax, "A"
 
                jb              .invalid_char
 
                cmp             eax, "F"
 
                jbe             .upper_letter
 
                cmp             eax, "a"
 
                jb              .invalid_char
 
                cmp             eax, "f"
 
                jbe             .letter
 
.invalid_char:
 
                mov             eax, 0xFF ; 0xFF -- special value means invalid char parsed
 
                ret
 
.digit:
 
                sub             eax, "0"
 
                ret
 
 
.upper_letter:
 
                sub             eax, "A"
 
                add             eax, 10
 
                ret
 
 
.letter:
 
                sub             eax, "a"
 
                add             eax, 10
 
                ret
 
 
; digit in eax, number begin in edi
 
add_digit:
 
                mov             ebx, 16
 
                call            mul_long_short
 
                call            add_long_short
 
                ret
 
 
 
; read long number from src
 
;    esi -- location for src
 
;    edi -- location for output (long number)
 
;    ecx -- length of long number in dwords
 
read_long_hex:
 
                push            ecx
 
                push            edi
 
                call            set_zero
 
                ;read first hex-digit and check sign
 
                call            read_char_hex
 
                or              eax, eax
 
                js              exit
 
                cmp             eax, 0
 
                je              .done
 
 
                cmp             eax, "-"
 
                jne             .not_sign
 
                not             ebp
 
                ;read other hex-digits
 
.loop:
 
                call            read_char_hex
 
                or              eax, eax
 
                js              exit
 
                cmp             eax, 0
 
                je              .done
 
.not_sign:
 
                call            convert_to_digit
 
                cmp             eax, 0xFF
 
                je              .skip_loop
 
                call            add_digit
 
                jmp             .loop
 
 
.done:
 
                pop             edi
 
                pop             ecx
 
                ret
 
 
.skip_loop:
 
                call            read_char_hex
 
                or              eax, eax
 
                js              exit
 
                cmp             eax, 0x0a
 
                je              exit
 
                jmp             .skip_loop
 
 
 
; write long number to stdout
 
;    edi -- argument (long number)
 
;    ecx -- length of long number in dwords
 
write_long_dec:
 
                push            eax
 
                push            ecx
 
                push            ebp
 
                mov             eax, 20
 
                mul             ecx
 
                mov             ebp, esp
 
                sub             esp, eax
 
                mov             eax, ebp
 
.loop:
 
                mov             ebx, 10
 
                call            div_long_short
 
                add             edx, "0"
 
                dec             eax
 
                mov             [eax], dl
 
                call            is_zero
 
                jnz             .loop
 
 
 
                mov             edx, ebp
 
                sub             edx, eax
 
                call            print_string
 
 
 
                mov             esp, ebp
 
                pop             ebp
 
                pop             ecx
 
                pop             eax
 
                ret
 
 
 
; read one char from stdin
 
; result:
 
;    eax == -1 if error occurs
 
;    eax \in [0; 255] if OK
 
read_char_hex:
                ; ebx -- descriptor
                ; ecx -- dst for read bytes
                ; edx -- number of bytes
 
                push            ecx
 
                push            edi
 
                push            ebx
 
                mov             al, byte[esi]
 
                inc             esi
 
                pop             ebx
 
                pop             edi
 
                pop             ecx
 
                ret
 
.error:
 
                mov             eax, -1
 
                add             esp, 1
 
                pop             edi
 
                pop             ecx
 
                ret
 
 
 
; write one char to stdout, errors are ignored
 
;    al -- char
 
write_char:
 
                ; ebx -- descriptor (rdi)
                ; ecx -- src for write bytes (rsi)
                ; edx -- number of bytes (rdx)
 
                push            edi
 
                push            esp
 
                push            edx
 
                push            eax
 
                push            ebx
 
                push            ecx
 
                push            edx
 
 
                mov             [esi], al
 
                inc              esi
 
 
                pop             edx
 
                pop             ecx
 
                pop             ebx
 
                pop             eax
 
                pop             edx
 
                pop             esp
 
                pop             edi
 
                ret
 
 
 
exit:
 
                mov             eax, 1
 
                xor             ebx, ebx
 
                int             0x80
 
 
 
; print string to dst (esi)
 
;    eax -- string
 
;    edx -- size
 
print_string:
 
                push            edx
                push            eax
 
.loop:
                push            eax
                mov             eax, [eax]
                call            write_char
                pop             eax
                inc             eax
                dec             edx
                jnz             .loop
 
                pop             eax
                pop             edx
 
                ret