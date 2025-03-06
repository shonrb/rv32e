#include "Asm.h"

int main(int argc, const char **argv)
{
    if (argc != 2) {
        printf("Usage: %s [source file]\n", argv[0]);
        return 1;
    }

    char *str;
    size len;
    { 
        const char *src_file = argv[1];
        FILE *fp = fopen(src_file, "r");

        fseek(fp, 0, SEEK_END);
        len = ftell(fp);
        fseek(fp, 0, SEEK_SET);

        str = malloc(len);
        fread(str, 1, len, fp);
        fclose(fp);
    };
    return 0;
}

