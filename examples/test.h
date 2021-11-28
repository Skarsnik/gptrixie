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
} s42;

struct s2 {
  struct s1	a;
  s42		aa;
  my64bits	b;
  int	c[99];
  double	d[4];
};

typedef struct s2 type2;

typedef struct {
union {
	char	charunion;
	struct {
		int a;
		int b;
	};
      } tunion;
} SWUnion;

struct s3 {
  type2 foo;
};

void	pretty_print(const char *toprint);
void	*do_stuff(struct s1 s, 
	  size_t piko,
	  bool b,
	  const char** const plo
 		);

int  flood(char *ref);
void testhello(type2 n);
