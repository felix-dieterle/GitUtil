# GitUtil - Git Branch Rewind Tool

An Android application for visually navigating git commit history and reverting branches to previous states.

## Features

- Browse git repositories on device
- View commit timeline with full details (hash, author, timestamp, message)
- Revert branch to any historical commit with one tap
- Simple, intuitive interface

## Project Structure

This app uses a custom lightweight architecture:
- `historywalker/` - Core git operations engine
- `screenflow/` - UI components and navigation
- `databridge/` - Data models and adapters

## Building

Standard Android build process applies. See build configuration files for dependencies.

## Usage

1. Launch app
2. Select or enter git repository path
3. Browse commit timeline (newest to oldest)
4. Tap any commit to see details
5. Confirm revert action to reset branch

## Requirements

- Android 8.0 (API 26) or higher
- Git repositories must be accessible on device storage