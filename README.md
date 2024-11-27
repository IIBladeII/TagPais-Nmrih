# NMRiH Country Tag Plugin

A SourceMod plugin for No More Room in Hell that adds country tags to player names.

## Features

- Automatically displays country tags next to player names
- Admin commands to set custom tags
- Welcome messages when players join showing their country
- Command to list all players and their countries
- Support for custom tags per player

## Commands

### Player Commands
- `!countries` - Shows a list of all players and their countries

### Admin Commands
- `!settag <player> <tag>` - Set a custom tag for a player
- `!resettag <player>` - Remove a player's custom tag

## ConVars

- `nmrih_ct_join_message` (Default: 1) - Show message when player joins (1 = Yes, 0 = No)
- `nmrih_ct_join_layout` (Default: "{purple}{NAME} from {LOC} has joined the server.") - Welcome message format
- `nmrih_ct_name_layout` (Default: "{NAME} [{TAG}]") - Player name layout with tag
- `nmrih_ct_show_list` (Default: 1) - Allow !countries command (1 = Yes, 0 = No)
- `nmrih_ct_version` - Plugin version (read-only)

## Installation

1. Make sure you have SourceMod installed on your server
2. Download the latest release
3. Extract the files to your server's `addons/sourcemod` directory
4. Reload the plugin or restart your server

## Requirements

- SourceMod 1.10 or higher
- No More Room in Hell dedicated server
- GeoIP database (included with SourceMod)

## Author

- **IIBladeII**
- GitHub: [https://github.com/IIBladeII](https://github.com/IIBladeII)

## Version

Current Version: 1.0.1

## License

This project is licensed under the MIT License - see the LICENSE file for details.