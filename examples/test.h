#include <stdbool.h>
#include <stddef.h>

#define HELLO_INT 0
#define HELLO_FLOAT 1
#define HELLO_TEXT 3

typedef unsigned long long int my64bits;

typedef struct s1 {
  int	a;
  float	b;
  double	c;
  char *d;
};

struct s2 {
  s1	a;
  my64bits	b;
  int	c[];
  double	d[4];
};

void	pretty_print(const char *toprint);
void	*do_stuff(s1 s, 
	  size_t piko,
	  bool b);