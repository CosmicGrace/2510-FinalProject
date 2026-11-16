"""
term_ui.py - Terminal UI help test

Colors turn themselves off when the
output isn't a real terminal (piping, CI) or when NO_COLOR is set, and box
characters fall back to plain ASCII if the terminal can't show Unicode.

Usage:
    import term_ui as ui
    choice = ui.menu("Test", ui.MAIN_MENU)
    ui.course_card(course)          # course can be an object OR a dict
    ui.course_table(list_of_courses)

Run `python term_ui.py` to see a demo.
"""

import os
import re
import shutil
import sys
import textwrap

# ----------------------------------------------------------------------------
# Setup / capability detection
# ----------------------------------------------------------------------------

if os.name == "nt":
    os.system("")  # quirk that enables ANSI escape codes on Windows 10+ terminals

USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ
USE_UNICODE = (getattr(sys.stdout, "encoding", "") or "").lower().replace("-", "").startswith("utf")

# top-left, top-right, bottom-left, bottom-right, horizontal, vertical
BOX = ("╭", "╮", "╰", "╯", "─", "│") if USE_UNICODE else ("+", "+", "+", "+", "-", "|")


class C:
    """ANSI style codes."""
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    CYAN = "\033[36m"


_ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


def style(text, *codes):
    """Wrap text in ANSI codes (no-op if color is disabled)."""
    if not USE_COLOR or not codes:
        return str(text)
    return "".join(codes) + str(text) + C.RESET


def visible_len(text):
    """Length of text as seen on screen (ignores color codes)."""
    return len(_ANSI_RE.sub("", text))


def pad(text, width):
    return text + " " * max(0, width - visible_len(text))


def term_width(max_width=100):
    return max(40, min(shutil.get_terminal_size((80, 24)).columns, max_width))


def clear():
    os.system("cls" if os.name == "nt" else "clear")


# ----------------------------------------------------------------------------
# Basic building blocks
# ----------------------------------------------------------------------------

def box(lines, title="", color=C.CYAN, width=None):
    """Print lines inside a rounded box. Lines should already fit the width."""
    w = width or term_width()
    inner = w - 4
    tl, tr, bl, br, h, v = BOX

    if title:
        t = f" {title} "
        top = (style(tl + h, color) + style(t, C.BOLD, color)
               + style(h * max(0, w - 3 - len(t)) + tr, color))
    else:
        top = style(tl + h * (w - 2) + tr, color)
    print(top)
    for line in lines:
        print(style(v, color) + " " + pad(line, inner) + " " + style(v, color))
    print(style(bl + h * (w - 2) + br, color))


def header(text):
    """Section header with an underline rule."""
    print()
    print(style(text, C.BOLD, C.CYAN))
    print(style(BOX[4] * min(len(text), term_width()), C.DIM))


def success(msg):
    print(style(("✔ " if USE_UNICODE else "[ok] ") + msg, C.GREEN))


def error(msg):
    print(style(("✖ " if USE_UNICODE else "[error] ") + msg, C.RED))


def warn(msg):
    print(style(("! " if USE_UNICODE else "[warn] ") + msg, C.YELLOW))


def info(msg):
    print(style(msg, C.DIM))


def banner(title, subtitle=""):
    w = term_width()
    inner = w - 4
    lines = ["", style(title.center(inner), C.BOLD, C.CYAN)]
    if subtitle:
        lines.append(style(subtitle.center(inner), C.DIM))
    lines.append("")
    box(lines, color=C.CYAN, width=w)


# ----------------------------------------------------------------------------
# Input helpers
# ----------------------------------------------------------------------------

def prompt(text, valid=None, allow_empty=False):
    """
    Ask for input. If `valid` (iterable of strings) is given, keeps asking
    until the answer matches one of them (case-insensitive).
    Ctrl+C / Ctrl+D returns "q" so users can always bail out.
    """
    valid_lower = {str(v).lower() for v in valid} if valid else None
    while True:
        try:
            answer = input(style(f"{text} ", C.BOLD, C.YELLOW)).strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return "q"
        if not answer and not allow_empty:
            continue
        if valid_lower is None or answer.lower() in valid_lower:
            return answer
        error(f"'{answer}' isn't a valid choice. Options: {', '.join(sorted(valid_lower))}")


def confirm(question):
    return prompt(f"{question} (y/n):", valid=["y", "n"]).lower() == "y"


def pause():
    try:
        input(style("\nPress Enter to continue...", C.DIM))
    except (EOFError, KeyboardInterrupt):
        print()


# ----------------------------------------------------------------------------
# Menus
# ----------------------------------------------------------------------------

MAIN_MENU = [
    ("1", "Text")
]


def menu(title, options, prompt_text="Select an option:"):
    """
    Show a boxed menu and return the chosen key (lowercase).
    `options` is a list of (key, label) tuples, e.g. MAIN_MENU.
    """
    lines = []
    for key, label in options:
        key_style = (C.BOLD, C.RED) if key.lower() == "q" else (C.BOLD, C.GREEN)
        lines.append(f"{style(f'[{key}]', *key_style)}  {label}")
    print()
    box(lines, title=title)
    return prompt(prompt_text, valid=[k for k, _ in options]).lower()
