unsigned short from[256 * 3] __attribute__((aligned(32)));
unsigned short to[16] = {0};

void test(unsigned short* from, unsigned short* to);

int main()
{
for (int i = 0; i < 256*3; i++) from[i] = i;

for (int i = 0; i < 1024 * 1024 * 100; i++) {
test(from, to);
}

}
