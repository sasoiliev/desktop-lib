#include <X11/Xlib.h>
#include <assert.h>
#include <unistd.h>
#include <stdio.h>
#include <malloc.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#define debug(debug_enabled, ...) if (debug_enabled) {\
    fprintf(stderr, __VA_ARGS__);\
}

#define VERSION "0.1"
#define DEFAULT_TOLERANCE 0
#define HELP "Usage: %s [OPTION...] EDGE -- CMD [CMDARGS...]\n\
\n\
Options:\n\
  -t TOLERANCE          How many pixels away from the edge to consider\n\
                        still at the edge. (default: %d)\n\
  -v                    Print version and exit.\n\
  -h                    Print usage and exit.\n\
\n\
EDGE is one of `N', `E', `S', or `W'\n\
"

void print_help(char *progname) {
    fprintf(stderr, HELP, progname, DEFAULT_TOLERANCE);
}

typedef struct {
    int w;
    int h;
} Size;

typedef struct {
    int x;
    int y;
} CursorPosition;

enum Edge {
    N, E, S, W
};

static int _xlib_error_handler(Display *dpy, XErrorEvent *event) {
    fprintf(stderr, "An error occured detecting the mouse position\n");
    return True;
}

Bool get_root_windows_size_and_mouse_cursor_position(
    Size *root_window_size_return, CursorPosition *cursor_position_return, bool debug_enabled
) {
    Display *dpy;
    int number_of_screens;
    int i;
    Window *root_windows;
    Window window_returned;
    int root_x, root_y;
    int win_x, win_y;
    unsigned int mask_return;
    unsigned int root_w, root_h, border_w, depth;
    int geometry_return;

    dpy = XOpenDisplay(NULL);
    assert(dpy);
    XSetErrorHandler(_xlib_error_handler);
    number_of_screens = XScreenCount(dpy);
    debug(debug_enabled, "There are %d screens available in this X session\n", number_of_screens);

    root_windows = malloc(sizeof(Window) * number_of_screens);
    for (i = 0; i < number_of_screens; i++) {
        root_windows[i] = XRootWindow(dpy, i);

        geometry_return = XGetGeometry(dpy, root_windows[i], &window_returned,
                &root_x, &root_y, &root_w, &root_h, &border_w, &depth);
        if (!geometry_return) {
            fprintf(stderr, "Failed to query root window geometry for screen %d\n", i);
            return False;
        }

        if (XQueryPointer(dpy, root_windows[i], &window_returned,
                &window_returned, &root_x, &root_y, &win_x, &win_y,
                &mask_return)) {
            root_window_size_return->w = root_w;
            root_window_size_return->h = root_h;
            cursor_position_return->x = root_x;
            cursor_position_return->y = root_y;
            return True;
        }
    }

    free(root_windows);
    XCloseDisplay(dpy);
    fprintf(stderr, "No mouse cursor found\n");
    return False;
}

void exec_if_within_tolerance(
    Size root_window_size,
    CursorPosition cursor_position,
    enum Edge edge,
    int tolerance,
    int newargc,
    char *newargv[],
    bool debug_enabled
) {
    debug(debug_enabled, "Root window size: %dx%d\n", root_window_size.w, root_window_size.h);
    debug(debug_enabled, "Cursor position: x: %d; y: %d\n", cursor_position.x, cursor_position.y);

    int border;
    int sign;
    int value;
    switch (edge) {
        case N: border = 0; sign = 1; value = cursor_position.y; break;
        case E: border = root_window_size.w; sign = -1; value = cursor_position.x; break;
        case S: border = root_window_size.h; sign = -1; value = cursor_position.y; break;
        case W: border = 0; sign = 1; value = cursor_position.x; break;
    }

    if ((border + (sign * value)) <= tolerance) {
        debug(debug_enabled, "Running: ");
        for (int i = 0; i < newargc; i++) {
            debug(debug_enabled, "%s ", newargv[i]);
        }
        debug(debug_enabled, "\n");
        execvp(newargv[0], newargv);
    }
}

int main(int argc, char *argv[]) {
    int tolerance = DEFAULT_TOLERANCE;
    enum Edge edge;
    int opt;
    bool debug_enabled = False;

    while ((opt = getopt(argc, argv, "t:vhd")) != -1) {
        switch (opt) {
            case 't': tolerance = atoi(optarg); break;
            case 'd': debug_enabled = True; break;
            case 'v': fprintf(stderr, VERSION); return 0;
            case 'h': print_help(argv[0]); return 0;
            default: print_help(argv[0]); return 0;
        }
    }

    if ((optind >= argc) || (strlen(argv[optind]) == 0) || (strlen(argv[optind]) > 1)) {
        fprintf(stderr, "Invalid EDGE argument: %d %d\n", optind, argc);
        print_help(argv[0]);
        return 1;
    }

    switch (argv[optind][0]) {
        case 'N': edge = N; break;
        case 'E': edge = E; break;
        case 'S': edge = S; break;
        case 'W': edge = W; break;
        default: print_help(argv[0]); return 1;
    }

    if (((++optind) >= argc) || !strcmp(argv[optind], "--"))  {
        print_help(argv[0]);
        return 1;
    }

    int newargc = argc - optind;
    char *newargv[newargc + 1];
    for (int i = 0; i < newargc; i++) {
        newargv[i] = argv[optind + i];
    }
    newargv[newargc] = NULL;

    Size root_window_size;
    CursorPosition cursor_position;

    if (!get_root_windows_size_and_mouse_cursor_position(&root_window_size, &cursor_position, debug_enabled)) {
        fprintf(stderr, "Failed to get screen size and mouse cursor position\n");
        return 1;
    }

    exec_if_within_tolerance(root_window_size, cursor_position, edge, tolerance, newargc, newargv, debug_enabled);
}
