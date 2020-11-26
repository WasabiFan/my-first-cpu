#define INPUT_BASE_ADDR ((volatile char*)0x1000)
#define OUTPUT_BASE_ADDR ((volatile char*)0x1800)

volatile char *LEDR = OUTPUT_BASE_ADDR;
volatile char *SW = INPUT_BASE_ADDR;

int main() {
	while (1) {
		LEDR[0] = 1;
		LEDR[1] = SW[0];
	}
}
