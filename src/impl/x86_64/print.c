#include "print.h"

const static unsigned NUM_COLS = 80;
const static unsigned NUM_ROWS = 25;

struct Char {
    uint8_t character;
    uint8_t color;
};

static struct Char *s_buffer = (struct Char *)0xb8000;
static unsigned s_row = 0;
static unsigned s_col = 0;
static unsigned s_color = PRINT_COLOR_WHITE | (PRINT_COLOR_BLACK << 4);

static void clear_row(unsigned row)
{
    struct Char empty = (struct Char){
        .character = ' ',
        .color = PRINT_COLOR_BLACK << 4
    };

    struct Char *curr_row = &s_buffer[row * NUM_COLS];
    for (unsigned col = 0; col < NUM_COLS; col++) {
        curr_row[col] = empty;
    }
}

void print_clear(void)
{
    for (unsigned i = 0; i < NUM_ROWS; i++) {
        clear_row(i);
    }
}

static void print_newline(void)
{
    s_col = 0;
    if (s_row < NUM_ROWS - 1) {
        s_row++;
        return;
    }

    for (unsigned row = 1; row < NUM_ROWS; row++) {
        struct Char *dst_row = &s_buffer[(row - 1) * NUM_COLS];
        struct Char *src_row = dst_row + NUM_COLS;
        for (unsigned col = 0; col < NUM_COLS; col++) {
            dst_row[col] = src_row[col];
        }
    }

    clear_row(NUM_ROWS - 1);
}

void print_char(char c)
{
    if (c == '\n') {
        print_newline();
        return;
    }

    if (s_col >= NUM_COLS) {
        print_newline();
    }

    s_buffer[s_col + NUM_COLS * s_row] = (struct Char){
        .character = (uint8_t)c,
        .color = s_color
    };
    s_col++;
}

void print_str(const char *string)
{
    for (size_t i = 0; 1; i++) {
        if (string[i] == '\0')
            return;
        print_char(string[i]);
    }
}

void print_set_color(uint8_t foreground, uint8_t background)
{
    s_color = foreground + (background << 4);
}
