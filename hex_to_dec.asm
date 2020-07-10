section .data
;для статических штук решил не использовать регистры, потому что их мало и это очень неудобно
    number_of_digits:    dd 0 ;в ней будет хранится количество цифр
 
    number_pointer:    times 4 dd 0 ;заполнить нулями, оказывается можно так просто
 
    shoud_be_negate:  db 0
 
section .text
        global print
 
    print:
        pushad
;указывает на src
        call  get_source_begin
;ecx - сдвиг относительно адреса(используя такой подход мы сразу и количество посчитаем)
        xor   ecx, ecx
.char_counter:
        call  read_char
        cmp   bl, 0
        jnz   .char_counter
        dec   ecx
        mov   [number_of_digits], ecx
 
;надо обработать минус в начале
        call   get_source_begin
        mov    bl, byte[eax]
        cmp    bl, '-'
        jne    .not_invert
 
        call negate_number
        ;посчитали лишний минус
        mov    ecx, -1
        call   change_number_count
 
.not_invert:
        xor    ecx, ecx
 
.parse:
        call   get_source_begin
        add    eax, [shoud_be_negate]
        mov    bl, byte [eax+ecx]
        cmp    bl, 0
        jz     .parsed
 
;без обработки ошибок, стало проще
        cmp    bl, 'A'
        jge     .letter
        jl    .number
 
.repeat_convertion:
        mov    edi, [number_of_digits]
        call   calc_idx
        push   ecx
        push   ebx
        call   move_and_zeroize
;цикл do-while
.loop:
        cmp    edi, 0
        je     .end_of_loop
        call   shift_number
        dec    edi
        jmp    .loop
 
.end_of_loop:
;насколько я понял, мне не стоит юзать никакие long_numbers, поэтому тупо работаю с 4 регистрами
        add   [number_pointer+ 12], edx
        adc   [number_pointer+ 8], ecx
        adc   [number_pointer+ 4], ebx
        adc   [number_pointer], eax
        pop   ebx
        pop   ecx
;продолжаю парсить
        inc   ecx
        jmp   .parse
 
.number:
        sub   bl, '0'
        jmp   .repeat_convertion
 
.letter:
        cmp   bl, 'F'
        jg    .cond1
        jmp   .cond2
    .cond1:
        sub   bl, 'a'
        add   bl, 10
        jmp  .repeat_convertion
    .cond2:
        sub   bl, 'A'
        add   bl, 10
        jmp   .repeat_convertion
 
.parsed:
        xor   esi, esi
        call  is_negative
        jnz   .not_inv
        mov   eax, 0
        mov   [shoud_be_negate], eax
.inv:
        call  mov_num_to_registers
        call  inv_all
        call  inc_128bit_num
        call  mov_registers_to_num
.not_inv:
        mov   eax, [number_pointer]
        test  eax, 0x80000000
        jz    .convertion
 
        ;не забываем про int_128_t_min, сначала забыл
        cmp    eax, 0x80000000
        jne    .not_int128_t_min
        push   edi
        push   ecx
        mov    ecx, 3
        lea    edi, [number_pointer + 4]
        call   is_zero
        jz     .int128_t_min
        pop    ecx
        pop    edi
.not_int128_t_min:
        call   negate_number
        jmp    .inv
 
.int128_t_min:
         call  negate_number
         pop   ecx
         pop   edi
 
.convertion:
        ;занулим, регистры, они нам понадобятся
        ;погуглил как делать нормально перевод и реализовал
        xor    ecx, ecx
        xor    edx, edx
        xor    ebx, ebx
;пушу на стэк, чтобы при выводе удобно брать цифры, тоже нагуглил такой трюк
.conv_loop:
        mov    edi, 10
        mov    eax, [number_pointer + ecx * 4]
        div    edi
        or     ebx, eax
        mov    [number_pointer + ecx * 4], eax
        inc    ecx
        cmp    ecx, 4
        jne    .conv_loop
        inc    esi
        push   edx
        cmp    ebx, 0
        jnz    .convertion
 
;записали количество десятичных цифр
        mov    [number_of_digits], esi
        mov    eax, [esp+32+4+esi*4]
;индекс для вывода
        xor    ecx, ecx
 
        call   is_negative
        jnz    .write_num
 
        mov    bl, '-'
        mov    [eax], bl
        inc    ecx
 
        push   ecx
        mov    ecx, 1
        call   change_number_count
        pop    ecx
 
.write_num:
        pop    ebx
        add    ebx, '0'
        mov    [eax+ecx], ebx
 
        inc    ecx
        cmp    ecx, [number_of_digits]
 
        jl     .write_num
.done:
        mov    bl, 0
        mov    [eax+ecx], bl
        popad
        ret
 
is_zero:
        push    eax
        push    edi
        push    ecx
        xor     eax, eax
 
        rep scasd
 
        pop     ecx
        pop     edi
        pop     eax
        ret
;ecx - shift, eax - adress
read_char:
        mov     bl, [eax + ecx]
        inc     ecx
        ret
;eax -> *source
get_source_begin:
        ;+4 из-за того что вызываем функцию
        mov     eax, [esp+32+4*2 + 4]
        ret
negate_number:
        push    eax
        mov     eax, 1
        mov     [shoud_be_negate], eax
        pop     eax
        ret
;number_of_digits+=ecx
change_number_count:
        push    ecx
        push    eax
        mov     eax, [number_of_digits]
        add     eax, ecx
        mov     [number_of_digits], eax
        pop     eax
        pop     ecx
        ret
move_and_zeroize:
        xor     edx, edx
        mov     dl, bl
        xor     ecx, ecx
        xor     ebx, ebx
        xor     eax, eax
        ret
;edi - размер, ecx - индекс слева направо
calc_idx:
        sub     edi,  ecx
        ;нумерация с нуля
        dec     edi
        ret
;умножает число на 16
shift_number:
        shld    eax, ebx, 4
        shld    ebx, ecx, 4
        shld    ecx, edx, 4
        shl     edx, 4
        ret
;устанавливает ZF
is_negative:
        push    eax
        mov     eax, 1
        cmp     [shoud_be_negate], eax
        pop     eax
        ret
inv_all:
        not     ebx
        not     eax
        not     edx
        not     ecx
        ret
inc_128bit_num:
        add     edx, 1
        adc     ecx, 0
        adc 	ebx, 0
        adc     eax, 0
        ret
mov_num_to_registers:
        mov     eax, [number_pointer]
        mov     ebx, [number_pointer + 4]
        mov     ecx, [number_pointer + 8]
        mov     edx, [number_pointer + 12]
        ret
mov_registers_to_num:
        mov     [number_pointer], eax
        mov     [number_pointer + 4], ebx
        mov     [number_pointer + 8], ecx
        mov     [number_pointer + 12], edx
        ret