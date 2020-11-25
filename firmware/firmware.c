int main() {
	volatile int foo[20];
	foo[0] = 4;
	foo[1] = 6;
	foo[2] = 9;
	foo[0] = 3;

	int total = foo[0] + foo[1] + foo[2];
	return total;
}
