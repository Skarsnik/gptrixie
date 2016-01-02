typedef struct {
  int	x;
  int	y;
} FakeObject;


FakeObject	*fakeobject_new();

void	fakeobject_init(FakeObject *obj);
void	fakeobject_print(FakeObject *obj);
void	fakeobject_dostuff_to_x(FakeObject *obj, int val);
void	fakeobject_add(FakeObject *obj1, FakeObject *obj2);


