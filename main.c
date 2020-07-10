#include <stdio.h>
#include <stdlib.h>

void __attribute__((__cdecl__)) hex_to_dec(char* dest, char* src);

int main() {

    char *src = "-FF";
    char dest[200];
    printf("hex: %s\n", src);
    hex_to_dec(dest, src);

    printf("dec: %s\n", dest);


    return 0;
}
