# OpenGL example using glut

import glut
import opengl
import glu

proc display() {.cdecl.} =
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT) # Clear color and depth buffers
  glMatrixMode(GL_MODELVIEW)                          # To operate on model-view matrix

  # Render a color-cube consisting of 6 quads with different colors
  glLoadIdentity()                 # Reset the model-view matrix
  glTranslatef(1.5, 0.0, -7.0)  # Move right and into the screen

  glBegin(GL_QUADS)             # Begin drawing the color cube with 6 quads

  # Top face (y = 1.0f)
  # Define vertices in counter-clockwise (CCW) order with normal pointing out
  glColor3f(0.0, 1.0, 0.0)     # Green
  glVertex3f( 1.0, 1.0, -1.0)
  glVertex3f(-1.0, 1.0, -1.0)
  glVertex3f(-1.0, 1.0,  1.0)
  glVertex3f( 1.0, 1.0,  1.0)

  # Bottom face (y = -1.0f)
  glColor3f(1.0, 0.5, 0.0)     # Orange
  glVertex3f( 1.0, -1.0,  1.0)
  glVertex3f(-1.0, -1.0,  1.0)
  glVertex3f(-1.0, -1.0, -1.0)
  glVertex3f( 1.0, -1.0, -1.0)

  # Front face  (z = 1.0f)
  glColor3f(1.0, 0.0, 0.0)     # Red
  glVertex3f( 1.0,  1.0, 1.0)
  glVertex3f(-1.0,  1.0, 1.0)
  glVertex3f(-1.0, -1.0, 1.0)
  glVertex3f( 1.0, -1.0, 1.0)

  # Back face (z = -1.0f)
  glColor3f(1.0, 1.0, 0.0)     # Yellow
  glVertex3f( 1.0, -1.0, -1.0)
  glVertex3f(-1.0, -1.0, -1.0)
  glVertex3f(-1.0,  1.0, -1.0)
  glVertex3f( 1.0,  1.0, -1.0)

  # Left face (x = -1.0f)
  glColor3f(0.0, 0.0, 1.0)     # Blue
  glVertex3f(-1.0,  1.0,  1.0)
  glVertex3f(-1.0,  1.0, -1.0)
  glVertex3f(-1.0, -1.0, -1.0)
  glVertex3f(-1.0, -1.0,  1.0)

  # Right face (x = 1.0f)
  glColor3f(1.0, 0.0, 1.0)    # Magenta
  glVertex3f(1.0,  1.0, -1.0)
  glVertex3f(1.0,  1.0,  1.0)
  glVertex3f(1.0, -1.0,  1.0)
  glVertex3f(1.0, -1.0, -1.0)

  glEnd()  # End of drawing

  glutSwapBuffers() # Swap the front and back frame buffers (double buffering)

proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
  # Compute aspect ratio of the new window
  if height == 0:
    return                # To prevent divide by 0

  # Set the viewport to cover the new window
  glViewport(0, 0, width, height)

  # Set the aspect ratio of the clipping volume to match the viewport
  glMatrixMode(GL_PROJECTION)  # To operate on the Projection matrix
  glLoadIdentity()             # Reset
  # Enable perspective projection with fovy, aspect, zNear and zFar
  gluPerspective(45.0, width / height, 0.1, 100.0)

loadExtensions()
glutInit()
glutInitDisplayMode(GLUT_DOUBLE)
glutInitWindowSize(640, 480)
glutInitWindowPosition(50, 50)
discard glutCreateWindow("OpenGL Example")

glutDisplayFunc(display)
glutReshapeFunc(reshape)

glClearColor(0.0, 0.0, 0.0, 1.0)                   # Set background color to black and opaque
glClearDepth(1.0)                                 # Set background depth to farthest
glEnable(GL_DEPTH_TEST)                           # Enable depth testing for z-culling
glDepthFunc(GL_LEQUAL)                            # Set the type of depth-test
glShadeModel(GL_SMOOTH)                           # Enable smooth shading
glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) # Nice perspective corrections

glutMainLoop()
