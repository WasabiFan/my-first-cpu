int func();

int main() {
	volatile int foo[20];
	foo[0] = 4;
	foo[1] = 6;
	foo[2] = 9;
	foo[0] = 3;
	foo[3] = 1000000000;

	int total = foo[0] + foo[1] + foo[2] + foo[3];
	total += func();
	return total;
}

int __attribute__ ((noinline)) func() {
	return 5;
}