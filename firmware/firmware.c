#define INPUT_BASE_ADDR ((volatile char*)0x1000)
#define OUTPUT_BASE_ADDR ((volatile char*)0x1800)

volatile char *LEDR = OUTPUT_BASE_ADDR;
volatile char *SW = INPUT_BASE_ADDR;

// approximately 6350 cycles of addi+bne in 1ms
#define MILLIS ((unsigned int)6350)

void sleep(unsigned int ticks) {
	while (ticks--) {
		asm("");
	};
}

int main() {
	while (1) {
		LEDR[0] = 0;
		sleep(1000 * MILLIS);
		LEDR[0] = 1;
		sleep(1000 * MILLIS);

		LEDR[1] = SW[0];
	}
}
