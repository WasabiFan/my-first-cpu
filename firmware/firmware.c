int func();

int main() {
	int data[20];
	for (int i = 0; i < 20; i++) {
		data[i] = i;
	}

	int total = data[0] + data[1] + data[2] + data[3];
	total += func();
	return total;
}

int __attribute__ ((noinline)) func() {
	return 5;
}