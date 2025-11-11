#!/usr/bin/env bash
set -e

echo "== raylib + Homebrew + VS Code setup script =="

# Ensure we have a POSIX shell
SHELL_NAME="$(basename "$SHELL")"
echo "Using shell: $SHELL_NAME"

# 1) Xcode Command Line Tools
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools not found. Installing..."
  xcode-select --install || true
  echo "If a GUI prompt appeared, complete the install and re-run this script."
  read -p "Press Enter after Xcode tools are installed..."
else
  echo "Xcode Command Line Tools already installed."
fi

# 2) Homebrew install or locate existing brew
BREW_CMD=""
if command -v brew >/dev/null 2>&1; then
  BREW_CMD="$(command -v brew)"
else
  # common brew prefixes
  if [ -x "/opt/homebrew/bin/brew" ]; then
    BREW_CMD="/opt/homebrew/bin/brew"
  elif [ -x "/usr/local/bin/brew" ]; then
    BREW_CMD="/usr/local/bin/brew"
  fi
fi

if [ -z "$BREW_CMD" ]; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH for current session
  if [[ -d "/opt/homebrew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    BREW_CMD="/opt/homebrew/bin/brew"
  elif [[ -d "/usr/local/Homebrew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    BREW_CMD="/usr/local/bin/brew"
  fi
fi

if [ -z "$BREW_CMD" ] || [ ! -x "$BREW_CMD" ]; then
  echo "ERROR: Homebrew not found after install. Trying to add to PATH..."
  # Try to add homebrew to PATH
  if [ -f "/opt/homebrew/bin/brew" ]; then
    export PATH="/opt/homebrew/bin:$PATH"
    BREW_CMD="/opt/homebrew/bin/brew"
  elif [ -f "/usr/local/bin/brew" ]; then
    export PATH="/usr/local/bin:$PATH"
    BREW_CMD="/usr/local/bin/brew"
  else
    echo "ERROR: Cannot locate Homebrew. Please install manually and add to PATH."
    exit 1
  fi
fi

echo "Using Homebrew at: $BREW_CMD"

# Ensure brew is in PATH for this script
export PATH="$(dirname "$BREW_CMD"):$PATH"

# 3) Install pkg-config and raylib with better error handling
echo "Updating Homebrew and installing pkg-config and raylib..."
if ! "$BREW_CMD" update; then
  echo "Warning: Homebrew update failed, continuing..."
fi

if ! "$BREW_CMD" install pkg-config; then
  echo "Warning: pkg-config install failed, it might already be installed"
fi

if ! "$BREW_CMD" install raylib; then
  echo "Warning: raylib install failed, it might already be installed"
fi

# Verify installations
if ! command -v pkg-config >/dev/null 2>&1; then
  echo "ERROR: pkg-config not found after install"
  exit 1
fi

if ! pkg-config --exists raylib; then
  echo "ERROR: raylib not found by pkg-config"
  echo "Available packages:"
  pkg-config --list-all | grep -i ray || echo "No raylib packages found"
  exit 1
fi

# 4) Create sample project files in current directory (NOT in subdirectory)
PROJECT_DIR="${PWD}"
echo "Creating project files in current directory: $PROJECT_DIR"

cat > main.c <<'EOF'
#include "raylib.h"

int main(void)
{
    const int screenWidth = 800;
    const int screenHeight = 450;

    InitWindow(screenWidth, screenHeight, "raylib example - basic window");
    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Hello, raylib! (from VS Code)", 120, 200, 20, LIGHTGRAY);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
EOF

cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.10)
project(raylib_demo C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(RAYLIB REQUIRED raylib)

include_directories(${RAYLIB_INCLUDE_DIRS})
link_directories(${RAYLIB_LIBRARY_DIRS})

add_executable(app main.c)
target_link_libraries(app ${RAYLIB_LIBRARIES})
EOF

# 5) Create .vscode configs
mkdir -p .vscode

cat > .vscode/tasks.json <<'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build (clang + pkg-config)",
      "type": "shell",
      "command": "clang",
      "args": [
        "${workspaceFolder}/main.c",
        "-o",
        "${workspaceFolder}/app"
      ],
      "options": {
        "env": {
          "PKG_CONFIG_PATH": "/opt/homebrew/lib/pkgconfig:/usr/local/lib/pkgconfig"
        },
        "shell": {
          "executable": "/bin/bash",
          "args": ["-c", "clang `pkg-config --cflags --libs raylib` ${workspaceFolder}/main.c -o ${workspaceFolder}/app"]
        }
      },
      "group": { "kind": "build", "isDefault": true },
      "problemMatcher": ["$gcc"]
    }
  ]
}
EOF

cat > .vscode/launch.json <<'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch app (lldb)",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/app",
      "args": [],
      "stopAtEntry": false,
      "cwd": "${workspaceFolder}",
      "environment": [],
      "externalConsole": false,
      "MIMode": "lldb",
      "miDebuggerPath": "/usr/bin/lldb",
      "preLaunchTask": "build (clang + pkg-config)",
      "setupCommands": [
        {
          "description": "Enable pretty printing",
          "text": "-enable-pretty-printing",
          "ignoreFailures": true
        }
      ]
    }
  ]
}
EOF

cat > .vscode/c_cpp_properties.json <<'EOF'
{
  "version": 4,
  "configurations": [
    {
      "name": "macos",
      "includePath": [
        "${workspaceFolder}/**",
        "/usr/local/include",
        "/opt/homebrew/include"
      ],
      "defines": [],
      "macFrameworkPath": [
        "/System/Library/Frameworks",
        "/Library/Frameworks"
      ],
      "compilerPath": "/usr/bin/clang",
      "cStandard": "c17",
      "cppStandard": "c++17",
      "intelliSenseMode": "macos-clang-x64"
    }
  ]
}
EOF

# 6) Build the sample once with better error handling
echo "Building the sample..."
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "Testing pkg-config raylib..."
if pkg-config --cflags --libs raylib; then
  echo "pkg-config working, building..."
  if clang `pkg-config --cflags --libs raylib` main.c -o app; then
    echo "Build successful!"
  else
    echo "Build failed. Trying alternative method..."
    clang -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib main.c -o app || \
    clang -I/usr/local/include -L/usr/local/lib -lraylib main.c -o app
  fi
else
  echo "pkg-config failed, trying direct linking..."
  clang -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib main.c -o app || \
  clang -I/usr/local/include -L/usr/local/lib -lraylib main.c -o app
fi

echo
echo "Done. Project created in current directory: $PROJECT_DIR"
echo
echo "To test the build manually:"
echo "  clang \`pkg-config --cflags --libs raylib\` main.c -o app"
echo "  ./app"
echo
echo "To use in VS Code:"
echo "  code ."