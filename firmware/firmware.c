// TODO: change to char once we support andi
#define INPUT_BASE_ADDR ((volatile int*)0x1000)
#define OUTPUT_BASE_ADDR ((volatile int*)0x1800)

volatile int *LEDR = OUTPUT_BASE_ADDR;
volatile int *SW = INPUT_BASE_ADDR;

int main() {
	while (1) {
		LEDR[0] = 1;
		LEDR[1] = SW[0];
	}
}
