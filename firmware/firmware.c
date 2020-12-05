#include <stdint.h>

#include "pix.c"

#define INPUT_BASE_ADDR ((volatile char*)0x1000)
#define OUTPUT_BASE_ADDR ((volatile char*)0x1800)

#define NUM_LEDS (10)
#define LEDMAT_BYTES_PER_CHANNEL (32)
#define LEDMAT_WIDTH 16
#define LEDMAT_HEIGHT 16
#define LEDMAT_BIT_STRIDE 8

#define SNAKE_LENGTH 10

volatile char * const SW           = INPUT_BASE_ADDR  + 0x00;
volatile char * const KEY          = INPUT_BASE_ADDR  + 0x10;
volatile char * const LEDR         = OUTPUT_BASE_ADDR + 0x00;
volatile char * const LEDMAT_RED   = OUTPUT_BASE_ADDR + 0x10;
volatile char * const LEDMAT_GREEN = OUTPUT_BASE_ADDR + 0x30;

int dot_pos_x, dot_pos_y;

#define DIR_UP    0
#define DIR_RIGHT 1
#define DIR_DOWN  2
#define DIR_LEFT  3
char current_direction;

char is_game_over;

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

void render_game_over() {
	volatile uint16_t* red_rows = ((volatile uint16_t*)LEDMAT_RED);
	volatile uint16_t* green_rows = ((volatile uint16_t*)LEDMAT_GREEN);

	const uint16_t left_mask = is_game_over == 1 ? 0xFFFF : 0x0000;
	const uint16_t right_mask = ~left_mask;

	for (int row = 0; row < LEDMAT_HEIGHT; row++) {
		red_rows[row] = (left_eye[row] & left_mask) | (right_eye[row] & right_mask) | mouth[row];
		green_rows[row] = (left_eye[row] & ~left_mask) | (right_eye[row] & ~right_mask);
	}

	if (is_game_over == 1) {
		is_game_over = 2;
	} else {
		is_game_over = 1; 
	}
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

void move_tick_in_current_direction() {
	switch (current_direction) {
		case DIR_UP:    dot_pos_y--; break;
		case DIR_DOWN:  dot_pos_y++; break;
		case DIR_RIGHT: dot_pos_x++; break;
		case DIR_LEFT:  dot_pos_x--; break;
		default:        break;
	}
}

int main() {
	volatile char *KEY_RIGHT = KEY + 0;
	volatile char *KEY_DOWN  = KEY + 1;
	volatile char *KEY_UP    = KEY + 2;
	volatile char *KEY_LEFT  = KEY + 3;

	dot_pos_x = 8;
	dot_pos_y = 8;

	current_direction = DIR_UP;
	
	is_game_over = 0;

	reset_lifetimes();

	while (1) {
		LEDR[0] = KEY[0];
		LEDR[1] = KEY[1];
		LEDR[2] = KEY[2];
		LEDR[3] = KEY[3];

		
		if (is_game_over) {
			render_game_over();
			sleep(750*MILLIS);
			continue;
		}

		if (*KEY_UP) {
			current_direction = DIR_UP;
		} else if (*KEY_DOWN) {
			current_direction = DIR_DOWN;
		} else if (*KEY_RIGHT) {
			current_direction = DIR_RIGHT;
		} else if (*KEY_LEFT) {
			current_direction = DIR_LEFT;
		}

		move_tick_in_current_direction();

		constrain(&dot_pos_x, 0, LEDMAT_WIDTH);
		constrain(&dot_pos_y, 0, LEDMAT_HEIGHT);

		if (cell_lifetimes[dot_pos_y][dot_pos_x] > 0) {
			// self-collision, wall collision
			is_game_over = 1;
			continue;
		}

		cell_lifetimes[dot_pos_y][dot_pos_x] = SNAKE_LENGTH;

		render_ledmat();

		decrement_lifetimes();

		sleep(500*MILLIS);
	}
}
