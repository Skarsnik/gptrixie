#ifndef TEST_H
#define TEST_H

#include <stddef.h>

foo *get_foo(void);

int copy_stuff(unsigned char *out, size_t outlen, const unsigned char *in, size_t inlen);

size_t get_some_config_var(void);
size_t get_another_config_var();

#endif
