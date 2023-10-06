# Package

version = "1.2.9"
author = "Andreas Rumpf"
description = "an OpenGL wrapper"
license = "MIT"

srcDir = "src"

# Dependencies

when defined(windows):
  requires "nim >= 0.11.0"
else:
  requires "nim >= 0.11.0", "x11 >= 1.1"
