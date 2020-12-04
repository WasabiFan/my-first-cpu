#include <stdint.h>

#define INPUT_BASE_ADDR ((volatile char*)0x1000)
#define OUTPUT_BASE_ADDR ((volatile char*)0x1800)

#define NUM_LEDS (10)
#define LEDMAT_BYTES_PER_CHANNEL (32)
#define LEDMAT_WIDTH 16
#define LEDMAT_HEIGHT 16
#define LEDMAT_BIT_STRIDE 8

volatile char *SW           = INPUT_BASE_ADDR  + 0x00;
volatile char *KEY          = INPUT_BASE_ADDR  + 0x10;
volatile char *LEDR         = OUTPUT_BASE_ADDR + 0x00;
volatile char *LEDMAT_RED   = OUTPUT_BASE_ADDR + 0x10;
volatile char *LEDMAT_GREEN = OUTPUT_BASE_ADDR + 0x30;

int dot_pos_x, dot_pos_y;

// approximately 6350 cycles of addi+bne in 1ms
#define MILLIS ((unsigned int)6350)

void sleep(unsigned int ticks) {
	while (ticks--) {
		asm("");
	}
}

char is_red_on(int x, int y) {
	return x == dot_pos_x && y == dot_pos_y;
}

void __attribute__ ((noinline)) render_ledmat() {
	for (int y = 0; y < LEDMAT_HEIGHT; y++) {
		uint16_t row = 0;
		for (int x = 0; x < LEDMAT_WIDTH; x++) {
			if (is_red_on(x, y)) {
				row |= 1 << (LEDMAT_WIDTH - x - 1);
			}
		}

		volatile uint16_t* red_row = &((volatile uint16_t*)LEDMAT_RED)[y];
		*red_row = row; 
	}
}

void constrain(int *val, int low, int high) {
	if (*val < low) {
		*val = low;
	} else if (*val >= high) {
		*val = high-1;
	}
}

int main() {
	volatile char *KEY_UP    = KEY + 0;
	volatile char *KEY_DOWN  = KEY + 1;
	volatile char *KEY_RIGHT = KEY + 2;
	volatile char *KEY_LEFT  = KEY + 3;

	dot_pos_x = 0;
	dot_pos_y = 0;

	while (1) {
		LEDR[0] = KEY[0];
		LEDR[1] = KEY[1];
		LEDR[2] = KEY[2];
		LEDR[3] = KEY[3];

		if (*KEY_UP) {
			dot_pos_y--;
		} else if (*KEY_DOWN) {
			dot_pos_y++;
		}

		if (*KEY_RIGHT) {
			dot_pos_x++;
		} else if (*KEY_LEFT) {
			dot_pos_x--;
		}

		constrain(&dot_pos_x, 0, LEDMAT_WIDTH);
		constrain(&dot_pos_y, 0, LEDMAT_HEIGHT);

		render_ledmat();

		sleep(50*MILLIS);
	}
}
