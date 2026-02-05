# GitUtil Mobile Interface

Touch-optimized web interface for managing git repositories on Android devices via Termux.

## Overview

This mobile interface provides a finger-friendly way to browse commit history and rollback branches on Android. It's designed specifically for touch screens with large tap targets and responsive design.

## Components

### `touch-ui.html`
Self-contained HTML interface with embedded CSS and JavaScript. Features:
- **Responsive design** - Adapts to any screen size
- **Touch-optimized** - 54px minimum tap targets
- **HTTP-based communication** - Connects to bridge server via fetch API
- **State persistence** - Remembers last repository path
- **Visual feedback** - Color-coded messages and loading indicators

Design principles:
- Custom CSS variables for consistent theming
- Widget-based state machine architecture
- Accessibility-friendly with proper semantic HTML
- Clean separation between UI and business logic

### `wrapper-bridge.py`
Python micro-HTTP server that bridges the UI to shell wrappers. Features:
- **Lightweight HTTP server** - Listens on localhost:8765
- **CORS-enabled** - Allows browser communication
- **Wrapper execution** - Safely runs shell scripts with arguments
- **JSON API** - Structured request/response format
- **Timeout protection** - 30-second execution limit

The bridge server:
- Serves the HTML interface on GET /
- Executes wrappers via POST /exec-wrapper
- Returns JSON with stdout, stderr, and exit codes
- Handles errors gracefully

### `launch-mobile.sh`
Launcher script that:
- Auto-generates wrapper scripts
- Sets up the wrapper directory structure
- Starts the Python bridge server
- Opens the interface in the default browser
- Manages server lifecycle (start/stop)

### `wrappers/` (auto-generated)
Shell script wrappers that bridge the UI to core functionality:
- `check-location.sh` - Validates repository paths
- `pull-timeline.sh` - Fetches commit history with custom format
- `apply-rollback.sh` - Performs git hard reset operations

These wrappers are generated on first launch and use unique output formats:
- `LOCATION_VALID/INVALID` - Repository validation
- `SNAPSHOT_BEGIN/END` blocks - Commit data
- `ROLLBACK_SUCCESS/FAILED` - Rollback status

## Architecture

### State Machine
The UI uses a two-state machine:
1. **Location Picker** - Repository selection and validation
2. **Timeline Viewer** - Commit browsing and rollback

State transitions:
```
[Location Picker] --verify--> [Timeline Viewer]
[Timeline Viewer] --switch--> [Location Picker]
[Timeline Viewer] --rollback--> [Timeline Viewer] (refresh)
```

### Data Flow
```
User Input → UI Widget → HTTP POST → Bridge Server → Wrapper Script → Git
                ↑                                                        ↓
                └─────────── JSON Response ←──────────────────────────────┘
```

### Communication Protocol

**Request to bridge server:**
```json
POST /exec-wrapper
{
  "wrapper": "check-location",
  "args": ["/path/to/repo"]
}
```

**Response from bridge:**
```json
{
  "success": true,
  "output": "LOCATION_VALID\n",
  "errors": "",
  "exit_code": 0
}
```

## Usage

### Basic Launch
```bash
bash mobile/launch-mobile.sh
```

This will:
1. Generate wrapper scripts
2. Start the bridge server on port 8765
3. Open http://localhost:8765 in your browser

### Manual Server Start
```bash
# Start bridge server manually
python3 mobile/wrapper-bridge.py

# In another terminal or browser, access:
# http://localhost:8765
```

### Custom Port
```bash
python3 mobile/wrapper-bridge.py 9000
# Then access http://localhost:9000
```

### Stopping the Server
Press Ctrl+C in the terminal where the bridge server is running.

## Customization

### Changing Colors
Edit the CSS variables in `touch-ui.html`:
```css
:root {
  --sky-600: #1b6ca8;  /* Primary color */
  --grass-600: #2d6a4f; /* Success color */
  --fire-600: #d62828;  /* Danger color */
  /* ... more variables ... */
}
```

