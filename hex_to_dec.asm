section         .text
 
 
 
                global          _start
 
_start:
                xor     	ebp,  ebp
 
                sub             esp, 16
 
                mov             edi, esp
 
                mov             ecx, 4
 
                call            read_long_hex
 
                call      	correct
 
                call        	write_minus
 
                call            write_long_dec
 
                mov             al, 0x0a
 
                call            write_char
 
                jmp             exit
 
 

 
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
 
                call    is_zero
 
                jz      .label1
 
                push    ecx
 
                mov     al,  "-"
 
                call    write_char
 
                pop     ecx
.label1:
 
                ret
 
correct:
                push    edx
                push    ebx
 
                push    ecx
;ebx -> 2^31
                mov     ebx, 2147483648
 
                mov     ecx, 3
 
                call    is_zero
 
                jnz     .not__int128_t_min
 
                mov     edx, [edi + 12]
 
                cmp     edx, ebx
 
                jne     .not__int128_t_min
 
                mov     ebp, 1
 
                pop     ecx
 
                jmp     .correct
 
.not__int128_t_min:
 
                mov     edx, [edi + 12]
 
                test    edx, ebx
 
                pop     ecx
 
                jz      .correct
 
                call    negate
.correct:
                pop     ebx
                pop     edx
                ret
 

negate:
 
                ;~number
 
                push            edi
 
                push            ecx
 
.loop:
 
                mov             eax, [edi]
 
                not             eax
 
                mov             [edi], eax
 
                add             edi,   4
 
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
 
 
 

 
add_long_long:
 
                push            edi
 
                push            esi
 
                push            ecx
 
                clc
 
.loop:
 
                mov             eax, [esi]
 
                lea             esi, [esi + 4]
 
                adc             [edi], eax
 
                lea             edi, [edi + 4]
 
                dec             ecx
 
                jnz             .loop
 
 
 
                pop             ecx
 
                pop             esi
 
                pop             edi
 
                ret
 
 
 

 
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
 
 
 

 
mul_long_short:
 
                push            eax
 
                push            edi
 
                push            ecx
 
 
 
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
 
 
 
                pop             ecx
 
                pop             edi
 
                pop             eax
 
                ret
 
 
 
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
 
                mov             esi, invalid_char_msg
 
                mov             edx, invalid_char_msg_size
 
                call            print_string
 
                call            write_char
 
                mov             al, 0x0a
 
                call            write_char
 
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
 
 
add_digit:
 
                mov             ebx, 16
 
                call            mul_long_short
 
                call            add_long_short
 
                ret
 
 

 
read_long_hex:
 
                push            ecx
 
                push            edi
 
 
 
                call            set_zero
 
 
 
                ;read first hex-digit and check sign
 
                call            read_char_hex
 
                or              eax, eax
 
                js              exit
 
                cmp             eax, 0x0a
 
                je              .done
 
 
 
                cmp             eax, "-"
 
                jne             .not_sign
 
                not             ebp
 
                ;read other hex-digits
 
.loop:
 
                call            read_char_hex
 
                or              eax, eax
 
                js              exit
 
                cmp             eax, 0x0a
 
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
 
 
 
write_long_dec:
 
                push            eax
 
                push            ecx
 
                push            ebp
 
                mov             eax, 20
 
                mul             ecx
 
                mov             ebp, esp
 
                sub             esp, eax
 
 
 
                mov             esi, ebp
 
 
 
.loop:
 
                mov             ebx, 10
 
                call            div_long_short
 
                add             edx, "0"
 
                dec             esi
 
                mov             [esi], dl
 
                call            is_zero
 
                jnz             .loop
 
 
 
                mov             edx, ebp
 
                sub             edx, esi
 
                call            print_string
 
 
 
                mov             esp, ebp
 
                pop             ebp
 
                pop             ecx
 
                pop             eax
 
                ret
 
 
 
read_char_hex:
 
                push            ecx
 
                push            edi
 
                push            ebx
 
 
                sub             esp, 1
 
                mov             eax, 3
 
                xor             ebx, ebx
 
                mov             ecx, esp
 
                mov             edx, 1
 
                int             0x80
 
 
 
                cmp             eax, 1
 
                jne             .error
 
                xor             eax, eax
 
                mov             al, [esp]
 
                add             esp, 1
 
 
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
 
 
 
 
write_char:

 
                push            edi
 
                push            esi
 
                push            esp
 
                push            edx
 
                push            eax
 
 
                push            ebx
 
                push            ecx
 
                push            edx
 
 
                sub             esp, 1
 
                mov             [esp], al
 
 
 
                mov             eax, 4 ; fd
 
                mov             ebx, 1 ; stdout
 
                mov             ecx, esp
 
                mov             edx, 1 ; number
 
                int             0x80
 
                add             esp, 1
 
 
                pop             edx
 
                pop             ecx
 
                pop             ebx
 
 
                pop             eax
 
                pop             edx
 
                pop             esp
 
                pop             esi
 
                pop             edi
 
                ret
 
 
 
exit:
 
                mov             eax, 1
 
                xor             edi, edi
 
                int             0x80
 
 
 
 
print_string:
 
                push            eax
 
                push            ebx
 
                push            ecx
 
 
                mov             eax, 4;stdout
 
                mov             ebx, 1 ; fd
 
                mov             ecx, esi ; buffer
 
                int             0x80 ; syscall
 
                pop             ecx
 
                pop             ebx
 
                pop             eax
 
                ret
 
 
 
 
 
                section         .rodata
 
invalid_char_msg:
 
                db              "Invalid character: "
 
invalid_char_msg_size: equ             $ - invalid_char_msg