#include <stdio.h>
#include <stdlib.h>

void __attribute__((__cdecl__)) print(char* dest, char* src);

int main() {
    const int MAX_LENGTH = 64;

    char *src = "-FF";
    char *dest = (char *)malloc(MAX_LENGTH * sizeof(char));

    printf("hex: %s\n", src);
    print(dest, src);

    printf("dec: ");
    for (int i = 0; i < MAX_LENGTH; ++i) {
        if (dest[i]) {
            printf("%c", dest[i]);
        }
    }
    printf("\n");

    free(dest);

    return 0;
}