### Adjusting Touch Targets
Modify the press zone size:
```css
:root {
  --press-zone: 54px;  /* Minimum 44px for accessibility */
}
```

### Timeline Height
Change the scrollable area:
```css
.timeline-zone {
  max-height: 56vh;  /* Adjust viewport percentage */
}
```

## Testing

Test the mobile interface:

1. **Validate wrapper generation:**
   ```bash
   bash mobile/launch-mobile.sh
   ls -la mobile/wrappers/
   ```

2. **Test wrappers directly:**
   ```bash
   bash mobile/wrappers/check-location.sh /path/to/repo
   bash mobile/wrappers/pull-timeline.sh /path/to/repo
   ```

3. **Browser testing:**
   - Open `touch-ui.html` in various browsers
   - Test on different screen sizes
   - Verify touch interactions

## Browser Compatibility

The interface works with any modern browser:
- ✅ Chrome for Android
- ✅ Firefox for Android  
- ✅ Samsung Internet
- ✅ Brave Browser
- ✅ Desktop browsers (via bridge server)

Requirements:
- ES6 JavaScript support
- Fetch API
- localStorage API
- CSS Grid and Flexbox

Note: The bridge server must be running on localhost for the interface to function.

## Performance

Optimizations:
- Minimal HTTP overhead (localhost only)
- Inline styles (no external CSS)
- Lazy DOM updates
- Debounced user interactions
- No external dependencies

Typical performance on Android:
- Bridge startup: <1 second
- UI load time: <200ms
- Wrapper execution: 50-500ms (depends on repo size)
- Timeline render: <100ms (for 100 commits)

## Security Considerations

- **Localhost only** - Bridge server only listens on 127.0.0.1
- **No external requests** - All communication is local
- **Subprocess isolation** - Wrappers run in separate processes
- **Timeout protection** - 30-second execution limit prevents hangs
- **Input validation** - Arguments passed as list (not shell string)
- **Confirmation dialogs** - Destructive actions require user confirmation
- **CORS restrictions** - Server only accepts requests from localhost

Security features:
- No shell injection - arguments are parameterized
- No arbitrary code execution - only predefined wrappers
- No network exposure - server is not accessible remotely

## Troubleshooting

### Bridge server won't start
```bash
# Check Python 3 is installed
python3 --version

# Check port is available
netstat -an | grep 8765

# Try a different port
python3 mobile/wrapper-bridge.py 9000
```

### UI can't connect to server
```bash
# Verify server is running
ps aux | grep wrapper-bridge

# Check server output for errors
# Ensure you're accessing http://localhost:8765
```

### Wrappers not executing
```bash
# Regenerate wrappers
rm -rf mobile/wrappers
bash mobile/launch-mobile.sh

# Test wrapper directly
bash mobile/wrappers/check-location.sh /path/to/repo
```

## Development

### Making Changes

1. Edit `touch-ui.html` for UI changes
2. Edit `launch-mobile.sh` for wrapper logic
3. Test on actual Android device
4. Verify wrapper generation

### Adding Features

When adding new features:
1. Keep the single-file architecture
2. Maintain touch-friendly design (54px+ targets)
3. Add proper error handling
4. Update this README

### Code Style

- Use unique variable names (not generic terms)
- Keep CSS custom properties organized
- Comment complex JavaScript logic
- Follow existing naming conventions

## Distribution

The mobile interface is packaged via GitHub Actions:
- Workflow: `.github/workflows/package-mobile.yml`
- Triggers: Version tags (v*)
- Output: ZIP and tar.gz archives
- Includes: mobile/, scripts/, README.md

## License

Same as the parent GitUtil project.

## Contributing

When contributing to the mobile interface:
1. Test on actual Android devices
2. Verify Termux compatibility
3. Maintain offline-first design
4. Keep the single-file approach
5. Update documentation

---

For full documentation, see [MOBILE-GUIDE.md](MOBILE-GUIDE.md)
