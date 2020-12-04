#include <stdint.h>

#define INPUT_BASE_ADDR ((volatile char*)0x1000)
#define OUTPUT_BASE_ADDR ((volatile char*)0x1800)

#define NUM_LEDS (10)
#define LEDMAT_BYTES_PER_CHANNEL (32)
#define LEDMAT_WIDTH 16
#define LEDMAT_HEIGHT 16
#define LEDMAT_BIT_STRIDE 8

#define SNAKE_LENGTH 8

volatile char *SW           = INPUT_BASE_ADDR  + 0x00;
volatile char *KEY          = INPUT_BASE_ADDR  + 0x10;
volatile char *LEDR         = OUTPUT_BASE_ADDR + 0x00;
volatile char *LEDMAT_RED   = OUTPUT_BASE_ADDR + 0x10;
volatile char *LEDMAT_GREEN = OUTPUT_BASE_ADDR + 0x30;

int dot_pos_x, dot_pos_y;

unsigned char cell_lifetimes[LEDMAT_HEIGHT][LEDMAT_WIDTH];

// approximately 6350 cycles of addi+bne in 1ms
#define MILLIS ((unsigned int)6350)

void sleep(unsigned int ticks) {
	while (ticks--) {
		asm("");
	}
}

char is_red_on(int x, int y) {
	return cell_lifetimes[y][x] > 0;
}

char is_green_on(int x, int y) {
	return x == dot_pos_x && y == dot_pos_y;
}

void __attribute__ ((noinline)) render_ledmat() {
	for (int y = 0; y < LEDMAT_HEIGHT; y++) {
		uint16_t red_row = 0, green_row = 0;
		for (int x = 0; x < LEDMAT_WIDTH; x++) {
			if (is_red_on(x, y)) {
				red_row |= 1 << (LEDMAT_WIDTH - x - 1);
			}

			if (is_green_on(x, y)) {
				green_row |= 1 << (LEDMAT_WIDTH - x - 1);
			}
		}

		volatile uint16_t* red_row_ptr = &((volatile uint16_t*)LEDMAT_RED)[y];
		volatile uint16_t* green_row_ptr = &((volatile uint16_t*)LEDMAT_GREEN)[y];
		*red_row_ptr = red_row;
		*green_row_ptr = green_row;
	}
}

void constrain(int *val, int low, int high) {
	if (*val < low) {
		*val = low;
	} else if (*val >= high) {
		*val = high-1;
	}
}

void reset_lifetimes() {
	for (int y = 0; y < LEDMAT_HEIGHT; y++) {
		for (int x = 0; x < LEDMAT_WIDTH; x++) {
			cell_lifetimes[y][x] = 0;
		}
	}
}

void decrement_lifetimes() {
	for (int y = 0; y < LEDMAT_HEIGHT; y++) {
		for (int x = 0; x < LEDMAT_WIDTH; x++) {
			if (cell_lifetimes[y][x] > 0) {
				cell_lifetimes[y][x]--;
			}
		}
	}
}

int main() {
	volatile char *KEY_UP    = KEY + 0;
	volatile char *KEY_DOWN  = KEY + 1;
	volatile char *KEY_RIGHT = KEY + 2;
	volatile char *KEY_LEFT  = KEY + 3;

	dot_pos_x = 0;
	dot_pos_y = 0;

	reset_lifetimes();

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

		cell_lifetimes[dot_pos_y][dot_pos_x] = SNAKE_LENGTH;

		render_ledmat();

		decrement_lifetimes();

		sleep(50*MILLIS);
	}
}
