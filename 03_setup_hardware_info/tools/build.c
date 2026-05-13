#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#define BOOTSECT_SIZE 512
#define SETUP_SIZE    2048  /* 4 sectors * 512 bytes */

static void die(const char *msg)
{
    fprintf(stderr, "%s\n", msg);
    exit(1);
}

int main(int argc, char *argv[])
{
    int fd_in, fd_out;
    unsigned char buf[SETUP_SIZE];
    int n;

    if (argc != 3) {
        die("Usage: build bootsect setup");
    }

    fd_out = open("linux.img", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd_out < 0)
        die("Cannot create linux.img");

    /* Read bootsect */
    fd_in = open(argv[1], O_RDONLY);
    if (fd_in < 0)
        die("Cannot open bootsect");
    memset(buf, 0, BOOTSECT_SIZE);
    n = read(fd_in, buf, BOOTSECT_SIZE);
    if (n < 0)
        die("Cannot read bootsect");
    if (n < BOOTSECT_SIZE) {
        fprintf(stderr, "Warning: bootsect is %d bytes, padding to 512\n", n);
    }
    /* Ensure boot signature */
    buf[510] = 0x55;
    buf[511] = 0xAA;
    if (write(fd_out, buf, BOOTSECT_SIZE) != BOOTSECT_SIZE)
        die("Write error");
    close(fd_in);

    /* Read setup */
    fd_in = open(argv[2], O_RDONLY);
    if (fd_in < 0)
        die("Cannot open setup");
    memset(buf, 0, SETUP_SIZE);
    n = read(fd_in, buf, SETUP_SIZE);
    if (n < 0)
        die("Cannot read setup");
    if (n > SETUP_SIZE) {
        fprintf(stderr, "Warning: setup is larger than %d, truncating\n", SETUP_SIZE);
        n = SETUP_SIZE;
    }
    if (write(fd_out, buf, SETUP_SIZE) != SETUP_SIZE)
        die("Write error");
    close(fd_in);

    close(fd_out);
    printf("Build complete: linux.img (%d bytes = %d sectors)\n",
           BOOTSECT_SIZE + SETUP_SIZE, (BOOTSECT_SIZE + SETUP_SIZE) / 512);
    return 0;
}
