import curses
import os
import re

CONFIG_PATH = os.path.expanduser("~/.config/hypr/hyprland.conf")

def parse_config():
    binds = []
    main_mod = "SUPER"
    
    try:
        with open(CONFIG_PATH, 'r') as f:
            lines = f.readlines()
            
        for line in lines:
            line = line.strip()
            
            # Extract variable definitions for mod key
            if line.startswith("$mainMod"):
                parts = line.split('=')
                if len(parts) > 1:
                    main_mod = parts[1].strip()

            # Parse binds
            # Format: bind = MOD, KEY, ACTION, ARG # Comment
            if line.startswith("bind =") or line.startswith("bindm ="):
                # Separate comment if exists
                comment = ""
                if "#" in line:
                    parts = line.split("#", 1)
                    line = parts[0].strip()
                    comment = parts[1].strip()
                
                # Remove "bind =" prefix
                content = line.split("=", 1)[1].strip()
                tokens = [t.strip() for t in content.split(",")]
                
                if len(tokens) >= 2:
                    mods = tokens[0].replace("$mainMod", main_mod).replace("SHIFT", "SHFT")
                    key = tokens[1].upper()
                    
                    # Construct Action description
                    action = tokens[2] if len(tokens) > 2 else ""
                    arg = tokens[3] if len(tokens) > 3 else ""
                    
                    # If we have a comment, that's the best description
                    # If not, combine action + arg
                    desc = comment if comment else f"{action} {arg}"
                    
                    # Clean up exec commands for display
                    if desc.startswith("exec"):
                        desc = desc.replace("exec", "").strip()
                        if desc.startswith(","): desc = desc[1:].strip()
                        
                    binds.append({
                        "keys": f"{mods} + {key}",
                        "desc": desc
                    })
    except Exception as e:
        return [{"keys": "Error", "desc": str(e)}]

    return binds

def draw_menu(stdscr):
    # Setup
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()
    
    # Define colors based on terminal palette (Ghostty handles the actual hex)
    # Pair 1: Header (Cyan on Base)
    curses.init_pair(1, curses.COLOR_CYAN, -1)
    # Pair 2: Key (Magenta/Pink)
    curses.init_pair(2, curses.COLOR_MAGENTA, -1)
    # Pair 3: Text (White)
    curses.init_pair(3, curses.COLOR_WHITE, -1)
    # Pair 4: Selected (Black on Green)
    curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_GREEN)

    binds = parse_config()
    current_row = 0
    
    while True:
        stdscr.clear()
        height, width = stdscr.getmaxyx()
        
        # Draw Header
        title = " :: CELESTIAL SHADE KEYMAPS :: "
        stdscr.attron(curses.color_pair(1) | curses.A_BOLD)
        stdscr.addstr(1, (width - len(title)) // 2, title)
        stdscr.attroff(curses.color_pair(1) | curses.A_BOLD)
        
        stdscr.addstr(2, 2, "-" * (width - 4), curses.color_pair(3))

        # Calculate scroll viewport
        max_lines = height - 5
        start_index = max(0, current_row - max_lines + 1)
        end_index = min(len(binds), start_index + max_lines)
        
        # Draw List
        for i in range(start_index, end_index):
            item = binds[i]
            y = 4 + (i - start_index)
            
            # Formatting
            key_str = f"{item['keys']:<20}"
            desc_str = item['desc'][:(width - 25)] # Truncate if too long
            
            if i == current_row:
                stdscr.attron(curses.color_pair(4))
                stdscr.addstr(y, 2, f" {key_str} {desc_str} ".ljust(width-4))
                stdscr.attroff(curses.color_pair(4))
            else:
                stdscr.attron(curses.color_pair(2) | curses.A_BOLD)
                stdscr.addstr(y, 2, key_str)
                stdscr.attroff(curses.color_pair(2) | curses.A_BOLD)
                
                stdscr.attron(curses.color_pair(3))
                stdscr.addstr(y, 24, desc_str)
                stdscr.attroff(curses.color_pair(3))

        # Draw Footer
        footer = " [UP/DOWN] Navigate  [Q] Quit "
        stdscr.addstr(height - 2, (width - len(footer)) // 2, footer, curses.color_pair(3) | curses.A_DIM)

        stdscr.refresh()

        # Input Handling
        key = stdscr.getch()
        
        if key == curses.KEY_UP and current_row > 0:
            current_row -= 1
        elif key == curses.KEY_DOWN and current_row < len(binds) - 1:
            current_row += 1
        elif key == ord('q') or key == 27: # q or ESC
            break

if __name__ == "__main__":
    curses.wrapper(draw_menu)
