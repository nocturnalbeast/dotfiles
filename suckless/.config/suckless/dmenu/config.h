/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

/* -n option; if 1, instantly executes match when only one is left */
static int instant = 0;
/* -b option; if 0, dmenu appears at bottom */
static int topbar = 1;
/* -F option; if 0, dmenu doesn't use fuzzy matching */
static int fuzzy = 1;

/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
	"Iosevka Aile Medium:size=10",
    "monospace:size=10"
};

/* -p option; prompt to the left of input field */
static const char *prompt = NULL;

static const char *colors[SchemeLast][2] = {
                            /*    fg          bg     */
	[SchemeNorm] =           { "#FFFFFF", "#9A9A9A" },
	[SchemeSel] =            { "#DADADA", "#000000" },
	[SchemeSelHighlight] =   { "#FF6666", "#000000" },
	[SchemeNormHighlight] =  { "#000000", "#9A9A9A" },
	[SchemeOut] =            { "#000000", "#00ffff" },
};

/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines = 0;
/* -h option; minimum height of a menu line */
static unsigned int lineheight = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";
