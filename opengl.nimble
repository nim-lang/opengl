# Package

version = "1.1.0"
author = "Andreas Rumpf"
description = "an OpenGL wrapper"
license = "MIT"

srcDir = "src"

# Dependencies

when defined(windows):
  requires "nim >= 0.10.3"
else:
  requires "nim >= 0.10.3", "x11"