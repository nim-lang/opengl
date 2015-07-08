
#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is a wrapper around `opengl`:idx:. If you define the symbol
## ``useGlew`` this wrapper does not use Nimrod's ``dynlib`` mechanism,
## but `glew`:idx: instead. However, this shouldn't be necessary anymore; even
## extension loading for the different operating systems is handled here.
##
## You need to call ``loadExtensions`` after a rendering context has been
## created to load any extension proc that your code uses.

{.deadCodeElim: on.}

import macros, sequtils

{.push warning[User]: off.}

when defined(linux) and not defined(android):
  import X, XLib, XUtil
elif defined(windows):
  import winlean, os

when defined(windows):
  const
    ogldll* = "OpenGL32.dll"
    gludll* = "GLU32.dll"
elif defined(macosx):
  #macosx has this notion of a framework, thus the path to the openGL dylib files
  #is absolute
  const
    ogldll* = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGL.dylib"
    gludll* = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGLU.dylib"
else:
  const
    ogldll* = "libGL.so.1"
    gludll* = "libGLU.so.1"

when defined(useGlew):
  {.pragma: ogl, header: "<GL/glew.h>".}
  {.pragma: oglx, header: "<GL/glxew.h>".}
  {.pragma: wgl, header: "<GL/wglew.h>".}
  {.pragma: glu, dynlib: gludll.}
elif defined(ios):
  {.pragma: ogl.}
  {.pragma: oglx.}
  {.passC: "-framework OpenGLES", passL: "-framework OpenGLES".}
elif defined(android) or defined(js):
  {.pragma: ogl.}
  {.pragma: oglx.}
else:
  # quite complex ... thanks to extension support for various platforms:
  import dynlib

  let oglHandle = loadLib(ogldll)
  if isNil(oglHandle): quit("could not load: " & ogldll)

  when defined(windows):
    var wglGetProcAddress = cast[proc (s: cstring): pointer {.stdcall.}](
      symAddr(oglHandle, "wglGetProcAddress"))
  elif defined(linux):
    var glxGetProcAddress = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glxGetProcAddress"))
    var glxGetProcAddressArb = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glxGetProcAddressARB"))

  proc glGetProc(h: LibHandle; procName: cstring): pointer =
    when defined(windows):
      result = symAddr(h, procname)
      if result != nil: return
      if not isNil(wglGetProcAddress): result = wglGetProcAddress(procName)
    elif defined(linux):
      if not isNil(glxGetProcAddress): result = glxGetProcAddress(procName)
      if result != nil: return
      if not isNil(glxGetProcAddressArb):
        result = glxGetProcAddressArb(procName)
        if result != nil: return
      result = symAddr(h, procname)
    else:
      result = symAddr(h, procName)
    if result == nil: raiseInvalidLibrary(procName)

  var gluHandle: LibHandle

  proc gluGetProc(procname: cstring): pointer =
    if gluHandle == nil:
      gluHandle = loadLib(gludll)
      if gluHandle == nil: quit("could not load: " & gludll)
    result = glGetProc(gluHandle, procname)

  # undocumented 'dynlib' feature: the string literal is replaced by
  # the imported proc name:
  {.pragma: ogl, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: oglx, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: wgl, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: glu, dynlib: gluGetProc("").}

  proc nimLoadProcs0() {.importc.}

  template loadExtensions*() =
    ## call this after your rendering context has been setup if you use
    ## extensions.
    bind nimLoadProcs0
    nimLoadProcs0()

{.pop.} # warning[User]: off

type
  GLenum* = uint32
  GLboolean* = bool
  GLbitfield* = uint32
  GLvoid* = pointer
  GLbyte* = int8
  GLshort* = int64
  GLint* = int32
  GLclampx* = int32
  GLubyte* = uint8
  GLushort* = uint16
  GLuint* = uint32
  GLhandle* = GLuint
  GLsizei* = int32
  GLfloat* = float32
  GLclampf* = float32
  GLdouble* = float64
  GLclampd* = float64
  GLeglImageOES* = distinct pointer
  GLchar* = char
  GLcharArb* = char
  GLfixed* = int32
  GLhalfNv* = uint16
  GLvdpauSurfaceNv* = uint
  GLintptr* = int32
  GLintptrArb* = int32
  GLint64EXT* = int64
  GLuint64EXT* = uint64
  GLint64* = int64
  GLsizeiptrArb* = int
  GLsizeiptr* = int
  GLsync* = distinct pointer
  GLuint64* = uint64
  GLvectorub2* = array[0..1, GLubyte]
  GLvectori2* = array[0..1, GLint]
  GLvectorf2* = array[0..1, GLfloat]
  GLvectord2* = array[0..1, GLdouble]
  GLvectorp2* = array[0..1, pointer]
  GLvectorb3* = array[0..2, GLbyte]
  GLvectorub3* = array[0..2, GLubyte]
  GLvectori3* = array[0..2, GLint]
  GLvectorui3* = array[0..2, GLuint]
  GLvectorf3* = array[0..2, GLfloat]
  GLvectord3* = array[0..2, GLdouble]
  GLvectorp3* = array[0..2, pointer]
  GLvectors3* = array[0..2, GLshort]
  GLvectorus3* = array[0..2, GLushort]
  GLvectorb4* = array[0..3, GLbyte]
  GLvectorub4* = array[0..3, GLubyte]
  GLvectori4* = array[0..3, GLint]
  GLvectorui4* = array[0..3, GLuint]
  GLvectorf4* = array[0..3, GLfloat]
  GLvectord4* = array[0..3, GLdouble]
  GLvectorp4* = array[0..3, pointer]
  GLvectors4* = array[0..3, GLshort]
  GLvectorus4* = array[0..3, GLshort]
  GLarray4f* = GLvectorf4
  GLarrayf3* = GLvectorf3
  GLarrayd3* = GLvectord3
  GLarrayi4* = GLvectori4
  GLarrayp4* = GLvectorp4
  GLmatrixub3* = array[0..2, array[0..2, GLubyte]]
  GLmatrixi3* = array[0..2, array[0..2, GLint]]
  GLmatrixf3* = array[0..2, array[0..2, GLfloat]]
  GLmatrixd3* = array[0..2, array[0..2, GLdouble]]
  GLmatrixub4* = array[0..3, array[0..3, GLubyte]]
  GLmatrixi4* = array[0..3, array[0..3, GLint]]
  GLmatrixf4* = array[0..3, array[0..3, GLfloat]]
  GLmatrixd4* = array[0..3, array[0..3, GLdouble]]
  ClContext* = distinct pointer
  ClEvent* = distinct pointer
  GLdebugProc* = proc (
    source: GLenum,
    typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcArb* = proc (
    source: GLenum,
    typ: GLenum,
    id: GLuint,
    severity: GLenum,
    len: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcAmd* = proc (
    id: GLuint,
    category: GLenum,
    severity: GLenum,
    len: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcKhr* = proc (
    source, typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
type
  GLerrorCode* {.size: GLenum.sizeof.} = enum # XXX: can't be evaluated when
                                              # in the same type section as
                                              # GLenum.
    glErrNoError = (0, "no error")
    glErrInvalidEnum = (0x0500, "invalid enum")
    glErrInvalidValue = (0x0501, "invalid value")
    glErrInvalidOperation = (0x0502, "invalid operation")
    glErrStackOverflow = (0x0503, "stack overflow")
    glErrStackUnderflow = (0x0504, "stack underflow")
    glErrOutOfMem = (0x0505, "out of memory")
    glErrInvalidFramebufferOperation = (0x0506, "invalid framebuffer operation")
    glErrTableTooLarge = (0x8031, "table too large")

const AllErrorCodes = {
    glErrNoError,
    glErrInvalidEnum,
    glErrInvalidValue,
    glErrInvalidOperation,
    glErrStackOverflow,
    glErrStackUnderflow,
    glErrOutOfMem,
    glErrInvalidFramebufferOperation,
    glErrTableTooLarge,
}

when defined(macosx):
  type
    GLhandleArb = pointer
else:
  type
    GLhandleArb = uint32

{.deprecated: [
  TGLerror: GLerrorCode,
  TGLhandleARB: GLhandleArb,
  TGLenum: GLenum,
  TGLboolean: GLboolean,
  TGLbitfield: GLbitfield,
  TGLvoid: GLvoid,
  TGLbyte: GLbyte,
  TGLshort: GLshort,
  TGLint: GLint,
  TGLclampx: GLclampx,
  TGLubyte: GLubyte,
  TGLushort: GLushort,
  TGLuint: GLuint,
  TGLsizei: GLsizei,
  TGLfloat: GLfloat,
  TGLclampf: GLclampf,
  TGLdouble: GLdouble,
  TGLclampd: GLclampd,
  TGLeglImageOES: GLeglImageOES,
  TGLchar: GLchar,
  TGLcharARB: GLcharArb,
  TGLfixed: GLfixed,
  TGLhalfNV: GLhalfNv,
  TGLvdpauSurfaceNv: GLvdpauSurfaceNv,
  TGLintptr: GLintptr,
  TGLintptrARB: GLintptrArb,
  TGLint64EXT: GLint64Ext,
  TGLuint64EXT: GLuint64Ext,
  TGLint64: GLint64,
  TGLsizeiptrARB: GLsizeiptrArb,
  TGLsizeiptr: GLsizeiptr,
  TGLsync: GLsync,
  TGLuint64: GLuint64,
  TCL_context: ClContext,
  TCL_event: ClEvent,
  TGLdebugProc: GLdebugProc,
  TGLDebugProcARB: GLdebugProcArb,
  TGLDebugProcAMD: GLdebugProcAmd,
  TGLDebugProcKHR: GLdebugProcKhr,
  TGLVectorub2: GLvectorub2,
  TGLVectori2: GLvectori2,
  TGLVectorf2: GLvectorf2,
  TGLVectord2: GLvectord2,
  TGLVectorp2: GLvectorp2,
  TGLVectorb3: GLvectorb3,
  TGLVectorub3: GLvectorub3,
  TGLVectori3: GLvectori3,
  TGLVectorui3: GLvectorui3,
  TGLVectorf3: GLvectorf3,
  TGLVectord3: GLvectord3,
  TGLVectorp3: GLvectorp3,
  TGLVectors3: GLvectors3,
  TGLVectorus3: GLvectorus3,
  TGLVectorb4: GLvectorb4,
  TGLVectorub4: GLvectorub4,
  TGLVectori4: GLvectori4,
  TGLVectorui4: GLvectorui4,
  TGLVectorf4: GLvectorf4,
  TGLVectord4: GLvectord4,
  TGLVectorp4: GLvectorp4,
  TGLVectors4: GLvectors4,
  TGLVectorus4: GLvectorus4,
  TGLArrayf4: GLarray4f,
  TGLArrayf3: GLarrayf3,
  TGLArrayd3: GLarrayd3,
  TGLArrayi4: GLarrayi4,
  TGLArrayp4: GLarrayp4,
  TGLMatrixub3: GLmatrixub3,
  TGLMatrixi3: GLmatrixi3,
  TGLMatrixf3: GLmatrixf3,
  TGLMatrixd3: GLmatrixd3,
  TGLMatrixub4: GLmatrixub4,
  TGLMatrixi4: GLmatrixi4,
  TGLMatrixf4: GLmatrixf4,
  TGLMatrixd4: GLmatrixd4,
  TGLVector3d: GLvectord3,
  TGLVector4i: GLvectori4,
  TGLVector4f: GLvectorf4,
  TGLVector4p: GLvectorp4,
  TGLMatrix4f: GLmatrixf4,
  TGLMatrix4d: GLmatrixd4,
].}

proc glGetError*: GLenum {.stdcall, importc, ogl.}
proc getGLerrorCode*: GLerrorCode = glGetError().GLerrorCode
  ## Like ``glGetError`` but returns an enumerator instead.

type
  GLerror* = object of Exception
    ## An exception for OpenGL errors.
    code*: GLerrorCode ## The error code. This might be invalid for two reasons:
                    ## an outdated list of errors or a bad driver.

proc checkGLerror* =
  ## Raise ``GLerror`` if the last call to an OpenGL function generated an error.
  ## You might want to call this once every frame for example if automatic
  ## error checking has been disabled.
  let error = getGLerrorCode()
  if error == glErrNoError:
    return

  var
    exc = new(GLerror)
  for e in AllErrorCodes:
    if e == error:
      exc.msg = "OpenGL error: " & $e
      raise exc

  exc.code = error
  exc.msg = "OpenGL error: unknown (" & $error & ")"
  raise exc

{.push warning[User]: off.}

const
  NoAutoGLerrorCheck* = defined(noAutoGLerrorCheck) ##\
  ## This determines (at compile time) whether an exception should be raised
  ## if an OpenGL call generates an error. No additional code will be generated
  ## and ``enableAutoGLerrorCheck(bool)`` will have no effect when
  ## ``noAutoGLerrorCheck`` is defined.

{.pop.} # warning[User]: off

var
  gAutoGLerrorCheck = true
  gInsideBeginEnd* = false # do not change manually.

proc enableAutoGLerrorCheck*(yes: bool) =
  ## This determines (at run time) whether an exception should be raised if an
  ## OpenGL call generates an error. This has no effect when
  ## ``noAutoGLerrorCheck`` is defined.
  gAutoGLerrorCheck = yes

macro wrapErrorChecking(f: stmt): stmt {.immediate.} =
  f.expectKind nnkStmtList
  result = newStmtList()

  for child in f.children:
    child.expectKind nnkProcDef
    let params = toSeq(child.params.children)
    var glProc = copy child
    glProc.pragma = newNimNode(nnkPragma).add(
        newNimNode(nnkExprColonExpr).add(
          ident"importc" , newLit($child.name))
      ).add(ident"ogl")

    let rawGLprocName = $glProc.name
    glProc.name = ident(rawGLprocName & "Impl")
    var
      body = newStmtList glProc
      returnsSomething = child.params[0].kind != nnkEmpty
      callParams = newSeq[when defined(nimnode): NimNode else: PNimrodNode]()
    for param in params[1 .. <params.len]:
      callParams.add param[0]

    let glCall = newCall(glProc.name, callParams)
    body.add if returnsSomething:
        newAssignment(ident"result", glCall)
      else:
        glCall

    if rawGLprocName == "glBegin":
      body.add newAssignment(ident"gInsideBeginEnd", ident"true")
    if rawGLprocName == "glEnd":
      body.add newAssignment(ident"gInsideBeginEnd", ident"false")

    template errCheck: stmt =
      when not (NoAutoGLerrorCheck):
        if gAutoGLerrorCheck and not gInsideBeginEnd:
          checkGLerror()

    body.add getAst(errCheck())

    var procc = newProc(child.name, params, body)
    procc.pragma = newNimNode(nnkPragma).add(ident"inline")
    procc.name = postfix(procc.name, "*")
    result.add procc

{.push stdcall, hint[XDeclaredButNotUsed]: off, warning[SmallLshouldNotBeUsed]: off.}
wrapErrorChecking:
  proc glMultiTexCoord2d(target: GLenum, s: GLdouble, t: GLdouble) {.importc.}
  proc glDrawElementsIndirect(mode: GLenum, `type`: GLenum, indirect: pointer) {.importc.}
  proc glEnableVertexArrayEXT(vaobj: GLuint, `array`: GLenum) {.importc.}
  proc glDeleteFramebuffers(n: GLsizei, framebuffers: ptr GLuint) {.importc.}
  proc glMultiTexCoord3dv(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glVertexAttrib4d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glLoadPaletteFromModelViewMatrixOES() {.importc.}
  proc glVertex3xvOES(coords: ptr GLfixed) {.importc.}
  proc glNormalStream3sATI(stream: GLenum, nx: GLshort, ny: GLshort, nz: GLshort) {.importc.}
  proc glMatrixFrustumEXT(mode: GLenum, left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble) {.importc.}
  proc glUniformMatrix2fvARB(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glColor4dv(v: ptr GLdouble) {.importc.}
  proc glColor3fv(v: ptr GLfloat) {.importc.}
  proc glVertexAttribI1uiEXT(index: GLuint, x: GLuint) {.importc.}
  proc glGetDebugMessageLogKHR(count: GLuint, bufsize: GLsizei, sources: ptr GLenum, types: ptr GLenum, ids: ptr GLuint, severities: ptr GLenum, lengths: ptr GLsizei, messageLog: cstring): GLuint {.importc.}
  proc glVertexAttribI2iv(index: GLuint, v: ptr GLint) {.importc.}
  proc glTexCoord1xvOES(coords: ptr GLfixed) {.importc.}
  proc glVertex3hNV(x: GLhalfNv, y: GLhalfNv, z: GLhalfNv) {.importc.}
  proc glIsShader(shader: GLuint): GLboolean {.importc.}
  proc glDeleteRenderbuffersEXT(n: GLsizei, renderbuffers: ptr GLuint) {.importc.}
  proc glVertex3hvNV(v: ptr GLhalfNv) {.importc.}
  proc glGetPointervKHR(pname: GLenum, params: ptr pointer) {.importc.}
  proc glProgramUniform3i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glNamedFramebufferTexture1DEXT(framebuffer: GLuint, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glGetNamedProgramLocalParameterfvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLfloat) {.importc.}
  proc glGenRenderbuffersOES(n: GLsizei, renderbuffers: ptr GLuint) {.importc.}
  proc glVertex4dv(v: ptr GLdouble) {.importc.}
  proc glTexCoord2fColor4ubVertex3fvSUN(tc: ptr GLfloat, c: ptr GLubyte, v: ptr GLfloat) {.importc.}
  proc glTexStorage2DEXT(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glVertexAttrib2d(index: GLuint, x: GLdouble, y: GLdouble) {.importc.}
  proc glVertexAttrib1dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glBindProgramARB(target: GLenum, program: GLuint) {.importc.}
  proc glRasterPos2dv(v: ptr GLdouble) {.importc.}
  proc glCompressedTextureSubImage2DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glNormalPointervINTEL(`type`: GLenum, `pointer`: ptr pointer) {.importc.}
  proc glGetInteger64vAPPLE(pname: GLenum, params: ptr GLint64) {.importc.}
  proc glPushMatrix() {.importc.}
  proc glGetCompressedTexImageARB(target: GLenum, level: GLint, img: pointer) {.importc.}
  proc glBindMaterialParameterEXT(face: GLenum, value: GLenum): GLuint {.importc.}
  proc glBlendEquationIndexedAMD(buf: GLuint, mode: GLenum) {.importc.}
  proc glGetObjectBufferfvATI(buffer: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glMakeNamedBufferNonResidentNV(buffer: GLuint) {.importc.}
  proc glUniform2ui64NV(location: GLint, x: GLuint64Ext, y: GLuint64Ext) {.importc.}
  proc glRasterPos4fv(v: ptr GLfloat) {.importc.}
  proc glDeleteTextures(n: GLsizei, textures: ptr GLuint) {.importc.}
  proc glSecondaryColorPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glTextureSubImage1DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glEndTilingQCOM(preserveMask: GLbitfield) {.importc.}
  proc glBindBuffer(target: GLenum, buffer: GLuint) {.importc.}
  proc glUniformMatrix3fvARB(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glSamplerParameterf(sampler: GLuint, pname: GLenum, param: GLfloat) {.importc.}
  proc glSecondaryColor3d(red: GLdouble, green: GLdouble, blue: GLdouble) {.importc.}
  proc glVertexAttrib4sARB(index: GLuint, x: GLshort, y: GLshort, z: GLshort, w: GLshort) {.importc.}
  proc glNamedProgramLocalParameterI4iEXT(program: GLuint, target: GLenum, index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glProgramUniform2iEXT(program: GLuint, location: GLint, v0: GLint, v1: GLint) {.importc.}
  proc glPopAttrib() {.importc.}
  proc glGetnColorTableARB(target: GLenum, format: GLenum, `type`: GLenum, bufSize: GLsizei, table: pointer) {.importc.}
  proc glMatrixLoadIdentityEXT(mode: GLenum) {.importc.}
  proc glGetNamedProgramivEXT(program: GLuint, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glCopyTextureSubImage2DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glUniform4i64NV(location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext, w: GLint64Ext) {.importc.}
  proc glDeleteTexturesEXT(n: GLsizei, textures: ptr GLuint) {.importc.}
  proc glMultiTexCoord1dv(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glMultiTexRenderbufferEXT(texunit: GLenum, target: GLenum, renderbuffer: GLuint) {.importc.}
  proc glMultiDrawArraysIndirect(mode: GLenum, indirect: ptr pointer, drawcount: GLsizei, stride: GLsizei) {.importc.}
  proc glGetUniformfvARB(programObj: GLhandleArb, location: GLint, params: ptr GLfloat) {.importc.}
  proc glBufferDataARB(target: GLenum, size: GLsizeiptrArb, data: pointer, usage: GLenum) {.importc.}
  proc glTexCoord2d(s: GLdouble, t: GLdouble) {.importc.}
  proc glGetArrayObjectfvATI(`array`: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glShaderOp1EXT(op: GLenum, res: GLuint, arg1: GLuint) {.importc.}
  proc glColor3s(red: GLshort, green: GLshort, blue: GLshort) {.importc.}
  proc glStencilFuncSeparate(face: GLenum, fun: GLenum, `ref`: GLint, mask: GLuint) {.importc.}
  proc glTextureImage2DMultisampleCoverageNV(texture: GLuint, target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, fixedSampleLocations: GLboolean) {.importc.}
  proc glMultiTexCoord2xvOES(texture: GLenum, coords: ptr GLfixed) {.importc.}
  proc glGetVertexAttribLui64vNV(index: GLuint, pname: GLenum, params: ptr GLuint64Ext) {.importc.}
  proc glNormal3xOES(nx: GLfixed, ny: GLfixed, nz: GLfixed) {.importc.}
  proc glMapBufferRangeEXT(target: GLenum, offset: GLintptr, length: GLsizeiptr, access: GLbitfield) {.importc.}
  proc glCreateShader(`type`: GLenum): GLuint {.importc.}
  proc glDrawRangeElementArrayAPPLE(mode: GLenum, start: GLuint, `end`: GLuint, first: GLint, count: GLsizei) {.importc.}
  proc glVertex2bOES(x: GLbyte) {.importc.}
  proc glGetMapxvOES(target: GLenum, query: GLenum, v: ptr GLfixed) {.importc.}
  proc glRasterPos3sv(v: ptr GLshort) {.importc.}
  proc glDeleteQueriesARB(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glProgramUniform1iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glVertexStream2dvATI(stream: GLenum, coords: ptr GLdouble) {.importc.}
  proc glBindVertexArrayOES(`array`: GLuint) {.importc.}
  proc glLightModelfv(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glEvalCoord2dv(u: ptr GLdouble) {.importc.}
  proc glColor3hNV(red: GLhalfNv, green: GLhalfNv, blue: GLhalfNv) {.importc.}
  proc glSecondaryColor3iEXT(red: GLint, green: GLint, blue: GLint) {.importc.}
  proc glBindTexture(target: GLenum, texture: GLuint) {.importc.}
  proc glUniformBufferEXT(program: GLuint, location: GLint, buffer: GLuint) {.importc.}
  proc glGetCombinerInputParameterfvNV(stage: GLenum, portion: GLenum, variable: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glUniform2ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glMatrixMultTransposefEXT(mode: GLenum, m: ptr GLfloat) {.importc.}
  proc glLineWidth(width: GLfloat) {.importc.}
  proc glRotatef(angle: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glNormalStream3svATI(stream: GLenum, coords: ptr GLshort) {.importc.}
  proc glTexCoordP4ui(`type`: GLenum, coords: GLuint) {.importc.}
  proc glImageTransformParameterfvHP(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glUniform3uiEXT(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint) {.importc.}
  proc glGetInvariantIntegervEXT(id: GLuint, value: GLenum, data: ptr GLint) {.importc.}
  proc glGetTransformFeedbackVaryingEXT(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLsizei, `type`: ptr GLenum, name: cstring) {.importc.}
  proc glSamplerParameterIuiv(sampler: GLuint, pname: GLenum, param: ptr GLuint) {.importc.}
  proc glProgramUniform2fEXT(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat) {.importc.}
  proc glMultiTexCoord2hvNV(target: GLenum, v: ptr GLhalfNv) {.importc.}
  proc glDeleteRenderbuffersOES(n: GLsizei, renderbuffers: ptr GLuint) {.importc.}
  proc glRenderbufferStorageMultisampleCoverageNV(target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glStencilClearTagEXT(stencilTagBits: GLsizei, stencilClearTag: GLuint) {.importc.}
  proc glConvolutionParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glFenceSyncAPPLE(condition: GLenum, flags: GLbitfield): GLsync {.importc.}
  proc glGetVariantArrayObjectivATI(id: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramUniform4dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glPushDebugGroupKHR(source: GLenum, id: GLuint, length: GLsizei, message: cstring) {.importc.}
  proc glFragmentLightivSGIX(light: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glFramebufferTexture2DEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glGetActiveSubroutineUniformiv(program: GLuint, shadertype: GLenum, index: GLuint, pname: GLenum, values: ptr GLint) {.importc.}
  proc glFrustumf(l: GLfloat, r: GLfloat, b: GLfloat, t: GLfloat, n: GLfloat, f: GLfloat) {.importc.}
  proc glEndQueryIndexed(target: GLenum, index: GLuint) {.importc.}
  proc glCompressedTextureSubImage3DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glGetProgramPipelineInfoLogEXT(pipeline: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring) {.importc.}
  proc glGetVertexAttribfvNV(index: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexArrayIndexOffsetEXT(vaobj: GLuint, buffer: GLuint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glDrawTexsvOES(coords: ptr GLshort) {.importc.}
  proc glMultiTexCoord1hNV(target: GLenum, s: GLhalfNv) {.importc.}
  proc glWindowPos2iv(v: ptr GLint) {.importc.}
  proc glMultiTexCoordP1ui(texture: GLenum, `type`: GLenum, coords: GLuint) {.importc.}
  proc glTexCoord1i(s: GLint) {.importc.}
  proc glVertex4hvNV(v: ptr GLhalfNv) {.importc.}
  proc glCallLists(n: GLsizei, `type`: GLenum, lists: pointer) {.importc.}
  proc glIndexFormatNV(`type`: GLenum, stride: GLsizei) {.importc.}
  proc glPointParameterfARB(pname: GLenum, param: GLfloat) {.importc.}
  proc glProgramUniform1dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glGetVertexAttribArrayObjectfvATI(index: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVDPAUUnmapSurfacesNV(numSurface: GLsizei, surfaces: ptr GLvdpauSurfaceNv) {.importc.}
  proc glVertexAttribIFormat(attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint) {.importc.}
  proc glClearColorx(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed) {.importc.}
  proc glColor3bv(v: ptr GLbyte) {.importc.}
  proc glNamedProgramLocalParameter4dEXT(program: GLuint, target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glVertexPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glGetObjectLabelKHR(identifier: GLenum, name: GLuint, bufSize: GLsizei, length: ptr GLsizei, label: cstring) {.importc.}
  proc glCombinerStageParameterfvNV(stage: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glNormal3hvNV(v: ptr GLhalfNv) {.importc.}
  proc glUniform2i64NV(location: GLint, x: GLint64Ext, y: GLint64Ext) {.importc.}
  proc glMultiTexCoord2iv(target: GLenum, v: ptr GLint) {.importc.}
  proc glProgramUniform3i(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint) {.importc.}
  proc glDeleteAsyncMarkersSGIX(marker: GLuint, range: GLsizei) {.importc.}
  proc glStencilOp(fail: GLenum, zfail: GLenum, zpass: GLenum) {.importc.}
  proc glColorP4ui(`type`: GLenum, color: GLuint) {.importc.}
  proc glFinishAsyncSGIX(markerp: ptr GLuint): GLint {.importc.}
  proc glDrawTexsOES(x: GLshort, y: GLshort, z: GLshort, width: GLshort, height: GLshort) {.importc.}
  proc glLineStipple(factor: GLint, pattern: GLushort) {.importc.}
  proc glAlphaFragmentOp1ATI(op: GLenum, dst: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint) {.importc.}
  proc glMapTexture2DINTEL(texture: GLuint, level: GLint, access: GLbitfield, stride: ptr GLint, layout: ptr GLenum) {.importc.}
  proc glVertex4f(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glFramebufferTextureARB(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glProgramUniform3ui64NV(program: GLuint, location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext) {.importc.}
  proc glMultTransposeMatrixxOES(m: ptr GLfixed) {.importc.}
  proc glNormal3fv(v: ptr GLfloat) {.importc.}
  proc glUniform4fARB(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) {.importc.}
  proc glBinormal3bEXT(bx: GLbyte, by: GLbyte, bz: GLbyte) {.importc.}
  proc glGenProgramPipelinesEXT(n: GLsizei, pipelines: ptr GLuint) {.importc.}
  proc glDispatchComputeIndirect(indirect: GLintptr) {.importc.}
  proc glGetPerfMonitorCounterDataAMD(monitor: GLuint, pname: GLenum, dataSize: GLsizei, data: ptr GLuint, bytesWritten: ptr GLint) {.importc.}
  proc glStencilOpValueAMD(face: GLenum, value: GLuint) {.importc.}
  proc glTangent3fvEXT(v: ptr GLfloat) {.importc.}
  proc glUniform3iARB(location: GLint, v0: GLint, v1: GLint, v2: GLint) {.importc.}
  proc glMatrixScalefEXT(mode: GLenum, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glVertexAttrib2dARB(index: GLuint, x: GLdouble, y: GLdouble) {.importc.}
  proc glIsVertexArray(`array`: GLuint): GLboolean {.importc.}
  proc glGetMaterialx(face: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glMultiTexCoord1dARB(target: GLenum, s: GLdouble) {.importc.}
  proc glColor3usv(v: ptr GLushort) {.importc.}
  proc glVertexStream3svATI(stream: GLenum, coords: ptr GLshort) {.importc.}
  proc glRasterPos3s(x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glMultiTexCoord2bOES(texture: GLenum, s: GLbyte, t: GLbyte) {.importc.}
  proc glGetClipPlanefOES(plane: GLenum, equation: ptr GLfloat) {.importc.}
  proc glFramebufferTextureEXT(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glVertexAttrib1dNV(index: GLuint, x: GLdouble) {.importc.}
  proc glSampleCoverageOES(value: GLfixed, invert: GLboolean) {.importc.}
  proc glCompressedTexSubImage2DARB(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.importc.}
  proc glUniform1iv(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glExtGetProgramsQCOM(programs: ptr GLuint, maxPrograms: GLint, numPrograms: ptr GLint) {.importc.}
  proc glFogx(pname: GLenum, param: GLfixed) {.importc.}
  proc glMultiTexCoord3hNV(target: GLenum, s: GLhalfNv, t: GLhalfNv, r: GLhalfNv) {.importc.}
  proc glClipPlane(plane: GLenum, equation: ptr GLdouble) {.importc.}
  proc glConvolutionParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glInvalidateBufferData(buffer: GLuint) {.importc.}
  proc glCheckNamedFramebufferStatusEXT(framebuffer: GLuint, target: GLenum): GLenum {.importc.}
  proc glLinkProgram(program: GLuint) {.importc.}
  proc glCheckFramebufferStatus(target: GLenum): GLenum {.importc.}
  proc glBlendFunci(buf: GLuint, src: GLenum, dst: GLenum) {.importc.}
  proc glProgramUniform4uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glConvolutionFilter2D(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, image: pointer) {.importc.}
  proc glVertex4bvOES(coords: ptr GLbyte) {.importc.}
  proc glCopyTextureSubImage1DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glColor4uiv(v: ptr GLuint) {.importc.}
  proc glGetBufferParameteri64v(target: GLenum, pname: GLenum, params: ptr GLint64) {.importc.}
  proc glGetLocalConstantBooleanvEXT(id: GLuint, value: GLenum, data: ptr GLboolean) {.importc.}
  proc glCoverStrokePathNV(path: GLuint, coverMode: GLenum) {.importc.}
  proc glScaled(x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glLightfv(light: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexParameterIiv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMakeImageHandleResidentNV(handle: GLuint64, access: GLenum) {.importc.}
  proc glWindowPos3iARB(x: GLint, y: GLint, z: GLint) {.importc.}
  proc glListBase(base: GLuint) {.importc.}
  proc glFlushMappedBufferRangeEXT(target: GLenum, offset: GLintptr, length: GLsizeiptr) {.importc.}
  proc glNormal3dv(v: ptr GLdouble) {.importc.}
  proc glProgramUniform4d(program: GLuint, location: GLint, v0: GLdouble, v1: GLdouble, v2: GLdouble, v3: GLdouble) {.importc.}
  proc glCreateShaderProgramEXT(`type`: GLenum, string: cstring): GLuint {.importc.}
  proc glGetLightxvOES(light: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glGetObjectPtrLabelKHR(`ptr`: ptr pointer, bufSize: GLsizei, length: ptr GLsizei, label: cstring) {.importc.}
  proc glTransformPathNV(resultPath: GLuint, srcPath: GLuint, transformType: GLenum, transformValues: ptr GLfloat) {.importc.}
  proc glMultTransposeMatrixf(m: ptr GLfloat) {.importc.}
  proc glMapVertexAttrib2dAPPLE(index: GLuint, size: GLuint, u1: GLdouble, u2: GLdouble, ustride: GLint, uorder: GLint, v1: GLdouble, v2: GLdouble, vstride: GLint, vorder: GLint, points: ptr GLdouble) {.importc.}
  proc glIsSync(sync: GLsync): GLboolean {.importc.}
  proc glMultMatrixx(m: ptr GLfixed) {.importc.}
  proc glInterpolatePathsNV(resultPath: GLuint, pathA: GLuint, pathB: GLuint, weight: GLfloat) {.importc.}
  proc glEnableClientStateIndexedEXT(`array`: GLenum, index: GLuint) {.importc.}
  proc glProgramEnvParameter4fARB(target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glVertexAttrib2svARB(index: GLuint, v: ptr GLshort) {.importc.}
  proc glLighti(light: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glSelectBuffer(size: GLsizei, buffer: ptr GLuint) {.importc.}
  proc glReplacementCodeusvSUN(code: ptr GLushort) {.importc.}
  proc glMapVertexAttrib1fAPPLE(index: GLuint, size: GLuint, u1: GLfloat, u2: GLfloat, stride: GLint, order: GLint, points: ptr GLfloat) {.importc.}
  proc glMaterialx(face: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glDrawTransformFeedback(mode: GLenum, id: GLuint) {.importc.}
  proc glWindowPos2i(x: GLint, y: GLint) {.importc.}
  proc glMultiTexEnviEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glProgramUniform1fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glDrawBuffersARB(n: GLsizei, bufs: ptr GLenum) {.importc.}
  proc glGetUniformLocationARB(programObj: GLhandleArb, name: cstring): GLint {.importc.}
  proc glResumeTransformFeedback() {.importc.}
  proc glMap1f(target: GLenum, u1: GLfloat, u2: GLfloat, stride: GLint, order: GLint, points: ptr GLfloat) {.importc.}
  proc glVertex3xOES(x: GLfixed, y: GLfixed) {.importc.}
  proc glPathCoordsNV(path: GLuint, numCoords: GLsizei, coordType: GLenum, coords: pointer) {.importc.}
  proc glListParameterfSGIX(list: GLuint, pname: GLenum, param: GLfloat) {.importc.}
  proc glGetUniformivARB(programObj: GLhandleArb, location: GLint, params: ptr GLint) {.importc.}
  proc glBinormal3bvEXT(v: ptr GLbyte) {.importc.}
  proc glVertexAttribP3ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint) {.importc.}
  proc glGetVertexArrayPointeri_vEXT(vaobj: GLuint, index: GLuint, pname: GLenum, param: ptr pointer) {.importc.}
  proc glProgramParameter4fvNV(target: GLenum, index: GLuint, v: ptr GLfloat) {.importc.}
  proc glDiscardFramebufferEXT(target: GLenum, numAttachments: GLsizei, attachments: ptr GLenum) {.importc.}
  proc glGetDebugMessageLogARB(count: GLuint, bufsize: GLsizei, sources: ptr GLenum, types: ptr GLenum, ids: ptr GLuint, severities: ptr GLenum, lengths: ptr GLsizei, messageLog: cstring): GLuint {.importc.}
  proc glResolveMultisampleFramebufferAPPLE() {.importc.}
  proc glGetIntegeri_vEXT(target: GLenum, index: GLuint, data: ptr GLint) {.importc.}
  proc glDepthBoundsdNV(zmin: GLdouble, zmax: GLdouble) {.importc.}
  proc glEnd() {.importc.}
  proc glBindBufferBaseEXT(target: GLenum, index: GLuint, buffer: GLuint) {.importc.}
  proc glVertexAttribDivisor(index: GLuint, divisor: GLuint) {.importc.}
  proc glFogCoorddEXT(coord: GLdouble) {.importc.}
  proc glFrontFace(mode: GLenum) {.importc.}
  proc glVertexAttrib1hNV(index: GLuint, x: GLhalfNv) {.importc.}
  proc glNamedProgramLocalParametersI4uivEXT(program: GLuint, target: GLenum, index: GLuint, count: GLsizei, params: ptr GLuint) {.importc.}
  proc glTexCoord1dv(v: ptr GLdouble) {.importc.}
  proc glBindVideoCaptureStreamTextureNV(video_capture_slot: GLuint, stream: GLuint, frame_region: GLenum, target: GLenum, texture: GLuint) {.importc.}
  proc glWindowPos2iARB(x: GLint, y: GLint) {.importc.}
  proc glVertexAttribFormatNV(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei) {.importc.}
  proc glUniform1uivEXT(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glGetVideoivNV(video_slot: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttrib3fvARB(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glVertexArraySecondaryColorOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glSecondaryColor3bv(v: ptr GLbyte) {.importc.}
  proc glDispatchComputeGroupSizeARB(num_groups_x: GLuint, num_groups_y: GLuint, num_groups_z: GLuint, group_size_x: GLuint, group_size_y: GLuint, group_size_z: GLuint) {.importc.}
  proc glNamedCopyBufferSubDataEXT(readBuffer: GLuint, writeBuffer: GLuint, readOffset: GLintptr, writeOffset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glSampleCoverage(value: GLfloat, invert: GLboolean) {.importc.}
  proc glGetnMapfvARB(target: GLenum, query: GLenum, bufSize: GLsizei, v: ptr GLfloat) {.importc.}
  proc glVertexStream2svATI(stream: GLenum, coords: ptr GLshort) {.importc.}
  proc glProgramParameters4fvNV(target: GLenum, index: GLuint, count: GLsizei, v: ptr GLfloat) {.importc.}
  proc glVertexAttrib4fARB(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glIndexd(c: GLdouble) {.importc.}
  proc glGetInteger64v(pname: GLenum, params: ptr GLint64) {.importc.}
  proc glGetMultiTexImageEXT(texunit: GLenum, target: GLenum, level: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glLightModelx(pname: GLenum, param: GLfixed) {.importc.}
  proc glMap2f(target: GLenum, u1: GLfloat, u2: GLfloat, ustride: GLint, uorder: GLint, v1: GLfloat, v2: GLfloat, vstride: GLint, vorder: GLint, points: ptr GLfloat) {.importc.}
  proc glSecondaryColorPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint) {.importc.}
  proc glVertexArrayVertexAttribIOffsetEXT(vaobj: GLuint, buffer: GLuint, index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glProgramUniformHandleui64vARB(program: GLuint, location: GLint, count: GLsizei, values: ptr GLuint64) {.importc.}
  proc glActiveProgramEXT(program: GLuint) {.importc.}
  proc glProgramUniformMatrix4x3fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glCompressedTexSubImage3DARB(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.importc.}
  proc glBindProgramPipelineEXT(pipeline: GLuint) {.importc.}
  proc glDetailTexFuncSGIS(target: GLenum, n: GLsizei, points: ptr GLfloat) {.importc.}
  proc glSecondaryColor3ubEXT(red: GLubyte, green: GLubyte, blue: GLubyte) {.importc.}
  proc glDrawArraysInstanced(mode: GLenum, first: GLint, count: GLsizei, instancecount: GLsizei) {.importc.}
  proc glWindowPos3fARB(x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glNamedProgramLocalParameter4fEXT(program: GLuint, target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glTextureParameterfvEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glProgramUniformHandleui64ARB(program: GLuint, location: GLint, value: GLuint64) {.importc.}
  proc glHistogramEXT(target: GLenum, width: GLsizei, internalformat: GLenum, sink: GLboolean) {.importc.}
  proc glResumeTransformFeedbackNV() {.importc.}
  proc glGetMaterialxv(face: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glMultiTexCoord1sv(target: GLenum, v: ptr GLshort) {.importc.}
  proc glReadInstrumentsSGIX(marker: GLint) {.importc.}
  proc glTexCoord4hNV(s: GLhalfNv, t: GLhalfNv, r: GLhalfNv, q: GLhalfNv) {.importc.}
  proc glVertexAttribL4i64vNV(index: GLuint, v: ptr GLint64Ext) {.importc.}
  proc glEnableVariantClientStateEXT(id: GLuint) {.importc.}
  proc glSyncTextureINTEL(texture: GLuint) {.importc.}
  proc glGetObjectPtrLabel(`ptr`: ptr pointer, bufSize: GLsizei, length: ptr GLsizei, label: cstring) {.importc.}
  proc glCopyTexSubImage1D(target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glOrthofOES(l: GLfloat, r: GLfloat, b: GLfloat, t: GLfloat, n: GLfloat, f: GLfloat) {.importc.}
  proc glWindowPos3sARB(x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glIsBufferARB(buffer: GLuint): GLboolean {.importc.}
  proc glColor3sv(v: ptr GLshort) {.importc.}
  proc glEvalMesh1(mode: GLenum, i1: GLint, i2: GLint) {.importc.}
  proc glMultiDrawArrays(mode: GLenum, first: ptr GLint, count: ptr GLsizei, drawcount: GLsizei) {.importc.}
  proc glGetMultiTexEnvfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glWindowPos3fMESA(x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glExtGetFramebuffersQCOM(framebuffers: ptr GLuint, maxFramebuffers: GLint, numFramebuffers: ptr GLint) {.importc.}
  proc glTexSubImage3D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glVertexAttrib4uiv(index: GLuint, v: ptr GLuint) {.importc.}
  proc glProgramUniformui64NV(program: GLuint, location: GLint, value: GLuint64Ext) {.importc.}
  proc glMultiTexCoord2ivARB(target: GLenum, v: ptr GLint) {.importc.}
  proc glProgramUniform4i64NV(program: GLuint, location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext, w: GLint64Ext) {.importc.}
  proc glWindowPos2svMESA(v: ptr GLshort) {.importc.}
  proc glVertexAttrib3dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glColor4i(red: GLint, green: GLint, blue: GLint, alpha: GLint) {.importc.}
  proc glClampColor(target: GLenum, clamp: GLenum) {.importc.}
  proc glVertexP2ui(`type`: GLenum, value: GLuint) {.importc.}
  proc glGenQueries(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glBindBufferOffsetNV(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr) {.importc.}
  proc glGetFragDataLocation(program: GLuint, name: cstring): GLint {.importc.}
  proc glVertexAttribs2svNV(index: GLuint, count: GLsizei, v: ptr GLshort) {.importc.}
  proc glGetPathLengthNV(path: GLuint, startSegment: GLsizei, numSegments: GLsizei): GLfloat {.importc.}
  proc glVertexAttrib3dARB(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glMultiTexGenfvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glFlushPixelDataRangeNV(target: GLenum) {.importc.}
  proc glReplacementCodeuiNormal3fVertex3fSUN(rc: GLuint, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glPathParameteriNV(path: GLuint, pname: GLenum, value: GLint) {.importc.}
  proc glVertexAttribI2iEXT(index: GLuint, x: GLint, y: GLint) {.importc.}
  proc glPixelStorei(pname: GLenum, param: GLint) {.importc.}
  proc glGetNamedFramebufferParameterivEXT(framebuffer: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetTexEnvxv(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glPathStringNV(path: GLuint, format: GLenum, length: GLsizei, pathString: pointer) {.importc.}
  proc glDepthMask(flag: GLboolean) {.importc.}
  proc glCopyTexImage1D(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint) {.importc.}
  proc glDepthRangexOES(n: GLfixed, f: GLfixed) {.importc.}
  proc glUniform2i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glSetFragmentShaderConstantATI(dst: GLuint, value: ptr GLfloat) {.importc.}
  proc glAttachShader(program: GLuint, shader: GLuint) {.importc.}
  proc glGetFramebufferParameterivEXT(framebuffer: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glPointParameteriNV(pname: GLenum, param: GLint) {.importc.}
  proc glWindowPos2dMESA(x: GLdouble, y: GLdouble) {.importc.}
  proc glGetTextureParameterfvEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexBumpParameterfvATI(pname: GLenum, param: ptr GLfloat) {.importc.}
  proc glCompressedTexImage1DARB(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.importc.}
  proc glGetTexGendv(coord: GLenum, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glGetFragmentMaterialfvSGIX(face: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glBeginConditionalRenderNVX(id: GLuint) {.importc.}
  proc glLightModelxOES(pname: GLenum, param: GLfixed) {.importc.}
  proc glTexCoord2xOES(s: GLfixed, t: GLfixed) {.importc.}
  proc glProgramUniformMatrix2x4fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glRasterPos2xvOES(coords: ptr GLfixed) {.importc.}
  proc glGetMapiv(target: GLenum, query: GLenum, v: ptr GLint) {.importc.}
  proc glGetImageHandleARB(texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, format: GLenum): GLuint64 {.importc.}
  proc glVDPAURegisterVideoSurfaceNV(vdpSurface: pointer, target: GLenum, numTextureNames: GLsizei, textureNames: ptr GLuint): GLvdpauSurfaceNv {.importc.}
  proc glVertexAttribL2dEXT(index: GLuint, x: GLdouble, y: GLdouble) {.importc.}
  proc glVertexAttrib1dvNV(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glPollAsyncSGIX(markerp: ptr GLuint): GLint {.importc.}
  proc glCullParameterfvEXT(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glMakeNamedBufferResidentNV(buffer: GLuint, access: GLenum) {.importc.}
  proc glPointParameterfSGIS(pname: GLenum, param: GLfloat) {.importc.}
  proc glGenLists(range: GLsizei): GLuint {.importc.}
  proc glGetTexBumpParameterfvATI(pname: GLenum, param: ptr GLfloat) {.importc.}
  proc glCompressedMultiTexSubImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glFinishFenceNV(fence: GLuint) {.importc.}
  proc glPointSize(size: GLfloat) {.importc.}
  proc glCompressedTextureImage2DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glGetUniformui64vNV(program: GLuint, location: GLint, params: ptr GLuint64Ext) {.importc.}
  proc glGetMapControlPointsNV(target: GLenum, index: GLuint, `type`: GLenum, ustride: GLsizei, vstride: GLsizei, packed: GLboolean, points: pointer) {.importc.}
  proc glGetPathColorGenfvNV(color: GLenum, pname: GLenum, value: ptr GLfloat) {.importc.}
  proc glTexCoord2f(s: GLfloat, t: GLfloat) {.importc.}
  proc glSampleMaski(index: GLuint, mask: GLbitfield) {.importc.}
  proc glReadBufferIndexedEXT(src: GLenum, index: GLint) {.importc.}
  proc glCoverFillPathNV(path: GLuint, coverMode: GLenum) {.importc.}
  proc glColorTableParameterfvSGI(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glDeleteVertexArraysAPPLE(n: GLsizei, arrays: ptr GLuint) {.importc.}
  proc glGetVertexAttribIiv(index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glWeightbvARB(size: GLint, weights: ptr GLbyte) {.importc.}
  proc glGetNamedBufferPointervEXT(buffer: GLuint, pname: GLenum, params: ptr pointer) {.importc.}
  proc glTexCoordPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glColor4fv(v: ptr GLfloat) {.importc.}
  proc glGetnUniformfvARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLfloat) {.importc.}
  proc glMaterialxOES(face: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glGetFixedv(pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glMaterialf(face: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glVideoCaptureStreamParameterfvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetDebugMessageLogAMD(count: GLuint, bufsize: GLsizei, categories: ptr GLenum, severities: ptr GLuint, ids: ptr GLuint, lengths: ptr GLsizei, message: cstring): GLuint {.importc.}
  proc glProgramUniform2uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glMatrixMultTransposedEXT(mode: GLenum, m: ptr GLdouble) {.importc.}
  proc glIsPointInStrokePathNV(path: GLuint, x: GLfloat, y: GLfloat): GLboolean {.importc.}
  proc glDisable(cap: GLenum) {.importc.}
  proc glCompileShader(shader: GLuint) {.importc.}
  proc glLoadTransposeMatrixd(m: ptr GLdouble) {.importc.}
  proc glGetMultiTexParameterIuivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glGetHistogram(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer) {.importc.}
  proc glMultiTexCoord3fvARB(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glColor4xvOES(components: ptr GLfixed) {.importc.}
  proc glIsBuffer(buffer: GLuint): GLboolean {.importc.}
  proc glVertex2dv(v: ptr GLdouble) {.importc.}
  proc glNamedProgramLocalParameterI4uivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLuint) {.importc.}
  proc glPixelTexGenParameteriSGIS(pname: GLenum, param: GLint) {.importc.}
  proc glBindVertexBuffers(first: GLuint, count: GLsizei, buffers: ptr GLuint, offsets: ptr GLintptr, strides: ptr GLsizei) {.importc.}
  proc glUniform1ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glColor4ub(red: GLubyte, green: GLubyte, blue: GLubyte, alpha: GLubyte) {.importc.}
  proc glConvolutionParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glReplacementCodeuiColor4fNormal3fVertex3fSUN(rc: GLuint, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glVertexAttribI2ui(index: GLuint, x: GLuint, y: GLuint) {.importc.}
  proc glDeleteNamesAMD(identifier: GLenum, num: GLuint, names: ptr GLuint) {.importc.}
  proc glPixelTransferxOES(pname: GLenum, param: GLfixed) {.importc.}
  proc glVertexAttrib4ivARB(index: GLuint, v: ptr GLint) {.importc.}
  proc glLightModeli(pname: GLenum, param: GLint) {.importc.}
  proc glGetHistogramEXT(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer) {.importc.}
  proc glWindowPos3svMESA(v: ptr GLshort) {.importc.}
  proc glRasterPos3iv(v: ptr GLint) {.importc.}
  proc glCopyTextureSubImage3DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glTextureStorage3DMultisampleEXT(texture: GLuint, target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, fixedsamplelocations: GLboolean) {.importc.}
  proc glIsNameAMD(identifier: GLenum, name: GLuint): GLboolean {.importc.}
  proc glProgramUniformMatrix3fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glGetProgramParameterfvNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexStorage3D(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei) {.importc.}
  proc glMultiTexCoord2xOES(texture: GLenum, s: GLfixed, t: GLfixed) {.importc.}
  proc glWindowPos2fARB(x: GLfloat, y: GLfloat) {.importc.}
  proc glGetProgramResourceIndex(program: GLuint, programInterface: GLenum, name: cstring): GLuint {.importc.}
  proc glProgramUniform2uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glMakeImageHandleNonResidentNV(handle: GLuint64) {.importc.}
  proc glNamedProgramLocalParameter4fvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLfloat) {.importc.}
  proc glInvalidateFramebuffer(target: GLenum, numAttachments: GLsizei, attachments: ptr GLenum) {.importc.}
  proc glTexStorage3DMultisample(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, fixedsamplelocations: GLboolean) {.importc.}
  proc glMapVertexAttrib2fAPPLE(index: GLuint, size: GLuint, u1: GLfloat, u2: GLfloat, ustride: GLint, uorder: GLint, v1: GLfloat, v2: GLfloat, vstride: GLint, vorder: GLint, points: ptr GLfloat) {.importc.}
  proc glCombinerParameterfNV(pname: GLenum, param: GLfloat) {.importc.}
  proc glCopyMultiTexImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint) {.importc.}
  proc glBindVertexShaderEXT(id: GLuint) {.importc.}
  proc glPathGlyphsNV(firstPathName: GLuint, fontTarget: GLenum, fontName: pointer, fontStyle: GLbitfield, numGlyphs: GLsizei, `type`: GLenum, charcodes: pointer, handleMissingGlyphs: GLenum, pathParameterTemplate: GLuint, emScale: GLfloat) {.importc.}
  proc glProgramLocalParametersI4uivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLuint) {.importc.}
  proc glMultiTexCoord3hvNV(target: GLenum, v: ptr GLhalfNv) {.importc.}
  proc glMultiTexCoordP2uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glDisableVariantClientStateEXT(id: GLuint) {.importc.}
  proc glGetTexLevelParameterxvOES(target: GLenum, level: GLint, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glRasterPos2sv(v: ptr GLshort) {.importc.}
  proc glWeightPathsNV(resultPath: GLuint, numPaths: GLsizei, paths: ptr GLuint, weights: ptr GLfloat) {.importc.}
  proc glDrawBuffersNV(n: GLsizei, bufs: ptr GLenum) {.importc.}
  proc glBindBufferARB(target: GLenum, buffer: GLuint) {.importc.}
  proc glVariantbvEXT(id: GLuint, `addr`: ptr GLbyte) {.importc.}
  proc glColorP3uiv(`type`: GLenum, color: ptr GLuint) {.importc.}
  proc glBlendEquationEXT(mode: GLenum) {.importc.}
  proc glProgramLocalParameterI4uivNV(target: GLenum, index: GLuint, params: ptr GLuint) {.importc.}
  proc glRenderMode(mode: GLenum): GLint {.importc.}
  proc glVertexStream4fATI(stream: GLenum, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glGetObjectLabelEXT(`type`: GLenum, `object`: GLuint, bufSize: GLsizei, length: ptr GLsizei, label: cstring) {.importc.}
  proc glNamedFramebufferTexture3DEXT(framebuffer: GLuint, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint) {.importc.}
  proc glLoadMatrixf(m: ptr GLfloat) {.importc.}
  proc glGetQueryObjectuivEXT(id: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glBindVideoCaptureStreamBufferNV(video_capture_slot: GLuint, stream: GLuint, frame_region: GLenum, offset: GLintPtrArb) {.importc.}
  proc glMatrixOrthoEXT(mode: GLenum, left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble) {.importc.}
  proc glBlendFunc(sfactor: GLenum, dfactor: GLenum) {.importc.}
  proc glTexGenxvOES(coord: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glMatrixMode(mode: GLenum) {.importc.}
  proc glColorTableParameterivSGI(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetProgramInfoLog(program: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring) {.importc.}
  proc glGetSeparableFilter(target: GLenum, format: GLenum, `type`: GLenum, row: pointer, column: pointer, span: pointer) {.importc.}
  proc glFogfv(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glDrawTexfvOES(coords: ptr GLfloat) {.importc.}
  proc glClipPlanexIMG(p: GLenum, eqn: ptr GLfixed) {.importc.}
  proc glResetHistogramEXT(target: GLenum) {.importc.}
  proc glMemoryBarrier(barriers: GLbitfield) {.importc.}
  proc glGetPixelMapusv(map: GLenum, values: ptr GLushort) {.importc.}
  proc glEvalCoord2f(u: GLfloat, v: GLfloat) {.importc.}
  proc glUniform4uiv(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glIsProgramARB(program: GLuint): GLboolean {.importc.}
  proc glPointParameterfv(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexBuffer(target: GLenum, internalformat: GLenum, buffer: GLuint) {.importc.}
  proc glVertexAttrib1s(index: GLuint, x: GLshort) {.importc.}
  proc glRenderbufferStorageMultisampleEXT(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glMapNamedBufferEXT(buffer: GLuint, access: GLenum) {.importc.}
  proc glDebugMessageCallbackAMD(callback: GLdebugProcAmd, userParam: ptr pointer) {.importc.}
  proc glGetTexEnvfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexAttribI3uivEXT(index: GLuint, v: ptr GLuint) {.importc.}
  proc glMultiTexEnvfEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glGetUniformiv(program: GLuint, location: GLint, params: ptr GLint) {.importc.}
  proc glProgramLocalParameters4fvEXT(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLfloat) {.importc.}
  proc glStencilStrokePathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, reference: GLint, mask: GLuint, transformType: GLenum, transformValues: ptr GLfloat) {.importc.}
  proc glBeginConditionalRender(id: GLuint, mode: GLenum) {.importc.}
  proc glVertexAttribI3uiEXT(index: GLuint, x: GLuint, y: GLuint, z: GLuint) {.importc.}
  proc glVDPAUMapSurfacesNV(numSurfaces: GLsizei, surfaces: ptr GLvdpauSurfaceNv) {.importc.}
  proc glGetProgramResourceName(program: GLuint, programInterface: GLenum, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, name: cstring) {.importc.}
  proc glMultiTexCoord4f(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat) {.importc.}
  proc glVertexAttrib2hNV(index: GLuint, x: GLhalfNv, y: GLhalfNv) {.importc.}
  proc glDrawArraysInstancedNV(mode: GLenum, first: GLint, count: GLsizei, primcount: GLsizei) {.importc.}
  proc glClearAccum(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {.importc.}
  proc glVertexAttribI4usv(index: GLuint, v: ptr GLushort) {.importc.}
  proc glGetProgramNamedParameterfvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, params: ptr GLfloat) {.importc.}
  proc glTextureLightEXT(pname: GLenum) {.importc.}
  proc glPathSubCoordsNV(path: GLuint, coordStart: GLsizei, numCoords: GLsizei, coordType: GLenum, coords: pointer) {.importc.}
  proc glBindImageTexture(unit: GLuint, texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, access: GLenum, format: GLenum) {.importc.}
  proc glGenVertexArraysAPPLE(n: GLsizei, arrays: ptr GLuint) {.importc.}
  proc glFogCoordf(coord: GLfloat) {.importc.}
  proc glFrameTerminatorGREMEDY() {.importc.}
  proc glValidateProgramPipelineEXT(pipeline: GLuint) {.importc.}
  proc glScalexOES(x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glReplacementCodeuiColor3fVertex3fvSUN(rc: ptr GLuint, c: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glProgramNamedParameter4dNV(id: GLuint, len: GLsizei, name: ptr GLubyte, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glMultiDrawElementsIndirectCountARB(mode: GLenum, `type`: GLenum, indirect: GLintptr, drawcount: GLintptr, maxdrawcount: GLsizei, stride: GLsizei) {.importc.}
  proc glReferencePlaneSGIX(equation: ptr GLdouble) {.importc.}
  proc glNormalStream3iATI(stream: GLenum, nx: GLint, ny: GLint, nz: GLint) {.importc.}
  proc glGetColorTableParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetAttribLocation(program: GLuint, name: cstring): GLint {.importc.}
  proc glMultiTexParameterfEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glGenFencesNV(n: GLsizei, fences: ptr GLuint) {.importc.}
  proc glUniform4dv(location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glGetTexLevelParameterfv(target: GLenum, level: GLint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glProgramUniform1ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glProgramUniform1dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glLoadTransposeMatrixdARB(m: ptr GLdouble) {.importc.}
  proc glVertexAttrib2fvARB(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glMultiTexGendEXT(texunit: GLenum, coord: GLenum, pname: GLenum, param: GLdouble) {.importc.}
  proc glProgramUniformMatrix4x3dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glUniform4ui(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint) {.importc.}
  proc glTexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glVertexAttrib3hNV(index: GLuint, x: GLhalfNv, y: GLhalfNv, z: GLhalfNv) {.importc.}
  proc glRotatexOES(angle: GLfixed, x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glGenTextures(n: GLsizei, textures: ptr GLuint) {.importc.}
  proc glCheckFramebufferStatusOES(target: GLenum): GLenum {.importc.}
  proc glGetVideoCaptureStreamdvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glCompressedTextureSubImage1DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glCurrentPaletteMatrixOES(matrixpaletteindex: GLuint) {.importc.}
  proc glCompressedMultiTexSubImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glNormal3d(nx: GLdouble, ny: GLdouble, nz: GLdouble) {.importc.}
  proc glMultiTexCoord1fv(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glProgramUniform2uiEXT(program: GLuint, location: GLint, v0: GLuint, v1: GLuint) {.importc.}
  proc glMultiTexCoord3fARB(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat) {.importc.}
  proc glRasterPos3xOES(x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glEGLImageTargetRenderbufferStorageOES(target: GLenum, image: GLeglImageOes) {.importc.}
  proc glGetAttribLocationARB(programObj: GLhandleArb, name: cstring): GLint {.importc.}
  proc glProgramNamedParameter4dvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, v: ptr GLdouble) {.importc.}
  proc glProgramLocalParameterI4uiNV(target: GLenum, index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint) {.importc.}
  proc glNamedFramebufferTextureFaceEXT(framebuffer: GLuint, attachment: GLenum, texture: GLuint, level: GLint, face: GLenum) {.importc.}
  proc glIndexf(c: GLfloat) {.importc.}
  proc glExtTexObjectStateOverrideiQCOM(target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glCoverageOperationNV(operation: GLenum) {.importc.}
  proc glColorP4uiv(`type`: GLenum, color: ptr GLuint) {.importc.}
  proc glDeleteSync(sync: GLsync) {.importc.}
  proc glGetHistogramParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexCoord4fColor4fNormal3fVertex4fSUN(s: GLfloat, t: GLfloat, p: GLfloat, q: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glEndPerfMonitorAMD(monitor: GLuint) {.importc.}
  proc glGetInternalformati64v(target: GLenum, internalformat: GLenum, pname: GLenum, bufSize: GLsizei, params: ptr GLint64) {.importc.}
  proc glGenNamesAMD(identifier: GLenum, num: GLuint, names: ptr GLuint) {.importc.}
  proc glDrawElementsInstancedBaseVertexBaseInstance(mode: GLenum, count: GLsizei, `type`: GLenum, indices: ptr pointer, instancecount: GLsizei, basevertex: GLint, baseinstance: GLuint) {.importc.}
  proc glMultiTexCoord4i(target: GLenum, s: GLint, t: GLint, r: GLint, q: GLint) {.importc.}
  proc glVertexAttribL1dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glGetProgramNamedParameterdvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, params: ptr GLdouble) {.importc.}
  proc glSetLocalConstantEXT(id: GLuint, `type`: GLenum, `addr`: pointer) {.importc.}
  proc glProgramBinary(program: GLuint, binaryFormat: GLenum, binary: pointer, length: GLsizei) {.importc.}
  proc glVideoCaptureNV(video_capture_slot: GLuint, sequence_num: ptr GLuint, capture_time: ptr GLuint64Ext): GLenum {.importc.}
  proc glDebugMessageEnableAMD(category: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean) {.importc.}
  proc glVertexAttribI1i(index: GLuint, x: GLint) {.importc.}
  proc glVertexWeighthNV(weight: GLhalfNv) {.importc.}
  proc glTextureParameterIivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glClipPlanefIMG(p: GLenum, eqn: ptr GLfloat) {.importc.}
  proc glGetLightxv(light: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glGetAttachedObjectsARB(containerObj: GLhandleArb, maxCount: GLsizei, count: ptr GLsizei, obj: ptr GLhandleArb) {.importc.}
  proc glVertexAttrib4fv(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glDisableVertexAttribArrayARB(index: GLuint) {.importc.}
  proc glWindowPos3fvARB(v: ptr GLfloat) {.importc.}
  proc glClearDepthdNV(depth: GLdouble) {.importc.}
  proc glMapParameterivNV(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glEndConditionalRenderNVX() {.importc.}
  proc glGetFragmentLightivSGIX(light: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramUniformMatrix4fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glVertexStream1iATI(stream: GLenum, x: GLint) {.importc.}
  proc glColorP3ui(`type`: GLenum, color: GLuint) {.importc.}
  proc glGetLightxOES(light: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glGetLightiv(light: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexStream3dATI(stream: GLenum, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glProgramUniform1iEXT(program: GLuint, location: GLint, v0: GLint) {.importc.}
  proc glSecondaryColorFormatNV(size: GLint, `type`: GLenum, stride: GLsizei) {.importc.}
  proc glDrawElementsBaseVertex(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, basevertex: GLint) {.importc.}
  proc glGenFencesAPPLE(n: GLsizei, fences: ptr GLuint) {.importc.}
  proc glBinormal3svEXT(v: ptr GLshort) {.importc.}
  proc glUseProgramStagesEXT(pipeline: GLuint, stages: GLbitfield, program: GLuint) {.importc.}
  proc glDebugMessageCallbackKHR(callback: GLdebugProcKhr, userParam: ptr pointer) {.importc.}
  proc glCopyMultiTexSubImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glColor4hvNV(v: ptr GLhalfNv) {.importc.}
  proc glFenceSync(condition: GLenum, flags: GLbitfield): GLsync {.importc.}
  proc glTexCoordPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint) {.importc.}
  proc glPopName() {.importc.}
  proc glColor3fVertex3fvSUN(c: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glGetUniformfv(program: GLuint, location: GLint, params: ptr GLfloat) {.importc.}
  proc glMultiTexCoord2hNV(target: GLenum, s: GLhalfNv, t: GLhalfNv) {.importc.}
  proc glLightxv(light: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glVideoCaptureStreamParameterivNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glEvalCoord1xvOES(coords: ptr GLfixed) {.importc.}
  proc glGetProgramEnvParameterIivNV(target: GLenum, index: GLuint, params: ptr GLint) {.importc.}
  proc glObjectPurgeableAPPLE(objectType: GLenum, name: GLuint, option: GLenum): GLenum {.importc.}
  proc glRequestResidentProgramsNV(n: GLsizei, programs: ptr GLuint) {.importc.}
  proc glIsImageHandleResidentNV(handle: GLuint64): GLboolean {.importc.}
  proc glColor3hvNV(v: ptr GLhalfNv) {.importc.}
  proc glMultiTexCoord2dARB(target: GLenum, s: GLdouble, t: GLdouble) {.importc.}
  proc glDeletePathsNV(path: GLuint, range: GLsizei) {.importc.}
  proc glVertexAttrib4Nsv(index: GLuint, v: ptr GLshort) {.importc.}
  proc glTexEnvf(target: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glGlobalAlphaFactoriSUN(factor: GLint) {.importc.}
  proc glBlendColorEXT(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {.importc.}
  proc glSecondaryColor3usvEXT(v: ptr GLushort) {.importc.}
  proc glProgramEnvParameterI4uiNV(target: GLenum, index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint) {.importc.}
  proc glTexImage4DSGIS(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, size4d: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glMatrixPushEXT(mode: GLenum) {.importc.}
  proc glGetPixelTexGenParameterivSGIS(pname: GLenum, params: ptr GLint) {.importc.}
  proc glVariantuivEXT(id: GLuint, `addr`: ptr GLuint) {.importc.}
  proc glTexParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetSubroutineUniformLocation(program: GLuint, shadertype: GLenum, name: cstring): GLint {.importc.}
  proc glProgramUniformMatrix3fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glDrawBuffersATI(n: GLsizei, bufs: ptr GLenum) {.importc.}
  proc glGetVertexAttribivNV(index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMultiTexCoord4bvOES(texture: GLenum, coords: ptr GLbyte) {.importc.}
  proc glCompressedTexSubImage1DARB(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.importc.}
  proc glClientActiveTexture(texture: GLenum) {.importc.}
  proc glVertexAttrib2fARB(index: GLuint, x: GLfloat, y: GLfloat) {.importc.}
  proc glProgramUniform2fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetBufferParameterui64vNV(target: GLenum, pname: GLenum, params: ptr GLuint64Ext) {.importc.}
  proc glVertexStream3dvATI(stream: GLenum, coords: ptr GLdouble) {.importc.}
  proc glReplacementCodeuiNormal3fVertex3fvSUN(rc: ptr GLuint, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glVertexAttrib4svNV(index: GLuint, v: ptr GLshort) {.importc.}
  proc glClearBufferSubData(target: GLenum, internalformat: GLenum, offset: GLintptr, size: GLsizeiptr, format: GLenum, `type`: GLenum, data: ptr pointer) {.importc.}
  proc glVertexStream2sATI(stream: GLenum, x: GLshort, y: GLshort) {.importc.}
  proc glTextureImage2DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGetListParameterfvSGIX(list: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glUniform3uiv(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glIsTexture(texture: GLuint): GLboolean {.importc.}
  proc glObjectUnpurgeableAPPLE(objectType: GLenum, name: GLuint, option: GLenum): GLenum {.importc.}
  proc glGetVertexAttribdv(index: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glGetPointeri_vEXT(pname: GLenum, index: GLuint, params: ptr pointer) {.importc.}
  proc glSampleCoveragex(value: GLclampx, invert: GLboolean) {.importc.}
  proc glColor3f(red: GLfloat, green: GLfloat, blue: GLfloat) {.importc.}
  proc glGetnMapivARB(target: GLenum, query: GLenum, bufSize: GLsizei, v: ptr GLint) {.importc.}
  proc glMakeTextureHandleResidentARB(handle: GLuint64) {.importc.}
  proc glSecondaryColorP3ui(`type`: GLenum, color: GLuint) {.importc.}
  proc glMultiTexCoord4sARB(target: GLenum, s: GLshort, t: GLshort, r: GLshort, q: GLshort) {.importc.}
  proc glUniform3i64NV(location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext) {.importc.}
  proc glVDPAUGetSurfaceivNV(surface: GLvdpauSurfaceNv, pname: GLenum, bufSize: GLsizei, length: ptr GLsizei, values: ptr GLint) {.importc.}
  proc glTexBufferEXT(target: GLenum, internalformat: GLenum, buffer: GLuint) {.importc.}
  proc glVertexAttribI4ubvEXT(index: GLuint, v: ptr GLubyte) {.importc.}
  proc glDeleteFramebuffersOES(n: GLsizei, framebuffers: ptr GLuint) {.importc.}
  proc glColor3fVertex3fSUN(r: GLfloat, g: GLfloat, b: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glCombinerInputNV(stage: GLenum, portion: GLenum, variable: GLenum, input: GLenum, mapping: GLenum, componentUsage: GLenum) {.importc.}
  proc glPolygonOffsetEXT(factor: GLfloat, bias: GLfloat) {.importc.}
  proc glWindowPos4dMESA(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glVertex3f(x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glTexCoord3f(s: GLfloat, t: GLfloat, r: GLfloat) {.importc.}
  proc glMultiTexCoord1fARB(target: GLenum, s: GLfloat) {.importc.}
  proc glVertexAttrib4f(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glGetFragDataLocationEXT(program: GLuint, name: cstring): GLint {.importc.}
  proc glFlushMappedNamedBufferRangeEXT(buffer: GLuint, offset: GLintptr, length: GLsizeiptr) {.importc.}
  proc glVertexAttrib1sARB(index: GLuint, x: GLshort) {.importc.}
  proc glBitmapxOES(width: GLsizei, height: GLsizei, xorig: GLfixed, yorig: GLfixed, xmove: GLfixed, ymove: GLfixed, bitmap: ptr GLubyte) {.importc.}
  proc glEnableVertexArrayAttribEXT(vaobj: GLuint, index: GLuint) {.importc.}
  proc glDeleteRenderbuffers(n: GLsizei, renderbuffers: ptr GLuint) {.importc.}
  proc glFramebufferRenderbuffer(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) {.importc.}
  proc glInvalidateTexImage(texture: GLuint, level: GLint) {.importc.}
  proc glProgramUniform2i64NV(program: GLuint, location: GLint, x: GLint64Ext, y: GLint64Ext) {.importc.}
  proc glTextureImage3DMultisampleNV(texture: GLuint, target: GLenum, samples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedSampleLocations: GLboolean) {.importc.}
  proc glValidateProgram(program: GLuint) {.importc.}
  proc glUniform1dv(location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glNormalStream3dvATI(stream: GLenum, coords: ptr GLdouble) {.importc.}
  proc glMultiDrawElementsIndirect(mode: GLenum, `type`: GLenum, indirect: ptr pointer, drawcount: GLsizei, stride: GLsizei) {.importc.}
  proc glVertexBlendARB(count: GLint) {.importc.}
  proc glIsSampler(sampler: GLuint): GLboolean {.importc.}
  proc glVariantdvEXT(id: GLuint, `addr`: ptr GLdouble) {.importc.}
  proc glProgramUniformMatrix3x2fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glVertexStream4fvATI(stream: GLenum, coords: ptr GLfloat) {.importc.}
  proc glOrthoxOES(l: GLfixed, r: GLfixed, b: GLfixed, t: GLfixed, n: GLfixed, f: GLfixed) {.importc.}
  proc glColorFormatNV(size: GLint, `type`: GLenum, stride: GLsizei) {.importc.}
  proc glFogCoordPointer(`type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glVertexAttrib3dvARB(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glVertex3bOES(x: GLbyte, y: GLbyte) {.importc.}
  proc glVertexAttribFormat(attribindex: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, relativeoffset: GLuint) {.importc.}
  proc glTexCoord4fVertex4fSUN(s: GLfloat, t: GLfloat, p: GLfloat, q: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glEnableDriverControlQCOM(driverControl: GLuint) {.importc.}
  proc glPointParameteri(pname: GLenum, param: GLint) {.importc.}
  proc glVertexAttribI2i(index: GLuint, x: GLint, y: GLint) {.importc.}
  proc glGetDriverControlStringQCOM(driverControl: GLuint, bufSize: GLsizei, length: ptr GLsizei, driverControlString: cstring) {.importc.}
  proc glGetTexLevelParameteriv(target: GLenum, level: GLint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetHandleARB(pname: GLenum): GLhandleArb {.importc.}
  proc glIndexubv(c: ptr GLubyte) {.importc.}
  proc glBlendFunciARB(buf: GLuint, src: GLenum, dst: GLenum) {.importc.}
  proc glColor4usv(v: ptr GLushort) {.importc.}
  proc glBlendEquationSeparateOES(modeRgb: GLenum, modeAlpha: GLenum) {.importc.}
  proc glVertexAttribI4ui(index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint) {.importc.}
  proc glProgramUniform3f(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) {.importc.}
  proc glVertexAttribL3i64vNV(index: GLuint, v: ptr GLint64Ext) {.importc.}
  proc glWeightdvARB(size: GLint, weights: ptr GLdouble) {.importc.}
  proc glVertexArrayRangeAPPLE(length: GLsizei, `pointer`: pointer) {.importc.}
  proc glMapGrid2d(un: GLint, u1: GLdouble, u2: GLdouble, vn: GLint, v1: GLdouble, v2: GLdouble) {.importc.}
  proc glFogiv(pname: GLenum, params: ptr GLint) {.importc.}
  proc glUniform2f(location: GLint, v0: GLfloat, v1: GLfloat) {.importc.}
  proc glGetDoublei_v(target: GLenum, index: GLuint, data: ptr GLdouble) {.importc.}
  proc glGetVertexAttribfv(index: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexAttribI2ivEXT(index: GLuint, v: ptr GLint) {.importc.}
  proc glIsProgramNV(id: GLuint): GLboolean {.importc.}
  proc glTexCoord1hNV(s: GLhalfNv) {.importc.}
  proc glMinSampleShadingARB(value: GLfloat) {.importc.}
  proc glMultiDrawElements(mode: GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, drawcount: GLsizei) {.importc.}
  proc glGetQueryObjectuiv(id: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glReadBuffer(mode: GLenum) {.importc.}
  proc glMultiTexCoordP3uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glUniformMatrix3x2fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glBindRenderbuffer(target: GLenum, renderbuffer: GLuint) {.importc.}
  proc glBinormal3sEXT(bx: GLshort, by: GLshort, bz: GLshort) {.importc.}
  proc glUniform4iARB(location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) {.importc.}
  proc glGetUniformOffsetEXT(program: GLuint, location: GLint): GLintptr {.importc.}
  proc glDeleteLists(list: GLuint, range: GLsizei) {.importc.}
  proc glVertexAttribI1iEXT(index: GLuint, x: GLint) {.importc.}
  proc glFramebufferTexture1D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glVertexAttribI2uiv(index: GLuint, v: ptr GLuint) {.importc.}
  proc glBindFragDataLocation(program: GLuint, color: GLuint, name: cstring) {.importc.}
  proc glClearStencil(s: GLint) {.importc.}
  proc glVertexAttrib4Nubv(index: GLuint, v: ptr GLubyte) {.importc.}
  proc glConvolutionFilter2DEXT(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, image: pointer) {.importc.}
  proc glGenFramebuffersEXT(n: GLsizei, framebuffers: ptr GLuint) {.importc.}
  proc glFogCoordfvEXT(coord: ptr GLfloat) {.importc.}
  proc glGetRenderbufferParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttribs1fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat) {.importc.}
  proc glTexCoord2fColor3fVertex3fSUN(s: GLfloat, t: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glRasterPos3i(x: GLint, y: GLint, z: GLint) {.importc.}
  proc glMultiTexSubImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glConvolutionParameteriEXT(target: GLenum, pname: GLenum, params: GLint) {.importc.}
  proc glVertexAttribI4iEXT(index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glVertexAttribL2i64vNV(index: GLuint, v: ptr GLint64Ext) {.importc.}
  proc glBlendColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {.importc.}
  proc glGetPathColorGenivNV(color: GLenum, pname: GLenum, value: ptr GLint) {.importc.}
  proc glCompressedTextureImage1DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glDrawElementsInstanced(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, instancecount: GLsizei) {.importc.}
  proc glFogCoordd(coord: GLdouble) {.importc.}
  proc glTexParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glWindowPos3svARB(v: ptr GLshort) {.importc.}
  proc glGetVertexArrayPointervEXT(vaobj: GLuint, pname: GLenum, param: ptr pointer) {.importc.}
  proc glDrawTextureNV(texture: GLuint, sampler: GLuint, x0: GLfloat, y0: GLfloat, x1: GLfloat, y1: GLfloat, z: GLfloat, s0: GLfloat, t0: GLfloat, s1: GLfloat, t1: GLfloat) {.importc.}
  proc glUniformMatrix2dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glTexImage3DOES(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glClampColorARB(target: GLenum, clamp: GLenum) {.importc.}
  proc glTexParameteri(target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glWindowPos4svMESA(v: ptr GLshort) {.importc.}
  proc glMultiTexCoordP4ui(texture: GLenum, `type`: GLenum, coords: GLuint) {.importc.}
  proc glVertexP4uiv(`type`: GLenum, value: ptr GLuint) {.importc.}
  proc glProgramUniform4iEXT(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) {.importc.}
  proc glTexCoord3xvOES(coords: ptr GLfixed) {.importc.}
  proc glCopyTexImage2DEXT(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint) {.importc.}
  proc glGenSamplers(count: GLsizei, samplers: ptr GLuint) {.importc.}
  proc glRasterPos4iv(v: ptr GLint) {.importc.}
  proc glWindowPos4sMESA(x: GLshort, y: GLshort, z: GLshort, w: GLshort) {.importc.}
  proc glProgramUniform2dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glPrioritizeTexturesEXT(n: GLsizei, textures: ptr GLuint, priorities: ptr GLclampf) {.importc.}
  proc glRects(x1: GLshort, y1: GLshort, x2: GLshort, y2: GLshort) {.importc.}
  proc glMultiDrawElementsBaseVertex(mode: GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, drawcount: GLsizei, basevertex: ptr GLint) {.importc.}
  proc glProgramBinaryOES(program: GLuint, binaryFormat: GLenum, binary: pointer, length: GLint) {.importc.}
  proc glReplacementCodeuiTexCoord2fColor4fNormal3fVertex3fvSUN(rc: ptr GLuint, tc: ptr GLfloat, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glGetMinmaxParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glColor4fNormal3fVertex3fSUN(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glWindowPos2d(x: GLdouble, y: GLdouble) {.importc.}
  proc glGetPerfMonitorGroupStringAMD(group: GLuint, bufSize: GLsizei, length: ptr GLsizei, groupString: cstring) {.importc.}
  proc glUniformHandleui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64) {.importc.}
  proc glBlendEquation(mode: GLenum) {.importc.}
  proc glMapBufferARB(target: GLenum, access: GLenum) {.importc.}
  proc glGetMaterialxvOES(face: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glVertexAttribI1ivEXT(index: GLuint, v: ptr GLint) {.importc.}
  proc glTexCoord4hvNV(v: ptr GLhalfNv) {.importc.}
  proc glVertexArrayVertexAttribLOffsetEXT(vaobj: GLuint, buffer: GLuint, index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glExtGetShadersQCOM(shaders: ptr GLuint, maxShaders: GLint, numShaders: ptr GLint) {.importc.}
  proc glWindowPos4ivMESA(v: ptr GLint) {.importc.}
  proc glVertexAttrib1sNV(index: GLuint, x: GLshort) {.importc.}
  proc glNormalStream3ivATI(stream: GLenum, coords: ptr GLint) {.importc.}
  proc glSecondaryColor3fEXT(red: GLfloat, green: GLfloat, blue: GLfloat) {.importc.}
  proc glVertexArrayFogCoordOffsetEXT(vaobj: GLuint, buffer: GLuint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glGetTextureImageEXT(texture: GLuint, target: GLenum, level: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glVertexAttrib4hNV(index: GLuint, x: GLhalfNv, y: GLhalfNv, z: GLhalfNv, w: GLhalfNv) {.importc.}
  proc glReplacementCodeusSUN(code: GLushort) {.importc.}
  proc glPixelTexGenSGIX(mode: GLenum) {.importc.}
  proc glMultiDrawRangeElementArrayAPPLE(mode: GLenum, start: GLuint, `end`: GLuint, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei) {.importc.}
  proc glDrawElements(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer) {.importc.}
  proc glTexCoord1hvNV(v: ptr GLhalfNv) {.importc.}
  proc glGetPixelMapuiv(map: GLenum, values: ptr GLuint) {.importc.}
  proc glRasterPos4d(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glTexImage1D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glConvolutionParameterxOES(target: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glSecondaryColor3dEXT(red: GLdouble, green: GLdouble, blue: GLdouble) {.importc.}
  proc glGetCombinerOutputParameterivNV(stage: GLenum, portion: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glQueryCounter(id: GLuint, target: GLenum) {.importc.}
  proc glGetUniformi64vNV(program: GLuint, location: GLint, params: ptr GLint64Ext) {.importc.}
  proc glTexCoord2fv(v: ptr GLfloat) {.importc.}
  proc glWindowPos3d(x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glBlendFuncSeparateINGR(sfactorRgb: GLenum, dfactorRgb: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum) {.importc.}
  proc glTextureNormalEXT(mode: GLenum) {.importc.}
  proc glVertexStream2fATI(stream: GLenum, x: GLfloat, y: GLfloat) {.importc.}
  proc glViewportIndexedf(index: GLuint, x: GLfloat, y: GLfloat, w: GLfloat, h: GLfloat) {.importc.}
  proc glMultiTexCoord4ivARB(target: GLenum, v: ptr GLint) {.importc.}
  proc glBindBufferOffsetEXT(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr) {.importc.}
  proc glTexCoord3sv(v: ptr GLshort) {.importc.}
  proc glVertexArrayVertexAttribBindingEXT(vaobj: GLuint, attribindex: GLuint, bindingindex: GLuint) {.importc.}
  proc glVertexAttrib2f(index: GLuint, x: GLfloat, y: GLfloat) {.importc.}
  proc glMultiTexGenivEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glUniformui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glGetInfoLogARB(obj: GLhandleArb, maxLength: GLsizei, length: ptr GLsizei, infoLog: cstring) {.importc.}
  proc glGetNamedProgramLocalParameterIivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLint) {.importc.}
  proc glVertexAttrib4s(index: GLuint, x: GLshort, y: GLshort, z: GLshort, w: GLshort) {.importc.}
  proc glUniformMatrix4x2dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glVertexAttribs3dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble) {.importc.}
  proc glSecondaryColor3dvEXT(v: ptr GLdouble) {.importc.}
  proc glTextureRenderbufferEXT(texture: GLuint, target: GLenum, renderbuffer: GLuint) {.importc.}
  proc glVertexAttribL2ui64vNV(index: GLuint, v: ptr GLuint64Ext) {.importc.}
  proc glBlendFuncSeparateOES(srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum) {.importc.}
  proc glVertexAttribDivisorARB(index: GLuint, divisor: GLuint) {.importc.}
  proc glWindowPos2sv(v: ptr GLshort) {.importc.}
  proc glMultiTexCoord3svARB(target: GLenum, v: ptr GLshort) {.importc.}
  proc glCombinerParameterfvNV(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetImageTransformParameterfvHP(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetArrayObjectivATI(`array`: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetTexParameterIuiv(target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glGetProgramPipelineInfoLog(pipeline: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring) {.importc.}
  proc glGetOcclusionQueryuivNV(id: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glVertexAttrib4bvARB(index: GLuint, v: ptr GLbyte) {.importc.}
  proc glListParameterfvSGIX(list: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glDeleteSamplers(count: GLsizei, samplers: ptr GLuint) {.importc.}
  proc glNormalStream3dATI(stream: GLenum, nx: GLdouble, ny: GLdouble, nz: GLdouble) {.importc.}
  proc glProgramUniform4i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glBlendFuncSeparateiARB(buf: GLuint, srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum) {.importc.}
  proc glEndTransformFeedbackEXT() {.importc.}
  proc glMultiTexCoord3i(target: GLenum, s: GLint, t: GLint, r: GLint) {.importc.}
  proc glMakeBufferResidentNV(target: GLenum, access: GLenum) {.importc.}
  proc glTangent3dvEXT(v: ptr GLdouble) {.importc.}
  proc glMatrixPopEXT(mode: GLenum) {.importc.}
  proc glVertexAttrib4NivARB(index: GLuint, v: ptr GLint) {.importc.}
  proc glProgramUniform2ui64NV(program: GLuint, location: GLint, x: GLuint64Ext, y: GLuint64Ext) {.importc.}
  proc glWeightPointerARB(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glCullParameterdvEXT(pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glFramebufferTexture2D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glGenVertexArrays(n: GLsizei, arrays: ptr GLuint) {.importc.}
  proc glUniformHandleui64NV(location: GLint, value: GLuint64) {.importc.}
  proc glIndexPointer(`type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glGetProgramSubroutineParameteruivNV(target: GLenum, index: GLuint, param: ptr GLuint) {.importc.}
  proc glVertexAttrib1svARB(index: GLuint, v: ptr GLshort) {.importc.}
  proc glDetachObjectARB(containerObj: GLhandleArb, attachedObj: GLhandleArb) {.importc.}
  proc glCompressedTexImage3D(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.importc.}
  proc glBlendFuncSeparate(sfactorRgb: GLenum, dfactorRgb: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum) {.importc.}
  proc glExecuteProgramNV(target: GLenum, id: GLuint, params: ptr GLfloat) {.importc.}
  proc glAttachObjectARB(containerObj: GLhandleArb, obj: GLhandleArb) {.importc.}
  proc glCompressedTexSubImage1D(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.importc.}
  proc glProgramUniform4iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glVertexAttrib3sv(index: GLuint, v: ptr GLshort) {.importc.}
  proc glTexCoord3bvOES(coords: ptr GLbyte) {.importc.}
  proc glGenTexturesEXT(n: GLsizei, textures: ptr GLuint) {.importc.}
  proc glColor4f(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {.importc.}
  proc glGetFramebufferAttachmentParameterivOES(target: GLenum, attachment: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glClearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat) {.importc.}
  proc glNamedProgramLocalParametersI4ivEXT(program: GLuint, target: GLenum, index: GLuint, count: GLsizei, params: ptr GLint) {.importc.}
  proc glMakeImageHandleNonResidentARB(handle: GLuint64) {.importc.}
  proc glGenRenderbuffers(n: GLsizei, renderbuffers: ptr GLuint) {.importc.}
  proc glVertexAttribL1ui64vARB(index: GLuint, v: ptr GLuint64Ext) {.importc.}
  proc glBindFramebufferEXT(target: GLenum, framebuffer: GLuint) {.importc.}
  proc glProgramUniform2dEXT(program: GLuint, location: GLint, x: GLdouble, y: GLdouble) {.importc.}
  proc glCompressedMultiTexImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glDeleteSyncAPPLE(sync: GLsync) {.importc.}
  proc glDebugMessageInsertAMD(category: GLenum, severity: GLenum, id: GLuint, length: GLsizei, buf: cstring) {.importc.}
  proc glSecondaryColorPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glTextureImage2DMultisampleNV(texture: GLuint, target: GLenum, samples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, fixedSampleLocations: GLboolean) {.importc.}
  proc glBeginFragmentShaderATI() {.importc.}
  proc glClearDepth(depth: GLdouble) {.importc.}
  proc glBindTextures(first: GLuint, count: GLsizei, textures: ptr GLuint) {.importc.}
  proc glEvalCoord1d(u: GLdouble) {.importc.}
  proc glSecondaryColor3b(red: GLbyte, green: GLbyte, blue: GLbyte) {.importc.}
  proc glExtGetTexSubImageQCOM(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, texels: pointer) {.importc.}
  proc glClearColorIiEXT(red: GLint, green: GLint, blue: GLint, alpha: GLint) {.importc.}
  proc glVertex2xOES(x: GLfixed) {.importc.}
  proc glVertexAttrib2s(index: GLuint, x: GLshort, y: GLshort) {.importc.}
  proc glUniformHandleui64vARB(location: GLint, count: GLsizei, value: ptr GLuint64) {.importc.}
  proc glAreTexturesResidentEXT(n: GLsizei, textures: ptr GLuint, residences: ptr GLboolean): GLboolean {.importc.}
  proc glDrawElementsInstancedBaseInstance(mode: GLenum, count: GLsizei, `type`: GLenum, indices: ptr pointer, instancecount: GLsizei, baseinstance: GLuint) {.importc.}
  proc glGetString(name: GLenum): ptr GLubyte {.importc.}
  proc glDrawTransformFeedbackStream(mode: GLenum, id: GLuint, stream: GLuint) {.importc.}
  proc glSecondaryColor3uiv(v: ptr GLuint) {.importc.}
  proc glNamedFramebufferParameteriEXT(framebuffer: GLuint, pname: GLenum, param: GLint) {.importc.}
  proc glVertexAttrib4hvNV(index: GLuint, v: ptr GLhalfNv) {.importc.}
  proc glGetnUniformuivARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLuint) {.importc.}
  proc glProgramUniform4ui(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint) {.importc.}
  proc glPointParameterxvOES(pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glIsEnabledi(target: GLenum, index: GLuint): GLboolean {.importc.}
  proc glColorPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer) {.importc.}
  proc glFragmentLightModelfvSGIX(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glRasterPos3f(x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glDeleteObjectARB(obj: GLhandleArb) {.importc.}
  proc glSetFenceNV(fence: GLuint, condition: GLenum) {.importc.}
  proc glTransformFeedbackAttribsNV(count: GLuint, attribs: ptr GLint, bufferMode: GLenum) {.importc.}
  proc glProgramUniformMatrix2fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glGetPointerv(pname: GLenum, params: ptr pointer) {.importc.}
  proc glWindowPos2dvMESA(v: ptr GLdouble) {.importc.}
  proc glTexImage2DMultisample(target: GLenum, samples: GLsizei, internalformat: GLint, width: GLsizei, height: GLsizei, fixedsamplelocations: GLboolean) {.importc.}
  proc glGenFragmentShadersATI(range: GLuint): GLuint {.importc.}
  proc glTexCoord4fv(v: ptr GLfloat) {.importc.}
  proc glCompressedTexImage1D(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.importc.}
  proc glGetNamedBufferSubDataEXT(buffer: GLuint, offset: GLintptr, size: GLsizeiptr, data: pointer) {.importc.}
  proc glFinish() {.importc.}
  proc glDeleteVertexShaderEXT(id: GLuint) {.importc.}
  proc glFinishObjectAPPLE(`object`: GLenum, name: GLint) {.importc.}
  proc glGetActiveAttribARB(programObj: GLhandleArb, index: GLuint, maxLength: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring) {.importc.}
  proc glPointParameterx(pname: GLenum, param: GLfixed) {.importc.}
  proc glProgramUniformui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glSecondaryColor3ubv(v: ptr GLubyte) {.importc.}
  proc glGetProgramLocalParameterIivNV(target: GLenum, index: GLuint, params: ptr GLint) {.importc.}
  proc glDeleteProgramPipelinesEXT(n: GLsizei, pipelines: ptr GLuint) {.importc.}
  proc glVertexAttrib4fNV(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glGetColorTableParameterfvSGI(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetFloati_v(target: GLenum, index: GLuint, data: ptr GLfloat) {.importc.}
  proc glGenBuffers(n: GLsizei, buffers: ptr GLuint) {.importc.}
  proc glNormal3b(nx: GLbyte, ny: GLbyte, nz: GLbyte) {.importc.}
  proc glDrawArraysInstancedARB(mode: GLenum, first: GLint, count: GLsizei, primcount: GLsizei) {.importc.}
  proc glTexStorage2DMultisample(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, fixedsamplelocations: GLboolean) {.importc.}
  proc glGetVariantIntegervEXT(id: GLuint, value: GLenum, data: ptr GLint) {.importc.}
  proc glColor3ubv(v: ptr GLubyte) {.importc.}
  proc glVertexAttribP4uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint) {.importc.}
  proc glProgramUniform2ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glVertexStream4dATI(stream: GLenum, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glVertexAttribL2ui64NV(index: GLuint, x: GLuint64Ext, y: GLuint64Ext) {.importc.}
  proc glSecondaryColor3bEXT(red: GLbyte, green: GLbyte, blue: GLbyte) {.importc.}
  proc glGetBufferPointervOES(target: GLenum, pname: GLenum, params: ptr pointer) {.importc.}
  proc glGetMaterialfv(face: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexStream3sATI(stream: GLenum, x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glUniform1i(location: GLint, v0: GLint) {.importc.}
  proc glVertexAttribL2d(index: GLuint, x: GLdouble, y: GLdouble) {.importc.}
  proc glTestObjectAPPLE(`object`: GLenum, name: GLuint): GLboolean {.importc.}
  proc glGetTransformFeedbackVarying(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLsizei, `type`: ptr GLenum, name: cstring) {.importc.}
  proc glFramebufferRenderbufferOES(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) {.importc.}
  proc glVertexStream3iATI(stream: GLenum, x: GLint, y: GLint, z: GLint) {.importc.}
  proc glMakeTextureHandleNonResidentNV(handle: GLuint64) {.importc.}
  proc glVertexAttrib4fvNV(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glArrayElement(i: GLint) {.importc.}
  proc glClearBufferData(target: GLenum, internalformat: GLenum, format: GLenum, `type`: GLenum, data: ptr pointer) {.importc.}
  proc glSecondaryColor3usEXT(red: GLushort, green: GLushort, blue: GLushort) {.importc.}
  proc glRenderbufferStorageMultisample(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glTexCoord2xvOES(coords: ptr GLfixed) {.importc.}
  proc glWindowPos3f(x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glTangent3svEXT(v: ptr GLshort) {.importc.}
  proc glPointParameterf(pname: GLenum, param: GLfloat) {.importc.}
  proc glVertexAttribI4uivEXT(index: GLuint, v: ptr GLuint) {.importc.}
  proc glColorTableParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMatrixMultdEXT(mode: GLenum, m: ptr GLdouble) {.importc.}
  proc glUseProgramStages(pipeline: GLuint, stages: GLbitfield, program: GLuint) {.importc.}
  proc glVertexStream4sATI(stream: GLenum, x: GLshort, y: GLshort, z: GLshort, w: GLshort) {.importc.}
  proc glDrawElementsInstancedNV(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, primcount: GLsizei) {.importc.}
  proc glUniform3d(location: GLint, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glDebugMessageControlARB(source: GLenum, `type`: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean) {.importc.}
  proc glVertexAttribs3svNV(index: GLuint, count: GLsizei, v: ptr GLshort) {.importc.}
  proc glElementPointerATI(`type`: GLenum, `pointer`: pointer) {.importc.}
  proc glColor4fNormal3fVertex3fvSUN(c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glGetPerfMonitorCountersAMD(group: GLuint, numCounters: ptr GLint, maxActiveCounters: ptr GLint, counterSize: GLsizei, counters: ptr GLuint) {.importc.}
  proc glDispatchCompute(num_groups_x: GLuint, num_groups_y: GLuint, num_groups_z: GLuint) {.importc.}
  proc glVertexAttribDivisorNV(index: GLuint, divisor: GLuint) {.importc.}
  proc glProgramUniform3uiEXT(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint) {.importc.}
  proc glRenderbufferStorageMultisampleNV(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glBinormalPointerEXT(`type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glRectxvOES(v1: ptr GLfixed, v2: ptr GLfixed) {.importc.}
  proc glGenVertexArraysOES(n: GLsizei, arrays: ptr GLuint) {.importc.}
  proc glDebugMessageControlKHR(source: GLenum, `type`: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean) {.importc.}
  proc glProgramUniform1uiEXT(program: GLuint, location: GLint, v0: GLuint) {.importc.}
  proc glPixelTransferi(pname: GLenum, param: GLint) {.importc.}
  proc glIsPointInFillPathNV(path: GLuint, mask: GLuint, x: GLfloat, y: GLfloat): GLboolean {.importc.}
  proc glVertexBindingDivisor(bindingindex: GLuint, divisor: GLuint) {.importc.}
  proc glGetVertexAttribLui64vARB(index: GLuint, pname: GLenum, params: ptr GLuint64Ext) {.importc.}
  proc glProgramUniformMatrix3dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glDrawBuffer(mode: GLenum) {.importc.}
  proc glMultiTexCoord1sARB(target: GLenum, s: GLshort) {.importc.}
  proc glSeparableFilter2DEXT(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, row: pointer, column: pointer) {.importc.}
  proc glTangent3bvEXT(v: ptr GLbyte) {.importc.}
  proc glTexParameterIuiv(target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glVertexAttribL4i64NV(index: GLuint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext, w: GLint64Ext) {.importc.}
  proc glDebugMessageCallbackARB(callback: GLdebugProcArb, userParam: ptr pointer) {.importc.}
  proc glMultiTexCoordP1uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glLabelObjectEXT(`type`: GLenum, `object`: GLuint, length: GLsizei, label: cstring) {.importc.}
  proc glGetnPolygonStippleARB(bufSize: GLsizei, pattern: ptr GLubyte) {.importc.}
  proc glTexCoord3xOES(s: GLfixed, t: GLfixed, r: GLfixed) {.importc.}
  proc glCopyPixels(x: GLint, y: GLint, width: GLsizei, height: GLsizei, `type`: GLenum) {.importc.}
  proc glGetnUniformfvEXT(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLfloat) {.importc.}
  proc glColorMaski(index: GLuint, r: GLboolean, g: GLboolean, b: GLboolean, a: GLboolean) {.importc.}
  proc glRasterPos2fv(v: ptr GLfloat) {.importc.}
  proc glBindBuffersBase(target: GLenum, first: GLuint, count: GLsizei, buffers: ptr GLuint) {.importc.}
  proc glSpriteParameterfvSGIX(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetSyncivAPPLE(sync: GLsync, pname: GLenum, bufSize: GLsizei, length: ptr GLsizei, values: ptr GLint) {.importc.}
  proc glVertexAttribI3i(index: GLuint, x: GLint, y: GLint, z: GLint) {.importc.}
  proc glPixelTransformParameteriEXT(target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glMultiDrawArraysEXT(mode: GLenum, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei) {.importc.}
  proc glGetTextureHandleNV(texture: GLuint): GLuint64 {.importc.}
  proc glTexCoordP2ui(`type`: GLenum, coords: GLuint) {.importc.}
  proc glDeleteQueries(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glGetVertexAttribArrayObjectivATI(index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexArrayVertexBindingDivisorEXT(vaobj: GLuint, bindingindex: GLuint, divisor: GLuint) {.importc.}
  proc glVertex3i(x: GLint, y: GLint, z: GLint) {.importc.}
  proc glBlendEquationSeparatei(buf: GLuint, modeRgb: GLenum, modeAlpha: GLenum) {.importc.}
  proc glGetMapAttribParameterivNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetVideoCaptureivNV(video_capture_slot: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glFragmentMaterialfvSGIX(face: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glEGLImageTargetTexture2DOES(target: GLenum, image: GLeglImageOes) {.importc.}
  proc glCopyImageSubDataNV(srcName: GLuint, srcTarget: GLenum, srcLevel: GLint, srcX: GLint, srcY: GLint, srcZ: GLint, dstName: GLuint, dstTarget: GLenum, dstLevel: GLint, dstX: GLint, dstY: GLint, dstZ: GLint, width: GLsizei, height: GLsizei, depth: GLsizei) {.importc.}
  proc glUniform2i(location: GLint, v0: GLint, v1: GLint) {.importc.}
  proc glVertexAttrib3fvNV(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glNamedBufferStorageEXT(buffer: GLuint, size: GLsizeiptr, data: ptr pointer, flags: GLbitfield) {.importc.}
  proc glProgramEnvParameterI4uivNV(target: GLenum, index: GLuint, params: ptr GLuint) {.importc.}
  proc glGetVertexAttribdvARB(index: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glVertexAttribL3ui64vNV(index: GLuint, v: ptr GLuint64Ext) {.importc.}
  proc glUniform4fvARB(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glWeightsvARB(size: GLint, weights: ptr GLshort) {.importc.}
  proc glMakeTextureHandleNonResidentARB(handle: GLuint64) {.importc.}
  proc glEvalCoord1xOES(u: GLfixed) {.importc.}
  proc glVertexAttrib2sv(index: GLuint, v: ptr GLshort) {.importc.}
  proc glVertexAttrib4dvNV(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glProgramNamedParameter4fNV(id: GLuint, len: GLsizei, name: ptr GLubyte, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glCompileShaderARB(shaderObj: GLhandleArb) {.importc.}
  proc glProgramEnvParameter4fvARB(target: GLenum, index: GLuint, params: ptr GLfloat) {.importc.}
  proc glGetVertexAttribiv(index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glEvalPoint1(i: GLint) {.importc.}
  proc glEvalMapsNV(target: GLenum, mode: GLenum) {.importc.}
  proc glGetTexGenxvOES(coord: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glBlendEquationSeparate(modeRgb: GLenum, modeAlpha: GLenum) {.importc.}
  proc glGetColorTableParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glQueryCounterEXT(id: GLuint, target: GLenum) {.importc.}
  proc glExtGetProgramBinarySourceQCOM(program: GLuint, shadertype: GLenum, source: cstring, length: ptr GLint) {.importc.}
  proc glGetConvolutionParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glIsProgramPipeline(pipeline: GLuint): GLboolean {.importc.}
  proc glVertexWeightfvEXT(weight: ptr GLfloat) {.importc.}
  proc glDisableDriverControlQCOM(driverControl: GLuint) {.importc.}
  proc glVertexStream1fvATI(stream: GLenum, coords: ptr GLfloat) {.importc.}
  proc glMakeTextureHandleResidentNV(handle: GLuint64) {.importc.}
  proc glSamplerParameteriv(sampler: GLuint, pname: GLenum, param: ptr GLint) {.importc.}
  proc glTexEnvxOES(target: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glEndOcclusionQueryNV() {.importc.}
  proc glFlushMappedBufferRangeAPPLE(target: GLenum, offset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glVertex4iv(v: ptr GLint) {.importc.}
  proc glVertexArrayVertexAttribIFormatEXT(vaobj: GLuint, attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint) {.importc.}
  proc glDisableIndexedEXT(target: GLenum, index: GLuint) {.importc.}
  proc glVertexAttribL1dEXT(index: GLuint, x: GLdouble) {.importc.}
  proc glBeginPerfMonitorAMD(monitor: GLuint) {.importc.}
  proc glConvolutionFilter1DEXT(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, image: pointer) {.importc.}
  proc glPrimitiveRestartIndex(index: GLuint) {.importc.}
  proc glWindowPos2dv(v: ptr GLdouble) {.importc.}
  proc glBindFramebufferOES(target: GLenum, framebuffer: GLuint) {.importc.}
  proc glTessellationModeAMD(mode: GLenum) {.importc.}
  proc glIsVariantEnabledEXT(id: GLuint, cap: GLenum): GLboolean {.importc.}
  proc glColor3iv(v: ptr GLint) {.importc.}
  proc glFogCoordFormatNV(`type`: GLenum, stride: GLsizei) {.importc.}
  proc glClearNamedBufferDataEXT(buffer: GLuint, internalformat: GLenum, format: GLenum, `type`: GLenum, data: ptr pointer) {.importc.}
  proc glTextureRangeAPPLE(target: GLenum, length: GLsizei, `pointer`: pointer) {.importc.}
  proc glTexCoord4bvOES(coords: ptr GLbyte) {.importc.}
  proc glRotated(angle: GLdouble, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glAccum(op: GLenum, value: GLfloat) {.importc.}
  proc glVertex3d(x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glGetPathMetricRangeNV(metricQueryMask: GLbitfield, firstPathName: GLuint, numPaths: GLsizei, stride: GLsizei, metrics: ptr GLfloat) {.importc.}
  proc glUniform4d(location: GLint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glTextureSubImage2DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glMultiTexCoord1iv(target: GLenum, v: ptr GLint) {.importc.}
  proc glFogFuncSGIS(n: GLsizei, points: ptr GLfloat) {.importc.}
  proc glGetMaterialxOES(face: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glGlobalAlphaFactorbSUN(factor: GLbyte) {.importc.}
  proc glGetProgramLocalParameterdvARB(target: GLenum, index: GLuint, params: ptr GLdouble) {.importc.}
  proc glDeleteProgramsARB(n: GLsizei, programs: ptr GLuint) {.importc.}
  proc glVertexStream1sATI(stream: GLenum, x: GLshort) {.importc.}
  proc glMatrixTranslatedEXT(mode: GLenum, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glTexSubImage1D(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGetBufferSubData(target: GLenum, offset: GLintptr, size: GLsizeiptr, data: pointer) {.importc.}
  proc glUniform4uiEXT(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint) {.importc.}
  proc glGetShaderiv(shader: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetQueryIndexediv(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glDebugMessageInsert(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum, length: GLsizei, buf: cstring) {.importc.}
  proc glVertexAttribs2dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble) {.importc.}
  proc glGetFixedvOES(pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glUniform2iv(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glTextureView(texture: GLuint, target: GLenum, origtexture: GLuint, internalformat: GLenum, minlevel: GLuint, numlevels: GLuint, minlayer: GLuint, numlayers: GLuint) {.importc.}
  proc glMultiTexCoord1xvOES(texture: GLenum, coords: ptr GLfixed) {.importc.}
  proc glTexBufferRange(target: GLenum, internalformat: GLenum, buffer: GLuint, offset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glMultiTexCoordPointerEXT(texunit: GLenum, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glBlendColorxOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed) {.importc.}
  proc glReadPixels(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glWindowPos3dARB(x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glPixelTexGenParameterivSGIS(pname: GLenum, params: ptr GLint) {.importc.}
  proc glSecondaryColor3svEXT(v: ptr GLshort) {.importc.}
  proc glPopGroupMarkerEXT() {.importc.}
  proc glImportSyncEXT(external_sync_type: GLenum, external_sync: GLintptr, flags: GLbitfield): GLsync {.importc.}
  proc glVertexAttribLFormatNV(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei) {.importc.}
  proc glVertexAttrib2sNV(index: GLuint, x: GLshort, y: GLshort) {.importc.}
  proc glGetIntegeri_v(target: GLenum, index: GLuint, data: ptr GLint) {.importc.}
  proc glProgramUniform3uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glGetActiveUniformBlockiv(program: GLuint, uniformBlockIndex: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glCreateShaderProgramv(`type`: GLenum, count: GLsizei, strings: cstringArray): GLuint {.importc.}
  proc glUniform2fARB(location: GLint, v0: GLfloat, v1: GLfloat) {.importc.}
  proc glVertexStream4ivATI(stream: GLenum, coords: ptr GLint) {.importc.}
  proc glNormalP3uiv(`type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glVertexAttribLFormat(attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint) {.importc.}
  proc glTexCoord2bvOES(coords: ptr GLbyte) {.importc.}
  proc glGetActiveUniformName(program: GLuint, uniformIndex: GLuint, bufSize: GLsizei, length: ptr GLsizei, uniformName: cstring) {.importc.}
  proc glTexCoord2sv(v: ptr GLshort) {.importc.}
  proc glVertexAttrib2dNV(index: GLuint, x: GLdouble, y: GLdouble) {.importc.}
  proc glGetFogFuncSGIS(points: ptr GLfloat) {.importc.}
  proc glSetFenceAPPLE(fence: GLuint) {.importc.}
  proc glRasterPos2f(x: GLfloat, y: GLfloat) {.importc.}
  proc glVertexWeightPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glEndList() {.importc.}
  proc glVDPAUFiniNV() {.importc.}
  proc glTbufferMask3DFX(mask: GLuint) {.importc.}
  proc glVertexP4ui(`type`: GLenum, value: GLuint) {.importc.}
  proc glTexEnviv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glColor4xOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed) {.importc.}
  proc glBlendEquationi(buf: GLuint, mode: GLenum) {.importc.}
  proc glLoadMatrixxOES(m: ptr GLfixed) {.importc.}
  proc glFogxOES(pname: GLenum, param: GLfixed) {.importc.}
  proc glTexCoord4dv(v: ptr GLdouble) {.importc.}
  proc glFogCoordPointerListIBM(`type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint) {.importc.}
  proc glGetPerfMonitorGroupsAMD(numGroups: ptr GLint, groupsSize: GLsizei, groups: ptr GLuint) {.importc.}
  proc glVertex2hNV(x: GLhalfNv, y: GLhalfNv) {.importc.}
  proc glDeleteFragmentShaderATI(id: GLuint) {.importc.}
  proc glGetSamplerParameterIiv(sampler: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glUniform2fvARB(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glFogf(pname: GLenum, param: GLfloat) {.importc.}
  proc glMultiTexCoord1iARB(target: GLenum, s: GLint) {.importc.}
  proc glGetActiveUniformARB(programObj: GLhandleArb, index: GLuint, maxLength: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring) {.importc.}
  proc glMapGrid1xOES(n: GLint, u1: GLfixed, u2: GLfixed) {.importc.}
  proc glIndexsv(c: ptr GLshort) {.importc.}
  proc glFragmentMaterialfSGIX(face: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glBindTextureEXT(target: GLenum, texture: GLuint) {.importc.}
  proc glRectiv(v1: ptr GLint, v2: ptr GLint) {.importc.}
  proc glTangent3dEXT(tx: GLdouble, ty: GLdouble, tz: GLdouble) {.importc.}
  proc glProgramUniformMatrix3x4fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glNormal3hNV(nx: GLhalfNv, ny: GLhalfNv, nz: GLhalfNv) {.importc.}
  proc glPushClientAttribDefaultEXT(mask: GLbitfield) {.importc.}
  proc glUnmapBufferARB(target: GLenum): GLboolean {.importc.}
  proc glVertexAttribs1dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble) {.importc.}
  proc glUniformMatrix2x3dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glUniform3f(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) {.importc.}
  proc glTexEnvxv(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glMapBufferOES(target: GLenum, access: GLenum) {.importc.}
  proc glBufferData(target: GLenum, size: GLsizeiptr, data: pointer, usage: GLenum) {.importc.}
  proc glDrawElementsInstancedANGLE(mode: GLenum, count: GLsizei, `type`: GLenum, indices: ptr pointer, primcount: GLsizei) {.importc.}
  proc glGetTextureHandleARB(texture: GLuint): GLuint64 {.importc.}
  proc glNormal3f(nx: GLfloat, ny: GLfloat, nz: GLfloat) {.importc.}
  proc glTexCoordP3uiv(`type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glTexParameterx(target: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glMapBufferRange(target: GLenum, offset: GLintptr, length: GLsizeiptr, access: GLbitfield) {.importc.}
  proc glTexCoord2fVertex3fSUN(s: GLfloat, t: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glVariantArrayObjectATI(id: GLuint, `type`: GLenum, stride: GLsizei, buffer: GLuint, offset: GLuint) {.importc.}
  proc glGetnHistogramARB(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, bufSize: GLsizei, values: pointer) {.importc.}
  proc glWindowPos3sv(v: ptr GLshort) {.importc.}
  proc glGetVariantPointervEXT(id: GLuint, value: GLenum, data: ptr pointer) {.importc.}
  proc glGetLightfv(light: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetnTexImageARB(target: GLenum, level: GLint, format: GLenum, `type`: GLenum, bufSize: GLsizei, img: pointer) {.importc.}
  proc glGenRenderbuffersEXT(n: GLsizei, renderbuffers: ptr GLuint) {.importc.}
  proc glMultiDrawArraysIndirectBindlessNV(mode: GLenum, indirect: pointer, drawCount: GLsizei, stride: GLsizei, vertexBufferCount: GLint) {.importc.}
  proc glDisableClientStateIndexedEXT(`array`: GLenum, index: GLuint) {.importc.}
  proc glMapGrid1f(un: GLint, u1: GLfloat, u2: GLfloat) {.importc.}
  proc glTexStorage2D(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glShaderStorageBlockBinding(program: GLuint, storageBlockIndex: GLuint, storageBlockBinding: GLuint) {.importc.}
  proc glBlendBarrierNV() {.importc.}
  proc glGetVideoui64vNV(video_slot: GLuint, pname: GLenum, params: ptr GLuint64Ext) {.importc.}
  proc glUniform3ui64NV(location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext) {.importc.}
  proc glUniform4ivARB(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glGetQueryObjectivARB(id: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glCompressedTexSubImage3DOES(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.importc.}
  proc glEnableIndexedEXT(target: GLenum, index: GLuint) {.importc.}
  proc glNamedRenderbufferStorageMultisampleCoverageEXT(renderbuffer: GLuint, coverageSamples: GLsizei, colorSamples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glVertexAttribI3iEXT(index: GLuint, x: GLint, y: GLint, z: GLint) {.importc.}
  proc glUniform4uivEXT(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glGetUniformLocation(program: GLuint, name: cstring): GLint {.importc.}
  proc glCurrentPaletteMatrixARB(index: GLint) {.importc.}
  proc glVertexAttribLPointerEXT(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glFogCoorddvEXT(coord: ptr GLdouble) {.importc.}
  proc glInitNames() {.importc.}
  proc glGetPathSpacingNV(pathListMode: GLenum, numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, advanceScale: GLfloat, kerningScale: GLfloat, transformType: GLenum, returnedSpacing: ptr GLfloat) {.importc.}
  proc glNormal3fVertex3fvSUN(n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glTexCoord2iv(v: ptr GLint) {.importc.}
  proc glWindowPos3s(x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glProgramUniformMatrix3x4fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glVertexAttribP4ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint) {.importc.}
  proc glVertexAttribs4ubvNV(index: GLuint, count: GLsizei, v: ptr GLubyte) {.importc.}
  proc glProgramLocalParameterI4iNV(target: GLenum, index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glStencilMaskSeparate(face: GLenum, mask: GLuint) {.importc.}
  proc glClientWaitSync(sync: GLsync, flags: GLbitfield, timeout: GLuint64): GLenum {.importc.}
  proc glPolygonOffsetx(factor: GLfixed, units: GLfixed) {.importc.}
  proc glCreateProgramObjectARB(): GLhandleArb {.importc.}
  proc glClearColorIuiEXT(red: GLuint, green: GLuint, blue: GLuint, alpha: GLuint) {.importc.}
  proc glDeleteTransformFeedbacksNV(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glFramebufferDrawBuffersEXT(framebuffer: GLuint, n: GLsizei, bufs: ptr GLenum) {.importc.}
  proc glAreTexturesResident(n: GLsizei, textures: ptr GLuint, residences: ptr GLboolean): GLboolean {.importc.}
  proc glNamedBufferDataEXT(buffer: GLuint, size: GLsizeiptr, data: pointer, usage: GLenum) {.importc.}
  proc glGetInvariantFloatvEXT(id: GLuint, value: GLenum, data: ptr GLfloat) {.importc.}
  proc glMultiTexCoord4d(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble) {.importc.}
  proc glGetPixelTransformParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetStringi(name: GLenum, index: GLuint): ptr GLubyte {.importc.}
  proc glMakeBufferNonResidentNV(target: GLenum) {.importc.}
  proc glVertex4bOES(x: GLbyte, y: GLbyte, z: GLbyte) {.importc.}
  proc glGetObjectLabel(identifier: GLenum, name: GLuint, bufSize: GLsizei, length: ptr GLsizei, label: cstring) {.importc.}
  proc glClipPlanexOES(plane: GLenum, equation: ptr GLfixed) {.importc.}
  proc glElementPointerAPPLE(`type`: GLenum, `pointer`: pointer) {.importc.}
  proc glIsAsyncMarkerSGIX(marker: GLuint): GLboolean {.importc.}
  proc glUseShaderProgramEXT(`type`: GLenum, program: GLuint) {.importc.}
  proc glReplacementCodeuiColor4ubVertex3fSUN(rc: GLuint, r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glIsTransformFeedback(id: GLuint): GLboolean {.importc.}
  proc glEdgeFlag(flag: GLboolean) {.importc.}
  proc glGetTexGeniv(coord: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glBeginQueryEXT(target: GLenum, id: GLuint) {.importc.}
  proc glUniform1uiEXT(location: GLint, v0: GLuint) {.importc.}
  proc glProgramUniform3fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetVideoi64vNV(video_slot: GLuint, pname: GLenum, params: ptr GLint64Ext) {.importc.}
  proc glProgramUniform3ui(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint) {.importc.}
  proc glSecondaryColor3uiEXT(red: GLuint, green: GLuint, blue: GLuint) {.importc.}
  proc glPathStencilFuncNV(fun: GLenum, `ref`: GLint, mask: GLuint) {.importc.}
  proc glVertexAttribP1ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint) {.importc.}
  proc glStencilFillPathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, fillMode: GLenum, mask: GLuint, transformType: GLenum, transformValues: ptr GLfloat) {.importc.}
  proc glFogCoordfEXT(coord: GLfloat) {.importc.}
  proc glTextureParameterIuivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glProgramUniform4dEXT(program: GLuint, location: GLint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glFramebufferTextureFaceARB(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, face: GLenum) {.importc.}
  proc glTexCoord3s(s: GLshort, t: GLshort, r: GLshort) {.importc.}
  proc glGetFramebufferAttachmentParameteriv(target: GLenum, attachment: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glEndVideoCaptureNV(video_capture_slot: GLuint) {.importc.}
  proc glProgramUniformMatrix2x4dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glGetFloatIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLfloat) {.importc.}
  proc glTexCoord1xOES(s: GLfixed) {.importc.}
  proc glTexCoord4f(s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat) {.importc.}
  proc glShaderSource(shader: GLuint, count: GLsizei, string: cstringArray, length: ptr GLint) {.importc.}
  proc glGetDetailTexFuncSGIS(target: GLenum, points: ptr GLfloat) {.importc.}
  proc glResetHistogram(target: GLenum) {.importc.}
  proc glVertexAttribP2ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint) {.importc.}
  proc glDrawTransformFeedbackNV(mode: GLenum, id: GLuint) {.importc.}
  proc glWindowPos2fMESA(x: GLfloat, y: GLfloat) {.importc.}
  proc glObjectLabelKHR(identifier: GLenum, name: GLuint, length: GLsizei, label: cstring) {.importc.}
  proc glMultiTexCoord2iARB(target: GLenum, s: GLint, t: GLint) {.importc.}
  proc glVertexAttrib4usv(index: GLuint, v: ptr GLushort) {.importc.}
  proc glGetGraphicsResetStatusARB(): GLenum {.importc.}
  proc glProgramUniform3dEXT(program: GLuint, location: GLint, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glPathSubCommandsNV(path: GLuint, commandStart: GLsizei, commandsToDelete: GLsizei, numCommands: GLsizei, commands: ptr GLubyte, numCoords: GLsizei, coordType: GLenum, coords: pointer) {.importc.}
  proc glEndTransformFeedbackNV() {.importc.}
  proc glWindowPos2sMESA(x: GLshort, y: GLshort) {.importc.}
  proc glTangent3sEXT(tx: GLshort, ty: GLshort, tz: GLshort) {.importc.}
  proc glLineWidthx(width: GLfixed) {.importc.}
  proc glGetUniformBufferSizeEXT(program: GLuint, location: GLint): GLint {.importc.}
  proc glTexCoord2bOES(s: GLbyte, t: GLbyte) {.importc.}
  proc glWindowPos3iMESA(x: GLint, y: GLint, z: GLint) {.importc.}
  proc glTexGend(coord: GLenum, pname: GLenum, param: GLdouble) {.importc.}
  proc glRenderbufferStorageMultisampleANGLE(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glGetProgramiv(program: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glDrawTransformFeedbackStreamInstanced(mode: GLenum, id: GLuint, stream: GLuint, instancecount: GLsizei) {.importc.}
  proc glMatrixTranslatefEXT(mode: GLenum, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glColor4iv(v: ptr GLint) {.importc.}
  proc glSecondaryColor3ivEXT(v: ptr GLint) {.importc.}
  proc glIsNamedStringARB(namelen: GLint, name: cstring): GLboolean {.importc.}
  proc glVertexAttribL4dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glEndTransformFeedback() {.importc.}
  proc glVertexStream3fvATI(stream: GLenum, coords: ptr GLfloat) {.importc.}
  proc glProgramUniformMatrix4x2dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glTextureBufferRangeEXT(texture: GLuint, target: GLenum, internalformat: GLenum, buffer: GLuint, offset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glTexCoord2fNormal3fVertex3fvSUN(tc: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glProgramUniform2f(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat) {.importc.}
  proc glMultiTexCoord2sv(target: GLenum, v: ptr GLshort) {.importc.}
  proc glTexCoord3bOES(s: GLbyte, t: GLbyte, r: GLbyte) {.importc.}
  proc glGenFramebuffersOES(n: GLsizei, framebuffers: ptr GLuint) {.importc.}
  proc glMultiTexCoord3sv(target: GLenum, v: ptr GLshort) {.importc.}
  proc glVertexAttrib4Nub(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte, w: GLubyte) {.importc.}
  proc glColor3d(red: GLdouble, green: GLdouble, blue: GLdouble) {.importc.}
  proc glGetActiveAttrib(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring) {.importc.}
  proc glConvolutionParameterfEXT(target: GLenum, pname: GLenum, params: GLfloat) {.importc.}
  proc glTexSubImage2DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glBinormal3fvEXT(v: ptr GLfloat) {.importc.}
  proc glDebugMessageControl(source: GLenum, `type`: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean) {.importc.}
  proc glProgramUniform3uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glPNTrianglesiATI(pname: GLenum, param: GLint) {.importc.}
  proc glGetPerfMonitorCounterInfoAMD(group: GLuint, counter: GLuint, pname: GLenum, data: pointer) {.importc.}
  proc glVertexAttribL3ui64NV(index: GLuint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext) {.importc.}
  proc glIsRenderbufferOES(renderbuffer: GLuint): GLboolean {.importc.}
  proc glColorSubTable(target: GLenum, start: GLsizei, count: GLsizei, format: GLenum, `type`: GLenum, data: pointer) {.importc.}
  proc glCompressedMultiTexImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glBindSampler(unit: GLuint, sampler: GLuint) {.importc.}
  proc glVariantubvEXT(id: GLuint, `addr`: ptr GLubyte) {.importc.}
  proc glDisablei(target: GLenum, index: GLuint) {.importc.}
  proc glVertexAttribI2uiEXT(index: GLuint, x: GLuint, y: GLuint) {.importc.}
  proc glDrawElementArrayATI(mode: GLenum, count: GLsizei) {.importc.}
  proc glTagSampleBufferSGIX() {.importc.}
  proc glVertexPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer) {.importc.}
  proc glFragmentLightiSGIX(light: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glLoadTransposeMatrixxOES(m: ptr GLfixed) {.importc.}
  proc glProgramLocalParameter4fvARB(target: GLenum, index: GLuint, params: ptr GLfloat) {.importc.}
  proc glGetVariantFloatvEXT(id: GLuint, value: GLenum, data: ptr GLfloat) {.importc.}
  proc glProgramUniform4ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glFragmentLightfSGIX(light: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glIsVertexArrayAPPLE(`array`: GLuint): GLboolean {.importc.}
  proc glTexCoord1bvOES(coords: ptr GLbyte) {.importc.}
  proc glUniform4fv(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glPixelDataRangeNV(target: GLenum, length: GLsizei, `pointer`: pointer) {.importc.}
  proc glUniformMatrix4x2fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glRectf(x1: GLfloat, y1: GLfloat, x2: GLfloat, y2: GLfloat) {.importc.}
  proc glCoverageMaskNV(mask: GLboolean) {.importc.}
  proc glPointParameterfvSGIS(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glProgramUniformMatrix4x2dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glFragmentLightModelfSGIX(pname: GLenum, param: GLfloat) {.importc.}
  proc glDisableVertexAttribAPPLE(index: GLuint, pname: GLenum) {.importc.}
  proc glMultiTexCoord3dvARB(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glTexCoord4iv(v: ptr GLint) {.importc.}
  proc glUniform1f(location: GLint, v0: GLfloat) {.importc.}
  proc glVertexAttribParameteriAMD(index: GLuint, pname: GLenum, param: GLint) {.importc.}
  proc glGetConvolutionParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glRecti(x1: GLint, y1: GLint, x2: GLint, y2: GLint) {.importc.}
  proc glTexEnvxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glGetRenderbufferParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glBlendFuncIndexedAMD(buf: GLuint, src: GLenum, dst: GLenum) {.importc.}
  proc glProgramUniformMatrix3x2fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glDrawArraysInstancedANGLE(mode: GLenum, first: GLint, count: GLsizei, primcount: GLsizei) {.importc.}
  proc glTextureBarrierNV() {.importc.}
  proc glDrawBuffersIndexedEXT(n: GLint, location: ptr GLenum, indices: ptr GLint) {.importc.}
  proc glUniformMatrix4fvARB(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glInstrumentsBufferSGIX(size: GLsizei, buffer: ptr GLint) {.importc.}
  proc glAlphaFuncQCOM(fun: GLenum, `ref`: GLclampf) {.importc.}
  proc glUniformMatrix4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glGetMinmaxParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetInvariantBooleanvEXT(id: GLuint, value: GLenum, data: ptr GLboolean) {.importc.}
  proc glVDPAUIsSurfaceNV(surface: GLvdpauSurfaceNv) {.importc.}
  proc glGenProgramsARB(n: GLsizei, programs: ptr GLuint) {.importc.}
  proc glDrawRangeElementArrayATI(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei) {.importc.}
  proc glFramebufferRenderbufferEXT(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) {.importc.}
  proc glClearIndex(c: GLfloat) {.importc.}
  proc glDepthRangeIndexed(index: GLuint, n: GLdouble, f: GLdouble) {.importc.}
  proc glDrawTexivOES(coords: ptr GLint) {.importc.}
  proc glTangent3iEXT(tx: GLint, ty: GLint, tz: GLint) {.importc.}
  proc glStringMarkerGREMEDY(len: GLsizei, string: pointer) {.importc.}
  proc glTexCoordP1ui(`type`: GLenum, coords: GLuint) {.importc.}
  proc glOrthox(l: GLfixed, r: GLfixed, b: GLfixed, t: GLfixed, n: GLfixed, f: GLfixed) {.importc.}
  proc glReplacementCodeuiVertex3fvSUN(rc: ptr GLuint, v: ptr GLfloat) {.importc.}
  proc glMultiTexCoord1bvOES(texture: GLenum, coords: ptr GLbyte) {.importc.}
  proc glDrawArraysInstancedBaseInstance(mode: GLenum, first: GLint, count: GLsizei, instancecount: GLsizei, baseinstance: GLuint) {.importc.}
  proc glMultMatrixf(m: ptr GLfloat) {.importc.}
  proc glProgramUniform4i(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) {.importc.}
  proc glScissorArrayv(first: GLuint, count: GLsizei, v: ptr GLint) {.importc.}
  proc glGetnUniformivEXT(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLint) {.importc.}
  proc glGetTexEnvxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glWindowPos3ivARB(v: ptr GLint) {.importc.}
  proc glProgramStringARB(target: GLenum, format: GLenum, len: GLsizei, string: pointer) {.importc.}
  proc glTextureColorMaskSGIS(red: GLboolean, green: GLboolean, blue: GLboolean, alpha: GLboolean) {.importc.}
  proc glMultiTexCoord4fv(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glUniformMatrix4x3fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glIsPathNV(path: GLuint): GLboolean {.importc.}
  proc glStartTilingQCOM(x: GLuint, y: GLuint, width: GLuint, height: GLuint, preserveMask: GLbitfield) {.importc.}
  proc glVariantivEXT(id: GLuint, `addr`: ptr GLint) {.importc.}
  proc glGetnMinmaxARB(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, bufSize: GLsizei, values: pointer) {.importc.}
  proc glTransformFeedbackVaryings(program: GLuint, count: GLsizei, varyings: cstringArray, bufferMode: GLenum) {.importc.}
  proc glShaderOp2EXT(op: GLenum, res: GLuint, arg1: GLuint, arg2: GLuint) {.importc.}
  proc glVertexAttribPointer(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glMultiTexCoord4dvARB(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glProgramUniform1ui64NV(program: GLuint, location: GLint, x: GLuint64Ext) {.importc.}
  proc glGetShaderSourceARB(obj: GLhandleArb, maxLength: GLsizei, length: ptr GLsizei, source: cstring) {.importc.}
  proc glGetBufferSubDataARB(target: GLenum, offset: GLintPtrArb, size: GLsizeiptrArb, data: pointer) {.importc.}
  proc glCopyTexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glProgramEnvParameterI4iNV(target: GLenum, index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glGetVertexAttribivARB(index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetFinalCombinerInputParameterivNV(variable: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glIndexFuncEXT(fun: GLenum, `ref`: GLclampf) {.importc.}
  proc glProgramUniformMatrix3dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glTexStorage1DEXT(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei) {.importc.}
  proc glUniformMatrix2fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glConvolutionParameterf(target: GLenum, pname: GLenum, params: GLfloat) {.importc.}
  proc glGlobalAlphaFactordSUN(factor: GLdouble) {.importc.}
  proc glCopyTextureImage2DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint) {.importc.}
  proc glVertex4xOES(x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glClearDepthx(depth: GLfixed) {.importc.}
  proc glGetColorTableParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGenProgramPipelines(n: GLsizei, pipelines: ptr GLuint) {.importc.}
  proc glVertexAttribL4ui64vNV(index: GLuint, v: ptr GLuint64Ext) {.importc.}
  proc glUniform1fARB(location: GLint, v0: GLfloat) {.importc.}
  proc glUniformMatrix3fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glUniform3dv(location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glVertexAttribI4iv(index: GLuint, v: ptr GLint) {.importc.}
  proc glPixelZoom(xfactor: GLfloat, yfactor: GLfloat) {.importc.}
  proc glShadeModel(mode: GLenum) {.importc.}
  proc glFramebufferTexture3DOES(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint) {.importc.}
  proc glMultiTexCoord2i(target: GLenum, s: GLint, t: GLint) {.importc.}
  proc glBlendEquationSeparateIndexedAMD(buf: GLuint, modeRgb: GLenum, modeAlpha: GLenum) {.importc.}
  proc glIsEnabled(cap: GLenum): GLboolean {.importc.}
  proc glTexImage2D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glPolygonOffsetxOES(factor: GLfixed, units: GLfixed) {.importc.}
  proc glDrawBuffersEXT(n: GLsizei, bufs: ptr GLenum) {.importc.}
  proc glPixelTexGenParameterfSGIS(pname: GLenum, param: GLfloat) {.importc.}
  proc glExtGetRenderbuffersQCOM(renderbuffers: ptr GLuint, maxRenderbuffers: GLint, numRenderbuffers: ptr GLint) {.importc.}
  proc glBindImageTextures(first: GLuint, count: GLsizei, textures: ptr GLuint) {.importc.}
  proc glVertexAttribP2uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint) {.importc.}
  proc glTextureImage3DMultisampleCoverageNV(texture: GLuint, target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedSampleLocations: GLboolean) {.importc.}
  proc glRasterPos2s(x: GLshort, y: GLshort) {.importc.}
  proc glVertexAttrib4dvARB(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glProgramUniformMatrix2x3fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glProgramUniformMatrix2x4dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glMultiTexCoord1d(target: GLenum, s: GLdouble) {.importc.}
  proc glGetProgramParameterdvNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glPNTrianglesfATI(pname: GLenum, param: GLfloat) {.importc.}
  proc glUniformMatrix3x4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glVertexAttrib3sNV(index: GLuint, x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glGetVideoCaptureStreamfvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glCombinerParameterivNV(pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetTexGenfvOES(coord: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glCopyTexSubImage2DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glGetProgramLocalParameterfvARB(target: GLenum, index: GLuint, params: ptr GLfloat) {.importc.}
  proc glTexCoord3iv(v: ptr GLint) {.importc.}
  proc glVertexAttribs2hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv) {.importc.}
  proc glNormal3sv(v: ptr GLshort) {.importc.}
  proc glUniform2dv(location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glSecondaryColor3hvNV(v: ptr GLhalfNv) {.importc.}
  proc glDrawArraysInstancedEXT(mode: GLenum, start: GLint, count: GLsizei, primcount: GLsizei) {.importc.}
  proc glBeginTransformFeedback(primitiveMode: GLenum) {.importc.}
  proc glTexParameterIuivEXT(target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glProgramBufferParametersfvNV(target: GLenum, bindingIndex: GLuint, wordIndex: GLuint, count: GLsizei, params: ptr GLfloat) {.importc.}
  proc glVertexArrayBindVertexBufferEXT(vaobj: GLuint, bindingindex: GLuint, buffer: GLuint, offset: GLintptr, stride: GLsizei) {.importc.}
  proc glPathParameterfNV(path: GLuint, pname: GLenum, value: GLfloat) {.importc.}
  proc glGetClipPlanexOES(plane: GLenum, equation: ptr GLfixed) {.importc.}
  proc glSecondaryColor3ubvEXT(v: ptr GLubyte) {.importc.}
  proc glGetPixelMapxv(map: GLenum, size: GLint, values: ptr GLfixed) {.importc.}
  proc glVertexAttribI1uivEXT(index: GLuint, v: ptr GLuint) {.importc.}
  proc glMultiTexImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glAlphaFuncxOES(fun: GLenum, `ref`: GLfixed) {.importc.}
  proc glMultiTexCoord2dv(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glBindRenderbufferOES(target: GLenum, renderbuffer: GLuint) {.importc.}
  proc glPathStencilDepthOffsetNV(factor: GLfloat, units: GLfloat) {.importc.}
  proc glPointParameterfvEXT(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glSampleCoverageARB(value: GLfloat, invert: GLboolean) {.importc.}
  proc glVertexAttrib3dNV(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glNamedProgramLocalParameter4dvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLdouble) {.importc.}
  proc glGenFramebuffers(n: GLsizei, framebuffers: ptr GLuint) {.importc.}
  proc glMultiDrawElementsEXT(mode: GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, primcount: GLsizei) {.importc.}
  proc glVertexAttrib2fNV(index: GLuint, x: GLfloat, y: GLfloat) {.importc.}
  proc glProgramUniform4ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glTexGeniOES(coord: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glBindProgramPipeline(pipeline: GLuint) {.importc.}
  proc glBindSamplers(first: GLuint, count: GLsizei, samplers: ptr GLuint) {.importc.}
  proc glColorTableSGI(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, table: pointer) {.importc.}
  proc glMultiTexCoord3xOES(texture: GLenum, s: GLfixed, t: GLfixed, r: GLfixed) {.importc.}
  proc glIsQueryEXT(id: GLuint): GLboolean {.importc.}
  proc glGenBuffersARB(n: GLsizei, buffers: ptr GLuint) {.importc.}
  proc glVertex4xvOES(coords: ptr GLfixed) {.importc.}
  proc glPixelMapuiv(map: GLenum, mapsize: GLsizei, values: ptr GLuint) {.importc.}
  proc glDrawTexfOES(x: GLfloat, y: GLfloat, z: GLfloat, width: GLfloat, height: GLfloat) {.importc.}
  proc glPointParameterfEXT(pname: GLenum, param: GLfloat) {.importc.}
  proc glPathDashArrayNV(path: GLuint, dashCount: GLsizei, dashArray: ptr GLfloat) {.importc.}
  proc glClearTexImage(texture: GLuint, level: GLint, format: GLenum, `type`: GLenum, data: ptr pointer) {.importc.}
  proc glIndexdv(c: ptr GLdouble) {.importc.}
  proc glMultTransposeMatrixfARB(m: ptr GLfloat) {.importc.}
  proc glVertexAttribL3d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glUniform3fv(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetProgramInterfaceiv(program: GLuint, programInterface: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glFogCoordfv(coord: ptr GLfloat) {.importc.}
  proc glTexSubImage3DOES(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGetPolygonStipple(mask: ptr GLubyte) {.importc.}
  proc glGetQueryObjectivEXT(id: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glColor3xOES(red: GLfixed, green: GLfixed, blue: GLfixed) {.importc.}
  proc glMultiTexParameterIivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetMaterialiv(face: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertex2fv(v: ptr GLfloat) {.importc.}
  proc glConvolutionParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGenOcclusionQueriesNV(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glGetVertexAttribdvNV(index: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glVertexAttribs4fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat) {.importc.}
  proc glVertexAttribL3dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glTexEnvi(target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glObjectPtrLabel(`ptr`: ptr pointer, length: GLsizei, label: cstring) {.importc.}
  proc glGetTexGenfv(coord: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glMapVertexAttrib1dAPPLE(index: GLuint, size: GLuint, u1: GLdouble, u2: GLdouble, stride: GLint, order: GLint, points: ptr GLdouble) {.importc.}
  proc glTexCoord3dv(v: ptr GLdouble) {.importc.}
  proc glIsEnabledIndexedEXT(target: GLenum, index: GLuint): GLboolean {.importc.}
  proc glGlobalAlphaFactoruiSUN(factor: GLuint) {.importc.}
  proc glMatrixIndexPointerARB(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glUniformHandleui64ARB(location: GLint, value: GLuint64) {.importc.}
  proc glUniform1fvARB(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetActiveSubroutineUniformName(program: GLuint, shadertype: GLenum, index: GLuint, bufsize: GLsizei, length: ptr GLsizei, name: cstring) {.importc.}
  proc glProgramUniformMatrix4x2fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glMultiTexCoord4fARB(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat) {.importc.}
  proc glGetDriverControlsQCOM(num: ptr GLint, size: GLsizei, driverControls: ptr GLuint) {.importc.}
  proc glBindBufferRange(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glMapGrid2f(un: GLint, u1: GLfloat, u2: GLfloat, vn: GLint, v1: GLfloat, v2: GLfloat) {.importc.}
  proc glUniform2fv(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glOrtho(left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble) {.importc.}
  proc glGetImageHandleNV(texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, format: GLenum): GLuint64 {.importc.}
  proc glIsImageHandleResidentARB(handle: GLuint64): GLboolean {.importc.}
  proc glGetConvolutionParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glLineWidthxOES(width: GLfixed) {.importc.}
  proc glPathCommandsNV(path: GLuint, numCommands: GLsizei, commands: ptr GLubyte, numCoords: GLsizei, coordType: GLenum, coords: pointer) {.importc.}
  proc glMaterialxvOES(face: GLenum, pname: GLenum, param: ptr GLfixed) {.importc.}
  proc glPauseTransformFeedbackNV() {.importc.}
  proc glTexCoord4d(s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble) {.importc.}
  proc glUniform3ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glMultiTexCoord3dARB(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble) {.importc.}
  proc glProgramUniform3fEXT(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) {.importc.}
  proc glTexImage3DMultisampleCoverageNV(target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedSampleLocations: GLboolean) {.importc.}
  proc glNormalPointerEXT(`type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer) {.importc.}
  proc glPathColorGenNV(color: GLenum, genMode: GLenum, colorFormat: GLenum, coeffs: ptr GLfloat) {.importc.}
  proc glGetMultiTexGendvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glColor3i(red: GLint, green: GLint, blue: GLint) {.importc.}
  proc glPointSizex(size: GLfixed) {.importc.}
  proc glGetConvolutionFilterEXT(target: GLenum, format: GLenum, `type`: GLenum, image: pointer) {.importc.}
  proc glBindBufferBaseNV(target: GLenum, index: GLuint, buffer: GLuint) {.importc.}
  proc glInsertComponentEXT(res: GLuint, src: GLuint, num: GLuint) {.importc.}
  proc glVertex2d(x: GLdouble, y: GLdouble) {.importc.}
  proc glGetPathDashArrayNV(path: GLuint, dashArray: ptr GLfloat) {.importc.}
  proc glVertexAttrib2sARB(index: GLuint, x: GLshort, y: GLshort) {.importc.}
  proc glScissor(x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glLoadMatrixd(m: ptr GLdouble) {.importc.}
  proc glVertex2bvOES(coords: ptr GLbyte) {.importc.}
  proc glTexCoord2i(s: GLint, t: GLint) {.importc.}
  proc glWriteMaskEXT(res: GLuint, `in`: GLuint, outX: GLenum, outY: GLenum, outZ: GLenum, outW: GLenum) {.importc.}
  proc glClientWaitSyncAPPLE(sync: GLsync, flags: GLbitfield, timeout: GLuint64): GLenum {.importc.}
  proc glGetObjectBufferivATI(buffer: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetNamedBufferParameterivEXT(buffer: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glTexCoord1bOES(s: GLbyte) {.importc.}
  proc glVertexAttrib4dARB(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glUniform3fARB(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat) {.importc.}
  proc glWindowPos2ivARB(v: ptr GLint) {.importc.}
  proc glCreateShaderProgramvEXT(`type`: GLenum, count: GLsizei, strings: cstringArray): GLuint {.importc.}
  proc glListParameterivSGIX(list: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetGraphicsResetStatusEXT(): GLenum {.importc.}
  proc glActiveShaderProgramEXT(pipeline: GLuint, program: GLuint) {.importc.}
  proc glTexCoordP1uiv(`type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glVideoCaptureStreamParameterdvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glGetVertexAttribPointerv(index: GLuint, pname: GLenum, `pointer`: ptr pointer) {.importc.}
  proc glGetCompressedMultiTexImageEXT(texunit: GLenum, target: GLenum, lod: GLint, img: pointer) {.importc.}
  proc glWindowPos4fMESA(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glDrawElementsInstancedARB(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, primcount: GLsizei) {.importc.}
  proc glVertexStream1dATI(stream: GLenum, x: GLdouble) {.importc.}
  proc glMatrixMultfEXT(mode: GLenum, m: ptr GLfloat) {.importc.}
  proc glGetPathParameterivNV(path: GLuint, pname: GLenum, value: ptr GLint) {.importc.}
  proc glCombinerParameteriNV(pname: GLenum, param: GLint) {.importc.}
  proc glUpdateObjectBufferATI(buffer: GLuint, offset: GLuint, size: GLsizei, `pointer`: pointer, preserve: GLenum) {.importc.}
  proc glVertexAttrib4uivARB(index: GLuint, v: ptr GLuint) {.importc.}
  proc glVertexAttrib4iv(index: GLuint, v: ptr GLint) {.importc.}
  proc glFrustum(left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble) {.importc.}
  proc glDrawTexxvOES(coords: ptr GLfixed) {.importc.}
  proc glTexCoord2fColor4ubVertex3fSUN(s: GLfloat, t: GLfloat, r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glMultiTexCoord2fARB(target: GLenum, s: GLfloat, t: GLfloat) {.importc.}
  proc glGenTransformFeedbacksNV(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glMultiTexGenfEXT(texunit: GLenum, coord: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glGetMinmax(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer) {.importc.}
  proc glBindTransformFeedback(target: GLenum, id: GLuint) {.importc.}
  proc glEnableVertexAttribArrayARB(index: GLuint) {.importc.}
  proc glIsFenceAPPLE(fence: GLuint): GLboolean {.importc.}
  proc glMultiTexGendvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glRotatex(angle: GLfixed, x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glGetFragmentLightfvSGIX(light: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glMultiTexCoord4dv(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glBlendFuncSeparateEXT(sfactorRgb: GLenum, dfactorRgb: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum) {.importc.}
  proc glMultiTexCoord1f(target: GLenum, s: GLfloat) {.importc.}
  proc glWindowPos2f(x: GLfloat, y: GLfloat) {.importc.}
  proc glGetPathTexGenivNV(texCoordSet: GLenum, pname: GLenum, value: ptr GLint) {.importc.}
  proc glIndexxvOES(component: ptr GLfixed) {.importc.}
  proc glDisableVertexArrayAttribEXT(vaobj: GLuint, index: GLuint) {.importc.}
  proc glGetProgramivARB(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glPatchParameteri(pname: GLenum, value: GLint) {.importc.}
  proc glMultiTexCoord2fv(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glTexSubImage3DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glFramebufferTexture1DEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glTangent3fEXT(tx: GLfloat, ty: GLfloat, tz: GLfloat) {.importc.}
  proc glIsVertexAttribEnabledAPPLE(index: GLuint, pname: GLenum): GLboolean {.importc.}
  proc glGetShaderInfoLog(shader: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring) {.importc.}
  proc glFrustumx(l: GLfixed, r: GLfixed, b: GLfixed, t: GLfixed, n: GLfixed, f: GLfixed) {.importc.}
  proc glTexGenfv(coord: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glCompressedTexImage2DARB(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.importc.}
  proc glMultiTexCoord2bvOES(texture: GLenum, coords: ptr GLbyte) {.importc.}
  proc glGetTexBumpParameterivATI(pname: GLenum, param: ptr GLint) {.importc.}
  proc glMultiTexCoord2svARB(target: GLenum, v: ptr GLshort) {.importc.}
  proc glProgramBufferParametersIivNV(target: GLenum, bindingIndex: GLuint, wordIndex: GLuint, count: GLsizei, params: ptr GLint) {.importc.}
  proc glIsQueryARB(id: GLuint): GLboolean {.importc.}
  proc glFramebufferTextureLayer(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint) {.importc.}
  proc glUniform4i(location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint) {.importc.}
  proc glDrawArrays(mode: GLenum, first: GLint, count: GLsizei) {.importc.}
  proc glWeightubvARB(size: GLint, weights: ptr GLubyte) {.importc.}
  proc glGetUniformSubroutineuiv(shadertype: GLenum, location: GLint, params: ptr GLuint) {.importc.}
  proc glMultTransposeMatrixdARB(m: ptr GLdouble) {.importc.}
  proc glReplacementCodeuiTexCoord2fNormal3fVertex3fvSUN(rc: ptr GLuint, tc: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glGetMapdv(target: GLenum, query: GLenum, v: ptr GLdouble) {.importc.}
  proc glGetMultisamplefvNV(pname: GLenum, index: GLuint, val: ptr GLfloat) {.importc.}
  proc glVertex2hvNV(v: ptr GLhalfNv) {.importc.}
  proc glProgramUniformMatrix2x3fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glProgramUniform3iEXT(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint) {.importc.}
  proc glGetnPixelMapusvARB(map: GLenum, bufSize: GLsizei, values: ptr GLushort) {.importc.}
  proc glVertexWeighthvNV(weight: ptr GLhalfNv) {.importc.}
  proc glDrawTransformFeedbackInstanced(mode: GLenum, id: GLuint, instancecount: GLsizei) {.importc.}
  proc glFlushStaticDataIBM(target: GLenum) {.importc.}
  proc glWindowPos2fvARB(v: ptr GLfloat) {.importc.}
  proc glMultiTexCoord3sARB(target: GLenum, s: GLshort, t: GLshort, r: GLshort) {.importc.}
  proc glWindowPos3fv(v: ptr GLfloat) {.importc.}
  proc glFlushVertexArrayRangeNV() {.importc.}
  proc glTangent3bEXT(tx: GLbyte, ty: GLbyte, tz: GLbyte) {.importc.}
  proc glIglooInterfaceSGIX(pname: GLenum, params: pointer) {.importc.}
  proc glProgramUniformMatrix4x2fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glVertexAttribIFormatNV(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei) {.importc.}
  proc glNamedRenderbufferStorageMultisampleEXT(renderbuffer: GLuint, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glCopyTexImage1DEXT(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint) {.importc.}
  proc glBindTexGenParameterEXT(unit: GLenum, coord: GLenum, value: GLenum): GLuint {.importc.}
  proc glVertex4hNV(x: GLhalfNv, y: GLhalfNv, z: GLhalfNv, w: GLhalfNv) {.importc.}
  proc glGetMapfv(target: GLenum, query: GLenum, v: ptr GLfloat) {.importc.}
  proc glSamplePatternEXT(pattern: GLenum) {.importc.}
  proc glIndexxOES(component: GLfixed) {.importc.}
  proc glVertexAttrib4ubv(index: GLuint, v: ptr GLubyte) {.importc.}
  proc glGetColorTable(target: GLenum, format: GLenum, `type`: GLenum, table: pointer) {.importc.}
  proc glFragmentLightModelivSGIX(pname: GLenum, params: ptr GLint) {.importc.}
  proc glPixelTransformParameterfEXT(target: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glSamplerParameterfv(sampler: GLuint, pname: GLenum, param: ptr GLfloat) {.importc.}
  proc glBindTextureUnitParameterEXT(unit: GLenum, value: GLenum): GLuint {.importc.}
  proc glColor3ub(red: GLubyte, green: GLubyte, blue: GLubyte) {.importc.}
  proc glGetMultiTexGenivEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVariantusvEXT(id: GLuint, `addr`: ptr GLushort) {.importc.}
  proc glMaterialiv(face: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glPassTexCoordATI(dst: GLuint, coord: GLuint, swizzle: GLenum) {.importc.}
  proc glGetIntegerui64vNV(value: GLenum, result: ptr GLuint64Ext) {.importc.}
  proc glProgramParameteriEXT(program: GLuint, pname: GLenum, value: GLint) {.importc.}
  proc glVertexArrayEdgeFlagOffsetEXT(vaobj: GLuint, buffer: GLuint, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glGetCombinerInputParameterivNV(stage: GLenum, portion: GLenum, variable: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glLogicOp(opcode: GLenum) {.importc.}
  proc glConvolutionParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glIsBufferResidentNV(target: GLenum): GLboolean {.importc.}
  proc glIsProgram(program: GLuint): GLboolean {.importc.}
  proc glEndQueryARB(target: GLenum) {.importc.}
  proc glRenderbufferStorage(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glMaterialfv(face: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTranslatex(x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glPathParameterivNV(path: GLuint, pname: GLenum, value: ptr GLint) {.importc.}
  proc glLightxOES(light: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glSampleMaskEXT(value: GLclampf, invert: GLboolean) {.importc.}
  proc glReplacementCodeubvSUN(code: ptr GLubyte) {.importc.}
  proc glVertexAttribArrayObjectATI(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, buffer: GLuint, offset: GLuint) {.importc.}
  proc glBeginTransformFeedbackNV(primitiveMode: GLenum) {.importc.}
  proc glEvalCoord1fv(u: ptr GLfloat) {.importc.}
  proc glProgramUniformMatrix2x3dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glMaterialxv(face: GLenum, pname: GLenum, param: ptr GLfixed) {.importc.}
  proc glGetIntegerui64i_vNV(value: GLenum, index: GLuint, result: ptr GLuint64Ext) {.importc.}
  proc glUniformBlockBinding(program: GLuint, uniformBlockIndex: GLuint, uniformBlockBinding: GLuint) {.importc.}
  proc glColor4ui(red: GLuint, green: GLuint, blue: GLuint, alpha: GLuint) {.importc.}
  proc glColor4ubVertex2fvSUN(c: ptr GLubyte, v: ptr GLfloat) {.importc.}
  proc glRectd(x1: GLdouble, y1: GLdouble, x2: GLdouble, y2: GLdouble) {.importc.}
  proc glGenVertexShadersEXT(range: GLuint): GLuint {.importc.}
  proc glLinkProgramARB(programObj: GLhandleArb) {.importc.}
  proc glVertexAttribL4dEXT(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glBlitFramebuffer(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum) {.importc.}
  proc glUseProgram(program: GLuint) {.importc.}
  proc glNamedProgramLocalParameterI4ivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLint) {.importc.}
  proc glMatrixLoadTransposedEXT(mode: GLenum, m: ptr GLdouble) {.importc.}
  proc glTranslatef(x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glGetBooleani_v(target: GLenum, index: GLuint, data: ptr GLboolean) {.importc.}
  proc glEndFragmentShaderATI() {.importc.}
  proc glVertexAttribI4ivEXT(index: GLuint, v: ptr GLint) {.importc.}
  proc glMultiDrawElementsIndirectBindlessNV(mode: GLenum, `type`: GLenum, indirect: pointer, drawCount: GLsizei, stride: GLsizei, vertexBufferCount: GLint) {.importc.}
  proc glTexCoord2s(s: GLshort, t: GLshort) {.importc.}
  proc glProgramUniform1i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glPointSizePointerOES(`type`: GLenum, stride: GLsizei, `pointer`: ptr pointer) {.importc.}
  proc glGetTexFilterFuncSGIS(target: GLenum, filter: GLenum, weights: ptr GLfloat) {.importc.}
  proc glMapGrid2xOES(n: GLint, u1: GLfixed, u2: GLfixed, v1: GLfixed, v2: GLfixed) {.importc.}
  proc glRasterPos4xvOES(coords: ptr GLfixed) {.importc.}
  proc glGetProgramBinary(program: GLuint, bufSize: GLsizei, length: ptr GLsizei, binaryFormat: ptr GLenum, binary: pointer) {.importc.}
  proc glNamedProgramLocalParameterI4uiEXT(program: GLuint, target: GLenum, index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint) {.importc.}
  proc glGetTexImage(target: GLenum, level: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glColor4d(red: GLdouble, green: GLdouble, blue: GLdouble, alpha: GLdouble) {.importc.}
  proc glTexCoord2fColor4fNormal3fVertex3fSUN(s: GLfloat, t: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glIndexi(c: GLint) {.importc.}
  proc glGetSamplerParameterIuiv(sampler: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glGetnUniformivARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLint) {.importc.}
  proc glCopyTexSubImage3DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glVertexAttribI2uivEXT(index: GLuint, v: ptr GLuint) {.importc.}
  proc glVertexStream2fvATI(stream: GLenum, coords: ptr GLfloat) {.importc.}
  proc glArrayElementEXT(i: GLint) {.importc.}
  proc glVertexAttrib2fv(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glCopyMultiTexSubImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glTexCoord4sv(v: ptr GLshort) {.importc.}
  proc glTexGenfvOES(coord: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glPointParameteriv(pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetNamedRenderbufferParameterivEXT(renderbuffer: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramVertexLimitNV(target: GLenum, limit: GLint) {.importc.}
  proc glSetMultisamplefvAMD(pname: GLenum, index: GLuint, val: ptr GLfloat) {.importc.}
  proc glLoadIdentityDeformationMapSGIX(mask: GLbitfield) {.importc.}
  proc glIsSyncAPPLE(sync: GLsync): GLboolean {.importc.}
  proc glProgramUniform1ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glEdgeFlagPointerListIBM(stride: GLint, `pointer`: ptr ptr GLboolean, ptrstride: GLint) {.importc.}
  proc glBeginVertexShaderEXT() {.importc.}
  proc glGetIntegerv(pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttrib2dvARB(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glBeginConditionalRenderNV(id: GLuint, mode: GLenum) {.importc.}
  proc glEdgeFlagv(flag: ptr GLboolean) {.importc.}
  proc glReplacementCodeubSUN(code: GLubyte) {.importc.}
  proc glObjectLabel(identifier: GLenum, name: GLuint, length: GLsizei, label: cstring) {.importc.}
  proc glMultiTexCoord3xvOES(texture: GLenum, coords: ptr GLfixed) {.importc.}
  proc glNormal3iv(v: ptr GLint) {.importc.}
  proc glSamplerParameteri(sampler: GLuint, pname: GLenum, param: GLint) {.importc.}
  proc glTextureStorage1DEXT(texture: GLuint, target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei) {.importc.}
  proc glVertexStream4dvATI(stream: GLenum, coords: ptr GLdouble) {.importc.}
  proc glWindowPos2fv(v: ptr GLfloat) {.importc.}
  proc glTexCoord4i(s: GLint, t: GLint, r: GLint, q: GLint) {.importc.}
  proc glVertexAttrib4NusvARB(index: GLuint, v: ptr GLushort) {.importc.}
  proc glVertexAttribL4d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glVertexAttribDivisorANGLE(index: GLuint, divisor: GLuint) {.importc.}
  proc glMatrixIndexPointerOES(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glMultMatrixxOES(m: ptr GLfixed) {.importc.}
  proc glMultiTexCoordP2ui(texture: GLenum, `type`: GLenum, coords: GLuint) {.importc.}
  proc glDeformationMap3dSGIX(target: GLenum, u1: GLdouble, u2: GLdouble, ustride: GLint, uorder: GLint, v1: GLdouble, v2: GLdouble, vstride: GLint, vorder: GLint, w1: GLdouble, w2: GLdouble, wstride: GLint, worder: GLint, points: ptr GLdouble) {.importc.}
  proc glClearDepthfOES(depth: GLclampf) {.importc.}
  proc glVertexStream1ivATI(stream: GLenum, coords: ptr GLint) {.importc.}
  proc glHint(target: GLenum, mode: GLenum) {.importc.}
  proc glVertex3fv(v: ptr GLfloat) {.importc.}
  proc glWaitSyncAPPLE(sync: GLsync, flags: GLbitfield, timeout: GLuint64) {.importc.}
  proc glWindowPos3i(x: GLint, y: GLint, z: GLint) {.importc.}
  proc glCompressedTexImage3DARB(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.importc.}
  proc glVertexAttrib1fvARB(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glMultiTexCoord4xOES(texture: GLenum, s: GLfixed, t: GLfixed, r: GLfixed, q: GLfixed) {.importc.}
  proc glUniform4ui64NV(location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext, w: GLuint64Ext) {.importc.}
  proc glProgramUniform4uiEXT(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint) {.importc.}
  proc glUnmapNamedBufferEXT(buffer: GLuint): GLboolean {.importc.}
  proc glBitmap(width: GLsizei, height: GLsizei, xorig: GLfloat, yorig: GLfloat, xmove: GLfloat, ymove: GLfloat, bitmap: ptr GLubyte) {.importc.}
  proc glNamedProgramLocalParameters4fvEXT(program: GLuint, target: GLenum, index: GLuint, count: GLsizei, params: ptr GLfloat) {.importc.}
  proc glGetPathCommandsNV(path: GLuint, commands: ptr GLubyte) {.importc.}
  proc glVertexAttrib3fNV(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glNamedProgramStringEXT(program: GLuint, target: GLenum, format: GLenum, len: GLsizei, string: pointer) {.importc.}
  proc glMatrixIndexusvARB(size: GLint, indices: ptr GLushort) {.importc.}
  proc glBlitFramebufferNV(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum) {.importc.}
  proc glVertexAttribI1uiv(index: GLuint, v: ptr GLuint) {.importc.}
  proc glEndConditionalRenderNV() {.importc.}
  proc glFeedbackBuffer(size: GLsizei, `type`: GLenum, buffer: ptr GLfloat) {.importc.}
  proc glMultiTexCoord3bvOES(texture: GLenum, coords: ptr GLbyte) {.importc.}
  proc glCopyColorTableSGI(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glActiveTexture(texture: GLenum) {.importc.}
  proc glFogCoordhNV(fog: GLhalfNv) {.importc.}
  proc glColorMaskIndexedEXT(index: GLuint, r: GLboolean, g: GLboolean, b: GLboolean, a: GLboolean) {.importc.}
  proc glGetCompressedTexImage(target: GLenum, level: GLint, img: pointer) {.importc.}
  proc glRasterPos2iv(v: ptr GLint) {.importc.}
  proc glGetBufferParameterivARB(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramUniform3d(program: GLuint, location: GLint, v0: GLdouble, v1: GLdouble, v2: GLdouble) {.importc.}
  proc glRasterPos3xvOES(coords: ptr GLfixed) {.importc.}
  proc glGetTextureParameterIuivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glBindImageTextureEXT(index: GLuint, texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, access: GLenum, format: GLint) {.importc.}
  proc glWindowPos2iMESA(x: GLint, y: GLint) {.importc.}
  proc glVertexPointervINTEL(size: GLint, `type`: GLenum, `pointer`: ptr pointer) {.importc.}
  proc glPixelTexGenParameterfvSGIS(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glUniform1iARB(location: GLint, v0: GLint) {.importc.}
  proc glTextureSubImage3DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glStencilOpSeparate(face: GLenum, sfail: GLenum, dpfail: GLenum, dppass: GLenum) {.importc.}
  proc glVertexAttrib1dARB(index: GLuint, x: GLdouble) {.importc.}
  proc glGetVideoCaptureStreamivNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glIsFramebufferEXT(framebuffer: GLuint): GLboolean {.importc.}
  proc glPointParameterxv(pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glProgramUniform4dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glPassThrough(token: GLfloat) {.importc.}
  proc glGetProgramPipelineiv(pipeline: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glApplyTextureEXT(mode: GLenum) {.importc.}
  proc glVertexArrayNormalOffsetEXT(vaobj: GLuint, buffer: GLuint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glTexFilterFuncSGIS(target: GLenum, filter: GLenum, n: GLsizei, weights: ptr GLfloat) {.importc.}
  proc glRenderbufferStorageOES(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glBindParameterEXT(value: GLenum): GLuint {.importc.}
  proc glVertex4s(x: GLshort, y: GLshort, z: GLshort, w: GLshort) {.importc.}
  proc glLoadTransposeMatrixf(m: ptr GLfloat) {.importc.}
  proc glDepthFunc(fun: GLenum) {.importc.}
  proc glGetFramebufferAttachmentParameterivEXT(target: GLenum, attachment: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glSampleMaskSGIS(value: GLclampf, invert: GLboolean) {.importc.}
  proc glGetPointerIndexedvEXT(target: GLenum, index: GLuint, data: ptr pointer) {.importc.}
  proc glVertexStream4iATI(stream: GLenum, x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glUnlockArraysEXT() {.importc.}
  proc glReplacementCodeuivSUN(code: ptr GLuint) {.importc.}
  proc glMatrixScaledEXT(mode: GLenum, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glMultiTexImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glFeedbackBufferxOES(n: GLsizei, `type`: GLenum, buffer: ptr GLfixed) {.importc.}
  proc glLightEnviSGIX(pname: GLenum, param: GLint) {.importc.}
  proc glMultiTexCoord4dARB(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble) {.importc.}
  proc glExtGetTexLevelParameterivQCOM(texture: GLuint, face: GLenum, level: GLint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttribI4usvEXT(index: GLuint, v: ptr GLushort) {.importc.}
  proc glWindowPos2dvARB(v: ptr GLdouble) {.importc.}
  proc glBindFramebuffer(target: GLenum, framebuffer: GLuint) {.importc.}
  proc glGetProgramPipelineivEXT(pipeline: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramUniformHandleui64vNV(program: GLuint, location: GLint, count: GLsizei, values: ptr GLuint64) {.importc.}
  proc glFogCoordhvNV(fog: ptr GLhalfNv) {.importc.}
  proc glTextureImage1DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGetActiveAtomicCounterBufferiv(program: GLuint, bufferIndex: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glBeginQueryARB(target: GLenum, id: GLuint) {.importc.}
  proc glGetTexParameterIuivEXT(target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glUniform4ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glClearAccumxOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed) {.importc.}
  proc glFreeObjectBufferATI(buffer: GLuint) {.importc.}
  proc glGetVideouivNV(video_slot: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glVertexAttribL4ui64NV(index: GLuint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext, w: GLuint64Ext) {.importc.}
  proc glGetUniformBlockIndex(program: GLuint, uniformBlockName: cstring): GLuint {.importc.}
  proc glCopyMultiTexSubImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glVertex3bvOES(coords: ptr GLbyte) {.importc.}
  proc glMultiDrawElementArrayAPPLE(mode: GLenum, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei) {.importc.}
  proc glPrimitiveRestartNV() {.importc.}
  proc glMateriali(face: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glBegin(mode: GLenum) {.importc.}
  proc glFogCoordPointerEXT(`type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glTexCoord1sv(v: ptr GLshort) {.importc.}
  proc glVertexAttribI4sv(index: GLuint, v: ptr GLshort) {.importc.}
  proc glTexEnvx(target: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glTexParameterIivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glLoadTransposeMatrixfARB(m: ptr GLfloat) {.importc.}
  proc glGetTextureSamplerHandleARB(texture: GLuint, sampler: GLuint): GLuint64 {.importc.}
  proc glVertexP3uiv(`type`: GLenum, value: ptr GLuint) {.importc.}
  proc glProgramUniform2dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glTexCoord4xvOES(coords: ptr GLfixed) {.importc.}
  proc glTexStorage1D(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei) {.importc.}
  proc glTextureParameterfEXT(texture: GLuint, target: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glVertexAttrib1d(index: GLuint, x: GLdouble) {.importc.}
  proc glGetnPixelMapfvARB(map: GLenum, bufSize: GLsizei, values: ptr GLfloat) {.importc.}
  proc glDisableVertexAttribArray(index: GLuint) {.importc.}
  proc glUniformMatrix4x3dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glRasterPos4f(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glProgramUniform1fEXT(program: GLuint, location: GLint, v0: GLfloat) {.importc.}
  proc glPathTexGenNV(texCoordSet: GLenum, genMode: GLenum, components: GLint, coeffs: ptr GLfloat) {.importc.}
  proc glUniform3ui(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint) {.importc.}
  proc glVDPAURegisterOutputSurfaceNV(vdpSurface: pointer, target: GLenum, numTextureNames: GLsizei, textureNames: ptr GLuint): GLvdpauSurfaceNv {.importc.}
  proc glGetProgramLocalParameterIuivNV(target: GLenum, index: GLuint, params: ptr GLuint) {.importc.}
  proc glIsTextureHandleResidentNV(handle: GLuint64): GLboolean {.importc.}
  proc glProgramEnvParameters4fvEXT(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLfloat) {.importc.}
  proc glReplacementCodeuiTexCoord2fNormal3fVertex3fSUN(rc: GLuint, s: GLfloat, t: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glGetMultiTexEnvivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetFloatv(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glInsertEventMarkerEXT(length: GLsizei, marker: cstring) {.importc.}
  proc glRasterPos3d(x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glNamedFramebufferRenderbufferEXT(framebuffer: GLuint, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint) {.importc.}
  proc glGetConvolutionFilter(target: GLenum, format: GLenum, `type`: GLenum, image: pointer) {.importc.}
  proc glIsOcclusionQueryNV(id: GLuint): GLboolean {.importc.}
  proc glGetnPixelMapuivARB(map: GLenum, bufSize: GLsizei, values: ptr GLuint) {.importc.}
  proc glMapParameterfvNV(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glPushDebugGroup(source: GLenum, id: GLuint, length: GLsizei, message: cstring) {.importc.}
  proc glMakeImageHandleResidentARB(handle: GLuint64, access: GLenum) {.importc.}
  proc glProgramUniformMatrix2fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glUniform3i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glImageTransformParameteriHP(target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glMultiTexCoord1s(target: GLenum, s: GLshort) {.importc.}
  proc glVertexAttribL4dvEXT(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glGetProgramEnvParameterfvARB(target: GLenum, index: GLuint, params: ptr GLfloat) {.importc.}
  proc glVertexArrayColorOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glGetHistogramParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetRenderbufferParameterivOES(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetBufferPointerv(target: GLenum, pname: GLenum, params: ptr pointer) {.importc.}
  proc glSecondaryColor3ui(red: GLuint, green: GLuint, blue: GLuint) {.importc.}
  proc glGetDebugMessageLog(count: GLuint, bufsize: GLsizei, sources: ptr GLenum, types: ptr GLenum, ids: ptr GLuint, severities: ptr GLenum, lengths: ptr GLsizei, messageLog: cstring): GLuint {.importc.}
  proc glNormal3i(nx: GLint, ny: GLint, nz: GLint) {.importc.}
  proc glTestFenceNV(fence: GLuint): GLboolean {.importc.}
  proc glSecondaryColor3usv(v: ptr GLushort) {.importc.}
  proc glGenPathsNV(range: GLsizei): GLuint {.importc.}
  proc glDeleteBuffersARB(n: GLsizei, buffers: ptr GLuint) {.importc.}
  proc glProgramUniform4fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetSharpenTexFuncSGIS(target: GLenum, points: ptr GLfloat) {.importc.}
  proc glDrawMeshArraysSUN(mode: GLenum, first: GLint, count: GLsizei, width: GLsizei) {.importc.}
  proc glVertexAttribs4hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv) {.importc.}
  proc glGetClipPlane(plane: GLenum, equation: ptr GLdouble) {.importc.}
  proc glEvalCoord2fv(u: ptr GLfloat) {.importc.}
  proc glAsyncMarkerSGIX(marker: GLuint) {.importc.}
  proc glGetSynciv(sync: GLsync, pname: GLenum, bufSize: GLsizei, length: ptr GLsizei, values: ptr GLint) {.importc.}
  proc glGetPathTexGenfvNV(texCoordSet: GLenum, pname: GLenum, value: ptr GLfloat) {.importc.}
  proc glTexParameterf(target: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glMultiTexCoord1fvARB(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glNormalPointerListIBM(`type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint) {.importc.}
  proc glFragmentLightfvSGIX(light: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glViewportArrayv(first: GLuint, count: GLsizei, v: ptr GLfloat) {.importc.}
  proc glNormal3fVertex3fSUN(nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glMultiTexCoord2dvARB(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glCopyColorSubTable(target: GLenum, start: GLsizei, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glTexCoord2hvNV(v: ptr GLhalfNv) {.importc.}
  proc glGetQueryObjectiv(id: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glColor4hNV(red: GLhalfNv, green: GLhalfNv, blue: GLhalfNv, alpha: GLhalfNv) {.importc.}
  proc glProgramUniform2fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glMultiTexCoord4hNV(target: GLenum, s: GLhalfNv, t: GLhalfNv, r: GLhalfNv, q: GLhalfNv) {.importc.}
  proc glWindowPos2fvMESA(v: ptr GLfloat) {.importc.}
  proc glVertexAttrib3s(index: GLuint, x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glGetIntegerIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLint) {.importc.}
  proc glVertexAttrib4Niv(index: GLuint, v: ptr GLint) {.importc.}
  proc glProgramLocalParameter4dvARB(target: GLenum, index: GLuint, params: ptr GLdouble) {.importc.}
  proc glFramebufferTextureLayerEXT(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint) {.importc.}
  proc glVertexAttribI1ui(index: GLuint, x: GLuint) {.importc.}
  proc glFogCoorddv(coord: ptr GLdouble) {.importc.}
  proc glLightModelxv(pname: GLenum, param: ptr GLfixed) {.importc.}
  proc glGetCombinerOutputParameterfvNV(stage: GLenum, portion: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glFramebufferReadBufferEXT(framebuffer: GLuint, mode: GLenum) {.importc.}
  proc glGetActiveUniformsiv(program: GLuint, uniformCount: GLsizei, uniformIndices: ptr GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetProgramStringNV(id: GLuint, pname: GLenum, program: ptr GLubyte) {.importc.}
  proc glCopyConvolutionFilter2D(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glMultiTexCoord3iARB(target: GLenum, s: GLint, t: GLint, r: GLint) {.importc.}
  proc glPushName(name: GLuint) {.importc.}
  proc glProgramParameter4dNV(target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glVertexAttrib4svARB(index: GLuint, v: ptr GLshort) {.importc.}
  proc glSecondaryColor3iv(v: ptr GLint) {.importc.}
  proc glCopyColorSubTableEXT(target: GLenum, start: GLsizei, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glCallList(list: GLuint) {.importc.}
  proc glGetMultiTexLevelParameterivEXT(texunit: GLenum, target: GLenum, level: GLint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramUniformMatrix2x4fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glTexBumpParameterivATI(pname: GLenum, param: ptr GLint) {.importc.}
  proc glTexGeni(coord: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glSecondaryColor3dv(v: ptr GLdouble) {.importc.}
  proc glGetnUniformdvARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLdouble) {.importc.}
  proc glGetNamedProgramLocalParameterdvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLdouble) {.importc.}
  proc glGetVertexAttribPointervARB(index: GLuint, pname: GLenum, `pointer`: ptr pointer) {.importc.}
  proc glCopyColorTable(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glNamedFramebufferTextureLayerEXT(framebuffer: GLuint, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint) {.importc.}
  proc glLoadProgramNV(target: GLenum, id: GLuint, len: GLsizei, program: ptr GLubyte) {.importc.}
  proc glAlphaFragmentOp2ATI(op: GLenum, dst: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint) {.importc.}
  proc glBindLightParameterEXT(light: GLenum, value: GLenum): GLuint {.importc.}
  proc glVertexAttrib1fv(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glLoadIdentity() {.importc.}
  proc glFramebufferTexture2DMultisampleEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, samples: GLsizei) {.importc.}
  proc glVertexAttrib1dvARB(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glDrawRangeElementsBaseVertex(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei, `type`: GLenum, indices: pointer, basevertex: GLint) {.importc.}
  proc glPixelMapfv(map: GLenum, mapsize: GLsizei, values: ptr GLfloat) {.importc.}
  proc glPointParameterxOES(pname: GLenum, param: GLfixed) {.importc.}
  proc glBindBufferRangeNV(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glDepthBoundsEXT(zmin: GLclampd, zmax: GLclampd) {.importc.}
  proc glProgramUniformMatrix2dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glSecondaryColor3s(red: GLshort, green: GLshort, blue: GLshort) {.importc.}
  proc glEdgeFlagPointerEXT(stride: GLsizei, count: GLsizei, `pointer`: ptr GLboolean) {.importc.}
  proc glVertexStream1fATI(stream: GLenum, x: GLfloat) {.importc.}
  proc glUniformui64NV(location: GLint, value: GLuint64Ext) {.importc.}
  proc glTexCoordP4uiv(`type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glTexCoord3d(s: GLdouble, t: GLdouble, r: GLdouble) {.importc.}
  proc glDeleteProgramPipelines(n: GLsizei, pipelines: ptr GLuint) {.importc.}
  proc glVertex2iv(v: ptr GLint) {.importc.}
  proc glGetMultisamplefv(pname: GLenum, index: GLuint, val: ptr GLfloat) {.importc.}
  proc glStartInstrumentsSGIX() {.importc.}
  proc glGetOcclusionQueryivNV(id: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glDebugMessageCallback(callback: GLdebugProc, userParam: ptr pointer) {.importc.}
  proc glPixelZoomxOES(xfactor: GLfixed, yfactor: GLfixed) {.importc.}
  proc glTexCoord3i(s: GLint, t: GLint, r: GLint) {.importc.}
  proc glEdgeFlagFormatNV(stride: GLsizei) {.importc.}
  proc glProgramUniform2i(program: GLuint, location: GLint, v0: GLint, v1: GLint) {.importc.}
  proc glColor3b(red: GLbyte, green: GLbyte, blue: GLbyte) {.importc.}
  proc glDepthRangefOES(n: GLclampf, f: GLclampf) {.importc.}
  proc glEndVertexShaderEXT() {.importc.}
  proc glBindVertexArrayAPPLE(`array`: GLuint) {.importc.}
  proc glColor4bv(v: ptr GLbyte) {.importc.}
  proc glNamedFramebufferTexture2DEXT(framebuffer: GLuint, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glTexCoord1f(s: GLfloat) {.importc.}
  proc glUniform3fvARB(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetQueryObjectuivARB(id: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glVertexAttrib4bv(index: GLuint, v: ptr GLbyte) {.importc.}
  proc glGetPixelTransformParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttrib3svNV(index: GLuint, v: ptr GLshort) {.importc.}
  proc glDeleteQueriesEXT(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glUniform3ivARB(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glNormal3xvOES(coords: ptr GLfixed) {.importc.}
  proc glMatrixLoadfEXT(mode: GLenum, m: ptr GLfloat) {.importc.}
  proc glGetNamedFramebufferAttachmentParameterivEXT(framebuffer: GLuint, attachment: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glSeparableFilter2D(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, row: pointer, column: pointer) {.importc.}
  proc glVertexAttribI3uiv(index: GLuint, v: ptr GLuint) {.importc.}
  proc glTextureStorageSparseAMD(texture: GLuint, target: GLenum, internalFormat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, layers: GLsizei, flags: GLbitfield) {.importc.}
  proc glMultiDrawArraysIndirectCountARB(mode: GLenum, indirect: GLintptr, drawcount: GLintptr, maxdrawcount: GLsizei, stride: GLsizei) {.importc.}
  proc glTranslated(x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glColorPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glDrawElementsInstancedBaseVertex(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, instancecount: GLsizei, basevertex: GLint) {.importc.}
  proc glBindAttribLocationARB(programObj: GLhandleArb, index: GLuint, name: cstring) {.importc.}
  proc glTexGendv(coord: GLenum, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glGetPathCoordsNV(path: GLuint, coords: ptr GLfloat) {.importc.}
  proc glGetMapParameterivNV(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glClientAttribDefaultEXT(mask: GLbitfield) {.importc.}
  proc glProgramUniformMatrix4x3fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glEnable(cap: GLenum) {.importc.}
  proc glGetVertexAttribPointervNV(index: GLuint, pname: GLenum, `pointer`: ptr pointer) {.importc.}
  proc glBindMultiTextureEXT(texunit: GLenum, target: GLenum, texture: GLuint) {.importc.}
  proc glGetConvolutionParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glLightModelxvOES(pname: GLenum, param: ptr GLfixed) {.importc.}
  proc glMultiTexCoord4sv(target: GLenum, v: ptr GLshort) {.importc.}
  proc glGetColorTableParameterivSGI(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glFramebufferTexture2DOES(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glClearDepthxOES(depth: GLfixed) {.importc.}
  proc glDisableClientStateiEXT(`array`: GLenum, index: GLuint) {.importc.}
  proc glWindowPos2dARB(x: GLdouble, y: GLdouble) {.importc.}
  proc glVertexAttrib1fvNV(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glDepthRangedNV(zNear: GLdouble, zFar: GLdouble) {.importc.}
  proc glClear(mask: GLbitfield) {.importc.}
  proc glUnmapTexture2DINTEL(texture: GLuint, level: GLint) {.importc.}
  proc glSecondaryColor3ub(red: GLubyte, green: GLubyte, blue: GLubyte) {.importc.}
  proc glVertexAttribI4bv(index: GLuint, v: ptr GLbyte) {.importc.}
  proc glTexRenderbufferNV(target: GLenum, renderbuffer: GLuint) {.importc.}
  proc glColor4ubVertex3fvSUN(c: ptr GLubyte, v: ptr GLfloat) {.importc.}
  proc glVertexAttrib2svNV(index: GLuint, v: ptr GLshort) {.importc.}
  proc glMultiTexCoord1ivARB(target: GLenum, v: ptr GLint) {.importc.}
  proc glUniformMatrix3x2dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glVertexAttribL3dvEXT(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glMultiTexSubImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGetBufferPointervARB(target: GLenum, pname: GLenum, params: ptr pointer) {.importc.}
  proc glGetMultiTexLevelParameterfvEXT(texunit: GLenum, target: GLenum, level: GLint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glMultiTexParameterIuivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glGetShaderSource(shader: GLuint, bufSize: GLsizei, length: ptr GLsizei, source: cstring) {.importc.}
  proc glStencilFunc(fun: GLenum, `ref`: GLint, mask: GLuint) {.importc.}
  proc glVertexAttribI4bvEXT(index: GLuint, v: ptr GLbyte) {.importc.}
  proc glVertexAttrib4NuivARB(index: GLuint, v: ptr GLuint) {.importc.}
  proc glIsObjectBufferATI(buffer: GLuint): GLboolean {.importc.}
  proc glRasterPos2xOES(x: GLfixed, y: GLfixed) {.importc.}
  proc glIsFenceNV(fence: GLuint): GLboolean {.importc.}
  proc glGetFramebufferParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glClearBufferfv(buffer: GLenum, drawbuffer: GLint, value: ptr GLfloat) {.importc.}
  proc glClearColorxOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed) {.importc.}
  proc glVertexWeightfEXT(weight: GLfloat) {.importc.}
  proc glExtIsProgramBinaryQCOM(program: GLuint): GLboolean {.importc.}
  proc glTextureStorage2DMultisampleEXT(texture: GLuint, target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, fixedsamplelocations: GLboolean) {.importc.}
  proc glGetHistogramParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glVertexAttrib4dNV(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glGetPerfMonitorCounterStringAMD(group: GLuint, counter: GLuint, bufSize: GLsizei, length: ptr GLsizei, counterString: cstring) {.importc.}
  proc glMultiTexCoord2sARB(target: GLenum, s: GLshort, t: GLshort) {.importc.}
  proc glSpriteParameterivSGIX(pname: GLenum, params: ptr GLint) {.importc.}
  proc glCompressedTextureImage3DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glBufferSubData(target: GLenum, offset: GLintptr, size: GLsizeiptr, data: pointer) {.importc.}
  proc glBlendParameteriNV(pname: GLenum, value: GLint) {.importc.}
  proc glVertexAttrib2fvNV(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glGetVariantBooleanvEXT(id: GLuint, value: GLenum, data: ptr GLboolean) {.importc.}
  proc glProgramParameteri(program: GLuint, pname: GLenum, value: GLint) {.importc.}
  proc glGetLocalConstantIntegervEXT(id: GLuint, value: GLenum, data: ptr GLint) {.importc.}
  proc glFragmentMaterialiSGIX(face: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glGetNamedStringivARB(namelen: GLint, name: cstring, pname: GLenum, params: ptr GLint) {.importc.}
  proc glBinormal3ivEXT(v: ptr GLint) {.importc.}
  proc glCheckFramebufferStatusEXT(target: GLenum): GLenum {.importc.}
  proc glVertexAttrib1fNV(index: GLuint, x: GLfloat) {.importc.}
  proc glNamedRenderbufferStorageEXT(renderbuffer: GLuint, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glPresentFrameKeyedNV(video_slot: GLuint, minPresentTime: GLuint64Ext, beginPresentTimeId: GLuint, presentDurationId: GLuint, `type`: GLenum, target0: GLenum, fill0: GLuint, key0: GLuint, target1: GLenum, fill1: GLuint, key1: GLuint) {.importc.}
  proc glGetObjectParameterfvARB(obj: GLhandleArb, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertex3sv(v: ptr GLshort) {.importc.}
  proc glColor4s(red: GLshort, green: GLshort, blue: GLshort, alpha: GLshort) {.importc.}
  proc glGetQueryObjecti64vEXT(id: GLuint, pname: GLenum, params: ptr GLint64) {.importc.}
  proc glEvalMesh2(mode: GLenum, i1: GLint, i2: GLint, j1: GLint, j2: GLint) {.importc.}
  proc glBeginTransformFeedbackEXT(primitiveMode: GLenum) {.importc.}
  proc glBufferAddressRangeNV(pname: GLenum, index: GLuint, address: GLuint64Ext, length: GLsizeiptr) {.importc.}
  proc glPointParameterfvARB(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetActiveVaryingNV(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLsizei, `type`: ptr GLenum, name: cstring) {.importc.}
  proc glIndexMask(mask: GLuint) {.importc.}
  proc glVertexAttribBinding(attribindex: GLuint, bindingindex: GLuint) {.importc.}
  proc glDeleteFencesNV(n: GLsizei, fences: ptr GLuint) {.importc.}
  proc glVertexAttribI4ubv(index: GLuint, v: ptr GLubyte) {.importc.}
  proc glPathParameterfvNV(path: GLuint, pname: GLenum, value: ptr GLfloat) {.importc.}
  proc glVertexStream3fATI(stream: GLenum, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glVertexAttribs4svNV(index: GLuint, count: GLsizei, v: ptr GLshort) {.importc.}
  proc glVertexAttrib4sNV(index: GLuint, x: GLshort, y: GLshort, z: GLshort, w: GLshort) {.importc.}
  proc glAlphaFragmentOp3ATI(op: GLenum, dst: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint, arg3: GLuint, arg3Rep: GLuint, arg3Mod: GLuint) {.importc.}
  proc glGetHistogramParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexAttribL1ui64NV(index: GLuint, x: GLuint64Ext) {.importc.}
  proc glVertexAttribs3fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat) {.importc.}
  proc glMultiTexCoord3ivARB(target: GLenum, v: ptr GLint) {.importc.}
  proc glClipPlanefOES(plane: GLenum, equation: ptr GLfloat) {.importc.}
  proc glVertex3s(x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glVertex3dv(v: ptr GLdouble) {.importc.}
  proc glWeightPointerOES(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glBindBufferBase(target: GLenum, index: GLuint, buffer: GLuint) {.importc.}
  proc glIndexs(c: GLshort) {.importc.}
  proc glTessellationFactorAMD(factor: GLfloat) {.importc.}
  proc glColor4ubVertex3fSUN(r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glPauseTransformFeedback() {.importc.}
  proc glImageTransformParameterivHP(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glColor3dv(v: ptr GLdouble) {.importc.}
  proc glRasterPos4sv(v: ptr GLshort) {.importc.}
  proc glInvalidateTexSubImage(texture: GLuint, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei) {.importc.}
  proc glNormalStream3bvATI(stream: GLenum, coords: ptr GLbyte) {.importc.}
  proc glUniformMatrix2x4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glMinmax(target: GLenum, internalformat: GLenum, sink: GLboolean) {.importc.}
  proc glGetProgramStageiv(program: GLuint, shadertype: GLenum, pname: GLenum, values: ptr GLint) {.importc.}
  proc glScalex(x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glTexBufferARB(target: GLenum, internalformat: GLenum, buffer: GLuint) {.importc.}
  proc glDrawArraysIndirect(mode: GLenum, indirect: pointer) {.importc.}
  proc glMatrixLoadTransposefEXT(mode: GLenum, m: ptr GLfloat) {.importc.}
  proc glMultiTexCoord2f(target: GLenum, s: GLfloat, t: GLfloat) {.importc.}
  proc glDrawRangeElements(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei, `type`: GLenum, indices: pointer) {.importc.}
  proc glVertexAttrib4NubARB(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte, w: GLubyte) {.importc.}
  proc glMultiTexCoord4xvOES(texture: GLenum, coords: ptr GLfixed) {.importc.}
  proc glVertexArrayVertexAttribOffsetEXT(vaobj: GLuint, buffer: GLuint, index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glVertexAttribL1i64vNV(index: GLuint, v: ptr GLint64Ext) {.importc.}
  proc glMapBuffer(target: GLenum, access: GLenum) {.importc.}
  proc glUniform1ui(location: GLint, v0: GLuint) {.importc.}
  proc glGetPixelMapfv(map: GLenum, values: ptr GLfloat) {.importc.}
  proc glTexImage2DMultisampleCoverageNV(target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, fixedSampleLocations: GLboolean) {.importc.}
  proc glUniform2ivARB(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glVertexAttribI3ui(index: GLuint, x: GLuint, y: GLuint, z: GLuint) {.importc.}
  proc glGetProgramResourceiv(program: GLuint, programInterface: GLenum, index: GLuint, propCount: GLsizei, props: ptr GLenum, bufSize: GLsizei, length: ptr GLsizei, params: ptr GLint) {.importc.}
  proc glUniform4iv(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glVertexAttrib3f(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glClientActiveVertexStreamATI(stream: GLenum) {.importc.}
  proc glTexCoord4fColor4fNormal3fVertex4fvSUN(tc: ptr GLfloat, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glColor3xvOES(components: ptr GLfixed) {.importc.}
  proc glVertexPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint) {.importc.}
  proc glProgramEnvParameter4dARB(target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glGetLocalConstantFloatvEXT(id: GLuint, value: GLenum, data: ptr GLfloat) {.importc.}
  proc glTexCoordPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer) {.importc.}
  proc glTexCoordPointervINTEL(size: GLint, `type`: GLenum, `pointer`: ptr pointer) {.importc.}
  proc glSelectPerfMonitorCountersAMD(monitor: GLuint, enable: GLboolean, group: GLuint, numCounters: GLint, counterList: ptr GLuint) {.importc.}
  proc glVertexStream4svATI(stream: GLenum, coords: ptr GLshort) {.importc.}
  proc glColor3ui(red: GLuint, green: GLuint, blue: GLuint) {.importc.}
  proc glBindTransformFeedbackNV(target: GLenum, id: GLuint) {.importc.}
  proc glDeformSGIX(mask: GLbitfield) {.importc.}
  proc glDeformationMap3fSGIX(target: GLenum, u1: GLfloat, u2: GLfloat, ustride: GLint, uorder: GLint, v1: GLfloat, v2: GLfloat, vstride: GLint, vorder: GLint, w1: GLfloat, w2: GLfloat, wstride: GLint, worder: GLint, points: ptr GLfloat) {.importc.}
  proc glNamedBufferSubDataEXT(buffer: GLuint, offset: GLintptr, size: GLsizeiptr, data: pointer) {.importc.}
  proc glGetNamedProgramStringEXT(program: GLuint, target: GLenum, pname: GLenum, string: pointer) {.importc.}
  proc glCopyPathNV(resultPath: GLuint, srcPath: GLuint) {.importc.}
  proc glMapControlPointsNV(target: GLenum, index: GLuint, `type`: GLenum, ustride: GLsizei, vstride: GLsizei, uorder: GLint, vorder: GLint, packed: GLboolean, points: pointer) {.importc.}
  proc glGetBufferParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glUnmapObjectBufferATI(buffer: GLuint) {.importc.}
  proc glGetProgramResourceLocation(program: GLuint, programInterface: GLenum, name: cstring): GLint {.importc.}
  proc glUniform4i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glImageTransformParameterfHP(target: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glArrayObjectATI(`array`: GLenum, size: GLint, `type`: GLenum, stride: GLsizei, buffer: GLuint, offset: GLuint) {.importc.}
  proc glBindBufferRangeEXT(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glVertexArrayVertexAttribFormatEXT(vaobj: GLuint, attribindex: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, relativeoffset: GLuint) {.importc.}
  proc glBindRenderbufferEXT(target: GLenum, renderbuffer: GLuint) {.importc.}
  proc glListParameteriSGIX(list: GLuint, pname: GLenum, param: GLint) {.importc.}
  proc glProgramUniformMatrix2dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glProgramUniform2i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glObjectPtrLabelKHR(`ptr`: ptr pointer, length: GLsizei, label: cstring) {.importc.}
  proc glVertexAttribL1i64NV(index: GLuint, x: GLint64Ext) {.importc.}
  proc glMultiTexBufferEXT(texunit: GLenum, target: GLenum, internalformat: GLenum, buffer: GLuint) {.importc.}
  proc glCoverFillPathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, coverMode: GLenum, transformType: GLenum, transformValues: ptr GLfloat) {.importc.}
  proc glGetVertexAttribIivEXT(index: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glLightf(light: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glGetMinmaxParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glUniform1d(location: GLint, x: GLdouble) {.importc.}
  proc glLightiv(light: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttrib2dvNV(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glNormalP3ui(`type`: GLenum, coords: GLuint) {.importc.}
  proc glFinalCombinerInputNV(variable: GLenum, input: GLenum, mapping: GLenum, componentUsage: GLenum) {.importc.}
  proc glUniform1uiv(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glValidateProgramARB(programObj: GLhandleArb) {.importc.}
  proc glNormalPointer(`type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glProgramNamedParameter4fvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, v: ptr GLfloat) {.importc.}
  proc glGetBooleanv(pname: GLenum, params: ptr GLboolean) {.importc.}
  proc glTangent3ivEXT(v: ptr GLint) {.importc.}
  proc glTexImage3DMultisample(target: GLenum, samples: GLsizei, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedsamplelocations: GLboolean) {.importc.}
  proc glGetUniformIndices(program: GLuint, uniformCount: GLsizei, uniformNames: cstringArray, uniformIndices: ptr GLuint) {.importc.}
  proc glVDPAUInitNV(vdpDevice: pointer, getProcAddress: pointer) {.importc.}
  proc glGetMinmaxParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMultiTexCoord2fvARB(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glProgramEnvParametersI4ivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLint) {.importc.}
  proc glClearTexSubImage(texture: GLuint, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, data: ptr pointer) {.importc.}
  proc glRectxOES(x1: GLfixed, y1: GLfixed, x2: GLfixed, y2: GLfixed) {.importc.}
  proc glBlendEquationOES(mode: GLenum) {.importc.}
  proc glFramebufferTexture(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glGetInstrumentsSGIX(): GLint {.importc.}
  proc glFramebufferParameteri(target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glPathCoverDepthFuncNV(fun: GLenum) {.importc.}
  proc glGetTranslatedShaderSourceANGLE(shader: GLuint, bufsize: GLsizei, length: ptr GLsizei, source: cstring) {.importc.}
  proc glIndexfv(c: ptr GLfloat) {.importc.}
  proc glGetActiveUniformBlockName(program: GLuint, uniformBlockIndex: GLuint, bufSize: GLsizei, length: ptr GLsizei, uniformBlockName: cstring) {.importc.}
  proc glNormal3s(nx: GLshort, ny: GLshort, nz: GLshort) {.importc.}
  proc glColorFragmentOp3ATI(op: GLenum, dst: GLuint, dstMask: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint, arg3: GLuint, arg3Rep: GLuint, arg3Mod: GLuint) {.importc.}
  proc glGetProgramResourceLocationIndex(program: GLuint, programInterface: GLenum, name: cstring): GLint {.importc.}
  proc glGetBooleanIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLboolean) {.importc.}
  proc glGenPerfMonitorsAMD(n: GLsizei, monitors: ptr GLuint) {.importc.}
  proc glDrawRangeElementsEXT(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei, `type`: GLenum, indices: pointer) {.importc.}
  proc glFramebufferTexture3D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint) {.importc.}
  proc glGetTexParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glCompileShaderIncludeARB(shader: GLuint, count: GLsizei, path: cstringArray, length: ptr GLint) {.importc.}
  proc glGetMultiTexParameterfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glEvalPoint2(i: GLint, j: GLint) {.importc.}
  proc glGetProgramivNV(id: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramParameter4fNV(target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glMultiTexParameterfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexAttrib3svARB(index: GLuint, v: ptr GLshort) {.importc.}
  proc glDrawElementArrayAPPLE(mode: GLenum, first: GLint, count: GLsizei) {.importc.}
  proc glMultiTexCoord4x(texture: GLenum, s: GLfixed, t: GLfixed, r: GLfixed, q: GLfixed) {.importc.}
  proc glUniformMatrix3dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glVertexAttribPointerARB(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glProgramUniformMatrix3x4dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glGetFloati_vEXT(pname: GLenum, index: GLuint, params: ptr GLfloat) {.importc.}
  proc glGetObjectParameterivAPPLE(objectType: GLenum, name: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glPushGroupMarkerEXT(length: GLsizei, marker: cstring) {.importc.}
  proc glProgramUniform4uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glReplacementCodeuiVertex3fSUN(rc: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glTexSubImage1DEXT(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glProgramUniform1uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glGetFenceivNV(fence: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetnCompressedTexImageARB(target: GLenum, lod: GLint, bufSize: GLsizei, img: pointer) {.importc.}
  proc glTexGenfOES(coord: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glVertexAttrib4dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glVertexAttribL1ui64vNV(index: GLuint, v: ptr GLuint64Ext) {.importc.}
  proc glVertexAttrib4fvARB(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glDeleteVertexArraysOES(n: GLsizei, arrays: ptr GLuint) {.importc.}
  proc glSamplerParameterIiv(sampler: GLuint, pname: GLenum, param: ptr GLint) {.importc.}
  proc glMapGrid1d(un: GLint, u1: GLdouble, u2: GLdouble) {.importc.}
  proc glTranslatexOES(x: GLfixed, y: GLfixed, z: GLfixed) {.importc.}
  proc glCullFace(mode: GLenum) {.importc.}
  proc glPrioritizeTextures(n: GLsizei, textures: ptr GLuint, priorities: ptr GLfloat) {.importc.}
  proc glGetSeparableFilterEXT(target: GLenum, format: GLenum, `type`: GLenum, row: pointer, column: pointer, span: pointer) {.importc.}
  proc glVertexAttrib4NubvARB(index: GLuint, v: ptr GLubyte) {.importc.}
  proc glGetTransformFeedbackVaryingNV(program: GLuint, index: GLuint, location: ptr GLint) {.importc.}
  proc glTexCoord4xOES(s: GLfixed, t: GLfixed, r: GLfixed, q: GLfixed) {.importc.}
  proc glGetProgramEnvParameterdvARB(target: GLenum, index: GLuint, params: ptr GLdouble) {.importc.}
  proc glWindowPos2ivMESA(v: ptr GLint) {.importc.}
  proc glGlobalAlphaFactorfSUN(factor: GLfloat) {.importc.}
  proc glNormalStream3fvATI(stream: GLenum, coords: ptr GLfloat) {.importc.}
  proc glRasterPos4i(x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glReleaseShaderCompiler() {.importc.}
  proc glProgramUniformMatrix4fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glCopyMultiTexImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint) {.importc.}
  proc glColorTableParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glSecondaryColor3bvEXT(v: ptr GLbyte) {.importc.}
  proc glMap1xOES(target: GLenum, u1: GLfixed, u2: GLfixed, stride: GLint, order: GLint, points: GLfixed) {.importc.}
  proc glVertexStream1svATI(stream: GLenum, coords: ptr GLshort) {.importc.}
  proc glIsRenderbuffer(renderbuffer: GLuint): GLboolean {.importc.}
  proc glPatchParameterfv(pname: GLenum, values: ptr GLfloat) {.importc.}
  proc glProgramUniformMatrix4dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glVertexAttrib4ubNV(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte, w: GLubyte) {.importc.}
  proc glVertex2i(x: GLint, y: GLint) {.importc.}
  proc glPushClientAttrib(mask: GLbitfield) {.importc.}
  proc glDrawArraysEXT(mode: GLenum, first: GLint, count: GLsizei) {.importc.}
  proc glCreateProgram(): GLuint {.importc.}
  proc glPolygonStipple(mask: ptr GLubyte) {.importc.}
  proc glGetColorTableEXT(target: GLenum, format: GLenum, `type`: GLenum, data: pointer) {.importc.}
  proc glSharpenTexFuncSGIS(target: GLenum, n: GLsizei, points: ptr GLfloat) {.importc.}
  proc glNamedFramebufferTextureEXT(framebuffer: GLuint, attachment: GLenum, texture: GLuint, level: GLint) {.importc.}
  proc glWindowPos3fvMESA(v: ptr GLfloat) {.importc.}
  proc glBinormal3iEXT(bx: GLint, by: GLint, bz: GLint) {.importc.}
  proc glEnableClientStateiEXT(`array`: GLenum, index: GLuint) {.importc.}
  proc glProgramUniform3iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glProgramUniform1dEXT(program: GLuint, location: GLint, x: GLdouble) {.importc.}
  proc glPollInstrumentsSGIX(marker_p: ptr GLint): GLint {.importc.}
  proc glSecondaryColor3f(red: GLfloat, green: GLfloat, blue: GLfloat) {.importc.}
  proc glDeleteTransformFeedbacks(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glCoverStrokePathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, coverMode: GLenum, transformType: GLenum, transformValues: ptr GLfloat) {.importc.}
  proc glIsTextureHandleResidentARB(handle: GLuint64): GLboolean {.importc.}
  proc glVariantsvEXT(id: GLuint, `addr`: ptr GLshort) {.importc.}
  proc glTexCoordFormatNV(size: GLint, `type`: GLenum, stride: GLsizei) {.importc.}
  proc glTexStorage3DEXT(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei) {.importc.}
  proc glUniform2ui(location: GLint, v0: GLuint, v1: GLuint) {.importc.}
  proc glReplacementCodePointerSUN(`type`: GLenum, stride: GLsizei, `pointer`: ptr pointer) {.importc.}
  proc glFramebufferTextureLayerARB(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint) {.importc.}
  proc glBinormal3dvEXT(v: ptr GLdouble) {.importc.}
  proc glProgramUniform2ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glGetnConvolutionFilterARB(target: GLenum, format: GLenum, `type`: GLenum, bufSize: GLsizei, image: pointer) {.importc.}
  proc glStopInstrumentsSGIX(marker: GLint) {.importc.}
  proc glVertexAttrib1svNV(index: GLuint, v: ptr GLshort) {.importc.}
  proc glVertexAttribs2fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat) {.importc.}
  proc glGetInternalformativ(target: GLenum, internalformat: GLenum, pname: GLenum, bufSize: GLsizei, params: ptr GLint) {.importc.}
  proc glIsProgramPipelineEXT(pipeline: GLuint): GLboolean {.importc.}
  proc glMatrixIndexubvARB(size: GLint, indices: ptr GLubyte) {.importc.}
  proc glTexCoord4bOES(s: GLbyte, t: GLbyte, r: GLbyte, q: GLbyte) {.importc.}
  proc glSecondaryColor3us(red: GLushort, green: GLushort, blue: GLushort) {.importc.}
  proc glGlobalAlphaFactorubSUN(factor: GLubyte) {.importc.}
  proc glNamedStringARB(`type`: GLenum, namelen: GLint, name: cstring, stringlen: GLint, string: cstring) {.importc.}
  proc glGetAttachedShaders(program: GLuint, maxCount: GLsizei, count: ptr GLsizei, shaders: ptr GLuint) {.importc.}
  proc glMatrixRotatefEXT(mode: GLenum, angle: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glVertexStream3ivATI(stream: GLenum, coords: ptr GLint) {.importc.}
  proc glMatrixIndexuivARB(size: GLint, indices: ptr GLuint) {.importc.}
  proc glMatrixRotatedEXT(mode: GLenum, angle: GLdouble, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glPathFogGenNV(genMode: GLenum) {.importc.}
  proc glMultiTexCoord4hvNV(target: GLenum, v: ptr GLhalfNv) {.importc.}
  proc glVertexAttribIPointer(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glMultiTexCoord3bOES(texture: GLenum, s: GLbyte, t: GLbyte, r: GLbyte) {.importc.}
  proc glResizeBuffersMESA() {.importc.}
  proc glPrimitiveRestartIndexNV(index: GLuint) {.importc.}
  proc glProgramUniform4f(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) {.importc.}
  proc glColor4ubVertex2fSUN(r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat) {.importc.}
  proc glGetColorTableParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glDepthRangef(n: GLfloat, f: GLfloat) {.importc.}
  proc glVertexArrayVertexOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glMatrixLoaddEXT(mode: GLenum, m: ptr GLdouble) {.importc.}
  proc glVariantfvEXT(id: GLuint, `addr`: ptr GLfloat) {.importc.}
  proc glReplacementCodeuiTexCoord2fVertex3fvSUN(rc: ptr GLuint, tc: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glSamplePatternSGIS(pattern: GLenum) {.importc.}
  proc glProgramUniform3i64NV(program: GLuint, location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext) {.importc.}
  proc glUniform3uivEXT(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glGetImageTransformParameterivHP(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glPopMatrix() {.importc.}
  proc glVertexAttrib3sARB(index: GLuint, x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glGenQueriesEXT(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glGetQueryObjectui64v(id: GLuint, pname: GLenum, params: ptr GLuint64) {.importc.}
  proc glWeightusvARB(size: GLint, weights: ptr GLushort) {.importc.}
  proc glWindowPos2sARB(x: GLshort, y: GLshort) {.importc.}
  proc glGetTextureLevelParameterivEXT(texture: GLuint, target: GLenum, level: GLint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glBufferParameteriAPPLE(target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glMultiModeDrawArraysIBM(mode: ptr GLenum, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei, modestride: GLint) {.importc.}
  proc glUniformMatrix2x3fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat) {.importc.}
  proc glTangentPointerEXT(`type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glResetMinmax(target: GLenum) {.importc.}
  proc glVertexAttribP1uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint) {.importc.}
  proc glPixelMapx(map: GLenum, size: GLint, values: ptr GLfixed) {.importc.}
  proc glPixelStoref(pname: GLenum, param: GLfloat) {.importc.}
  proc glBinormal3dEXT(bx: GLdouble, by: GLdouble, bz: GLdouble) {.importc.}
  proc glVertexAttribs1hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv) {.importc.}
  proc glVertexAttrib4usvARB(index: GLuint, v: ptr GLushort) {.importc.}
  proc glUnmapBuffer(target: GLenum): GLboolean {.importc.}
  proc glFlushRasterSGIX() {.importc.}
  proc glColor3uiv(v: ptr GLuint) {.importc.}
  proc glInvalidateBufferSubData(buffer: GLuint, offset: GLintptr, length: GLsizeiptr) {.importc.}
  proc glPassThroughxOES(token: GLfixed) {.importc.}
  proc glLockArraysEXT(first: GLint, count: GLsizei) {.importc.}
  proc glStencilFuncSeparateATI(frontfunc: GLenum, backfunc: GLenum, `ref`: GLint, mask: GLuint) {.importc.}
  proc glProgramUniform3dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glGenTransformFeedbacks(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glCopyTexSubImage3DOES(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glIsNamedBufferResidentNV(buffer: GLuint): GLboolean {.importc.}
  proc glSampleMaskIndexedNV(index: GLuint, mask: GLbitfield) {.importc.}
  proc glVDPAUSurfaceAccessNV(surface: GLvdpauSurfaceNv, access: GLenum) {.importc.}
  proc glProgramUniform3dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble) {.importc.}
  proc glDeleteProgram(program: GLuint) {.importc.}
  proc glConvolutionFilter1D(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, image: pointer) {.importc.}
  proc glVertex2f(x: GLfloat, y: GLfloat) {.importc.}
  proc glWindowPos4dvMESA(v: ptr GLdouble) {.importc.}
  proc glColor4us(red: GLushort, green: GLushort, blue: GLushort, alpha: GLushort) {.importc.}
  proc glColorMask(red: GLboolean, green: GLboolean, blue: GLboolean, alpha: GLboolean) {.importc.}
  proc glGetTexEnviv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glProgramUniform3ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glSecondaryColor3i(red: GLint, green: GLint, blue: GLint) {.importc.}
  proc glGetSamplerParameteriv(sampler: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glDeleteFramebuffersEXT(n: GLsizei, framebuffers: ptr GLuint) {.importc.}
  proc glCompressedTexSubImage3D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.importc.}
  proc glVertex2s(x: GLshort, y: GLshort) {.importc.}
  proc glIsQuery(id: GLuint): GLboolean {.importc.}
  proc glFogxv(pname: GLenum, param: ptr GLfixed) {.importc.}
  proc glAreProgramsResidentNV(n: GLsizei, programs: ptr GLuint, residences: ptr GLboolean): GLboolean {.importc.}
  proc glShaderSourceARB(shaderObj: GLhandleArb, count: GLsizei, string: cstringArray, length: ptr GLint) {.importc.}
  proc glPointSizexOES(size: GLfixed) {.importc.}
  proc glPixelTransferf(pname: GLenum, param: GLfloat) {.importc.}
  proc glExtractComponentEXT(res: GLuint, src: GLuint, num: GLuint) {.importc.}
  proc glUniform1fv(location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetNamedStringARB(namelen: GLint, name: cstring, bufSize: GLsizei, stringlen: ptr GLint, string: cstring) {.importc.}
  proc glGetProgramBinaryOES(program: GLuint, bufSize: GLsizei, length: ptr GLsizei, binaryFormat: ptr GLenum, binary: pointer) {.importc.}
  proc glDeleteOcclusionQueriesNV(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glEnableClientState(`array`: GLenum) {.importc.}
  proc glProgramBufferParametersIuivNV(target: GLenum, bindingIndex: GLuint, wordIndex: GLuint, count: GLsizei, params: ptr GLuint) {.importc.}
  proc glProgramUniform2ui(program: GLuint, location: GLint, v0: GLuint, v1: GLuint) {.importc.}
  proc glReplacementCodeuiSUN(code: GLuint) {.importc.}
  proc glMultMatrixd(m: ptr GLdouble) {.importc.}
  proc glInvalidateSubFramebuffer(target: GLenum, numAttachments: GLsizei, attachments: ptr GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glGenerateMultiTexMipmapEXT(texunit: GLenum, target: GLenum) {.importc.}
  proc glDepthRangex(n: GLfixed, f: GLfixed) {.importc.}
  proc glGetInteger64i_v(target: GLenum, index: GLuint, data: ptr GLint64) {.importc.}
  proc glDrawBuffers(n: GLsizei, bufs: ptr GLenum) {.importc.}
  proc glGetPointervEXT(pname: GLenum, params: ptr pointer) {.importc.}
  proc glFogxvOES(pname: GLenum, param: ptr GLfixed) {.importc.}
  proc glTexCoordP2uiv(`type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glVertexFormatNV(size: GLint, `type`: GLenum, stride: GLsizei) {.importc.}
  proc glColorPointervINTEL(size: GLint, `type`: GLenum, `pointer`: ptr pointer) {.importc.}
  proc glGetMultiTexParameterivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMultiTexCoordP4uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint) {.importc.}
  proc glResetMinmaxEXT(target: GLenum) {.importc.}
  proc glCopyBufferSubData(readTarget: GLenum, writeTarget: GLenum, readOffset: GLintptr, writeOffset: GLintptr, size: GLsizeiptr) {.importc.}
  proc glSecondaryColor3sv(v: ptr GLshort) {.importc.}
  proc glPixelStorex(pname: GLenum, param: GLfixed) {.importc.}
  proc glWaitSync(sync: GLsync, flags: GLbitfield, timeout: GLuint64) {.importc.}
  proc glVertexAttribI1iv(index: GLuint, v: ptr GLint) {.importc.}
  proc glColorSubTableEXT(target: GLenum, start: GLsizei, count: GLsizei, format: GLenum, `type`: GLenum, data: pointer) {.importc.}
  proc glGetDoublev(pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glMultiTexParameterivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMultiTexCoord4svARB(target: GLenum, v: ptr GLshort) {.importc.}
  proc glColorPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint) {.importc.}
  proc glScissorIndexed(index: GLuint, left: GLint, bottom: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glStencilOpSeparateATI(face: GLenum, sfail: GLenum, dpfail: GLenum, dppass: GLenum) {.importc.}
  proc glLoadName(name: GLuint) {.importc.}
  proc glIsTransformFeedbackNV(id: GLuint): GLboolean {.importc.}
  proc glPopDebugGroup() {.importc.}
  proc glClipPlanef(p: GLenum, eqn: ptr GLfloat) {.importc.}
  proc glDeleteFencesAPPLE(n: GLsizei, fences: ptr GLuint) {.importc.}
  proc glGetQueryObjecti64v(id: GLuint, pname: GLenum, params: ptr GLint64) {.importc.}
  proc glAlphaFunc(fun: GLenum, `ref`: GLfloat) {.importc.}
  proc glIndexPointerEXT(`type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer) {.importc.}
  proc glVertexAttribI3ivEXT(index: GLuint, v: ptr GLint) {.importc.}
  proc glIndexub(c: GLubyte) {.importc.}
  proc glVertexP2uiv(`type`: GLenum, value: ptr GLuint) {.importc.}
  proc glProgramUniform1uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glDebugMessageInsertKHR(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum, length: GLsizei, buf: cstring) {.importc.}
  proc glColor4b(red: GLbyte, green: GLbyte, blue: GLbyte, alpha: GLbyte) {.importc.}
  proc glRenderbufferStorageMultisampleAPPLE(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glMinSampleShading(value: GLfloat) {.importc.}
  proc glBindProgramNV(target: GLenum, id: GLuint) {.importc.}
  proc glWindowPos3dMESA(x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glEdgeFlagPointer(stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glGetFragDataIndex(program: GLuint, name: cstring): GLint {.importc.}
  proc glTexCoord3hNV(s: GLhalfNv, t: GLhalfNv, r: GLhalfNv) {.importc.}
  proc glMultiDrawArraysIndirectAMD(mode: GLenum, indirect: pointer, primcount: GLsizei, stride: GLsizei) {.importc.}
  proc glFragmentColorMaterialSGIX(face: GLenum, mode: GLenum) {.importc.}
  proc glTexGenf(coord: GLenum, pname: GLenum, param: GLfloat) {.importc.}
  proc glVertexAttrib4ubvARB(index: GLuint, v: ptr GLubyte) {.importc.}
  proc glClearBufferiv(buffer: GLenum, drawbuffer: GLint, value: ptr GLint) {.importc.}
  proc glGenQueriesARB(n: GLsizei, ids: ptr GLuint) {.importc.}
  proc glRectdv(v1: ptr GLdouble, v2: ptr GLdouble) {.importc.}
  proc glBlendEquationSeparateEXT(modeRgb: GLenum, modeAlpha: GLenum) {.importc.}
  proc glTestFenceAPPLE(fence: GLuint): GLboolean {.importc.}
  proc glTexGeniv(coord: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glPolygonMode(face: GLenum, mode: GLenum) {.importc.}
  proc glFrameZoomSGIX(factor: GLint) {.importc.}
  proc glReplacementCodeuiTexCoord2fVertex3fSUN(rc: GLuint, s: GLfloat, t: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glUniformSubroutinesuiv(shadertype: GLenum, count: GLsizei, indices: ptr GLuint) {.importc.}
  proc glBeginQueryIndexed(target: GLenum, index: GLuint, id: GLuint) {.importc.}
  proc glMultiTexGeniEXT(texunit: GLenum, coord: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glRasterPos3fv(v: ptr GLfloat) {.importc.}
  proc glMapObjectBufferATI(buffer: GLuint) {.importc.}
  proc glIndexiv(c: ptr GLint) {.importc.}
  proc glVertexAttribLPointer(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glMultiTexCoord4s(target: GLenum, s: GLshort, t: GLshort, r: GLshort, q: GLshort) {.importc.}
  proc glSecondaryColorP3uiv(`type`: GLenum, color: ptr GLuint) {.importc.}
  proc glNormalFormatNV(`type`: GLenum, stride: GLsizei) {.importc.}
  proc glVertex4i(x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glUniform1ui64NV(location: GLint, x: GLuint64Ext) {.importc.}
  proc glScissorIndexedv(index: GLuint, v: ptr GLint) {.importc.}
  proc glProgramUniform1i(program: GLuint, location: GLint, v0: GLint) {.importc.}
  proc glCompressedMultiTexSubImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glFinishTextureSUNX() {.importc.}
  proc glFramebufferTexture3DEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint) {.importc.}
  proc glSetInvariantEXT(id: GLuint, `type`: GLenum, `addr`: pointer) {.importc.}
  proc glGetTexParameterIivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMultiTexCoordP3ui(texture: GLenum, `type`: GLenum, coords: GLuint) {.importc.}
  proc glMultiTexCoord3f(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat) {.importc.}
  proc glNormalStream3fATI(stream: GLenum, nx: GLfloat, ny: GLfloat, nz: GLfloat) {.importc.}
  proc glActiveShaderProgram(pipeline: GLuint, program: GLuint) {.importc.}
  proc glDisableVertexArrayEXT(vaobj: GLuint, `array`: GLenum) {.importc.}
  proc glVertexAttribI3iv(index: GLuint, v: ptr GLint) {.importc.}
  proc glProvokingVertex(mode: GLenum) {.importc.}
  proc glTexCoord1fv(v: ptr GLfloat) {.importc.}
  proc glVertexAttrib3fv(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glWindowPos3iv(v: ptr GLint) {.importc.}
  proc glProgramUniform4ui64NV(program: GLuint, location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext, w: GLuint64Ext) {.importc.}
  proc glProgramUniform2d(program: GLuint, location: GLint, v0: GLdouble, v1: GLdouble) {.importc.}
  proc glDebugMessageInsertARB(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum, length: GLsizei, buf: cstring) {.importc.}
  proc glMultiTexSubImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glMap1d(target: GLenum, u1: GLdouble, u2: GLdouble, stride: GLint, order: GLint, points: ptr GLdouble) {.importc.}
  proc glDeleteShader(shader: GLuint) {.importc.}
  proc glTexturePageCommitmentEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, resident: GLboolean) {.importc.}
  proc glFramebufferDrawBufferEXT(framebuffer: GLuint, mode: GLenum) {.importc.}
  proc glTexCoord2fNormal3fVertex3fSUN(s: GLfloat, t: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glDeleteProgramsNV(n: GLsizei, programs: ptr GLuint) {.importc.}
  proc glPointAlongPathNV(path: GLuint, startSegment: GLsizei, numSegments: GLsizei, distance: GLfloat, x: ptr GLfloat, y: ptr GLfloat, tangentX: ptr GLfloat, tangentY: ptr GLfloat): GLboolean {.importc.}
  proc glTexCoord1d(s: GLdouble) {.importc.}
  proc glStencilStrokePathNV(path: GLuint, reference: GLint, mask: GLuint) {.importc.}
  proc glQueryMatrixxOES(mantissa: ptr GLfixed, exponent: ptr GLint): GLbitfield {.importc.}
  proc glGetNamedProgramLocalParameterIuivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLuint) {.importc.}
  proc glGenerateMipmapOES(target: GLenum) {.importc.}
  proc glRenderbufferStorageMultisampleIMG(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glVertexBlendEnviATI(pname: GLenum, param: GLint) {.importc.}
  proc glPushAttrib(mask: GLbitfield) {.importc.}
  proc glShaderOp3EXT(op: GLenum, res: GLuint, arg1: GLuint, arg2: GLuint, arg3: GLuint) {.importc.}
  proc glEnableVertexAttribArray(index: GLuint) {.importc.}
  proc glVertexAttrib4Nbv(index: GLuint, v: ptr GLbyte) {.importc.}
  proc glExtGetBuffersQCOM(buffers: ptr GLuint, maxBuffers: GLint, numBuffers: ptr GLint) {.importc.}
  proc glCopyTexSubImage3D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glDeletePerfMonitorsAMD(n: GLsizei, monitors: ptr GLuint) {.importc.}
  proc glGetTrackMatrixivNV(target: GLenum, address: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glEndConditionalRender() {.importc.}
  proc glVertexAttribL3i64NV(index: GLuint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext) {.importc.}
  proc glProgramLocalParametersI4ivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLint) {.importc.}
  proc glFlush() {.importc.}
  proc glGetNamedBufferParameterui64vNV(buffer: GLuint, pname: GLenum, params: ptr GLuint64Ext) {.importc.}
  proc glGetVertexArrayIntegeri_vEXT(vaobj: GLuint, index: GLuint, pname: GLenum, param: ptr GLint) {.importc.}
  proc glReadnPixelsEXT(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, bufSize: GLsizei, data: pointer) {.importc.}
  proc glMultiTexImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGetVaryingLocationNV(program: GLuint, name: cstring): GLint {.importc.}
  proc glMultiTexCoord4fvARB(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glMultiTexCoord3iv(target: GLenum, v: ptr GLint) {.importc.}
  proc glVertexAttribL2dvEXT(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glTexParameterxOES(target: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glSecondaryColor3uivEXT(v: ptr GLuint) {.importc.}
  proc glReadnPixelsARB(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, bufSize: GLsizei, data: pointer) {.importc.}
  proc glCopyTexSubImage1DEXT(target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glGetDoublei_vEXT(pname: GLenum, index: GLuint, params: ptr GLdouble) {.importc.}
  proc glVariantPointerEXT(id: GLuint, `type`: GLenum, stride: GLuint, `addr`: pointer) {.importc.}
  proc glProgramUniform3ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext) {.importc.}
  proc glTexCoord2fColor3fVertex3fvSUN(tc: ptr GLfloat, c: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glProgramUniform3fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glBindFragDataLocationIndexed(program: GLuint, colorNumber: GLuint, index: GLuint, name: cstring) {.importc.}
  proc glGetnSeparableFilterARB(target: GLenum, format: GLenum, `type`: GLenum, rowBufSize: GLsizei, row: pointer, columnBufSize: GLsizei, column: pointer, span: pointer) {.importc.}
  proc glTextureParameteriEXT(texture: GLuint, target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glGetUniformuivEXT(program: GLuint, location: GLint, params: ptr GLuint) {.importc.}
  proc glFragmentMaterialivSGIX(face: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMultiTexCoord1svARB(target: GLenum, v: ptr GLshort) {.importc.}
  proc glClientActiveTextureARB(texture: GLenum) {.importc.}
  proc glVertexAttrib1fARB(index: GLuint, x: GLfloat) {.importc.}
  proc glVertexAttrib4NbvARB(index: GLuint, v: ptr GLbyte) {.importc.}
  proc glRasterPos2d(x: GLdouble, y: GLdouble) {.importc.}
  proc glMultiTexCoord4iARB(target: GLenum, s: GLint, t: GLint, r: GLint, q: GLint) {.importc.}
  proc glGetPixelTexGenParameterfvSGIS(pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexAttribL2dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glGetProgramStringARB(target: GLenum, pname: GLenum, string: pointer) {.importc.}
  proc glRasterPos2i(x: GLint, y: GLint) {.importc.}
  proc glTexCoord2fColor4fNormal3fVertex3fvSUN(tc: ptr GLfloat, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glMultiTexCoord3s(target: GLenum, s: GLshort, t: GLshort, r: GLshort) {.importc.}
  proc glMultTransposeMatrixd(m: ptr GLdouble) {.importc.}
  proc glActiveVaryingNV(program: GLuint, name: cstring) {.importc.}
  proc glProgramUniform1f(program: GLuint, location: GLint, v0: GLfloat) {.importc.}
  proc glGetActiveSubroutineName(program: GLuint, shadertype: GLenum, index: GLuint, bufsize: GLsizei, length: ptr GLsizei, name: cstring) {.importc.}
  proc glClipPlanex(plane: GLenum, equation: ptr GLfixed) {.importc.}
  proc glMultiTexCoord4iv(target: GLenum, v: ptr GLint) {.importc.}
  proc glTransformFeedbackVaryingsEXT(program: GLuint, count: GLsizei, varyings: cstringArray, bufferMode: GLenum) {.importc.}
  proc glBlendEquationSeparateiARB(buf: GLuint, modeRgb: GLenum, modeAlpha: GLenum) {.importc.}
  proc glVertex2sv(v: ptr GLshort) {.importc.}
  proc glAccumxOES(op: GLenum, value: GLfixed) {.importc.}
  proc glProgramLocalParameter4dARB(target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glIsRenderbufferEXT(renderbuffer: GLuint): GLboolean {.importc.}
  proc glMultiDrawElementsIndirectAMD(mode: GLenum, `type`: GLenum, indirect: pointer, primcount: GLsizei, stride: GLsizei) {.importc.}
  proc glVertexAttribI4uiEXT(index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint) {.importc.}
  proc glVertex4fv(v: ptr GLfloat) {.importc.}
  proc glGenerateMipmapEXT(target: GLenum) {.importc.}
  proc glVertexP3ui(`type`: GLenum, value: GLuint) {.importc.}
  proc glTexCoord2dv(v: ptr GLdouble) {.importc.}
  proc glFlushMappedBufferRange(target: GLenum, offset: GLintptr, length: GLsizeiptr) {.importc.}
  proc glTrackMatrixNV(target: GLenum, address: GLuint, matrix: GLenum, transform: GLenum) {.importc.}
  proc glFragmentLightModeliSGIX(pname: GLenum, param: GLint) {.importc.}
  proc glVertexAttrib4Nusv(index: GLuint, v: ptr GLushort) {.importc.}
  proc glScalef(x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glLightxvOES(light: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glTextureParameterivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glCompressedMultiTexImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer) {.importc.}
  proc glVertexAttribL1d(index: GLuint, x: GLdouble) {.importc.}
  proc glVertexAttrib3fARB(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glVertexAttrib3hvNV(index: GLuint, v: ptr GLhalfNv) {.importc.}
  proc glSpriteParameteriSGIX(pname: GLenum, param: GLint) {.importc.}
  proc glFrustumxOES(l: GLfixed, r: GLfixed, b: GLfixed, t: GLfixed, n: GLfixed, f: GLfixed) {.importc.}
  proc glGetnMapdvARB(target: GLenum, query: GLenum, bufSize: GLsizei, v: ptr GLdouble) {.importc.}
  proc glGetMinmaxEXT(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer) {.importc.}
  proc glProgramUniformHandleui64NV(program: GLuint, location: GLint, value: GLuint64) {.importc.}
  proc glWindowPos4fvMESA(v: ptr GLfloat) {.importc.}
  proc glExtGetTexturesQCOM(textures: ptr GLuint, maxTextures: GLint, numTextures: ptr GLint) {.importc.}
  proc glProgramSubroutineParametersuivNV(target: GLenum, count: GLsizei, params: ptr GLuint) {.importc.}
  proc glSampleCoveragexOES(value: GLclampx, invert: GLboolean) {.importc.}
  proc glMultiTexEnvivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetFinalCombinerInputParameterfvNV(variable: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glLightModeliv(pname: GLenum, params: ptr GLint) {.importc.}
  proc glUniform4f(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) {.importc.}
  proc glDepthRange(near: GLdouble, far: GLdouble) {.importc.}
  proc glProgramUniformMatrix4x3dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glProgramUniform4fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glGetTexParameterIiv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttribs4dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble) {.importc.}
  proc glConvolutionParameteri(target: GLenum, pname: GLenum, params: GLint) {.importc.}
  proc glVertexAttribI4uiv(index: GLuint, v: ptr GLuint) {.importc.}
  proc glEvalCoord1dv(u: ptr GLdouble) {.importc.}
  proc glIsFramebuffer(framebuffer: GLuint): GLboolean {.importc.}
  proc glEvalCoord2d(u: GLdouble, v: GLdouble) {.importc.}
  proc glClearDepthf(d: GLfloat) {.importc.}
  proc glCompressedTexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer) {.importc.}
  proc glProgramUniformMatrix3x2dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glGetTexParameterxv(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glBinormal3fEXT(bx: GLfloat, by: GLfloat, bz: GLfloat) {.importc.}
  proc glProgramParameteriARB(program: GLuint, pname: GLenum, value: GLint) {.importc.}
  proc glWindowPos3ivMESA(v: ptr GLint) {.importc.}
  proc glReplacementCodeuiColor4fNormal3fVertex3fvSUN(rc: ptr GLuint, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glPresentFrameDualFillNV(video_slot: GLuint, minPresentTime: GLuint64Ext, beginPresentTimeId: GLuint, presentDurationId: GLuint, `type`: GLenum, target0: GLenum, fill0: GLuint, target1: GLenum, fill1: GLuint, target2: GLenum, fill2: GLuint, target3: GLenum, fill3: GLuint) {.importc.}
  proc glIndexPointerListIBM(`type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint) {.importc.}
  proc glVertexStream2dATI(stream: GLenum, x: GLdouble, y: GLdouble) {.importc.}
  proc glUniformMatrix3x4dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glMapNamedBufferRangeEXT(buffer: GLuint, offset: GLintptr, length: GLsizeiptr, access: GLbitfield) {.importc.}
  proc glColor4sv(v: ptr GLshort) {.importc.}
  proc glStencilFillPathNV(path: GLuint, fillMode: GLenum, mask: GLuint) {.importc.}
  proc glGetVertexAttribfvARB(index: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glWindowPos3dv(v: ptr GLdouble) {.importc.}
  proc glHintPGI(target: GLenum, mode: GLint) {.importc.}
  proc glVertexAttribs3hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv) {.importc.}
  proc glProgramUniform1i64NV(program: GLuint, location: GLint, x: GLint64Ext) {.importc.}
  proc glReplacementCodeuiColor3fVertex3fSUN(rc: GLuint, r: GLfloat, g: GLfloat, b: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glUniform2iARB(location: GLint, v0: GLint, v1: GLint) {.importc.}
  proc glViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glBlendFuncSeparateIndexedAMD(buf: GLuint, srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum) {.importc.}
  proc glColor3us(red: GLushort, green: GLushort, blue: GLushort) {.importc.}
  proc glVertexAttrib2hvNV(index: GLuint, v: ptr GLhalfNv) {.importc.}
  proc glGenerateMipmap(target: GLenum) {.importc.}
  proc glGetProgramEnvParameterIuivNV(target: GLenum, index: GLuint, params: ptr GLuint) {.importc.}
  proc glBlendEquationiARB(buf: GLuint, mode: GLenum) {.importc.}
  proc glReadBufferNV(mode: GLenum) {.importc.}
  proc glProvokingVertexEXT(mode: GLenum) {.importc.}
  proc glPointParameterivNV(pname: GLenum, params: ptr GLint) {.importc.}
  proc glBlitFramebufferANGLE(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum) {.importc.}
  proc glGetObjectParameterivARB(obj: GLhandleArb, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetSubroutineIndex(program: GLuint, shadertype: GLenum, name: cstring): GLuint {.importc.}
  proc glMap2d(target: GLenum, u1: GLdouble, u2: GLdouble, ustride: GLint, uorder: GLint, v1: GLdouble, v2: GLdouble, vstride: GLint, vorder: GLint, points: ptr GLdouble) {.importc.}
  proc glRectfv(v1: ptr GLfloat, v2: ptr GLfloat) {.importc.}
  proc glDepthRangeArrayv(first: GLuint, count: GLsizei, v: ptr GLdouble) {.importc.}
  proc glMultiTexParameteriEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLint) {.importc.}
  proc glTexStorageSparseAMD(target: GLenum, internalFormat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, layers: GLsizei, flags: GLbitfield) {.importc.}
  proc glGenerateTextureMipmapEXT(texture: GLuint, target: GLenum) {.importc.}
  proc glCopyConvolutionFilter1D(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glVertex4d(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) {.importc.}
  proc glGetPathParameterfvNV(path: GLuint, pname: GLenum, value: ptr GLfloat) {.importc.}
  proc glDetachShader(program: GLuint, shader: GLuint) {.importc.}
  proc glGetColorTableSGI(target: GLenum, format: GLenum, `type`: GLenum, table: pointer) {.importc.}
  proc glPixelTransformParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glBufferSubDataARB(target: GLenum, offset: GLintPtrArb, size: GLsizeiptrArb, data: pointer) {.importc.}
  proc glVertexAttrib4ubvNV(index: GLuint, v: ptr GLubyte) {.importc.}
  proc glCopyTextureImage1DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint) {.importc.}
  proc glGetQueryivARB(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glVertexAttribIPointerEXT(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glVertexAttribL3dEXT(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glGetQueryObjectui64vEXT(id: GLuint, pname: GLenum, params: ptr GLuint64) {.importc.}
  proc glColor4x(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed) {.importc.}
  proc glProgramUniformMatrix3x2dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glVertexAttribI4i(index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glVertexAttrib1f(index: GLuint, x: GLfloat) {.importc.}
  proc glUnmapBufferOES(target: GLenum): GLboolean {.importc.}
  proc glVertexStream2ivATI(stream: GLenum, coords: ptr GLint) {.importc.}
  proc glBeginOcclusionQueryNV(id: GLuint) {.importc.}
  proc glVertex4sv(v: ptr GLshort) {.importc.}
  proc glEnablei(target: GLenum, index: GLuint) {.importc.}
  proc glUseProgramObjectARB(programObj: GLhandleArb) {.importc.}
  proc glGetVertexAttribLdvEXT(index: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glUniform2d(location: GLint, x: GLdouble, y: GLdouble) {.importc.}
  proc glMinmaxEXT(target: GLenum, internalformat: GLenum, sink: GLboolean) {.importc.}
  proc glTexImage3D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGenSymbolsEXT(datatype: GLenum, storagetype: GLenum, range: GLenum, components: GLuint): GLuint {.importc.}
  proc glVertexAttribI4svEXT(index: GLuint, v: ptr GLshort) {.importc.}
  proc glProgramEnvParameter4dvARB(target: GLenum, index: GLuint, params: ptr GLdouble) {.importc.}
  proc glProgramUniformMatrix4dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glGetSamplerParameterfv(sampler: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glPopClientAttrib() {.importc.}
  proc glHistogram(target: GLenum, width: GLsizei, internalformat: GLenum, sink: GLboolean) {.importc.}
  proc glTexEnvfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glMultiTexCoord1dvARB(target: GLenum, v: ptr GLdouble) {.importc.}
  proc glGetTexGenivOES(coord: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glUniform1ivARB(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glTexCoord3fv(v: ptr GLfloat) {.importc.}
  proc glVertex2xvOES(coords: ptr GLfixed) {.importc.}
  proc glTexCoord4fVertex4fvSUN(tc: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glUniform2uiv(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glMultiTexEnvfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glGetTextureParameterIivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMemoryBarrierEXT(barriers: GLbitfield) {.importc.}
  proc glGetTexParameterPointervAPPLE(target: GLenum, pname: GLenum, params: ptr pointer) {.importc.}
  proc glWindowPos2svARB(v: ptr GLshort) {.importc.}
  proc glEndQuery(target: GLenum) {.importc.}
  proc glBlitFramebufferEXT(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum) {.importc.}
  proc glProgramEnvParametersI4uivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLuint) {.importc.}
  proc glGetActiveUniform(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring) {.importc.}
  proc glGenAsyncMarkersSGIX(range: GLsizei): GLuint {.importc.}
  proc glClipControlARB(origin: GLenum, depth: GLenum) {.importc.}
  proc glDrawElementsInstancedEXT(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, primcount: GLsizei) {.importc.}
  proc glGetFragmentMaterialivSGIX(face: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glSwizzleEXT(res: GLuint, `in`: GLuint, outX: GLenum, outY: GLenum, outZ: GLenum, outW: GLenum) {.importc.}
  proc glMultiTexCoord1bOES(texture: GLenum, s: GLbyte) {.importc.}
  proc glProgramParameters4dvNV(target: GLenum, index: GLuint, count: GLsizei, v: ptr GLdouble) {.importc.}
  proc glWindowPos2s(x: GLshort, y: GLshort) {.importc.}
  proc glBlendFuncSeparatei(buf: GLuint, srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum) {.importc.}
  proc glMultiModeDrawElementsIBM(mode: ptr GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, primcount: GLsizei, modestride: GLint) {.importc.}
  proc glNormal3x(nx: GLfixed, ny: GLfixed, nz: GLfixed) {.importc.}
  proc glProgramUniform1fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat) {.importc.}
  proc glTexCoord2hNV(s: GLhalfNv, t: GLhalfNv) {.importc.}
  proc glViewportIndexedfv(index: GLuint, v: ptr GLfloat) {.importc.}
  proc glDrawTexxOES(x: GLfixed, y: GLfixed, z: GLfixed, width: GLfixed, height: GLfixed) {.importc.}
  proc glProgramParameter4dvNV(target: GLenum, index: GLuint, v: ptr GLdouble) {.importc.}
  proc glDeleteBuffers(n: GLsizei, buffers: ptr GLuint) {.importc.}
  proc glGetVertexArrayIntegervEXT(vaobj: GLuint, pname: GLenum, param: ptr GLint) {.importc.}
  proc glBindFragDataLocationEXT(program: GLuint, color: GLuint, name: cstring) {.importc.}
  proc glGenProgramsNV(n: GLsizei, programs: ptr GLuint) {.importc.}
  proc glMultiTexCoord1i(target: GLenum, s: GLint) {.importc.}
  proc glCompressedTexImage3DOES(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.importc.}
  proc glGetQueryivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glExtGetBufferPointervQCOM(target: GLenum, params: ptr pointer) {.importc.}
  proc glVertex3iv(v: ptr GLint) {.importc.}
  proc glVertexAttribL1dvEXT(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glValidateProgramPipeline(pipeline: GLuint) {.importc.}
  proc glBindVertexArray(`array`: GLuint) {.importc.}
  proc glUniform2uiEXT(location: GLint, v0: GLuint, v1: GLuint) {.importc.}
  proc glUniform3i(location: GLint, v0: GLint, v1: GLint, v2: GLint) {.importc.}
  proc glGetVertexAttribIuiv(index: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glVertexArrayParameteriAPPLE(pname: GLenum, param: GLint) {.importc.}
  proc glVertexAttribL2i64NV(index: GLuint, x: GLint64Ext, y: GLint64Ext) {.importc.}
  proc glTexGenivOES(coord: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glIsFramebufferOES(framebuffer: GLuint): GLboolean {.importc.}
  proc glColor4ubv(v: ptr GLubyte) {.importc.}
  proc glDeleteNamedStringARB(namelen: GLint, name: cstring) {.importc.}
  proc glCopyConvolutionFilter1DEXT(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei) {.importc.}
  proc glBufferStorage(target: GLenum, size: GLsizeiptr, data: ptr pointer, flags: GLbitfield) {.importc.}
  proc glDrawTexiOES(x: GLint, y: GLint, z: GLint, width: GLint, height: GLint) {.importc.}
  proc glRasterPos3dv(v: ptr GLdouble) {.importc.}
  proc glIndexMaterialEXT(face: GLenum, mode: GLenum) {.importc.}
  proc glGetClipPlanex(plane: GLenum, equation: ptr GLfixed) {.importc.}
  proc glIsVertexArrayOES(`array`: GLuint): GLboolean {.importc.}
  proc glColorTableEXT(target: GLenum, internalFormat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, table: pointer) {.importc.}
  proc glCompressedTexImage2D(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: pointer) {.importc.}
  proc glLightx(light: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glGetTexParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexAttrib4NsvARB(index: GLuint, v: ptr GLshort) {.importc.}
  proc glInterleavedArrays(format: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glProgramLocalParameter4fARB(target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) {.importc.}
  proc glPopDebugGroupKHR() {.importc.}
  proc glVDPAUUnregisterSurfaceNV(surface: GLvdpauSurfaceNv) {.importc.}
  proc glTexCoord1s(s: GLshort) {.importc.}
  proc glFramebufferTexture2DMultisampleIMG(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, samples: GLsizei) {.importc.}
  proc glShaderBinary(count: GLsizei, shaders: ptr GLuint, binaryformat: GLenum, binary: pointer, length: GLsizei) {.importc.}
  proc glVertexAttrib2dv(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glUniformMatrix4dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glWeightivARB(size: GLint, weights: ptr GLint) {.importc.}
  proc glGetMultiTexParameterIivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glCopyConvolutionFilter2DEXT(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei) {.importc.}
  proc glSecondaryColor3hNV(red: GLhalfNv, green: GLhalfNv, blue: GLhalfNv) {.importc.}
  proc glVertexAttrib1sv(index: GLuint, v: ptr GLshort) {.importc.}
  proc glFrustumfOES(l: GLfloat, r: GLfloat, b: GLfloat, t: GLfloat, n: GLfloat, f: GLfloat) {.importc.}
  proc glVertexStream2iATI(stream: GLenum, x: GLint, y: GLint) {.importc.}
  proc glNormalStream3bATI(stream: GLenum, nx: GLbyte, ny: GLbyte, nz: GLbyte) {.importc.}
  proc glVertexArrayTexCoordOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glGetQueryiv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glTransformFeedbackStreamAttribsNV(count: GLsizei, attribs: ptr GLint, nbuffers: GLsizei, bufstreams: ptr GLint, bufferMode: GLenum) {.importc.}
  proc glTextureStorage3DEXT(texture: GLuint, target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei) {.importc.}
  proc glWindowPos3dvMESA(v: ptr GLdouble) {.importc.}
  proc glUniform2uivEXT(location: GLint, count: GLsizei, value: ptr GLuint) {.importc.}
  proc glTextureStorage2DEXT(texture: GLuint, target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glVertexArrayMultiTexCoordOffsetEXT(vaobj: GLuint, buffer: GLuint, texunit: GLenum, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr) {.importc.}
  proc glVertexStream1dvATI(stream: GLenum, coords: ptr GLdouble) {.importc.}
  proc glCopyImageSubData(srcName: GLuint, srcTarget: GLenum, srcLevel: GLint, srcX: GLint, srcY: GLint, srcZ: GLint, dstName: GLuint, dstTarget: GLenum, dstLevel: GLint, dstX: GLint, dstY: GLint, dstZ: GLint, srcWidth: GLsizei, srcHeight: GLsizei, srcDepth: GLsizei) {.importc.}
  proc glClearNamedBufferSubDataEXT(buffer: GLuint, internalformat: GLenum, format: GLenum, `type`: GLenum, offset: GLsizeiptr, size: GLsizeiptr, data: ptr pointer) {.importc.}
  proc glBindBuffersRange(target: GLenum, first: GLuint, count: GLsizei, buffers: ptr GLuint, offsets: ptr GLintptr, sizes: ptr GLsizeiptr) {.importc.}
  proc glGetVertexAttribIuivEXT(index: GLuint, pname: GLenum, params: ptr GLuint) {.importc.}
  proc glLoadMatrixx(m: ptr GLfixed) {.importc.}
  proc glTransformFeedbackVaryingsNV(program: GLuint, count: GLsizei, locations: ptr GLint, bufferMode: GLenum) {.importc.}
  proc glUniform1i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext) {.importc.}
  proc glVertexArrayVertexAttribLFormatEXT(vaobj: GLuint, attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint) {.importc.}
  proc glClearBufferuiv(buffer: GLenum, drawbuffer: GLint, value: ptr GLuint) {.importc.}
  proc glCombinerOutputNV(stage: GLenum, portion: GLenum, abOutput: GLenum, cdOutput: GLenum, sumOutput: GLenum, scale: GLenum, bias: GLenum, abDotProduct: GLboolean, cdDotProduct: GLboolean, muxSum: GLboolean) {.importc.}
  proc glTexImage3DEXT(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glPixelTransformParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glActiveStencilFaceEXT(face: GLenum) {.importc.}
  proc glCreateShaderObjectARB(shaderType: GLenum): GLhandleArb {.importc.}
  proc glGetTextureParameterivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glCopyTextureLevelsAPPLE(destinationTexture: GLuint, sourceTexture: GLuint, sourceBaseLevel: GLint, sourceLevelCount: GLsizei) {.importc.}
  proc glVertexAttrib4Nuiv(index: GLuint, v: ptr GLuint) {.importc.}
  proc glDrawPixels(width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glWindowPos3dvARB(v: ptr GLdouble) {.importc.}
  proc glProgramLocalParameterI4ivNV(target: GLenum, index: GLuint, params: ptr GLint) {.importc.}
  proc glRasterPos4s(x: GLshort, y: GLshort, z: GLshort, w: GLshort) {.importc.}
  proc glTexCoord2fVertex3fvSUN(tc: ptr GLfloat, v: ptr GLfloat) {.importc.}
  proc glGetPathMetricsNV(metricQueryMask: GLbitfield, numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, stride: GLsizei, metrics: ptr GLfloat) {.importc.}
  proc glMultiTexCoord4bOES(texture: GLenum, s: GLbyte, t: GLbyte, r: GLbyte, q: GLbyte) {.importc.}
  proc glTextureBufferEXT(texture: GLuint, target: GLenum, internalformat: GLenum, buffer: GLuint) {.importc.}
  proc glSecondaryColor3fv(v: ptr GLfloat) {.importc.}
  proc glMultiTexCoord3fv(target: GLenum, v: ptr GLfloat) {.importc.}
  proc glGetTexParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glMap2xOES(target: GLenum, u1: GLfixed, u2: GLfixed, ustride: GLint, uorder: GLint, v1: GLfixed, v2: GLfixed, vstride: GLint, vorder: GLint, points: GLfixed) {.importc.}
  proc glFlushVertexArrayRangeAPPLE(length: GLsizei, `pointer`: pointer) {.importc.}
  proc glActiveTextureARB(texture: GLenum) {.importc.}
  proc glGetVertexAttribLi64vNV(index: GLuint, pname: GLenum, params: ptr GLint64Ext) {.importc.}
  proc glNormal3bv(v: ptr GLbyte) {.importc.}
  proc glCreateSyncFromCLeventARB(context: ptr ClContext, event: ptr ClContext, flags: GLbitfield): GLsync {.importc.}
  proc glRenderbufferStorageEXT(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei) {.importc.}
  proc glGetCompressedTextureImageEXT(texture: GLuint, target: GLenum, lod: GLint, img: pointer) {.importc.}
  proc glColorFragmentOp2ATI(op: GLenum, dst: GLuint, dstMask: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint) {.importc.}
  proc glPixelMapusv(map: GLenum, mapsize: GLsizei, values: ptr GLushort) {.importc.}
  proc glGlobalAlphaFactorsSUN(factor: GLshort) {.importc.}
  proc glTexParameterxv(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glEvalCoord2xOES(u: GLfixed, v: GLfixed) {.importc.}
  proc glIsList(list: GLuint): GLboolean {.importc.}
  proc glVertexAttrib3d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble) {.importc.}
  proc glSpriteParameterfSGIX(pname: GLenum, param: GLfloat) {.importc.}
  proc glPathGlyphRangeNV(firstPathName: GLuint, fontTarget: GLenum, fontName: pointer, fontStyle: GLbitfield, firstGlyph: GLuint, numGlyphs: GLsizei, handleMissingGlyphs: GLenum, pathParameterTemplate: GLuint, emScale: GLfloat) {.importc.}
  proc glUniform3iv(location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glClearBufferfi(buffer: GLenum, drawbuffer: GLint, depth: GLfloat, stencil: GLint) {.importc.}
  proc glWindowPos3sMESA(x: GLshort, y: GLshort, z: GLshort) {.importc.}
  proc glGetMapParameterfvNV(target: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glBindFragmentShaderATI(id: GLuint) {.importc.}
  proc glTexCoord4s(s: GLshort, t: GLshort, r: GLshort, q: GLshort) {.importc.}
  proc glGetMultiTexGenfvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glColorMaterial(face: GLenum, mode: GLenum) {.importc.}
  proc glVertexAttribs1svNV(index: GLuint, count: GLsizei, v: ptr GLshort) {.importc.}
  proc glEnableVertexAttribAPPLE(index: GLuint, pname: GLenum) {.importc.}
  proc glGetDoubleIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLdouble) {.importc.}
  proc glOrthof(l: GLfloat, r: GLfloat, b: GLfloat, t: GLfloat, n: GLfloat, f: GLfloat) {.importc.}
  proc glVertexBlendEnvfATI(pname: GLenum, param: GLfloat) {.importc.}
  proc glUniformMatrix2x4dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glPrioritizeTexturesxOES(n: GLsizei, textures: ptr GLuint, priorities: ptr GLfixed) {.importc.}
  proc glGetTextureSamplerHandleNV(texture: GLuint, sampler: GLuint): GLuint64 {.importc.}
  proc glDeleteVertexArrays(n: GLsizei, arrays: ptr GLuint) {.importc.}
  proc glMultiTexCoord1xOES(texture: GLenum, s: GLfixed) {.importc.}
  proc glGlobalAlphaFactorusSUN(factor: GLushort) {.importc.}
  proc glGetConvolutionParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glProgramUniform4fEXT(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat) {.importc.}
  proc glProgramUniformMatrix3x4dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
  proc glBindVertexBuffer(bindingindex: GLuint, buffer: GLuint, offset: GLintptr, stride: GLsizei) {.importc.}
  proc glGetHistogramParameteriv(target: GLenum, pname: GLenum, params: ptr GLint) {.importc.}
  proc glGetShaderPrecisionFormat(shadertype: GLenum, precisiontype: GLenum, range: ptr GLint, precision: ptr GLint) {.importc.}
  proc glTextureMaterialEXT(face: GLenum, mode: GLenum) {.importc.}
  proc glEvalCoord2xvOES(coords: ptr GLfixed) {.importc.}
  proc glWeightuivARB(size: GLint, weights: ptr GLuint) {.importc.}
  proc glGetTextureLevelParameterfvEXT(texture: GLuint, target: GLenum, level: GLint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glVertexAttribP3uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint) {.importc.}
  proc glProgramEnvParameterI4ivNV(target: GLenum, index: GLuint, params: ptr GLint) {.importc.}
  proc glFogi(pname: GLenum, param: GLint) {.importc.}
  proc glTexCoord1iv(v: ptr GLint) {.importc.}
  proc glReplacementCodeuiColor4ubVertex3fvSUN(rc: ptr GLuint, c: ptr GLubyte, v: ptr GLfloat) {.importc.}
  proc glProgramUniform1ui(program: GLuint, location: GLint, v0: GLuint) {.importc.}
  proc glMultiTexCoord3d(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble) {.importc.}
  proc glBeginVideoCaptureNV(video_capture_slot: GLuint) {.importc.}
  proc glEvalCoord1f(u: GLfloat) {.importc.}
  proc glMultiTexCoord1hvNV(target: GLenum, v: ptr GLhalfNv) {.importc.}
  proc glSecondaryColor3sEXT(red: GLshort, green: GLshort, blue: GLshort) {.importc.}
  proc glTextureImage3DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glCopyTexImage2D(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint) {.importc.}
  proc glFinishFenceAPPLE(fence: GLuint) {.importc.}
  proc glVertexArrayRangeNV(length: GLsizei, `pointer`: pointer) {.importc.}
  proc glLightModelf(pname: GLenum, param: GLfloat) {.importc.}
  proc glVertexAttribL1ui64ARB(index: GLuint, x: GLuint64Ext) {.importc.}
  proc glPolygonOffset(factor: GLfloat, units: GLfloat) {.importc.}
  proc glRasterPos4xOES(x: GLfixed, y: GLfixed, z: GLfixed, w: GLfixed) {.importc.}
  proc glVertexAttrib3dvNV(index: GLuint, v: ptr GLdouble) {.importc.}
  proc glBeginQuery(target: GLenum, id: GLuint) {.importc.}
  proc glWeightfvARB(size: GLint, weights: ptr GLfloat) {.importc.}
  proc glGetUniformuiv(program: GLuint, location: GLint, params: ptr GLuint) {.importc.}
  proc glIsTextureEXT(texture: GLuint): GLboolean {.importc.}
  proc glGetClipPlanef(plane: GLenum, equation: ptr GLfloat) {.importc.}
  proc glTexGenxOES(coord: GLenum, pname: GLenum, param: GLfixed) {.importc.}
  proc glFramebufferTextureFaceEXT(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, face: GLenum) {.importc.}
  proc glDisableClientState(`array`: GLenum) {.importc.}
  proc glTexPageCommitmentARB(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, resident: GLboolean) {.importc.}
  proc glRasterPos4dv(v: ptr GLdouble) {.importc.}
  proc glGetLightx(light: GLenum, pname: GLenum, params: ptr GLfixed) {.importc.}
  proc glVertexAttrib1hvNV(index: GLuint, v: ptr GLhalfNv) {.importc.}
  proc glMultiTexCoord2s(target: GLenum, s: GLshort, t: GLshort) {.importc.}
  proc glProgramUniform2iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint) {.importc.}
  proc glGetListParameterivSGIX(list: GLuint, pname: GLenum, params: ptr GLint) {.importc.}
  proc glColorFragmentOp1ATI(op: GLenum, dst: GLuint, dstMask: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint) {.importc.}
  proc glReplacementCodeuiTexCoord2fColor4fNormal3fVertex3fSUN(rc: GLuint, s: GLfloat, t: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) {.importc.}
  proc glSampleMapATI(dst: GLuint, interp: GLuint, swizzle: GLenum) {.importc.}
  proc glProgramUniform1d(program: GLuint, location: GLint, v0: GLdouble) {.importc.}
  proc glBindAttribLocation(program: GLuint, index: GLuint, name: cstring) {.importc.}
  proc glGetCombinerStageParameterfvNV(stage: GLenum, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexSubImage4DSGIS(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, woffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, size4d: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer) {.importc.}
  proc glGetMapAttribParameterfvNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glNewObjectBufferATI(size: GLsizei, `pointer`: pointer, usage: GLenum): GLuint {.importc.}
  proc glWindowPos4iMESA(x: GLint, y: GLint, z: GLint, w: GLint) {.importc.}
  proc glNewList(list: GLuint, mode: GLenum) {.importc.}
  proc glUniform1i64NV(location: GLint, x: GLint64Ext) {.importc.}
  proc glTexCoordP3ui(`type`: GLenum, coords: GLuint) {.importc.}
  proc glEndQueryEXT(target: GLenum) {.importc.}
  proc glGetVertexAttribLdv(index: GLuint, pname: GLenum, params: ptr GLdouble) {.importc.}
  proc glStencilMask(mask: GLuint) {.importc.}
  proc glVertexAttrib4sv(index: GLuint, v: ptr GLshort) {.importc.}
  proc glRectsv(v1: ptr GLshort, v2: ptr GLshort) {.importc.}
  proc glGetVariantArrayObjectfvATI(id: GLuint, pname: GLenum, params: ptr GLfloat) {.importc.}
  proc glTexCoord3hvNV(v: ptr GLhalfNv) {.importc.}
  proc glGetUniformdv(program: GLuint, location: GLint, params: ptr GLdouble) {.importc.}
  proc glSecondaryColor3fvEXT(v: ptr GLfloat) {.importc.}
  proc glAlphaFuncx(fun: GLenum, `ref`: GLfixed) {.importc.}
  proc glVertexAttribPointerNV(index: GLuint, fsize: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer) {.importc.}
  proc glColorTable(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, table: pointer) {.importc.}
  proc glProgramUniformMatrix2x3dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble) {.importc.}
{.pop.} # stdcall, hint[XDeclaredButNotUsed]: off, warning[SmallLshouldNotBeUsed]: off.

const
  cGL_UNSIGNED_BYTE* = 0x1401
  cGL_UNSIGNED_SHORT* = 0x1403

  GL_2X_BIT_ATI* = 0x00000001
  GL_MODELVIEW6_ARB* = 0x8726
  GL_CULL_FACE_MODE* = 0x0B45
  GL_TEXTURE_MAG_FILTER* = 0x2800
  GL_TRANSFORM_FEEDBACK_VARYINGS_EXT* = 0x8C83
  GL_PATH_JOIN_STYLE_NV* = 0x9079
  GL_FEEDBACK_BUFFER_SIZE* = 0x0DF1
  GL_FRAGMENT_LIGHT0_SGIX* = 0x840C
  GL_DRAW_BUFFER7_ARB* = 0x882C
  GL_POINT_SPRITE_OES* = 0x8861
  GL_INT_SAMPLER_RENDERBUFFER_NV* = 0x8E57
  GL_POST_CONVOLUTION_COLOR_TABLE_SGI* = 0x80D1
  GL_ZOOM_X* = 0x0D16
  GL_DRAW_FRAMEBUFFER_NV* = 0x8CA9
  GL_RGB_FLOAT16_ATI* = 0x881B
  GL_NUM_COMPRESSED_TEXTURE_FORMATS* = 0x86A2
  GL_LINE_STRIP* = 0x0003
  GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE_SGI* = 0x80D5
  GL_CURRENT_TIME_NV* = 0x8E28
  GL_FRAMEBUFFER_UNSUPPORTED* = 0x8CDD
  GL_PIXEL_TEX_GEN_Q_CEILING_SGIX* = 0x8184
  GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH_EXT* = 0x8C76
  GL_MAP_PERSISTENT_BIT* = 0x0040
  GL_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x9056
  GL_CON_16_ATI* = 0x8951
  GL_DEPTH_BUFFER_BIT1_QCOM* = 0x00000200
  GL_TEXTURE30_ARB* = 0x84DE
  GL_SAMPLER_BUFFER* = 0x8DC2
  GL_MAX_COLOR_TEXTURE_SAMPLES* = 0x910E
  GL_DEPTH_STENCIL* = 0x84F9
  GL_C4F_N3F_V3F* = 0x2A26
  GL_ZOOM_Y* = 0x0D17
  GL_RGB10* = 0x8052
  GL_PRESERVE_ATI* = 0x8762
  GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB* = 0x8B4D
  GL_COLOR_ATTACHMENT12_NV* = 0x8CEC
  GL_GREEN_MAX_CLAMP_INGR* = 0x8565
  GL_CURRENT_VERTEX_ATTRIB* = 0x8626
  GL_TEXTURE_SHARED_SIZE* = 0x8C3F
  GL_NORMAL_ARRAY_TYPE* = 0x807E
  GL_DYNAMIC_READ* = 0x88E9
  GL_ALPHA4_EXT* = 0x803B
  GL_REPLACEMENT_CODE_ARRAY_SUN* = 0x85C0
  GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_NV* = 0x8852
  GL_MAX_VERTEX_ATTRIBS_ARB* = 0x8869
  GL_VIDEO_COLOR_CONVERSION_MIN_NV* = 0x902B
  GL_SOURCE3_RGB_NV* = 0x8583
  GL_ALPHA* = 0x1906
  GL_OUTPUT_TEXTURE_COORD16_EXT* = 0x87AD
  GL_BLEND_EQUATION_EXT* = 0x8009
  GL_BIAS_BIT_ATI* = 0x00000008
  GL_BLEND_EQUATION_RGB* = 0x8009
  GL_SHADER_BINARY_DMP* = 0x9250
  GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE* = 0x90C8
  GL_Z4Y12Z4CB12Z4CR12_444_NV* = 0x9037
  GL_READ_PIXELS_TYPE* = 0x828E
  GL_CONVOLUTION_HINT_SGIX* = 0x8316
  GL_TRANSPOSE_AFFINE_3D_NV* = 0x9098
  GL_PIXEL_MAP_B_TO_B* = 0x0C78
  GL_VERTEX_BLEND_ARB* = 0x86A7
  GL_LIGHT2* = 0x4002
  cGL_BYTE* = 0x1400
  GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS* = 0x92D3
  GL_DOMAIN* = 0x0A02
  GL_PROGRAM_NATIVE_TEMPORARIES_ARB* = 0x88A6
  GL_RELATIVE_CUBIC_CURVE_TO_NV* = 0x0D
  GL_TEXTURE_DEPTH_TYPE_ARB* = 0x8C16
  GL_STENCIL_BACK_PASS_DEPTH_PASS* = 0x8803
  GL_MAX_FRAGMENT_PROGRAM_LOCAL_PARAMETERS_NV* = 0x8868
  GL_ATTRIB_STACK_DEPTH* = 0x0BB0
  GL_DEPTH_COMPONENT16_ARB* = 0x81A5
  GL_TESSELLATION_MODE_AMD* = 0x9004
  GL_UNSIGNED_INT8_VEC3_NV* = 0x8FEE
  GL_DOUBLE_VEC4* = 0x8FFE
  GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS* = 0x8E85
  GL_TEXTURE_GREEN_TYPE_ARB* = 0x8C11
  GL_PIXEL_PACK_BUFFER* = 0x88EB
  GL_VERTEX_WEIGHT_ARRAY_EXT* = 0x850C
  GL_HALF_FLOAT* = 0x140B
  GL_REG_0_ATI* = 0x8921
  GL_DEPTH_BUFFER_BIT4_QCOM* = 0x00001000
  GL_UNSIGNED_INT_5_9_9_9_REV_EXT* = 0x8C3E
  GL_DEPTH_COMPONENT16_SGIX* = 0x81A5
  GL_COMPRESSED_RGBA_ASTC_8x5_KHR* = 0x93B5
  GL_EDGE_FLAG_ARRAY_LENGTH_NV* = 0x8F30
  GL_CON_17_ATI* = 0x8952
  GL_PARAMETER_BUFFER_ARB* = 0x80EE
  GL_COLOR_ATTACHMENT6_EXT* = 0x8CE6
  GL_INDEX_ARRAY_EXT* = 0x8077
  GL_ALPHA_SCALE* = 0x0D1C
  GL_LINE_QUALITY_HINT_SGIX* = 0x835B
  GL_SLUMINANCE8* = 0x8C47
  GL_DEBUG_OUTPUT_KHR* = 0x92E0
  GL_TEXTURE_LIGHTING_MODE_HP* = 0x8167
  GL_SPOT_DIRECTION* = 0x1204
  GL_V3F* = 0x2A21
  GL_ALPHA16_EXT* = 0x803E
  GL_DRAW_BUFFER15_NV* = 0x8834
  GL_MIN_PROGRAM_TEXEL_OFFSET_EXT* = 0x8904
  GL_ACTIVE_VARYING_MAX_LENGTH_NV* = 0x8C82
  GL_COLOR_ATTACHMENT10* = 0x8CEA
  GL_COLOR_ARRAY_LIST_STRIDE_IBM* = 103082
  GL_TEXTURE_TARGET_QCOM* = 0x8BDA
  GL_DRAW_BUFFER12_ARB* = 0x8831
  GL_SAMPLE_MASK* = 0x8E51
  GL_TEXTURE_FORMAT_QCOM* = 0x8BD6
  GL_TEXTURE_COMPONENTS* = 0x1003
  GL_PROGRAM_PIPELINE_BINDING* = 0x825A
  GL_HIGH_INT* = 0x8DF5
  GL_MAP_INVALIDATE_BUFFER_BIT* = 0x0008
  GL_LAYOUT_LINEAR_CPU_CACHED_INTEL* = 2
  GL_TEXTURE_DS_SIZE_NV* = 0x871D
  GL_HALF_FLOAT_NV* = 0x140B
  GL_PROXY_POST_COLOR_MATRIX_COLOR_TABLE* = 0x80D5
  GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER* = 0x8A45
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR* = 0x93DB
  GL_REG_18_ATI* = 0x8933
  GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS* = 0x8266
  GL_UNPACK_FLIP_Y_WEBGL* = 0x9240
  GL_POLYGON_STIPPLE_BIT* = 0x00000010
  GL_MULTISAMPLE_BUFFER_BIT6_QCOM* = 0x40000000
  GL_ONE_MINUS_SRC_ALPHA* = 0x0303
  GL_RASTERIZER_DISCARD_EXT* = 0x8C89
  GL_BGRA_INTEGER* = 0x8D9B
  GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS* = 0x92CE
  GL_MODELVIEW1_EXT* = 0x850A
  GL_VERTEX_ELEMENT_SWIZZLE_AMD* = 0x91A4
  GL_MAP1_GRID_SEGMENTS* = 0x0DD1
  GL_PATH_ERROR_POSITION_NV* = 0x90AB
  GL_FOG_COORDINATE_ARRAY_EXT* = 0x8457
  GL_NUM_INPUT_INTERPOLATOR_COMPONENTS_ATI* = 0x8973
  GL_MAX_PROGRAM_TEX_INDIRECTIONS_ARB* = 0x880D
  GL_PATH_GEN_COLOR_FORMAT_NV* = 0x90B2
  GL_BUFFER_VARIABLE* = 0x92E5
  GL_PROXY_TEXTURE_CUBE_MAP_ARB* = 0x851B
  GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB* = 0x8E8D
  GL_TEXT_FRAGMENT_SHADER_ATI* = 0x8200
  GL_ALPHA_MAX_SGIX* = 0x8321
  GL_UNPACK_ALIGNMENT* = 0x0CF5
  GL_POST_COLOR_MATRIX_RED_SCALE* = 0x80B4
  GL_CIRCULAR_CW_ARC_TO_NV* = 0xFA
  GL_MAX_SAMPLES_APPLE* = 0x8D57
  GL_4PASS_3_SGIS* = 0x80A7
  GL_SAMPLER_3D_OES* = 0x8B5F
  GL_UNSIGNED_INT16_VEC2_NV* = 0x8FF1
  GL_UNSIGNED_INT_SAMPLER_1D_ARRAY* = 0x8DD6
  GL_REG_8_ATI* = 0x8929
  GL_UNSIGNED_SHORT_1_5_5_5_REV_EXT* = 0x8366
  GL_QUERY_RESULT_AVAILABLE_EXT* = 0x8867
  GL_INTENSITY8_EXT* = 0x804B
  GL_OUTPUT_TEXTURE_COORD9_EXT* = 0x87A6
  GL_TEXTURE_BINDING_RECTANGLE_NV* = 0x84F6
  GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_SCALE_NV* = 0x8853
  GL_IMAGE_FORMAT_COMPATIBILITY_TYPE* = 0x90C7
  GL_WRITE_ONLY* = 0x88B9
  GL_SAMPLER_1D_SHADOW* = 0x8B61
  GL_DISPATCH_INDIRECT_BUFFER_BINDING* = 0x90EF
  GL_VERTEX_PROGRAM_BINDING_NV* = 0x864A
  GL_RGB8_EXT* = 0x8051
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR* = 0x93D7
  GL_CON_5_ATI* = 0x8946
  GL_DUAL_INTENSITY8_SGIS* = 0x8119
  GL_MAX_SAMPLES_EXT* = 0x8D57
  GL_VERTEX_ARRAY_POINTER_EXT* = 0x808E
  GL_COMBINE_EXT* = 0x8570
  GL_MULTISAMPLE_BUFFER_BIT1_QCOM* = 0x02000000
  GL_MAGNITUDE_SCALE_NV* = 0x8712
  GL_SYNC_CONDITION_APPLE* = 0x9113
  GL_RGBA_S3TC* = 0x83A2
  GL_LINE_STIPPLE_REPEAT* = 0x0B26
  GL_TEXTURE_COMPRESSION_HINT* = 0x84EF
  GL_TEXTURE_COMPARE_MODE* = 0x884C
  GL_RGBA_FLOAT_MODE_ATI* = 0x8820
  GL_OPERAND0_RGB* = 0x8590
  GL_SIGNED_RGB8_UNSIGNED_ALPHA8_NV* = 0x870D
  GL_POST_COLOR_MATRIX_GREEN_SCALE_SGI* = 0x80B5
  GL_Z6Y10Z6CB10Z6Y10Z6CR10_422_NV* = 0x9033
  GL_UNPACK_ROW_LENGTH* = 0x0CF2
  GL_DOUBLE_MAT2_EXT* = 0x8F46
  GL_TEXTURE_GEQUAL_R_SGIX* = 0x819D
  GL_UNSIGNED_INT_8_24_REV_MESA* = 0x8752
  GL_DSDT8_NV* = 0x8709
  GL_RESAMPLE_DECIMATE_SGIX* = 0x8430
  GL_DEBUG_SOURCE_OTHER_KHR* = 0x824B
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_ARB* = 0x8DA8
  GL_MAX_VERTEX_UNITS_OES* = 0x86A4
  GL_ISOLINES* = 0x8E7A
  GL_INCR_WRAP* = 0x8507
  GL_BUFFER_MAP_POINTER* = 0x88BD
  GL_INT_SAMPLER_CUBE_MAP_ARRAY* = 0x900E
  GL_UNSIGNED_INT_VEC2* = 0x8DC6
  GL_RENDERBUFFER_HEIGHT_OES* = 0x8D43
  GL_COMPRESSED_RGBA_ASTC_10x10_KHR* = 0x93BB
  GL_PIXEL_TEX_GEN_ALPHA_MS_SGIX* = 0x818A
  GL_LINEAR_SHARPEN_COLOR_SGIS* = 0x80AF
  GL_COLOR_ATTACHMENT5_EXT* = 0x8CE5
  GL_VERTEX_ATTRIB_ARRAY9_NV* = 0x8659
  GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING* = 0x889D
  GL_BLEND_DST_RGB* = 0x80C8
  GL_VERTEX_ARRAY_EXT* = 0x8074
  GL_VERTEX_ARRAY_RANGE_POINTER_NV* = 0x8521
  GL_DEBUG_SEVERITY_MEDIUM_ARB* = 0x9147
  GL_OPERAND0_ALPHA* = 0x8598
  GL_TEXTURE_BINDING_CUBE_MAP* = 0x8514
  GL_ADD_ATI* = 0x8963
  GL_AUX1* = 0x040A
  GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT* = 0x8210
  GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS* = 0x8CD9
  GL_MINUS_NV* = 0x929F
  GL_RGB4* = 0x804F
  GL_COMPRESSED_RGBA_ASTC_12x12_KHR* = 0x93BD
  GL_MAX_GEOMETRY_OUTPUT_VERTICES* = 0x8DE0
  GL_SURFACE_STATE_NV* = 0x86EB
  GL_COLOR_MATERIAL_FACE* = 0x0B55
  GL_TEXTURE18_ARB* = 0x84D2
  GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2_OES* = 0x9277
  GL_LOWER_LEFT* = 0x8CA1
  GL_DRAW_BUFFER8_ATI* = 0x882D
  GL_TEXTURE_CONSTANT_DATA_SUNX* = 0x81D6
  GL_SAMPLER_1D* = 0x8B5D
  GL_POLYGON_OFFSET_EXT* = 0x8037
  GL_EQUIV* = 0x1509
  GL_QUERY_BUFFER_BINDING* = 0x9193
  GL_COMBINE_ARB* = 0x8570
  GL_MATRIX0_NV* = 0x8630
  GL_CLAMP_TO_BORDER_SGIS* = 0x812D
  GL_INTENSITY8UI_EXT* = 0x8D7F
  GL_TRACK_MATRIX_TRANSFORM_NV* = 0x8649
  GL_SURFACE_MAPPED_NV* = 0x8700
  GL_INT_VEC3_ARB* = 0x8B54
  GL_IMAGE_TRANSFORM_2D_HP* = 0x8161
  GL_PROGRAM_BINARY_RETRIEVABLE_HINT* = 0x8257
  GL_DRAW_BUFFER8_EXT* = 0x882D
  GL_DEPTH_STENCIL_EXT* = 0x84F9
  GL_CONTEXT_PROFILE_MASK* = 0x9126
  GL_MAX_PROGRAM_NATIVE_INSTRUCTIONS_ARB* = 0x88A3
  GL_MATRIX5_ARB* = 0x88C5
  GL_FRAMEBUFFER_UNDEFINED_OES* = 0x8219
  GL_UNPACK_CMYK_HINT_EXT* = 0x800F
  GL_UNSIGNED_NORMALIZED_EXT* = 0x8C17
  GL_ONE* = 1
  GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB* = 0x889B
  GL_TRANSPOSE_PROJECTION_MATRIX* = 0x84E4
  GL_MAX_PROGRAM_TOTAL_OUTPUT_COMPONENTS_NV* = 0x8C28
  GL_CLIP_DISTANCE3* = 0x3003
  GL_4PASS_1_SGIS* = 0x80A5
  GL_MAX_FRAGMENT_LIGHTS_SGIX* = 0x8404
  GL_TEXTURE_3D_OES* = 0x806F
  GL_TEXTURE0* = 0x84C0
  GL_INT_IMAGE_CUBE_EXT* = 0x905B
  GL_INNOCENT_CONTEXT_RESET_ARB* = 0x8254
  GL_INDEX_ARRAY_TYPE_EXT* = 0x8085
  GL_SAMPLER_OBJECT_AMD* = 0x9155
  GL_INDEX_ARRAY_BUFFER_BINDING_ARB* = 0x8899
  GL_RENDERBUFFER_DEPTH_SIZE_OES* = 0x8D54
  GL_MAX_SAMPLE_MASK_WORDS* = 0x8E59
  GL_COMBINER2_NV* = 0x8552
  GL_COLOR_ARRAY_BUFFER_BINDING_ARB* = 0x8898
  GL_VERTEX_ATTRIB_ARRAY_NORMALIZED_ARB* = 0x886A
  GL_STREAM_DRAW* = 0x88E0
  GL_RGB8I* = 0x8D8F
  GL_BLEND_COLOR_EXT* = 0x8005
  GL_MAX_VARYING_VECTORS* = 0x8DFC
  GL_COPY_WRITE_BUFFER_BINDING* = 0x8F37
  GL_FIXED_ONLY_ARB* = 0x891D
  GL_INT_VEC4* = 0x8B55
  GL_PROGRAM_PIPELINE_BINDING_EXT* = 0x825A
  GL_UNSIGNED_NORMALIZED_ARB* = 0x8C17
  GL_NUM_INSTRUCTIONS_PER_PASS_ATI* = 0x8971
  GL_PIXEL_MODE_BIT* = 0x00000020
  GL_COMPRESSED_RED_RGTC1* = 0x8DBB
  GL_SHADER_IMAGE_ACCESS_BARRIER_BIT_EXT* = 0x00000020
  GL_VARIANT_DATATYPE_EXT* = 0x87E5
  GL_DARKEN_NV* = 0x9297
  GL_POINT_SIZE_MAX_SGIS* = 0x8127
  GL_OBJECT_ATTACHED_OBJECTS_ARB* = 0x8B85
  GL_SLUMINANCE_ALPHA_EXT* = 0x8C44
  GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY* = 0x906A
  GL_EDGE_FLAG_ARRAY* = 0x8079
  GL_LINEAR_CLIPMAP_NEAREST_SGIX* = 0x844F
  GL_LUMINANCE_ALPHA32F_EXT* = 0x8819
  GL_NORMAL_BIT_PGI* = 0x08000000
  GL_SECONDARY_COLOR_ARRAY* = 0x845E
  GL_CLIP_PLANE1_IMG* = 0x3001
  GL_REG_19_ATI* = 0x8934
  GL_PIXEL_PACK_BUFFER_BINDING* = 0x88ED
  GL_PIXEL_GROUP_COLOR_SGIS* = 0x8356
  GL_SELECTION_BUFFER_SIZE* = 0x0DF4
  GL_SRC_OUT_NV* = 0x928C
  GL_TEXTURE7* = 0x84C7
  GL_COMPARE_R_TO_TEXTURE* = 0x884E
  GL_DUDV_ATI* = 0x8779
  GL_TEXTURE_BASE_LEVEL* = 0x813C
  GL_PN_TRIANGLES_POINT_MODE_LINEAR_ATI* = 0x87F5
  GL_LAYOUT_LINEAR_INTEL* = 1
  GL_DEPTH_BUFFER_BIT2_QCOM* = 0x00000400
  GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS* = 0x8E8A
  GL_LIGHT3* = 0x4003
  GL_ALPHA_MAX_CLAMP_INGR* = 0x8567
  GL_RG_INTEGER* = 0x8228
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL* = 0x8CD2
  GL_TEXTURE_STACK_DEPTH* = 0x0BA5
  GL_ALREADY_SIGNALED* = 0x911A
  GL_TEXTURE_CUBE_MAP_OES* = 0x8513
  GL_N3F_V3F* = 0x2A25
  GL_SUBTRACT_ARB* = 0x84E7
  GL_ELEMENT_ARRAY_LENGTH_NV* = 0x8F33
  GL_NORMAL_ARRAY_EXT* = 0x8075
  GL_POLYGON_OFFSET_FACTOR_EXT* = 0x8038
  GL_EIGHTH_BIT_ATI* = 0x00000020
  GL_UNSIGNED_INT_SAMPLER_2D_RECT* = 0x8DD5
  GL_OBJECT_ACTIVE_ATTRIBUTES_ARB* = 0x8B89
  GL_MAX_VERTEX_VARYING_COMPONENTS_ARB* = 0x8DDE
  GL_TEXTURE_COORD_ARRAY_STRIDE_EXT* = 0x808A
  GL_4_BYTES* = 0x1409
  GL_SAMPLE_SHADING* = 0x8C36
  GL_FOG_MODE* = 0x0B65
  GL_CON_7_ATI* = 0x8948
  GL_DRAW_FRAMEBUFFER* = 0x8CA9
  GL_TEXTURE_MEMORY_LAYOUT_INTEL* = 0x83FF
  GL_RGB32I_EXT* = 0x8D83
  GL_VERTEX_ARRAY_STRIDE* = 0x807C
  GL_COLOR_ATTACHMENT3_NV* = 0x8CE3
  GL_NORMAL_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F6
  GL_CONTRAST_NV* = 0x92A1
  GL_RGBA32F* = 0x8814
  GL_YCBAYCR8A_4224_NV* = 0x9032
  GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET* = 0x82D9
  GL_TEXTURE22* = 0x84D6
  GL_TEXTURE_3D* = 0x806F
  GL_STENCIL_PASS_DEPTH_FAIL* = 0x0B95
  GL_PROXY_HISTOGRAM_EXT* = 0x8025
  GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS* = 0x92C5
  GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE* = 0x92D8
  GL_FOG_COORD_ARRAY_TYPE* = 0x8454
  GL_MAP2_VERTEX_4* = 0x0DB8
  GL_PACK_COMPRESSED_SIZE_SGIX* = 0x831C
  GL_POST_TEXTURE_FILTER_SCALE_RANGE_SGIX* = 0x817C
  GL_ITALIC_BIT_NV* = 0x02
  GL_COMPRESSED_LUMINANCE_ALPHA* = 0x84EB
  GL_COLOR_TABLE_SCALE_SGI* = 0x80D6
  GL_DOUBLE_MAT2x4_EXT* = 0x8F4A
  GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE* = 0x8215
  GL_MATRIX11_ARB* = 0x88CB
  GL_REG_5_ATI* = 0x8926
  GL_RGBA2_EXT* = 0x8055
  GL_DISCARD_NV* = 0x8530
  GL_TEXTURE7_ARB* = 0x84C7
  GL_LUMINANCE32UI_EXT* = 0x8D74
  GL_ACTIVE_UNIFORM_BLOCKS* = 0x8A36
  GL_UNSIGNED_INT16_VEC4_NV* = 0x8FF3
  GL_VERTEX_ATTRIB_ARRAY5_NV* = 0x8655
  GL_DOUBLE_MAT3x4* = 0x8F4C
  GL_BOOL* = 0x8B56
  GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB* = 0x86A2
  GL_COMPRESSED_RGB_ARB* = 0x84ED
  GL_DEBUG_TYPE_MARKER_KHR* = 0x8268
  GL_TEXTURE_DEPTH_QCOM* = 0x8BD4
  GL_VARIABLE_F_NV* = 0x8528
  GL_MAX_PIXEL_MAP_TABLE* = 0x0D34
  GL_DST_COLOR* = 0x0306
  GL_OR_INVERTED* = 0x150D
  GL_TRANSFORM_FEEDBACK_VARYINGS_NV* = 0x8C83
  GL_RGB_INTEGER* = 0x8D98
  GL_COLOR_MATERIAL* = 0x0B57
  GL_DEBUG_SEVERITY_LOW_AMD* = 0x9148
  GL_MIRROR_CLAMP_TO_BORDER_EXT* = 0x8912
  GL_TEXTURE1_ARB* = 0x84C1
  GL_MIN_MAP_BUFFER_ALIGNMENT* = 0x90BC
  GL_MATRIX16_ARB* = 0x88D0
  GL_TEXTURE_ALPHA_TYPE_ARB* = 0x8C13
  GL_PROGRAM_POINT_SIZE* = 0x8642
  GL_COMBINER_AB_OUTPUT_NV* = 0x854A
  GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2_OES* = 0x9276
  GL_RGB4_S3TC* = 0x83A1
  GL_TEXTURE_EXTERNAL_OES* = 0x8D65
  GL_MAX_MAP_TESSELLATION_NV* = 0x86D6
  GL_AUX_DEPTH_STENCIL_APPLE* = 0x8A14
  GL_MAX_DEBUG_LOGGED_MESSAGES_AMD* = 0x9144
  GL_CONSTANT_BORDER* = 0x8151
  GL_RESAMPLE_ZERO_FILL_OML* = 0x8987
  GL_POST_CONVOLUTION_ALPHA_SCALE_EXT* = 0x801F
  GL_OBJECT_VALIDATE_STATUS_ARB* = 0x8B83
  GL_DST_ALPHA* = 0x0304
  GL_COMBINER5_NV* = 0x8555
  GL_VERSION_ES_CL_1_1* = 1
  GL_MOVE_TO_CONTINUES_NV* = 0x90B6
  GL_IMAGE_MAG_FILTER_HP* = 0x815C
  GL_TEXTURE_FREE_MEMORY_ATI* = 0x87FC
  GL_DEBUG_TYPE_PORTABILITY_KHR* = 0x824F
  GL_BUFFER_UPDATE_BARRIER_BIT* = 0x00000200
  GL_FUNC_ADD* = 0x8006
  GL_PN_TRIANGLES_POINT_MODE_ATI* = 0x87F2
  GL_DEBUG_CALLBACK_USER_PARAM_ARB* = 0x8245
  GL_CURRENT_SECONDARY_COLOR* = 0x8459
  GL_DEPENDENT_RGB_TEXTURE_CUBE_MAP_NV* = 0x885A
  GL_FRAGMENT_LIGHT7_SGIX* = 0x8413
  GL_MAP2_TEXTURE_COORD_4* = 0x0DB6
  GL_PACK_ALIGNMENT* = 0x0D05
  GL_VERTEX23_BIT_PGI* = 0x00000004
  GL_MAX_CLIPMAP_DEPTH_SGIX* = 0x8177
  GL_TEXTURE_3D_BINDING_EXT* = 0x806A
  GL_COLOR_ATTACHMENT1* = 0x8CE1
  GL_NEAREST* = 0x2600
  GL_MAX_DEBUG_LOGGED_MESSAGES* = 0x9144
  GL_COMBINER6_NV* = 0x8556
  GL_COLOR_SUM_EXT* = 0x8458
  GL_CONVOLUTION_WIDTH* = 0x8018
  GL_SAMPLE_ALPHA_TO_COVERAGE_ARB* = 0x809E
  GL_DRAW_FRAMEBUFFER_EXT* = 0x8CA9
  GL_PROXY_HISTOGRAM* = 0x8025
  GL_PIXEL_FRAGMENT_ALPHA_SOURCE_SGIS* = 0x8355
  GL_COMPRESSED_RGBA_ASTC_10x5_KHR* = 0x93B8
  GL_SMOOTH_CUBIC_CURVE_TO_NV* = 0x10
  GL_BGR_EXT* = 0x80E0
  GL_PROGRAM_UNDER_NATIVE_LIMITS_ARB* = 0x88B6
  GL_VIBRANCE_BIAS_NV* = 0x8719
  GL_UNPACK_COLORSPACE_CONVERSION_WEBGL* = 0x9243
  GL_SLUMINANCE8_NV* = 0x8C47
  GL_TEXTURE_MAX_LEVEL_SGIS* = 0x813D
  GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX* = 0x92DA
  GL_RGB9_E5_EXT* = 0x8C3D
  GL_CULL_VERTEX_IBM* = 103050
  GL_PROXY_COLOR_TABLE* = 0x80D3
  GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE* = 0x8216
  GL_MAX_FRAGMENT_UNIFORM_COMPONENTS* = 0x8B49
  GL_CCW* = 0x0901
  GL_COLOR_WRITEMASK* = 0x0C23
  GL_TEXTURE19_ARB* = 0x84D3
  GL_VERTEX_STREAM3_ATI* = 0x876F
  GL_ONE_EXT* = 0x87DE
  GL_MAX_SAMPLES* = 0x8D57
  GL_STENCIL_PASS_DEPTH_PASS* = 0x0B96
  GL_PERFMON_RESULT_AVAILABLE_AMD* = 0x8BC4
  GL_RETURN* = 0x0102
  GL_DETAIL_TEXTURE_LEVEL_SGIS* = 0x809A
  GL_UNSIGNED_INT_IMAGE_CUBE_EXT* = 0x9066
  GL_FOG_OFFSET_VALUE_SGIX* = 0x8199
  GL_TEXTURE_MAX_LOD_SGIS* = 0x813B
  GL_TRANSPOSE_COLOR_MATRIX_ARB* = 0x84E6
  GL_DEBUG_SOURCE_APPLICATION_ARB* = 0x824A
  GL_SIGNED_ALPHA_NV* = 0x8705
  GL_UNSIGNED_INT_IMAGE_2D_EXT* = 0x9063
  GL_SHADER_IMAGE_ACCESS_BARRIER_BIT* = 0x00000020
  GL_ATOMIC_COUNTER_BARRIER_BIT* = 0x00001000
  GL_COLOR3_BIT_PGI* = 0x00010000
  GL_MATERIAL_SIDE_HINT_PGI* = 0x1A22C
  GL_LIGHT_MODEL_SPECULAR_VECTOR_APPLE* = 0x85B0
  GL_LINEAR_SHARPEN_SGIS* = 0x80AD
  GL_LUMINANCE_SNORM* = 0x9011
  GL_TEXTURE_LUMINANCE_SIZE* = 0x8060
  GL_REPLACE_MIDDLE_SUN* = 0x0002
  GL_TEXTURE_DEFORMATION_SGIX* = 0x8195
  GL_MULTISAMPLE_BUFFER_BIT7_QCOM* = 0x80000000
  GL_FONT_HAS_KERNING_BIT_NV* = 0x10000000
  GL_COPY* = 0x1503
  GL_READ_BUFFER_NV* = 0x0C02
  GL_TRANSPOSE_CURRENT_MATRIX_ARB* = 0x88B7
  GL_VERTEX_ARRAY_OBJECT_AMD* = 0x9154
  GL_TIMEOUT_EXPIRED* = 0x911B
  GL_DYNAMIC_COPY* = 0x88EA
  GL_DRAW_BUFFER2_ARB* = 0x8827
  GL_OUTPUT_TEXTURE_COORD10_EXT* = 0x87A7
  GL_SIGNED_RGBA8_NV* = 0x86FC
  GL_MATRIX6_ARB* = 0x88C6
  GL_OP_SUB_EXT* = 0x8796
  GL_NO_RESET_NOTIFICATION_EXT* = 0x8261
  GL_TEXTURE_BASE_LEVEL_SGIS* = 0x813C
  GL_ALPHA_INTEGER* = 0x8D97
  GL_TEXTURE13* = 0x84CD
  GL_EYE_LINEAR* = 0x2400
  GL_INTENSITY4_EXT* = 0x804A
  GL_SOURCE1_RGB_EXT* = 0x8581
  GL_AUX_BUFFERS* = 0x0C00
  GL_SOURCE0_ALPHA* = 0x8588
  GL_RGB32I* = 0x8D83
  GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS* = 0x8C8A
  GL_VIEW_CLASS_S3TC_DXT1_RGBA* = 0x82CD
  GL_TRANSFORM_FEEDBACK_BUFFER_SIZE_NV* = 0x8C85
  GL_SAMPLER_KHR* = 0x82E6
  GL_WRITEONLY_RENDERING_QCOM* = 0x8823
  GL_PACK_SKIP_ROWS* = 0x0D03
  GL_MAP1_VERTEX_ATTRIB0_4_NV* = 0x8660
  GL_PATH_STENCIL_VALUE_MASK_NV* = 0x90B9
  GL_REPLACE_EXT* = 0x8062
  GL_MODELVIEW3_ARB* = 0x8723
  GL_ONE_MINUS_CONSTANT_ALPHA* = 0x8004
  GL_DSDT8_MAG8_INTENSITY8_NV* = 0x870B
  GL_CURRENT_QUERY_ARB* = 0x8865
  GL_LUMINANCE8_ALPHA8_OES* = 0x8045
  GL_ARRAY_ELEMENT_LOCK_COUNT_EXT* = 0x81A9
  GL_MODELVIEW19_ARB* = 0x8733
  GL_MAX_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x87C5
  GL_MAX_PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB* = 0x8810
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x906C
  GL_NORMAL_ARRAY_BUFFER_BINDING* = 0x8897
  GL_AMBIENT* = 0x1200
  GL_TEXTURE_MATERIAL_PARAMETER_EXT* = 0x8352
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR* = 0x93DA
  GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS* = 0x8E7F
  GL_COMPRESSED_LUMINANCE_ALPHA_ARB* = 0x84EB
  GL_MODELVIEW14_ARB* = 0x872E
  GL_INTERLACE_READ_OML* = 0x8981
  GL_RENDERBUFFER_FREE_MEMORY_ATI* = 0x87FD
  GL_EMBOSS_MAP_NV* = 0x855F
  GL_POINT_SIZE_RANGE* = 0x0B12
  GL_FOG_COORDINATE* = 0x8451
  GL_MAJOR_VERSION* = 0x821B
  GL_FRAME_NV* = 0x8E26
  GL_CURRENT_TEXTURE_COORDS* = 0x0B03
  GL_PACK_RESAMPLE_OML* = 0x8984
  GL_DEPTH24_STENCIL8_OES* = 0x88F0
  GL_PROGRAM_BINARY_FORMATS_OES* = 0x87FF
  GL_TRANSLATE_3D_NV* = 0x9091
  GL_TEXTURE_GEN_Q* = 0x0C63
  GL_COLOR_ATTACHMENT0_EXT* = 0x8CE0
  GL_ALPHA12* = 0x803D
  GL_INCR_WRAP_EXT* = 0x8507
  GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN* = 0x8C88
  GL_DUAL_ALPHA12_SGIS* = 0x8112
  GL_EYE_LINE_SGIS* = 0x81F6
  GL_TEXTURE_MAX_LEVEL_APPLE* = 0x813D
  GL_TRIANGLE_FAN* = 0x0006
  GL_DEBUG_GROUP_STACK_DEPTH* = 0x826D
  GL_IMAGE_CLASS_1_X_16* = 0x82BE
  GL_COMPILE* = 0x1300
  GL_LINE_SMOOTH* = 0x0B20
  GL_FEEDBACK_BUFFER_POINTER* = 0x0DF0
  GL_CURRENT_SECONDARY_COLOR_EXT* = 0x8459
  GL_DRAW_BUFFER2_ATI* = 0x8827
  GL_PN_TRIANGLES_NORMAL_MODE_ATI* = 0x87F3
  GL_MODELVIEW0_ARB* = 0x1700
  GL_SRGB8_ALPHA8* = 0x8C43
  GL_TEXTURE_BLUE_TYPE* = 0x8C12
  GL_POST_CONVOLUTION_ALPHA_BIAS* = 0x8023
  GL_PATH_STROKE_BOUNDING_BOX_NV* = 0x90A2
  GL_RGBA16UI* = 0x8D76
  GL_OFFSET_HILO_TEXTURE_2D_NV* = 0x8854
  GL_PREVIOUS_ARB* = 0x8578
  GL_BINORMAL_ARRAY_EXT* = 0x843A
  GL_UNSIGNED_INT_IMAGE_CUBE* = 0x9066
  GL_REG_30_ATI* = 0x893F
  GL_VIEWPORT_SUBPIXEL_BITS* = 0x825C
  GL_VERSION* = 0x1F02
  GL_COMPUTE_PROGRAM_PARAMETER_BUFFER_NV* = 0x90FC
  GL_DEBUG_CATEGORY_SHADER_COMPILER_AMD* = 0x914E
  GL_CONVOLUTION_FILTER_SCALE_EXT* = 0x8014
  GL_HALF_BIT_ATI* = 0x00000008
  GL_SPRITE_AXIS_SGIX* = 0x814A
  GL_INDEX_ARRAY_STRIDE* = 0x8086
  GL_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB* = 0x88B2
  GL_EVAL_VERTEX_ATTRIB0_NV* = 0x86C6
  GL_COUNTER_RANGE_AMD* = 0x8BC1
  GL_VERTEX_WEIGHTING_EXT* = 0x8509
  GL_POST_CONVOLUTION_GREEN_SCALE* = 0x801D
  GL_UNSIGNED_INT8_NV* = 0x8FEC
  GL_CURRENT_MATRIX_STACK_DEPTH_NV* = 0x8640
  GL_STENCIL_INDEX1_OES* = 0x8D46
  GL_SLUMINANCE_NV* = 0x8C46
  GL_UNSIGNED_INT_8_8_8_8_REV_EXT* = 0x8367
  GL_HISTOGRAM_FORMAT* = 0x8027
  GL_LUMINANCE12_ALPHA4_EXT* = 0x8046
  GL_FLOAT_MAT3* = 0x8B5B
  GL_MAX_PROGRAM_TEXEL_OFFSET_NV* = 0x8905
  GL_PALETTE8_RGBA4_OES* = 0x8B98
  GL_UNPACK_SKIP_IMAGES_EXT* = 0x806D
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y* = 0x8518
  GL_UNPACK_SUBSAMPLE_RATE_SGIX* = 0x85A1
  GL_NORMAL_ARRAY_LENGTH_NV* = 0x8F2C
  GL_VERTEX_ATTRIB_ARRAY4_NV* = 0x8654
  GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES* = 0x8CD9
  GL_UNSIGNED_BYTE* = 0x1401
  GL_RGB2_EXT* = 0x804E
  GL_TEXTURE_BUFFER_SIZE* = 0x919E
  GL_MAP_STENCIL* = 0x0D11
  GL_TIMEOUT_EXPIRED_APPLE* = 0x911B
  GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS* = 0x8C29
  GL_CON_14_ATI* = 0x894F
  GL_RGBA12* = 0x805A
  GL_MAX_SPARSE_ARRAY_TEXTURE_LAYERS* = 0x919A
  GL_CON_20_ATI* = 0x8955
  GL_LOCAL_CONSTANT_DATATYPE_EXT* = 0x87ED
  GL_DUP_FIRST_CUBIC_CURVE_TO_NV* = 0xF2
  GL_SECONDARY_COLOR_ARRAY_ADDRESS_NV* = 0x8F27
  GL_TEXTURE_COORD_ARRAY* = 0x8078
  GL_LUMINANCE8I_EXT* = 0x8D92
  GL_REPLACE_OLDEST_SUN* = 0x0003
  GL_TEXTURE_SHADER_NV* = 0x86DE
  GL_UNSIGNED_INT_8_8_8_8_EXT* = 0x8035
  GL_SAMPLE_COVERAGE_INVERT* = 0x80AB
  GL_FOG_COORD_ARRAY_ADDRESS_NV* = 0x8F28
  GL_GPU_DISJOINT_EXT* = 0x8FBB
  GL_STENCIL_BACK_PASS_DEPTH_PASS_ATI* = 0x8803
  GL_TEXTURE_GREEN_SIZE_EXT* = 0x805D
  GL_INTERLEAVED_ATTRIBS* = 0x8C8C
  GL_FOG_FUNC_SGIS* = 0x812A
  GL_TEXTURE_DEPTH_SIZE_ARB* = 0x884A
  GL_MAP_COHERENT_BIT* = 0x0080
  GL_COMPRESSED_SLUMINANCE_ALPHA* = 0x8C4B
  GL_RGB32UI* = 0x8D71
  GL_SEPARABLE_2D* = 0x8012
  GL_MATRIX10_ARB* = 0x88CA
  GL_FLOAT_RGBA32_NV* = 0x888B
  GL_MAX_SPARSE_3D_TEXTURE_SIZE_ARB* = 0x9199
  GL_TEXTURE_RENDERBUFFER_DATA_STORE_BINDING_NV* = 0x8E54
  GL_REG_9_ATI* = 0x892A
  GL_MAP2_VERTEX_ATTRIB14_4_NV* = 0x867E
  GL_OP_EXP_BASE_2_EXT* = 0x8791
  GL_INT_IMAGE_BUFFER_EXT* = 0x905C
  GL_TEXTURE_WRAP_R_EXT* = 0x8072
  GL_DOUBLE_VEC3* = 0x8FFD
  GL_DRAW_BUFFER5_EXT* = 0x882A
  GL_OUTPUT_TEXTURE_COORD7_EXT* = 0x87A4
  GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB* = 0x8242
  GL_MAX_TESS_GEN_LEVEL* = 0x8E7E
  GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB* = 0x8895
  GL_RGBA16I_EXT* = 0x8D88
  GL_REG_10_ATI* = 0x892B
  GL_MAT_EMISSION_BIT_PGI* = 0x00800000
  GL_TEXTURE_COORD_ARRAY_SIZE_EXT* = 0x8088
  GL_RED_BIAS* = 0x0D15
  GL_RGB16F_ARB* = 0x881B
  GL_ANY_SAMPLES_PASSED_CONSERVATIVE* = 0x8D6A
  GL_BLUE_MAX_CLAMP_INGR* = 0x8566
  cGL_FLOAT* = 0x1406
  GL_STENCIL_INDEX8_EXT* = 0x8D48
  GL_POINT_SIZE_ARRAY_OES* = 0x8B9C
  GL_INT16_NV* = 0x8FE4
  GL_PALETTE4_RGB8_OES* = 0x8B90
  GL_RENDERBUFFER_GREEN_SIZE_OES* = 0x8D51
  GL_SEPARATE_ATTRIBS_NV* = 0x8C8D
  GL_BOOL_VEC3_ARB* = 0x8B58
  GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES* = 0x92C6
  GL_STACK_UNDERFLOW_KHR* = 0x0504
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB* = 0x8519
  GL_COMPRESSED_INTENSITY_ARB* = 0x84EC
  GL_MAX_ASYNC_TEX_IMAGE_SGIX* = 0x835F
  GL_TEXTURE_4D_SGIS* = 0x8134
  GL_TEXCOORD3_BIT_PGI* = 0x40000000
  GL_PIXEL_MAP_I_TO_R_SIZE* = 0x0CB2
  GL_NORMAL_MAP_ARB* = 0x8511
  GL_MAX_CONVOLUTION_HEIGHT* = 0x801B
  GL_COMPRESSED_INTENSITY* = 0x84EC
  GL_FONT_Y_MAX_BOUNDS_BIT_NV* = 0x00080000
  GL_FLOAT_MAT2* = 0x8B5A
  GL_TEXTURE_SRGB_DECODE_EXT* = 0x8A48
  GL_FRAMEBUFFER_BLEND* = 0x828B
  GL_TEXTURE_COORD_ARRAY_LIST_IBM* = 103074
  GL_REG_12_ATI* = 0x892D
  GL_UNSIGNED_INT_ATOMIC_COUNTER* = 0x92DB
  GL_DETAIL_TEXTURE_2D_BINDING_SGIS* = 0x8096
  GL_OCCLUSION_TEST_HP* = 0x8165
  GL_TEXTURE11_ARB* = 0x84CB
  GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC* = 0x9279
  GL_BUFFER_MAPPED* = 0x88BC
  GL_VARIANT_ARRAY_STRIDE_EXT* = 0x87E6
  GL_CONVOLUTION_BORDER_COLOR_HP* = 0x8154
  GL_UNPACK_RESAMPLE_OML* = 0x8985
  GL_TRANSFORM_FEEDBACK_BUFFER_SIZE* = 0x8C85
  GL_PROXY_TEXTURE_2D_ARRAY_EXT* = 0x8C1B
  GL_RGBA4_EXT* = 0x8056
  GL_ALPHA32I_EXT* = 0x8D84
  GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE* = 0x92C4
  GL_FRAGMENT_LIGHT_MODEL_AMBIENT_SGIX* = 0x840A
  GL_BINORMAL_ARRAY_TYPE_EXT* = 0x8440
  GL_VIEW_CLASS_S3TC_DXT5_RGBA* = 0x82CF
  GL_TEXTURE_CLIPMAP_OFFSET_SGIX* = 0x8173
  GL_RESTART_SUN* = 0x0001
  GL_PERTURB_EXT* = 0x85AE
  GL_UNSIGNED_BYTE_3_3_2_EXT* = 0x8032
  GL_LUMINANCE16I_EXT* = 0x8D8C
  GL_TEXTURE3_ARB* = 0x84C3
  GL_POINT_SIZE_MIN_EXT* = 0x8126
  GL_OUTPUT_TEXTURE_COORD1_EXT* = 0x879E
  GL_COMPARE_REF_TO_TEXTURE* = 0x884E
  GL_KEEP* = 0x1E00
  GL_FLOAT_MAT2x4* = 0x8B66
  GL_FLOAT_VEC4_ARB* = 0x8B52
  GL_BIAS_BY_NEGATIVE_ONE_HALF_NV* = 0x8541
  GL_BGR* = 0x80E0
  GL_SHADER_BINARY_FORMATS* = 0x8DF8
  GL_CND0_ATI* = 0x896B
  GL_MIRRORED_REPEAT_IBM* = 0x8370
  GL_REFLECTION_MAP_OES* = 0x8512
  GL_MAX_VERTEX_BINDABLE_UNIFORMS_EXT* = 0x8DE2
  GL_R* = 0x2002
  GL_MAX_SHADER_STORAGE_BLOCK_SIZE* = 0x90DE
  GL_ATTRIB_ARRAY_STRIDE_NV* = 0x8624
  GL_VARIABLE_E_NV* = 0x8527
  GL_HISTOGRAM_EXT* = 0x8024
  GL_TEXTURE_BINDING_BUFFER_ARB* = 0x8C2C
  GL_MAX_SPARSE_TEXTURE_SIZE_ARB* = 0x9198
  GL_TEXTURE5* = 0x84C5
  GL_NUM_ACTIVE_VARIABLES* = 0x9304
  GL_DEPTH_STENCIL_ATTACHMENT* = 0x821A
  GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB* = 0x889E
  GL_AMBIENT_AND_DIFFUSE* = 0x1602
  GL_LAYER_NV* = 0x8DAA
  GL_GLYPH_HORIZONTAL_BEARING_Y_BIT_NV* = 0x08
  GL_TEXTURE8* = 0x84C8
  GL_MODELVIEW5_ARB* = 0x8725
  GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS* = 0x92D1
  GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS* = 0x92CD
  GL_BLUE_MIN_CLAMP_INGR* = 0x8562
  GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS* = 0x90D9
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z_OES* = 0x8519
  GL_MAX_SAMPLES_IMG* = 0x9135
  GL_QUERY_BY_REGION_WAIT* = 0x8E15
  GL_T* = 0x2001
  GL_VIEW_CLASS_RGTC2_RG* = 0x82D1
  GL_TEXTURE_ENV_MODE* = 0x2200
  GL_COMPRESSED_SRGB8_ETC2* = 0x9275
  GL_MAP_FLUSH_EXPLICIT_BIT* = 0x0010
  GL_COLOR_MATERIAL_PARAMETER* = 0x0B56
  GL_HALF_FLOAT_ARB* = 0x140B
  GL_NOTEQUAL* = 0x0205
  GL_MAP_INVALIDATE_BUFFER_BIT_EXT* = 0x0008
  GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_EXT* = 0x8C29
  GL_DUAL_TEXTURE_SELECT_SGIS* = 0x8124
  GL_TEXTURE31* = 0x84DF
  GL_EVAL_TRIANGULAR_2D_NV* = 0x86C1
  GL_VIDEO_COLOR_CONVERSION_OFFSET_NV* = 0x902C
  GL_COMPRESSED_R11_EAC_OES* = 0x9270
  GL_RGB8_OES* = 0x8051
  GL_CLIP_PLANE2* = 0x3002
  GL_HINT_BIT* = 0x00008000
  GL_TEXTURE6_ARB* = 0x84C6
  GL_FLOAT_VEC2* = 0x8B50
  GL_TRANSFORM_FEEDBACK_BUFFER_SIZE_EXT* = 0x8C85
  GL_MAX_EVAL_ORDER* = 0x0D30
  GL_DUAL_LUMINANCE8_SGIS* = 0x8115
  GL_ALPHA16I_EXT* = 0x8D8A
  GL_IDENTITY_NV* = 0x862A
  GL_VIEW_CLASS_BPTC_UNORM* = 0x82D2
  GL_PATH_DASH_CAPS_NV* = 0x907B
  GL_IGNORE_BORDER_HP* = 0x8150
  GL_PN_TRIANGLES_POINT_MODE_CUBIC_ATI* = 0x87F6
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS_EXT* = 0x8C8B
  GL_DRAW_BUFFER1_ATI* = 0x8826
  GL_TEXTURE_MIN_FILTER* = 0x2801
  GL_EVAL_VERTEX_ATTRIB12_NV* = 0x86D2
  GL_INT_IMAGE_2D_ARRAY* = 0x905E
  GL_SRC0_RGB* = 0x8580
  GL_MIN_EXT* = 0x8007
  GL_PROGRAM_PIPELINE_OBJECT_EXT* = 0x8A4F
  GL_STENCIL_BUFFER_BIT* = 0x00000400
  GL_SCREEN_COORDINATES_REND* = 0x8490
  GL_DOUBLE_VEC3_EXT* = 0x8FFD
  GL_SUBSAMPLE_DISTANCE_AMD* = 0x883F
  GL_VERTEX_SHADER_LOCALS_EXT* = 0x87D3
  GL_VERTEX_ATTRIB_ARRAY13_NV* = 0x865D
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR* = 0x93D9
  GL_UNSIGNED_NORMALIZED* = 0x8C17
  GL_DRAW_BUFFER10_NV* = 0x882F
  GL_PATH_STROKE_MASK_NV* = 0x9084
  GL_MAX_PROGRAM_NATIVE_TEMPORARIES_ARB* = 0x88A7
  GL_SRGB_ALPHA_EXT* = 0x8C42
  GL_CONST_EYE_NV* = 0x86E5
  GL_MODELVIEW1_ARB* = 0x850A
  GL_FORMAT_SUBSAMPLE_244_244_OML* = 0x8983
  GL_LOGIC_OP_MODE* = 0x0BF0
  GL_CLIP_DISTANCE4* = 0x3004
  GL_DEBUG_CATEGORY_WINDOW_SYSTEM_AMD* = 0x914A
  GL_SAMPLES* = 0x80A9
  GL_UNSIGNED_SHORT_5_5_5_1_EXT* = 0x8034
  GL_POINT_DISTANCE_ATTENUATION* = 0x8129
  GL_3D_COLOR* = 0x0602
  GL_BGRA* = 0x80E1
  GL_PARAMETER_BUFFER_BINDING_ARB* = 0x80EF
  GL_EDGE_FLAG_ARRAY_LIST_STRIDE_IBM* = 103085
  GL_HSL_LUMINOSITY_NV* = 0x92B0
  GL_PROJECTION_STACK_DEPTH* = 0x0BA4
  GL_COMBINER_BIAS_NV* = 0x8549
  GL_AND* = 0x1501
  GL_TEXTURE27* = 0x84DB
  GL_VERTEX_PROGRAM_CALLBACK_DATA_MESA* = 0x8BB7
  GL_DRAW_BUFFER13_ATI* = 0x8832
  GL_UNSIGNED_SHORT_5_5_5_1* = 0x8034
  GL_PERFMON_GLOBAL_MODE_QCOM* = 0x8FA0
  GL_RED_EXT* = 0x1903
  GL_INNOCENT_CONTEXT_RESET_EXT* = 0x8254
  GL_UNIFORM_BUFFER_START* = 0x8A29
  GL_MAX_UNIFORM_BUFFER_BINDINGS* = 0x8A2F
  GL_SLICE_ACCUM_SUN* = 0x85CC
  GL_DRAW_BUFFER9_ATI* = 0x882E
  GL_VERTEX_PROGRAM_PARAMETER_BUFFER_NV* = 0x8DA2
  GL_READ_FRAMEBUFFER_BINDING_APPLE* = 0x8CAA
  GL_INDEX_ARRAY_LENGTH_NV* = 0x8F2E
  GL_DETAIL_TEXTURE_MODE_SGIS* = 0x809B
  GL_MATRIX13_ARB* = 0x88CD
  GL_ADD_SIGNED_ARB* = 0x8574
  GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE* = 0x910A
  GL_DEPTH_BITS* = 0x0D56
  GL_LUMINANCE_ALPHA_SNORM* = 0x9012
  GL_VIEW_CLASS_RGTC1_RED* = 0x82D0
  GL_LINE_WIDTH* = 0x0B21
  GL_DRAW_BUFFER14_ATI* = 0x8833
  GL_CON_30_ATI* = 0x895F
  GL_POST_COLOR_MATRIX_BLUE_BIAS* = 0x80BA
  GL_PIXEL_TRANSFORM_2D_EXT* = 0x8330
  GL_CONTEXT_LOST_WEBGL* = 0x9242
  GL_COLOR_TABLE_BLUE_SIZE_SGI* = 0x80DC
  GL_CONSTANT_EXT* = 0x8576
  GL_IMPLEMENTATION_COLOR_READ_TYPE* = 0x8B9A
  GL_HSL_COLOR_NV* = 0x92AF
  GL_LOAD* = 0x0101
  GL_TEXTURE_BIT* = 0x00040000
  GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT* = 0x8CD9
  GL_IMAGE_ROTATE_ORIGIN_X_HP* = 0x815A
  GL_DEPTH_BUFFER_BIT6_QCOM* = 0x00004000
  GL_QUERY* = 0x82E3
  GL_INVALID_VALUE* = 0x0501
  GL_PACK_COMPRESSED_BLOCK_HEIGHT* = 0x912C
  GL_MAX_PROGRAM_GENERIC_RESULTS_NV* = 0x8DA6
  GL_BACK_PRIMARY_COLOR_NV* = 0x8C77
  GL_ALPHA8_OES* = 0x803C
  GL_INDEX* = 0x8222
  GL_ATTRIB_ARRAY_SIZE_NV* = 0x8623
  GL_INT_IMAGE_1D_ARRAY* = 0x905D
  GL_LOCATION* = 0x930E
  GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT* = 0x8CD7
  GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE* = 0x82AF
  GL_RESAMPLE_ZERO_FILL_SGIX* = 0x842F
  GL_VERTEX_ARRAY_BINDING_OES* = 0x85B5
  GL_MATRIX4_ARB* = 0x88C4
  GL_NEXT_BUFFER_NV* = -2
  GL_ELEMENT_ARRAY_BARRIER_BIT* = 0x00000002
  GL_RGBA16_EXT* = 0x805B
  GL_SEPARABLE_2D_EXT* = 0x8012
  GL_R11F_G11F_B10F_EXT* = 0x8C3A
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER_EXT* = 0x8CD4
  GL_IMAGE_2D_EXT* = 0x904D
  GL_DRAW_BUFFER6_NV* = 0x882B
  GL_TEXTURE_RANGE_LENGTH_APPLE* = 0x85B7
  GL_TEXTURE_RED_TYPE_ARB* = 0x8C10
  GL_ALPHA16F_ARB* = 0x881C
  GL_DEBUG_LOGGED_MESSAGES_ARB* = 0x9145
  GL_TRANSPOSE_MODELVIEW_MATRIX_ARB* = 0x84E3
  GL_TRANSFORM_FEEDBACK_BUFFER_BINDING_EXT* = 0x8C8F
  GL_MAX_CONVOLUTION_WIDTH* = 0x801A
  GL_MIN_FRAGMENT_INTERPOLATION_OFFSET_NV* = 0x8E5B
  GL_PIXEL_TILE_CACHE_SIZE_SGIX* = 0x8145
  GL_4PASS_0_SGIS* = 0x80A4
  GL_PRIMITIVE_RESTART* = 0x8F9D
  GL_RG16_SNORM* = 0x8F99
  GL_SAMPLER_2D_SHADOW_EXT* = 0x8B62
  GL_FRONT* = 0x0404
  GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY* = 0x9103
  GL_SAMPLER_BINDING* = 0x8919
  GL_TEXTURE_2D_STACK_MESAX* = 0x875A
  GL_ASYNC_HISTOGRAM_SGIX* = 0x832C
  GL_IMPLEMENTATION_COLOR_READ_FORMAT_OES* = 0x8B9B
  GL_OP_SET_LT_EXT* = 0x878D
  GL_INTERNALFORMAT_RED_TYPE* = 0x8278
  GL_AUX2* = 0x040B
  GL_CLAMP_FRAGMENT_COLOR* = 0x891B
  GL_BROWSER_DEFAULT_WEBGL* = 0x9244
  GL_IMAGE_CLASS_11_11_10* = 0x82C2
  GL_BUMP_ENVMAP_ATI* = 0x877B
  GL_FLOAT_32_UNSIGNED_INT_24_8_REV_NV* = 0x8DAD
  GL_RG_SNORM* = 0x8F91
  GL_BUMP_ROT_MATRIX_ATI* = 0x8775
  GL_UNIFORM_TYPE* = 0x8A37
  GL_FRAGMENT_COLOR_MATERIAL_PARAMETER_SGIX* = 0x8403
  GL_TEXTURE_BINDING_CUBE_MAP_ARRAY* = 0x900A
  GL_LUMINANCE12* = 0x8041
  GL_QUERY_NO_WAIT_NV* = 0x8E14
  GL_TEXTURE_CUBE_MAP_ARRAY_ARB* = 0x9009
  GL_QUERY_BY_REGION_NO_WAIT_NV* = 0x8E16
  GL_FOG_END* = 0x0B64
  GL_OBJECT_LINK_STATUS_ARB* = 0x8B82
  GL_TEXTURE_COORD_ARRAY_SIZE* = 0x8088
  GL_SOURCE0_ALPHA_ARB* = 0x8588
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB* = 0x8518
  GL_FRAGMENT_LIGHT_MODEL_NORMAL_INTERPOLATION_SGIX* = 0x840B
  GL_STATIC_COPY* = 0x88E6
  GL_LINE_WIDTH_RANGE* = 0x0B22
  GL_VERTEX_SOURCE_ATI* = 0x8774
  GL_FLOAT_MAT4x3* = 0x8B6A
  GL_HALF_APPLE* = 0x140B
  GL_TEXTURE11* = 0x84CB
  GL_DECODE_EXT* = 0x8A49
  GL_VERTEX_ARRAY_STRIDE_EXT* = 0x807C
  GL_SAMPLER_BUFFER_EXT* = 0x8DC2
  GL_TEXTURE_LOD_BIAS_EXT* = 0x8501
  GL_MODULATE_SIGNED_ADD_ATI* = 0x8745
  GL_DEPTH_CLEAR_VALUE* = 0x0B73
  GL_COMPRESSED_ALPHA* = 0x84E9
  GL_TEXTURE_1D_STACK_MESAX* = 0x8759
  GL_TEXTURE_FIXED_SAMPLE_LOCATIONS* = 0x9107
  GL_LARGE_CCW_ARC_TO_NV* = 0x16
  GL_COMBINER1_NV* = 0x8551
  GL_ARRAY_SIZE* = 0x92FB
  GL_MAX_COMPUTE_IMAGE_UNIFORMS* = 0x91BD
  GL_TEXTURE_BINDING_EXTERNAL_OES* = 0x8D67
  GL_REG_26_ATI* = 0x893B
  GL_MUL_ATI* = 0x8964
  GL_STENCIL_BUFFER_BIT6_QCOM* = 0x00400000
  GL_INVALID_OPERATION* = 0x0502
  GL_COLOR_SUM* = 0x8458
  GL_OP_CROSS_PRODUCT_EXT* = 0x8797
  GL_COLOR_ATTACHMENT4_NV* = 0x8CE4
  GL_MAX_RECTANGLE_TEXTURE_SIZE_NV* = 0x84F8
  GL_BOOL_ARB* = 0x8B56
  GL_VERTEX_ATTRIB_ARRAY_TYPE_ARB* = 0x8625
  GL_MODELVIEW8_ARB* = 0x8728
  GL_STENCIL_TEST* = 0x0B90
  GL_SRC_OVER_NV* = 0x9288
  GL_COMPRESSED_LUMINANCE* = 0x84EA
  GL_MAX_GEOMETRY_PROGRAM_INVOCATIONS_NV* = 0x8E5A
  GL_WEIGHT_ARRAY_TYPE_ARB* = 0x86A9
  GL_WRITE_PIXEL_DATA_RANGE_POINTER_NV* = 0x887C
  GL_COLOR_ARRAY_STRIDE_EXT* = 0x8083
  GL_BLEND_SRC_ALPHA_EXT* = 0x80CB
  GL_MAX_PROGRAM_LOCAL_PARAMETERS_ARB* = 0x88B4
  GL_SCALAR_EXT* = 0x87BE
  GL_DEBUG_SEVERITY_MEDIUM_KHR* = 0x9147
  GL_IMAGE_SCALE_X_HP* = 0x8155
  GL_LUMINANCE6_ALPHA2_EXT* = 0x8044
  GL_OUTPUT_TEXTURE_COORD22_EXT* = 0x87B3
  GL_CURRENT_PROGRAM* = 0x8B8D
  GL_FRAGMENT_PROGRAM_ARB* = 0x8804
  GL_INFO_LOG_LENGTH* = 0x8B84
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z* = 0x8519
  GL_PROJECTION_MATRIX_FLOAT_AS_INT_BITS_OES* = 0x898E
  GL_PRIMITIVE_RESTART_FIXED_INDEX* = 0x8D69
  GL_ARRAY_BUFFER_ARB* = 0x8892
  GL_DEPTH_STENCIL_MESA* = 0x8750
  GL_LUMINANCE8_OES* = 0x8040
  GL_REFLECTION_MAP_EXT* = 0x8512
  GL_PRIMITIVES_GENERATED* = 0x8C87
  GL_IMAGE_PIXEL_FORMAT* = 0x82A9
  GL_VERTEX_ARRAY_LIST_STRIDE_IBM* = 103080
  GL_MAP2_COLOR_4* = 0x0DB0
  GL_MULTIPLY_NV* = 0x9294
  GL_UNIFORM_BARRIER_BIT_EXT* = 0x00000004
  GL_STENCIL_BUFFER_BIT3_QCOM* = 0x00080000
  GL_REG_7_ATI* = 0x8928
  GL_STATIC_READ_ARB* = 0x88E5
  GL_MATRIX2_ARB* = 0x88C2
  GL_STENCIL_BUFFER_BIT5_QCOM* = 0x00200000
  GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB* = 0x8B4C
  GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG* = 0x8C03
  GL_R1UI_T2F_N3F_V3F_SUN* = 0x85CA
  GL_TEXTURE27_ARB* = 0x84DB
  GL_FRAMEBUFFER_INCOMPLETE_FORMATS_OES* = 0x8CDA
  GL_MAX_PROGRAM_TEXEL_OFFSET* = 0x8905
  GL_INT_SAMPLER_2D_ARRAY_EXT* = 0x8DCF
  GL_DRAW_BUFFER9_EXT* = 0x882E
  GL_RGB5_A1_EXT* = 0x8057
  GL_FIELDS_NV* = 0x8E27
  GL_MAX_TRACK_MATRIX_STACK_DEPTH_NV* = 0x862E
  GL_SHADER_COMPILER* = 0x8DFA
  GL_SRC2_ALPHA* = 0x858A
  GL_TRACE_NAME_MESA* = 0x8756
  GL_MIRROR_CLAMP_TO_EDGE* = 0x8743
  GL_OPERAND0_RGB_EXT* = 0x8590
  GL_UNSIGNED_BYTE_2_3_3_REV_EXT* = 0x8362
  GL_UNSIGNED_INT_2_10_10_10_REV* = 0x8368
  GL_MAX_CLIP_DISTANCES* = 0x0D32
  GL_MAP2_TEXTURE_COORD_3* = 0x0DB5
  GL_DUAL_LUMINANCE16_SGIS* = 0x8117
  GL_TEXTURE_UPDATE_BARRIER_BIT_EXT* = 0x00000100
  GL_IMAGE_BUFFER_EXT* = 0x9051
  GL_REDUCE_EXT* = 0x8016
  GL_EVAL_VERTEX_ATTRIB9_NV* = 0x86CF
  GL_IMAGE_CLASS_4_X_32* = 0x82B9
  GL_MAX_FRAGMENT_BINDABLE_UNIFORMS_EXT* = 0x8DE3
  GL_FRAGMENTS_INSTRUMENT_MAX_SGIX* = 0x8315
  GL_REG_28_ATI* = 0x893D
  GL_VARIABLE_B_NV* = 0x8524
  GL_GET_TEXTURE_IMAGE_TYPE* = 0x8292
  GL_PERCENTAGE_AMD* = 0x8BC3
  GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_ARB* = 0x8DE1
  GL_MAX_COMPUTE_UNIFORM_BLOCKS* = 0x91BB
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE* = 0x8D56
  GL_PROVOKING_VERTEX* = 0x8E4F
  GL_FRAMEZOOM_FACTOR_SGIX* = 0x818C
  GL_COLOR_TABLE_ALPHA_SIZE* = 0x80DD
  GL_PIXEL_TEXTURE_SGIS* = 0x8353
  GL_MODELVIEW26_ARB* = 0x873A
  GL_MAX_DEBUG_MESSAGE_LENGTH_KHR* = 0x9143
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z_EXT* = 0x8519
  GL_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x87D2
  GL_DRAW_INDIRECT_LENGTH_NV* = 0x8F42
  GL_OPERAND2_RGB_ARB* = 0x8592
  GL_TESS_EVALUATION_SHADER* = 0x8E87
  GL_INTERLACE_SGIX* = 0x8094
  GL_HARDLIGHT_NV* = 0x929B
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_EXT* = 0x8CD0
  GL_OUTPUT_TEXTURE_COORD6_EXT* = 0x87A3
  GL_SIGNED_LUMINANCE_NV* = 0x8701
  GL_CON_13_ATI* = 0x894E
  GL_CURRENT_TANGENT_EXT* = 0x843B
  GL_UNSIGNED_INT_IMAGE_3D* = 0x9064
  GL_MODELVIEW24_ARB* = 0x8738
  GL_EVAL_FRACTIONAL_TESSELLATION_NV* = 0x86C5
  GL_POINT_SPRITE_NV* = 0x8861
  GL_MULTISAMPLE_EXT* = 0x809D
  GL_INT64_VEC3_NV* = 0x8FEA
  GL_ABGR_EXT* = 0x8000
  GL_MAX_GENERAL_COMBINERS_NV* = 0x854D
  GL_NUM_PROGRAM_BINARY_FORMATS* = 0x87FE
  GL_TEXTURE_LO_SIZE_NV* = 0x871C
  GL_INT_IMAGE_1D_ARRAY_EXT* = 0x905D
  GL_MULTISAMPLE_BUFFER_BIT3_QCOM* = 0x08000000
  GL_TEXTURE_GEN_MODE_OES* = 0x2500
  GL_SECONDARY_COLOR_ARRAY_STRIDE* = 0x845C
  GL_ELEMENT_ARRAY_TYPE_APPLE* = 0x8A0D
  GL_UNPACK_IMAGE_HEIGHT_EXT* = 0x806E
  GL_PALETTE4_R5_G6_B5_OES* = 0x8B92
  GL_TEXTURE_RED_SIZE* = 0x805C
  GL_COLOR_ATTACHMENT7_EXT* = 0x8CE7
  GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET* = 0x8E5F
  GL_DRAW_BUFFER11* = 0x8830
  GL_MODELVIEW0_MATRIX_EXT* = 0x0BA6
  GL_LAYER_PROVOKING_VERTEX* = 0x825E
  GL_TEXTURE14* = 0x84CE
  GL_ALPHA8_EXT* = 0x803C
  GL_GENERIC_ATTRIB_NV* = 0x8C7D
  GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES* = 0x8B8B
  GL_STENCIL_ATTACHMENT_OES* = 0x8D20
  GL_MAX_VARYING_FLOATS* = 0x8B4B
  GL_RGB_SNORM* = 0x8F92
  GL_SECONDARY_COLOR_ARRAY_TYPE_EXT* = 0x845B
  GL_MAX_PROGRAM_LOOP_DEPTH_NV* = 0x88F7
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER* = 0x8CD4
  GL_MAX_MODELVIEW_STACK_DEPTH* = 0x0D36
  GL_CON_23_ATI* = 0x8958
  GL_VERTEX_ARRAY_RANGE_POINTER_APPLE* = 0x8521
  GL_VERTEX_ARRAY_BUFFER_BINDING* = 0x8896
  GL_VERTEX_STREAM2_ATI* = 0x876E
  GL_STENCIL* = 0x1802
  GL_IMAGE_2D_ARRAY_EXT* = 0x9053
  GL_RGBA8* = 0x8058
  GL_TEXTURE_SPARSE_ARB* = 0x91A6
  GL_PIXEL_TEX_GEN_ALPHA_NO_REPLACE_SGIX* = 0x8188
  GL_SECONDARY_INTERPOLATOR_ATI* = 0x896D
  GL_MAX_COMBINED_DIMENSIONS* = 0x8282
  GL_DEBUG_TYPE_POP_GROUP* = 0x826A
  GL_IMAGE_CLASS_4_X_8* = 0x82BF
  GL_VERTEX_ARRAY_RANGE_VALID_NV* = 0x851F
  GL_LUMINANCE_ALPHA8UI_EXT* = 0x8D81
  GL_RGBA32F_ARB* = 0x8814
  GL_GLYPH_HEIGHT_BIT_NV* = 0x02
  GL_FOG_COORD_ARRAY_BUFFER_BINDING* = 0x889D
  GL_TRACE_OPERATIONS_BIT_MESA* = 0x0001
  GL_INT8_VEC4_NV* = 0x8FE3
  GL_VERTEX_BINDING_STRIDE* = 0x82D8
  GL_LIGHT_ENV_MODE_SGIX* = 0x8407
  GL_PROXY_TEXTURE_1D_EXT* = 0x8063
  GL_CON_31_ATI* = 0x8960
  GL_TEXTURE_BORDER_COLOR* = 0x1004
  GL_ELEMENT_ARRAY_POINTER_APPLE* = 0x8A0E
  GL_NAME_LENGTH* = 0x92F9
  GL_PIXEL_COUNT_AVAILABLE_NV* = 0x8867
  GL_IUI_V3F_EXT* = 0x81AE
  GL_OBJECT_LINE_SGIS* = 0x81F7
  GL_T2F_N3F_V3F* = 0x2A2B
  GL_TRUE* = 1
  GL_COMPARE_REF_TO_TEXTURE_EXT* = 0x884E
  GL_MAX_3D_TEXTURE_SIZE* = 0x8073
  GL_LUMINANCE16_ALPHA16_EXT* = 0x8048
  GL_DRAW_INDIRECT_ADDRESS_NV* = 0x8F41
  GL_TEXTURE_IMAGE_FORMAT* = 0x828F
  GL_MODELVIEW_MATRIX_FLOAT_AS_INT_BITS_OES* = 0x898D
  GL_TEXTURE_RECTANGLE_ARB* = 0x84F5
  GL_TEXTURE_INDEX_SIZE_EXT* = 0x80ED
  GL_VERTEX_ATTRIB_ARRAY_LENGTH_NV* = 0x8F2A
  GL_DEBUG_CALLBACK_USER_PARAM* = 0x8245
  GL_INTENSITY8_SNORM* = 0x9017
  GL_DISTANCE_ATTENUATION_EXT* = 0x8129
  GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS* = 0x90CC
  GL_ATTRIB_ARRAY_POINTER_NV* = 0x8645
  GL_OBJECT_TYPE* = 0x9112
  GL_PROGRAM_KHR* = 0x82E2
  GL_SOURCE0_ALPHA_EXT* = 0x8588
  GL_PIXEL_MAP_I_TO_G_SIZE* = 0x0CB3
  GL_RGBA_MODE* = 0x0C31
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR* = 0x93D6
  GL_MAX_ELEMENTS_VERTICES_EXT* = 0x80E8
  GL_DEBUG_SOURCE_SHADER_COMPILER* = 0x8248
  GL_ARC_TO_NV* = 0xFE
  GL_CON_6_ATI* = 0x8947
  GL_MAX_OPTIMIZED_VERTEX_SHADER_LOCALS_EXT* = 0x87CE
  GL_VERTEX_ATTRIB_MAP1_DOMAIN_APPLE* = 0x8A05
  GL_R16_SNORM* = 0x8F98
  GL_DOUBLE_VEC2_EXT* = 0x8FFC
  GL_UNSIGNED_INT8_VEC4_NV* = 0x8FEF
  GL_POST_CONVOLUTION_RED_SCALE* = 0x801C
  GL_FULL_STIPPLE_HINT_PGI* = 0x1A219
  GL_ACTIVE_ATTRIBUTES* = 0x8B89
  GL_TEXTURE_MATERIAL_FACE_EXT* = 0x8351
  GL_INCR_WRAP_OES* = 0x8507
  GL_UNPACK_COMPRESSED_BLOCK_WIDTH* = 0x9127
  GL_COMPRESSED_SIGNED_LUMINANCE_ALPHA_LATC2_EXT* = 0x8C73
  GL_MAX_VERTEX_SHADER_LOCALS_EXT* = 0x87C9
  GL_NUM_VIDEO_CAPTURE_STREAMS_NV* = 0x9024
  GL_DRAW_BUFFER3_ARB* = 0x8828
  GL_COMBINER_COMPONENT_USAGE_NV* = 0x8544
  GL_ELEMENT_ARRAY_POINTER_ATI* = 0x876A
  GL_RGB8UI_EXT* = 0x8D7D
  GL_RGBA8I* = 0x8D8E
  GL_TEXTURE_WIDTH_QCOM* = 0x8BD2
  GL_DOT3_RGB* = 0x86AE
  GL_VIDEO_CAPTURE_FIELD_LOWER_HEIGHT_NV* = 0x903B
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X* = 0x8516
  GL_UNIFORM_BUFFER_SIZE* = 0x8A2A
  GL_OPERAND1_ALPHA* = 0x8599
  GL_TEXTURE_INTENSITY_SIZE_EXT* = 0x8061
  GL_DEBUG_TYPE_OTHER* = 0x8251
  GL_MAX_TESS_PATCH_COMPONENTS* = 0x8E84
  GL_UNIFORM_BUFFER_BINDING* = 0x8A28
  GL_INTENSITY_FLOAT16_APPLE* = 0x881D
  GL_TEXTURE_BLUE_SIZE* = 0x805E
  GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT* = 0x919F
  GL_TEXTURE_SWIZZLE_G* = 0x8E43
  GL_MAX_PROGRAM_TEXEL_OFFSET_EXT* = 0x8905
  GL_COLOR_BUFFER_BIT* = 0x00004000
  GL_ALPHA_FLOAT32_APPLE* = 0x8816
  GL_PROXY_TEXTURE_2D_EXT* = 0x8064
  GL_STENCIL_COMPONENTS* = 0x8285
  GL_VIDEO_CAPTURE_TO_422_SUPPORTED_NV* = 0x9026
  GL_TEXTURE_COMPRESSED_ARB* = 0x86A1
  GL_OBJECT_SUBTYPE_ARB* = 0x8B4F
  GL_MAX_PROGRAM_PARAMETERS_ARB* = 0x88A9
  GL_OFFSET_TEXTURE_2D_MATRIX_NV* = 0x86E1
  GL_PN_TRIANGLES_NORMAL_MODE_LINEAR_ATI* = 0x87F7
  GL_PATCH_VERTICES* = 0x8E72
  GL_NEGATIVE_Y_EXT* = 0x87DA
  GL_INT_2_10_10_10_REV* = 0x8D9F
  GL_READ_FRAMEBUFFER_BINDING_NV* = 0x8CAA
  GL_POST_COLOR_MATRIX_COLOR_TABLE_SGI* = 0x80D2
  GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS* = 0x90DA
  GL_IMAGE_COMPATIBILITY_CLASS* = 0x82A8
  GL_FLOAT_MAT4* = 0x8B5C
  GL_FIELD_LOWER_NV* = 0x9023
  GL_UNPACK_IMAGE_HEIGHT* = 0x806E
  GL_PATH_COMMAND_COUNT_NV* = 0x909D
  GL_UNSIGNED_SHORT_4_4_4_4_EXT* = 0x8033
  GL_VIEW_CLASS_S3TC_DXT3_RGBA* = 0x82CE
  GL_STENCIL_BUFFER_BIT1_QCOM* = 0x00020000
  GL_BLOCK_INDEX* = 0x92FD
  GL_BUMP_TARGET_ATI* = 0x877C
  GL_PATH_STROKE_COVER_MODE_NV* = 0x9083
  GL_INT_IMAGE_2D_RECT* = 0x905A
  GL_VECTOR_EXT* = 0x87BF
  GL_INDEX_ARRAY_BUFFER_BINDING* = 0x8899
  GL_SAMPLER_2D_SHADOW* = 0x8B62
  GL_OBJECT_BUFFER_SIZE_ATI* = 0x8764
  GL_NORMALIZED_RANGE_EXT* = 0x87E0
  GL_DEPTH_COMPONENT32_OES* = 0x81A7
  GL_CON_9_ATI* = 0x894A
  GL_VIRTUAL_PAGE_SIZE_X_ARB* = 0x9195
  GL_LESS* = 0x0201
  GL_FRAMEBUFFER_UNSUPPORTED_OES* = 0x8CDD
  GL_CON_19_ATI* = 0x8954
  GL_PROGRAM_NATIVE_INSTRUCTIONS_ARB* = 0x88A2
  GL_MAX_TEXTURE_COORDS_ARB* = 0x8871
  GL_TRANSFORM_FEEDBACK_BUFFER_MODE* = 0x8C7F
  GL_TEXTURE_1D_BINDING_EXT* = 0x8068
  GL_LINE_TOKEN* = 0x0702
  GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES* = 0x8CD7
  GL_Z4Y12Z4CB12Z4A12Z4Y12Z4CR12Z4A12_4224_NV* = 0x9036
  GL_TEXTURE_SWIZZLE_R* = 0x8E42
  GL_PIXEL_UNPACK_BUFFER_ARB* = 0x88EC
  GL_UNKNOWN_CONTEXT_RESET_EXT* = 0x8255
  GL_PROGRAM_ERROR_POSITION_NV* = 0x864B
  GL_ONE_MINUS_CONSTANT_COLOR* = 0x8002
  GL_POST_COLOR_MATRIX_GREEN_SCALE* = 0x80B5
  GL_TEXTURE_CUBE_MAP_SEAMLESS* = 0x884F
  GL_DRAW_BUFFER2* = 0x8827
  GL_STENCIL_INDEX* = 0x1901
  GL_FOG_DENSITY* = 0x0B62
  GL_MATRIX27_ARB* = 0x88DB
  GL_CURRENT_NORMAL* = 0x0B02
  GL_AFFINE_3D_NV* = 0x9094
  GL_STATIC_COPY_ARB* = 0x88E6
  GL_4X_BIT_ATI* = 0x00000002
  GL_COLOR_BUFFER_BIT3_QCOM* = 0x00000008
  GL_TEXTURE_MATRIX* = 0x0BA8
  GL_UNDEFINED_APPLE* = 0x8A1C
  GL_COLOR_TABLE_LUMINANCE_SIZE_SGI* = 0x80DE
  GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x9061
  GL_RELATIVE_ARC_TO_NV* = 0xFF
  GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL* = 0x9241
  GL_READ_FRAMEBUFFER_BINDING_EXT* = 0x8CAA
  GL_TEXTURE_WRAP_R_OES* = 0x8072
  GL_MAX_GEOMETRY_VARYING_COMPONENTS_EXT* = 0x8DDD
  GL_TEXTURE_CUBE_MAP_EXT* = 0x8513
  GL_COMMAND_BARRIER_BIT_EXT* = 0x00000040
  GL_DEBUG_SEVERITY_NOTIFICATION* = 0x826B
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR* = 0x93D8
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS* = 0x8C8B
  GL_MAX_DEEP_3D_TEXTURE_WIDTH_HEIGHT_NV* = 0x90D0
  GL_INT_IMAGE_2D_EXT* = 0x9058
  GL_RGB_S3TC* = 0x83A0
  GL_SUCCESS_NV* = 0x902F
  GL_MATRIX_INDEX_ARRAY_SIZE_OES* = 0x8846
  GL_VIEW_CLASS_8_BITS* = 0x82CB
  GL_DONT_CARE* = 0x1100
  GL_FOG_COORDINATE_ARRAY* = 0x8457
  GL_DRAW_BUFFER9* = 0x882E
  GL_TEXTURE28_ARB* = 0x84DC
  GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_ARB* = 0x8E5F
  GL_TEXTURE21* = 0x84D5
  GL_TRANSLATE_Y_NV* = 0x908F
  GL_MODELVIEW17_ARB* = 0x8731
  GL_ALPHA_FLOAT16_ATI* = 0x881C
  GL_DEPTH_STENCIL_OES* = 0x84F9
  GL_QUAD_MESH_SUN* = 0x8614
  GL_PROGRAM_ADDRESS_REGISTERS_ARB* = 0x88B0
  GL_VERTEX_BINDING_OFFSET* = 0x82D7
  GL_FIRST_TO_REST_NV* = 0x90AF
  GL_SHADE_MODEL* = 0x0B54
  GL_INT_IMAGE_2D_ARRAY_EXT* = 0x905E
  GL_FRONT_FACE* = 0x0B46
  GL_PRIMITIVE_RESTART_INDEX* = 0x8F9E
  GL_LUMINANCE8* = 0x8040
  GL_COVERAGE_ALL_FRAGMENTS_NV* = 0x8ED5
  GL_FRAGMENT_ALPHA_MODULATE_IMG* = 0x8C08
  GL_CLIP_PLANE3_IMG* = 0x3003
  GL_EVAL_VERTEX_ATTRIB15_NV* = 0x86D5
  GL_SYNC_GPU_COMMANDS_COMPLETE* = 0x9117
  GL_FALSE* = 0
  GL_MAX_DEBUG_GROUP_STACK_DEPTH_KHR* = 0x826C
  GL_STENCIL_ATTACHMENT_EXT* = 0x8D20
  GL_DST_ATOP_NV* = 0x928F
  GL_REPLACEMENT_CODE_ARRAY_TYPE_SUN* = 0x85C1
  GL_COMBINE4_NV* = 0x8503
  GL_MINMAX_SINK_EXT* = 0x8030
  GL_RG16I* = 0x8239
  GL_BGRA_IMG* = 0x80E1
  GL_REFERENCED_BY_COMPUTE_SHADER* = 0x930B
  GL_MIN_LOD_WARNING_AMD* = 0x919C
  GL_READ_BUFFER_EXT* = 0x0C02
  GL_RGBA8UI_EXT* = 0x8D7C
  GL_LINE_BIT* = 0x00000004
  GL_CONDITION_SATISFIED* = 0x911C
  GL_SLUMINANCE_ALPHA* = 0x8C44
  GL_FOG_COORDINATE_ARRAY_TYPE* = 0x8454
  GL_EXPAND_NORMAL_NV* = 0x8538
  GL_TEXTURE_2D_ARRAY_EXT* = 0x8C1A
  GL_SAMPLER_2D_RECT_ARB* = 0x8B63
  GL_CLAMP_TO_BORDER_NV* = 0x812D
  GL_MAX_GEOMETRY_OUTPUT_VERTICES_ARB* = 0x8DE0
  GL_TEXCOORD2_BIT_PGI* = 0x20000000
  GL_MATRIX0_ARB* = 0x88C0
  GL_STENCIL_BUFFER_BIT2_QCOM* = 0x00040000
  GL_COLOR_MATRIX_SGI* = 0x80B1
  GL_PN_TRIANGLES_TESSELATION_LEVEL_ATI* = 0x87F4
  GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT* = 0x8CDC
  GL_LEFT* = 0x0406
  GL_LO_SCALE_NV* = 0x870F
  GL_STRICT_DEPTHFUNC_HINT_PGI* = 0x1A216
  GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS* = 0x8E1E
  GL_REPEAT* = 0x2901
  GL_DEBUG_TYPE_PORTABILITY_ARB* = 0x824F
  GL_MAX_FRAMEBUFFER_LAYERS* = 0x9317
  GL_TRIANGLE_STRIP* = 0x0005
  GL_RECLAIM_MEMORY_HINT_PGI* = 0x1A1FE
  GL_RELATIVE_LINE_TO_NV* = 0x05
  GL_MAX_LIGHTS* = 0x0D31
  GL_MULTISAMPLE_BIT* = 0x20000000
  GL_READ_PIXELS* = 0x828C
  GL_DISCRETE_AMD* = 0x9006
  GL_QUAD_TEXTURE_SELECT_SGIS* = 0x8125
  GL_CON_25_ATI* = 0x895A
  GL_BUFFER_IMMUTABLE_STORAGE* = 0x821F
  GL_FLOAT_R16_NV* = 0x8884
  GL_GREEN_INTEGER_EXT* = 0x8D95
  cGL_FIXED* = 0x140C
  GL_LIST_PRIORITY_SGIX* = 0x8182
  GL_DRAW_BUFFER6_EXT* = 0x882B
  GL_OFFSET_TEXTURE_BIAS_NV* = 0x86E3
  GL_VERTEX_ATTRIB_ARRAY_POINTER_ARB* = 0x8645
  GL_MALI_SHADER_BINARY_ARM* = 0x8F60
  GL_RGB_422_APPLE* = 0x8A1F
  GL_R1UI_N3F_V3F_SUN* = 0x85C7
  GL_VERTEX_ARRAY_OBJECT_EXT* = 0x9154
  GL_UNSIGNED_INT_10F_11F_11F_REV* = 0x8C3B
  GL_VERSION_ES_CM_1_1* = 1
  GL_CLEAR_TEXTURE* = 0x9365
  GL_FLOAT16_VEC3_NV* = 0x8FFA
  GL_TEXTURE_LUMINANCE_TYPE* = 0x8C14
  GL_TRANSFORM_FEEDBACK* = 0x8E22
  GL_POST_CONVOLUTION_COLOR_TABLE* = 0x80D1
  GL_DEPTH_TEST* = 0x0B71
  GL_CON_1_ATI* = 0x8942
  GL_FRAGMENT_SHADER_ATI* = 0x8920
  GL_SAMPLER_1D_ARRAY_SHADOW* = 0x8DC3
  GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT* = 0x90DF
  GL_MAX_SERVER_WAIT_TIMEOUT* = 0x9111
  GL_VERTEX_SHADER_BIT_EXT* = 0x00000001
  GL_TEXTURE_BINDING_CUBE_MAP_OES* = 0x8514
  GL_PIXEL_MAP_S_TO_S_SIZE* = 0x0CB1
  GL_CURRENT_OCCLUSION_QUERY_ID_NV* = 0x8865
  GL_TIMEOUT_IGNORED_APPLE* = 0xFFFFFFFFFFFFFFFF
  GL_MAX_COMPUTE_UNIFORM_COMPONENTS* = 0x8263
  GL_COPY_PIXEL_TOKEN* = 0x0706
  GL_SPOT_CUTOFF* = 0x1206
  GL_FRACTIONAL_EVEN* = 0x8E7C
  GL_MAP1_VERTEX_ATTRIB6_4_NV* = 0x8666
  GL_TRIANGLE_LIST_SUN* = 0x81D7
  GL_ATOMIC_COUNTER_BUFFER_START* = 0x92C2
  GL_MAX_ELEMENTS_VERTICES* = 0x80E8
  GL_COLOR_ATTACHMENT9_EXT* = 0x8CE9
  GL_ACCUM_CLEAR_VALUE* = 0x0B80
  GL_TEXTURE_COORD_ARRAY_LENGTH_NV* = 0x8F2F
  GL_DRAW_BUFFER3_EXT* = 0x8828
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y_EXT* = 0x8517
  GL_C4UB_V3F* = 0x2A23
  GL_MAX_PROGRAM_ATTRIBS_ARB* = 0x88AD
  GL_PIXEL_TILE_CACHE_INCREMENT_SGIX* = 0x813F
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_ARB* = 0x8DA9
  GL_CON_8_ATI* = 0x8949
  GL_POST_COLOR_MATRIX_ALPHA_BIAS* = 0x80BB
  GL_RENDERBUFFER_WIDTH* = 0x8D42
  GL_VERTEX_ID_NV* = 0x8C7B
  GL_STRICT_LIGHTING_HINT_PGI* = 0x1A217
  GL_COMPRESSED_RGBA8_ETC2_EAC_OES* = 0x9278
  GL_PACK_COMPRESSED_BLOCK_WIDTH* = 0x912B
  GL_ZERO_EXT* = 0x87DD
  GL_DEBUG_SOURCE_OTHER* = 0x824B
  GL_MAP_UNSYNCHRONIZED_BIT* = 0x0020
  GL_VERTEX_ARRAY_POINTER* = 0x808E
  GL_FLOAT_RGBA_NV* = 0x8883
  GL_WEIGHT_ARRAY_STRIDE_OES* = 0x86AA
  GL_UNPACK_ROW_BYTES_APPLE* = 0x8A16
  GL_CURRENT_COLOR* = 0x0B00
  GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT* = 0x8CD7
  GL_MAX_NAME_STACK_DEPTH* = 0x0D37
  GL_SHADER_STORAGE_BUFFER_START* = 0x90D4
  GL_TRANSFORM_FEEDBACK_BUFFER_MODE_EXT* = 0x8C7F
  GL_PATH_GEN_COMPONENTS_NV* = 0x90B3
  GL_AUTO_GENERATE_MIPMAP* = 0x8295
  GL_UNSIGNED_INT_5_9_9_9_REV* = 0x8C3E
  GL_VIEWPORT* = 0x0BA2
  GL_MAX_VERTEX_STREAMS_ATI* = 0x876B
  GL_MAX_OPTIMIZED_VERTEX_SHADER_VARIANTS_EXT* = 0x87CB
  GL_STENCIL_CLEAR_VALUE* = 0x0B91
  GL_UNSIGNED_INT_IMAGE_2D_ARRAY_EXT* = 0x9069
  GL_FRAGMENT_LIGHT_MODEL_TWO_SIDE_SGIX* = 0x8409
  GL_FRAGMENT_SHADER_BIT_EXT* = 0x00000002
  GL_COLOR_SUM_ARB* = 0x8458
  GL_RGBA4_DXT5_S3TC* = 0x83A5
  GL_INT_IMAGE_CUBE* = 0x905B
  GL_ACTIVE_ATOMIC_COUNTER_BUFFERS* = 0x92D9
  GL_INTERNALFORMAT_GREEN_SIZE* = 0x8272
  GL_OFFSET_HILO_TEXTURE_RECTANGLE_NV* = 0x8855
  GL_MAX_PN_TRIANGLES_TESSELATION_LEVEL_ATI* = 0x87F1
  GL_REG_24_ATI* = 0x8939
  GL_MULT* = 0x0103
  GL_RGBA2* = 0x8055
  GL_CONVOLUTION_WIDTH_EXT* = 0x8018
  GL_STENCIL_EXT* = 0x1802
  GL_PATH_STROKE_WIDTH_NV* = 0x9075
  GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB* = 0x8247
  GL_QUERY_COUNTER_BITS* = 0x8864
  GL_OUTPUT_FOG_EXT* = 0x87BD
  GL_POST_COLOR_MATRIX_RED_BIAS* = 0x80B8
  GL_UNSIGNED_INT_10_10_10_2* = 0x8036
  GL_INT_SAMPLER_1D* = 0x8DC9
  GL_INT_IMAGE_2D_MULTISAMPLE_EXT* = 0x9060
  GL_RENDERBUFFER_INTERNAL_FORMAT_OES* = 0x8D44
  GL_TRACE_PIXELS_BIT_MESA* = 0x0010
  GL_FAILURE_NV* = 0x9030
  GL_INT_SAMPLER_3D_EXT* = 0x8DCB
  GL_MAX_PROGRAM_PARAMETER_BUFFER_SIZE_NV* = 0x8DA1
  GL_OBJECT_DISTANCE_TO_POINT_SGIS* = 0x81F1
  GL_BLEND_SRC_RGB_OES* = 0x80C9
  GL_LUMINANCE4_ALPHA4_OES* = 0x8043
  GL_REG_4_ATI* = 0x8925
  GL_SHADING_LANGUAGE_VERSION_ARB* = 0x8B8C
  GL_RGBA16F_ARB* = 0x881A
  GL_R32F* = 0x822E
  GL_COMPRESSED_SRGB_S3TC_DXT1_NV* = 0x8C4C
  GL_TESS_CONTROL_OUTPUT_VERTICES* = 0x8E75
  GL_ONE_MINUS_DST_COLOR* = 0x0307
  GL_MATRIX19_ARB* = 0x88D3
  GL_INT_SAMPLER_2D_RECT* = 0x8DCD
  GL_POST_CONVOLUTION_GREEN_SCALE_EXT* = 0x801D
  GL_CLIP_DISTANCE5* = 0x3005
  GL_HISTOGRAM_RED_SIZE_EXT* = 0x8028
  GL_INTENSITY_FLOAT32_APPLE* = 0x8817
  GL_MODULATE_ADD_ATI* = 0x8744
  GL_NEGATIVE_X_EXT* = 0x87D9
  GL_REG_21_ATI* = 0x8936
  GL_STENCIL_RENDERABLE* = 0x8288
  GL_FOG_COORD_ARRAY_STRIDE* = 0x8455
  GL_FACTOR_MAX_AMD* = 0x901D
  GL_LUMINANCE16_EXT* = 0x8042
  GL_VARIANT_ARRAY_POINTER_EXT* = 0x87E9
  GL_DECAL* = 0x2101
  GL_SIGNED_ALPHA8_NV* = 0x8706
  GL_ALPHA_BITS* = 0x0D55
  GL_MATRIX29_ARB* = 0x88DD
  GL_FOG* = 0x0B60
  GL_INDEX_ARRAY_LIST_STRIDE_IBM* = 103083
  GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS* = 0x90C9
  GL_RGBA4_S3TC* = 0x83A3
  GL_LUMINANCE16_ALPHA16* = 0x8048
  GL_PROXY_TEXTURE_RECTANGLE* = 0x84F7
  GL_FRAGMENT_PROGRAM_PARAMETER_BUFFER_NV* = 0x8DA4
  GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER* = 0x84F0
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE* = 0x8CD3
  GL_COLOR_TABLE_GREEN_SIZE_SGI* = 0x80DB
  GL_TEXTURE_PRE_SPECULAR_HP* = 0x8169
  GL_SHADOW_ATTENUATION_EXT* = 0x834E
  GL_SIGNED_RGB_NV* = 0x86FE
  GL_CLIENT_ALL_ATTRIB_BITS* = 0xFFFFFFFF
  GL_DEPTH_ATTACHMENT_EXT* = 0x8D00
  GL_DEBUG_SOURCE_API_KHR* = 0x8246
  GL_COLOR_INDEXES* = 0x1603
  GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH* = 0x8243
  GL_TEXTURE_BINDING_1D* = 0x8068
  GL_UNSIGNED_INT_SAMPLER_2D* = 0x8DD2
  GL_DRAW_BUFFER9_NV* = 0x882E
  GL_RED* = 0x1903
  GL_LINE_STRIP_ADJACENCY_EXT* = 0x000B
  GL_NUM_PASSES_ATI* = 0x8970
  GL_MAT_DIFFUSE_BIT_PGI* = 0x00400000
  GL_LUMINANCE_INTEGER_EXT* = 0x8D9C
  GL_PIXEL_MAP_I_TO_I* = 0x0C70
  GL_SLUMINANCE8_ALPHA8_NV* = 0x8C45
  GL_RGBA4_OES* = 0x8056
  GL_COMPRESSED_SIGNED_R11_EAC* = 0x9271
  GL_FRAGMENT_LIGHT4_SGIX* = 0x8410
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS_NV* = 0x8C80
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT* = 0x8C4D
  GL_READ_FRAMEBUFFER_APPLE* = 0x8CA8
  GL_DRAW_BUFFER15_ARB* = 0x8834
  GL_INSTRUMENT_MEASUREMENTS_SGIX* = 0x8181
  GL_REG_15_ATI* = 0x8930
  GL_UNSIGNED_INT_IMAGE_1D_ARRAY* = 0x9068
  GL_COMPUTE_LOCAL_WORK_SIZE* = 0x8267
  GL_RGBA32I* = 0x8D82
  GL_VERTEX_ATTRIB_MAP2_APPLE* = 0x8A01
  GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR* = 0x824D
  GL_READ_FRAMEBUFFER_BINDING_ANGLE* = 0x8CAA
  GL_DEBUG_SOURCE_WINDOW_SYSTEM_KHR* = 0x8247
  GL_OP_FRAC_EXT* = 0x8789
  GL_RGB_FLOAT32_APPLE* = 0x8815
  GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER* = 0x8A44
  GL_NORMAL_ARRAY* = 0x8075
  GL_TEXTURE21_ARB* = 0x84D5
  GL_WRITE_ONLY_OES* = 0x88B9
  GL_TEXTURE0_ARB* = 0x84C0
  GL_SPRITE_OBJECT_ALIGNED_SGIX* = 0x814D
  GL_POSITION* = 0x1203
  GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR* = 0x824E
  GL_GEOMETRY_OUTPUT_TYPE_ARB* = 0x8DDC
  GL_IMAGE_PIXEL_TYPE* = 0x82AA
  GL_UNSIGNED_INT64_AMD* = 0x8BC2
  GL_LIST_INDEX* = 0x0B33
  GL_UNSIGNED_INT_8_8_S8_S8_REV_NV* = 0x86DB
  GL_MAP_ATTRIB_U_ORDER_NV* = 0x86C3
  GL_PROXY_TEXTURE_RECTANGLE_ARB* = 0x84F7
  GL_CLIP_NEAR_HINT_PGI* = 0x1A220
  GL_POST_TEXTURE_FILTER_BIAS_RANGE_SGIX* = 0x817B
  GL_MAX_UNIFORM_BLOCK_SIZE* = 0x8A30
  GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER* = 0x8CDB
  GL_SAMPLE_MASK_INVERT_EXT* = 0x80AB
  GL_MAP1_VERTEX_ATTRIB14_4_NV* = 0x866E
  GL_SYNC_FLAGS* = 0x9115
  GL_COMPRESSED_RGBA* = 0x84EE
  GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT* = 0x82B2
  GL_INDEX_ARRAY_STRIDE_EXT* = 0x8086
  GL_CLIP_DISTANCE_NV* = 0x8C7A
  GL_UNSIGNED_INT_VEC4* = 0x8DC8
  GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB* = 0x8E8E
  GL_MIRRORED_REPEAT_OES* = 0x8370
  GL_WEIGHT_ARRAY_SIZE_ARB* = 0x86AB
  GL_MIN_SAMPLE_SHADING_VALUE* = 0x8C37
  GL_SOURCE0_RGB* = 0x8580
  GL_RG32I* = 0x823B
  GL_QUERY_BUFFER_BINDING_AMD* = 0x9193
  GL_OFFSET_PROJECTIVE_TEXTURE_2D_SCALE_NV* = 0x8851
  GL_POST_CONVOLUTION_BLUE_SCALE_EXT* = 0x801E
  GL_DOUBLE_MAT3x4_EXT* = 0x8F4C
  GL_MAX_VERTEX_HINT_PGI* = 0x1A22D
  GL_ADD* = 0x0104
  GL_PATH_FORMAT_SVG_NV* = 0x9070
  GL_VIDEO_BUFFER_BINDING_NV* = 0x9021
  GL_NUM_EXTENSIONS* = 0x821D
  GL_DEPTH_RANGE* = 0x0B70
  GL_FRAGMENT_SUBROUTINE* = 0x92EC
  GL_DEPTH24_STENCIL8_EXT* = 0x88F0
  GL_COMPRESSED_RGBA_S3TC_DXT3_EXT* = 0x83F2
  GL_COLOR_TABLE_SGI* = 0x80D0
  GL_OBJECT_ACTIVE_UNIFORMS_ARB* = 0x8B86
  GL_RGBA16F* = 0x881A
  GL_COORD_REPLACE_ARB* = 0x8862
  GL_SAMPLE_POSITION_NV* = 0x8E50
  GL_SRC_ALPHA* = 0x0302
  GL_COMBINE_ALPHA* = 0x8572
  GL_CLEAR* = 0x1500
  GL_HSL_HUE_NV* = 0x92AD
  GL_SCISSOR_TEST* = 0x0C11
  GL_UNSIGNED_INT_SAMPLER_BUFFER_EXT* = 0x8DD8
  GL_RGB16UI* = 0x8D77
  GL_MATRIX9_ARB* = 0x88C9
  GL_COLOR_ATTACHMENT13* = 0x8CED
  GL_BUMP_ROT_MATRIX_SIZE_ATI* = 0x8776
  GL_PIXEL_PACK_BUFFER_BINDING_ARB* = 0x88ED
  GL_FONT_X_MAX_BOUNDS_BIT_NV* = 0x00040000
  GL_MODELVIEW31_ARB* = 0x873F
  GL_DRAW_BUFFER14_ARB* = 0x8833
  GL_EDGEFLAG_BIT_PGI* = 0x00040000
  GL_TEXTURE_LOD_BIAS_R_SGIX* = 0x8190
  GL_FIELD_UPPER_NV* = 0x9022
  GL_CLIP_PLANE3* = 0x3003
  GL_FRAGMENT_LIGHT_MODEL_LOCAL_VIEWER_SGIX* = 0x8408
  GL_BLUE* = 0x1905
  GL_LUMINANCE_ALPHA_FLOAT32_ATI* = 0x8819
  GL_MATRIX31_ARB* = 0x88DF
  GL_OR_REVERSE* = 0x150B
  GL_INTERPOLATE_EXT* = 0x8575
  GL_MODELVIEW13_ARB* = 0x872D
  GL_UTF16_NV* = 0x909B
  GL_READ_FRAMEBUFFER_ANGLE* = 0x8CA8
  GL_LUMINANCE16F_EXT* = 0x881E
  GL_VERTEX_ATTRIB_ARRAY7_NV* = 0x8657
  GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS_EXT* = 0x8C8A
  GL_PRIMARY_COLOR_EXT* = 0x8577
  GL_VERTEX_ATTRIB_RELATIVE_OFFSET* = 0x82D5
  GL_LARGE_CW_ARC_TO_NV* = 0x18
  GL_PROGRAM_PARAMETER_NV* = 0x8644
  GL_ASYNC_MARKER_SGIX* = 0x8329
  GL_TEXTURE24_ARB* = 0x84D8
  GL_PIXEL_SUBSAMPLE_4242_SGIX* = 0x85A4
  GL_RGB10_A2_EXT* = 0x8059
  GL_IMAGE_CLASS_2_X_32* = 0x82BA
  GL_TEXTURE_INTENSITY_TYPE* = 0x8C15
  GL_TEXTURE_LOD_BIAS_S_SGIX* = 0x818E
  GL_PROGRAM_BINARY_LENGTH* = 0x8741
  GL_CURRENT_RASTER_NORMAL_SGIX* = 0x8406
  GL_DETAIL_TEXTURE_2D_SGIS* = 0x8095
  GL_MAX_FRAGMENT_INTERPOLATION_OFFSET_NV* = 0x8E5C
  GL_CONVOLUTION_FILTER_BIAS_EXT* = 0x8015
  GL_DT_BIAS_NV* = 0x8717
  GL_RESET_NOTIFICATION_STRATEGY_EXT* = 0x8256
  GL_SHADER_STORAGE_BUFFER* = 0x90D2
  GL_RESET_NOTIFICATION_STRATEGY_ARB* = 0x8256
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_EXT* = 0x8CD1
  GL_SRC_NV* = 0x9286
  GL_POINT_FADE_THRESHOLD_SIZE* = 0x8128
  GL_DEPENDENT_RGB_TEXTURE_3D_NV* = 0x8859
  GL_QUERY_RESULT_ARB* = 0x8866
  GL_GEOMETRY_VERTICES_OUT* = 0x8916
  GL_MAX_COMPUTE_FIXED_GROUP_INVOCATIONS_ARB* = 0x90EB
  GL_MODELVIEW27_ARB* = 0x873B
  GL_DRAW_BUFFER11_NV* = 0x8830
  GL_COLOR_ATTACHMENT9_NV* = 0x8CE9
  GL_BLEND_SRC* = 0x0BE1
  GL_CONVOLUTION_2D_EXT* = 0x8011
  GL_MAX_ELEMENTS_INDICES* = 0x80E9
  GL_LUMINANCE_ALPHA_FLOAT32_APPLE* = 0x8819
  GL_INT_IMAGE_1D* = 0x9057
  GL_CONSTANT_COLOR* = 0x8001
  GL_FRAMEBUFFER_BARRIER_BIT* = 0x00000400
  GL_POST_CONVOLUTION_BLUE_SCALE* = 0x801E
  GL_DEBUG_SOURCE_SHADER_COMPILER_ARB* = 0x8248
  GL_RGB16I* = 0x8D89
  GL_MAX_WIDTH* = 0x827E
  GL_LIGHT_MODEL_AMBIENT* = 0x0B53
  GL_COVERAGE_ATTACHMENT_NV* = 0x8ED2
  GL_PROGRAM* = 0x82E2
  GL_IMAGE_ROTATE_ANGLE_HP* = 0x8159
  GL_SRC2_RGB* = 0x8582
  GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_KHR* = 0x824E
  GL_PASS_THROUGH_NV* = 0x86E6
  GL_HALF_BIAS_NEGATE_NV* = 0x853B
  GL_SAMPLER_CUBE_SHADOW_EXT* = 0x8DC5
  GL_COMPRESSED_RGBA_BPTC_UNORM_ARB* = 0x8E8C
  GL_MAX_SERVER_WAIT_TIMEOUT_APPLE* = 0x9111
  GL_STORAGE_PRIVATE_APPLE* = 0x85BD
  GL_VERTEX_SHADER_BIT* = 0x00000001
  GL_POST_COLOR_MATRIX_BLUE_SCALE_SGI* = 0x80B6
  GL_VERTEX_SHADER_VARIANTS_EXT* = 0x87D0
  GL_TRANSFORM_FEEDBACK_ACTIVE* = 0x8E24
  GL_ACTIVE_UNIFORMS* = 0x8B86
  GL_MULTISAMPLE_BUFFER_BIT0_QCOM* = 0x01000000
  GL_OFFSET_TEXTURE_SCALE_NV* = 0x86E2
  GL_VERTEX_ATTRIB_ARRAY_DIVISOR_ARB* = 0x88FE
  GL_BEVEL_NV* = 0x90A6
  GL_MAX_DRAW_BUFFERS_NV* = 0x8824
  GL_MAP1_TANGENT_EXT* = 0x8444
  GL_ANY_SAMPLES_PASSED* = 0x8C2F
  GL_MAX_IMAGE_SAMPLES* = 0x906D
  GL_PIXEL_UNPACK_BUFFER_BINDING* = 0x88EF
  GL_SRGB8_ALPHA8_EXT* = 0x8C43
  GL_2PASS_1_SGIS* = 0x80A3
  GL_PROGRAM_POINT_SIZE_ARB* = 0x8642
  GL_ALLOW_DRAW_WIN_HINT_PGI* = 0x1A20F
  GL_INTERNALFORMAT_RED_SIZE* = 0x8271
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_OES* = 0x8CD3
  GL_4PASS_2_SGIS* = 0x80A6
  GL_PROGRAM_OBJECT_EXT* = 0x8B40
  GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST* = 0x82AD
  GL_LIGHTING_BIT* = 0x00000040
  GL_DRAW_BUFFER13_EXT* = 0x8832
  GL_STREAM_DRAW_ARB* = 0x88E0
  GL_INDEX_ARRAY_TYPE* = 0x8085
  GL_DEBUG_SOURCE_THIRD_PARTY* = 0x8249
  GL_DYNAMIC_COPY_ARB* = 0x88EA
  GL_COMPARE_R_TO_TEXTURE_ARB* = 0x884E
  GL_FRAGMENTS_INSTRUMENT_COUNTERS_SGIX* = 0x8314
  GL_SPARSE_TEXTURE_FULL_ARRAY_CUBE_MIPMAPS_ARB* = 0x91A9
  GL_MAX_GEOMETRY_UNIFORM_COMPONENTS* = 0x8DDF
  GL_READ_PIXEL_DATA_RANGE_POINTER_NV* = 0x887D
  GL_BUFFER_MAPPED_OES* = 0x88BC
  GL_COLOR_ARRAY_COUNT_EXT* = 0x8084
  GL_SET_AMD* = 0x874A
  GL_BLEND_DST_RGB_OES* = 0x80C8
  GL_MAX_CONVOLUTION_HEIGHT_EXT* = 0x801B
  GL_DEBUG_SEVERITY_MEDIUM* = 0x9147
  GL_TEXTURE_INTENSITY_TYPE_ARB* = 0x8C15
  GL_IMAGE_CLASS_10_10_10_2* = 0x82C3
  GL_TEXTURE_BORDER_COLOR_NV* = 0x1004
  GL_VERTEX_ATTRIB_ARRAY12_NV* = 0x865C
  GL_MAX_GEOMETRY_SHADER_INVOCATIONS* = 0x8E5A
  GL_NEAREST_CLIPMAP_NEAREST_SGIX* = 0x844D
  GL_MAP2_VERTEX_ATTRIB12_4_NV* = 0x867C
  GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING* = 0x889A
  GL_SEPARATE_SPECULAR_COLOR_EXT* = 0x81FA
  GL_MATRIX_INDEX_ARRAY_SIZE_ARB* = 0x8846
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB* = 0x8517
  GL_DECR* = 0x1E03
  GL_DEPTH_BUFFER_BIT7_QCOM* = 0x00008000
  GL_LOCAL_EXT* = 0x87C4
  GL_FUNC_REVERSE_SUBTRACT_OES* = 0x800B
  GL_FLOAT_VEC3* = 0x8B51
  GL_POINT_SIZE_GRANULARITY* = 0x0B13
  GL_COLOR_ATTACHMENT9* = 0x8CE9
  GL_MAT_SPECULAR_BIT_PGI* = 0x04000000
  GL_VERTEX_ATTRIB_MAP1_APPLE* = 0x8A00
  GL_DEBUG_SOURCE_WINDOW_SYSTEM* = 0x8247
  GL_NEAREST_MIPMAP_NEAREST* = 0x2700
  GL_MODELVIEW7_ARB* = 0x8727
  GL_OUTPUT_VERTEX_EXT* = 0x879A
  GL_FRAMEBUFFER_EXT* = 0x8D40
  GL_ATC_RGBA_EXPLICIT_ALPHA_AMD* = 0x8C93
  GL_RENDERBUFFER_WIDTH_OES* = 0x8D42
  GL_TEXTURE_VIEW_MIN_LAYER* = 0x82DD
  GL_TEXTURE25_ARB* = 0x84D9
  GL_LIGHT7* = 0x4007
  GL_TESS_EVALUATION_SHADER_BIT* = 0x00000010
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_EXT* = 0x8CD2
  GL_COLOR_ATTACHMENT15_NV* = 0x8CEF
  GL_RED_SNORM* = 0x8F90
  GL_VIVIDLIGHT_NV* = 0x92A6
  GL_OBJECT_COMPILE_STATUS_ARB* = 0x8B81
  GL_INTERNALFORMAT_PREFERRED* = 0x8270
  GL_OUT_OF_MEMORY* = 0x0505
  GL_422_REV_EXT* = 0x80CD
  GL_DOT_PRODUCT_TEXTURE_CUBE_MAP_NV* = 0x86F0
  GL_PROXY_TEXTURE_1D* = 0x8063
  GL_FRAGMENT_PROGRAM_CALLBACK_FUNC_MESA* = 0x8BB2
  GL_YCBCR_422_APPLE* = 0x85B9
  GL_DRAW_BUFFER10_ATI* = 0x882F
  GL_COLOR_TABLE_ALPHA_SIZE_SGI* = 0x80DD
  GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS* = 0x8E86
  GL_MAX_PROGRAM_OUTPUT_VERTICES_NV* = 0x8C27
  GL_IMAGE_2D_MULTISAMPLE_EXT* = 0x9055
  GL_ACTIVE_TEXTURE_ARB* = 0x84E0
  GL_FONT_MAX_ADVANCE_HEIGHT_BIT_NV* = 0x02000000
  GL_QUERY_WAIT_NV* = 0x8E13
  GL_MAX_ELEMENT_INDEX* = 0x8D6B
  GL_OP_LOG_BASE_2_EXT* = 0x8792
  GL_ADD_SIGNED* = 0x8574
  GL_CONVOLUTION_FORMAT* = 0x8017
  GL_RENDERBUFFER_RED_SIZE_EXT* = 0x8D50
  GL_RENDERBUFFER_INTERNAL_FORMAT* = 0x8D44
  GL_COLOR_ATTACHMENT11_NV* = 0x8CEB
  GL_MATRIX14_ARB* = 0x88CE
  GL_COLOR_TABLE_RED_SIZE_SGI* = 0x80DA
  GL_CON_22_ATI* = 0x8957
  GL_TEXTURE_SWIZZLE_B_EXT* = 0x8E44
  GL_SAMPLES_SGIS* = 0x80A9
  GL_WRITE_PIXEL_DATA_RANGE_LENGTH_NV* = 0x887A
  GL_FONT_X_MIN_BOUNDS_BIT_NV* = 0x00010000
  GL_3_BYTES* = 0x1408
  GL_TEXTURE_MAX_CLAMP_S_SGIX* = 0x8369
  GL_PROXY_TEXTURE_CUBE_MAP_EXT* = 0x851B
  GL_VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE* = 0x88FE
  GL_VERTEX_DATA_HINT_PGI* = 0x1A22A
  GL_VERTEX_WEIGHT_ARRAY_SIZE_EXT* = 0x850D
  GL_MAX_INTEGER_SAMPLES* = 0x9110
  GL_TEXTURE_BUFFER_ARB* = 0x8C2A
  GL_FOG_COORD_ARRAY_POINTER* = 0x8456
  GL_UNSIGNED_SHORT_1_15_REV_MESA* = 0x8754
  GL_IMAGE_CUBIC_WEIGHT_HP* = 0x815E
  GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES* = 0x8CD6
  GL_RGBA_DXT5_S3TC* = 0x83A4
  GL_INT_IMAGE_2D_MULTISAMPLE* = 0x9060
  GL_ACTIVE_RESOURCES* = 0x92F5
  GL_TEXTURE_BINDING_2D* = 0x8069
  GL_SAMPLE_COVERAGE* = 0x80A0
  GL_SMOOTH* = 0x1D01
  GL_SAMPLER_1D_SHADOW_ARB* = 0x8B61
  GL_VIRTUAL_PAGE_SIZE_Y_AMD* = 0x9196
  GL_HORIZONTAL_LINE_TO_NV* = 0x06
  GL_HISTOGRAM_GREEN_SIZE_EXT* = 0x8029
  GL_COLOR_FLOAT_APPLE* = 0x8A0F
  GL_NUM_SHADER_BINARY_FORMATS* = 0x8DF9
  GL_TIMESTAMP* = 0x8E28
  GL_SRGB_EXT* = 0x8C40
  GL_MAX_VERTEX_UNIFORM_BLOCKS* = 0x8A2B
  GL_COLOR_ATTACHMENT2_EXT* = 0x8CE2
  GL_DEBUG_CALLBACK_FUNCTION_KHR* = 0x8244
  GL_DISPLAY_LIST* = 0x82E7
  GL_MAP1_NORMAL* = 0x0D92
  GL_COMPUTE_TEXTURE* = 0x82A0
  GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS* = 0x90DB
  GL_W_EXT* = 0x87D8
  GL_SAMPLE_SHADING_ARB* = 0x8C36
  GL_FRAGMENT_INTERPOLATION_OFFSET_BITS* = 0x8E5D
  GL_IMAGE_CLASS_4_X_16* = 0x82BC
  GL_FRAGMENT_DEPTH_EXT* = 0x8452
  GL_EVAL_BIT* = 0x00010000
  GL_UNSIGNED_INT_8_8_8_8* = 0x8035
  GL_MAX_TESS_CONTROL_INPUT_COMPONENTS* = 0x886C
  GL_FRAGMENT_PROGRAM_CALLBACK_DATA_MESA* = 0x8BB3
  GL_SLUMINANCE8_ALPHA8* = 0x8C45
  GL_MODULATE_COLOR_IMG* = 0x8C04
  GL_TEXTURE20* = 0x84D4
  GL_ALPHA_INTEGER_EXT* = 0x8D97
  GL_TEXTURE_BINDING_CUBE_MAP_EXT* = 0x8514
  GL_BACK_LEFT* = 0x0402
  GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS_EXT* = 0x8F39
  GL_MAX_TRANSFORM_FEEDBACK_BUFFERS* = 0x8E70
  GL_TRANSFORM_BIT* = 0x00001000
  GL_RGB4_EXT* = 0x804F
  GL_FRAGMENT_COLOR_EXT* = 0x834C
  GL_PIXEL_MAP_S_TO_S* = 0x0C71
  GL_COMPRESSED_RGBA_S3TC_DXT5_EXT* = 0x83F3
  GL_PATH_STENCIL_DEPTH_OFFSET_FACTOR_NV* = 0x90BD
  GL_SOURCE0_RGB_EXT* = 0x8580
  GL_PIXEL_COUNTER_BITS_NV* = 0x8864
  GL_ALIASED_LINE_WIDTH_RANGE* = 0x846E
  GL_DRAW_BUFFER10* = 0x882F
  GL_T4F_C4F_N3F_V4F* = 0x2A2D
  GL_BLEND_EQUATION_OES* = 0x8009
  GL_DEPTH_COMPONENT32* = 0x81A7
  GL_MAX_OPTIMIZED_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x87CA
  GL_DEPTH_BUFFER_BIT5_QCOM* = 0x00002000
  GL_RED_MIN_CLAMP_INGR* = 0x8560
  GL_RGBA_INTEGER_MODE_EXT* = 0x8D9E
  GL_DOUBLE_MAT4_EXT* = 0x8F48
  GL_OBJECT_DELETE_STATUS_ARB* = 0x8B80
  GL_FOG_COORD_ARRAY_LENGTH_NV* = 0x8F32
  GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING* = 0x889C
  GL_MAP1_VERTEX_ATTRIB7_4_NV* = 0x8667
  GL_BLEND_SRC_RGB_EXT* = 0x80C9
  GL_VERTEX_PROGRAM_POINT_SIZE_ARB* = 0x8642
  GL_STENCIL_INDEX1_EXT* = 0x8D46
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X_EXT* = 0x8516
  GL_FRAGMENT_SHADER_DISCARDS_SAMPLES_EXT* = 0x8A52
  GL_FOG_COORD_SRC* = 0x8450
  GL_ANY_SAMPLES_PASSED_EXT* = 0x8C2F
  GL_ALPHA4* = 0x803B
  GL_TEXTURE_GEN_MODE* = 0x2500
  GL_FLOAT_MAT3_ARB* = 0x8B5B
  GL_PIXEL_MAP_A_TO_A_SIZE* = 0x0CB9
  GL_FRAGMENT_SHADER_DERIVATIVE_HINT_ARB* = 0x8B8B
  GL_STENCIL_BACK_PASS_DEPTH_FAIL_ATI* = 0x8802
  GL_COPY_READ_BUFFER_BINDING* = 0x8F36
  GL_YCRCB_444_SGIX* = 0x81BC
  GL_SLUMINANCE_EXT* = 0x8C46
  GL_EDGE_FLAG_ARRAY_EXT* = 0x8079
  GL_STENCIL_INDEX8_OES* = 0x8D48
  GL_RGBA32UI* = 0x8D70
  GL_TEXTURE_CUBE_MAP* = 0x8513
  GL_STREAM_COPY* = 0x88E2
  GL_VIEWPORT_BOUNDS_RANGE* = 0x825D
  GL_ASYNC_READ_PIXELS_SGIX* = 0x835E
  GL_VERTEX_ATTRIB_ARRAY_INTEGER* = 0x88FD
  GL_INTERNALFORMAT_STENCIL_TYPE* = 0x827D
  GL_OUTPUT_TEXTURE_COORD28_EXT* = 0x87B9
  GL_MATRIX_MODE* = 0x0BA0
  GL_MULTISAMPLE_SGIS* = 0x809D
  GL_R1UI_V3F_SUN* = 0x85C4
  GL_FLOAT_R32_NV* = 0x8885
  GL_MAX_DRAW_BUFFERS* = 0x8824
  GL_CIRCULAR_CCW_ARC_TO_NV* = 0xF8
  GL_PROGRAM_OUTPUT* = 0x92E4
  GL_MAX_CUBE_MAP_TEXTURE_SIZE* = 0x851C
  GL_TRIANGLE_STRIP_ADJACENCY_ARB* = 0x000D
  GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT* = 0x8A34
  GL_SRGB* = 0x8C40
  GL_BUFFER_ACCESS* = 0x88BB
  GL_TEXTURE_WRAP_S* = 0x2802
  GL_TRANSFORM_FEEDBACK_VARYINGS* = 0x8C83
  GL_RG16UI* = 0x823A
  GL_DUAL_LUMINANCE4_SGIS* = 0x8114
  GL_DOT_PRODUCT_DEPTH_REPLACE_NV* = 0x86ED
  GL_READ_FRAMEBUFFER_BINDING* = 0x8CAA
  GL_MAX_FOG_FUNC_POINTS_SGIS* = 0x812C
  GL_QUERY_RESULT_NO_WAIT* = 0x9194
  GL_FILE_NAME_NV* = 0x9074
  GL_DRAW_FRAMEBUFFER_BINDING* = 0x8CA6
  GL_FRAGMENT_SHADER* = 0x8B30
  GL_VIBRANCE_SCALE_NV* = 0x8713
  GL_PATH_FILL_COVER_MODE_NV* = 0x9082
  GL_LINEAR_MIPMAP_LINEAR* = 0x2703
  GL_TEXTURE29* = 0x84DD
  GL_SCISSOR_BOX* = 0x0C10
  GL_PACK_SKIP_IMAGES* = 0x806B
  GL_BUFFER_MAP_OFFSET* = 0x9121
  GL_SLUMINANCE8_EXT* = 0x8C47
  GL_CONVOLUTION_1D* = 0x8010
  GL_MAX_GEOMETRY_IMAGE_UNIFORMS* = 0x90CD
  GL_MAP1_VERTEX_ATTRIB11_4_NV* = 0x866B
  GL_COLOR_LOGIC_OP* = 0x0BF2
  GL_SYNC_FLAGS_APPLE* = 0x9115
  GL_ACCUM_RED_BITS* = 0x0D58
  GL_VIEW_CLASS_128_BITS* = 0x82C4
  GL_INT_VEC3* = 0x8B54
  GL_INTENSITY12* = 0x804C
  GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER* = 0x90EC
  GL_REQUIRED_TEXTURE_IMAGE_UNITS_OES* = 0x8D68
  GL_MAX_COLOR_MATRIX_STACK_DEPTH* = 0x80B3
  GL_GLOBAL_ALPHA_FACTOR_SUN* = 0x81DA
  GL_PACK_RESAMPLE_SGIX* = 0x842C
  GL_MAX_COMPUTE_FIXED_GROUP_SIZE_ARB* = 0x91BF
  GL_DEPTH_BUFFER_FLOAT_MODE_NV* = 0x8DAF
  GL_SIGNED_LUMINANCE_ALPHA_NV* = 0x8703
  GL_OP_MIN_EXT* = 0x878B
  GL_TRANSFORM_FEEDBACK_BUFFER_MODE_NV* = 0x8C7F
  GL_COLOR_INDEX12_EXT* = 0x80E6
  GL_AUTO_NORMAL* = 0x0D80
  GL_ARRAY_BUFFER* = 0x8892
  GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_EXT* = 0x8DE1
  GL_VIDEO_CAPTURE_SURFACE_ORIGIN_NV* = 0x903C
  GL_ACCUM_BLUE_BITS* = 0x0D5A
  GL_RENDERBUFFER_SAMPLES_ANGLE* = 0x8CAB
  GL_MAX_ASYNC_HISTOGRAM_SGIX* = 0x832D
  GL_GLYPH_HAS_KERNING_BIT_NV* = 0x100
  GL_TESS_CONTROL_SUBROUTINE_UNIFORM* = 0x92EF
  GL_DRAW_BUFFER1* = 0x8826
  GL_INT8_NV* = 0x8FE0
  GL_2PASS_0_EXT* = 0x80A2
  GL_TRANSFORM_FEEDBACK_BUFFER_INDEX* = 0x934B
  GL_NUM_VIRTUAL_PAGE_SIZES_ARB* = 0x91A8
  GL_INT_SAMPLER_3D* = 0x8DCB
  GL_RASTERIZER_DISCARD* = 0x8C89
  GL_SOURCE2_RGB_ARB* = 0x8582
  GL_LOCAL_CONSTANT_EXT* = 0x87C3
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_EXT* = 0x8DA9
  GL_MODELVIEW12_ARB* = 0x872C
  GL_VERTEX_SUBROUTINE_UNIFORM* = 0x92EE
  GL_OPERAND0_ALPHA_ARB* = 0x8598
  GL_DEPTH24_STENCIL8* = 0x88F0
  GL_RENDERBUFFER_RED_SIZE* = 0x8D50
  GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING* = 0x8210
  GL_DRAW_BUFFER10_ARB* = 0x882F
  GL_UNSIGNED_INT_SAMPLER_3D* = 0x8DD3
  GL_SKIP_COMPONENTS2_NV* = -5
  GL_PROGRAM_BINARY_LENGTH_OES* = 0x8741
  GL_VERTEX_ATTRIB_MAP1_SIZE_APPLE* = 0x8A02
  GL_QUERY_RESULT_EXT* = 0x8866
  GL_CONSTANT_COLOR0_NV* = 0x852A
  GL_MAX_ASYNC_DRAW_PIXELS_SGIX* = 0x8360
  GL_DOT_PRODUCT_DIFFUSE_CUBE_MAP_NV* = 0x86F1
  GL_ALPHA_TEST_REF* = 0x0BC2
  GL_MAX_4D_TEXTURE_SIZE_SGIS* = 0x8138
  GL_INT_SAMPLER_2D_MULTISAMPLE* = 0x9109
  GL_DRAW_BUFFER6_ATI* = 0x882B
  GL_INTENSITY16UI_EXT* = 0x8D79
  GL_POINT_FADE_THRESHOLD_SIZE_ARB* = 0x8128
  GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING* = 0x889F
  GL_RENDERBUFFER_WIDTH_EXT* = 0x8D42
  GL_FIXED_ONLY* = 0x891D
  GL_HISTOGRAM_BLUE_SIZE* = 0x802A
  GL_PROGRAM_TEX_INSTRUCTIONS_ARB* = 0x8806
  GL_MAX_VERTEX_SHADER_VARIANTS_EXT* = 0x87C6
  GL_UNSIGNED_INT_10_10_10_2_EXT* = 0x8036
  GL_SAMPLE_ALPHA_TO_ONE_EXT* = 0x809F
  GL_INDEX_ARRAY* = 0x8077
  GL_GEQUAL* = 0x0206
  GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS* = 0x90D8
  GL_DITHER* = 0x0BD0
  GL_ATTACHED_SHADERS* = 0x8B85
  GL_FUNC_SUBTRACT* = 0x800A
  GL_ATOMIC_COUNTER_BARRIER_BIT_EXT* = 0x00001000
  GL_LUMINANCE4* = 0x803F
  GL_BLEND_EQUATION_RGB_EXT* = 0x8009
  GL_TEXTURE_MULTI_BUFFER_HINT_SGIX* = 0x812E
  GL_DEBUG_SEVERITY_LOW_KHR* = 0x9148
  GL_UNPACK_COMPRESSED_BLOCK_HEIGHT* = 0x9128
  GL_CULL_VERTEX_OBJECT_POSITION_EXT* = 0x81AC
  GL_POST_COLOR_MATRIX_ALPHA_BIAS_SGI* = 0x80BB
  GL_ADD_SIGNED_EXT* = 0x8574
  GL_VERTEX_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F5
  GL_CURRENT_RASTER_SECONDARY_COLOR* = 0x845F
  GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_NV* = 0x8E5F
  GL_CONTINUOUS_AMD* = 0x9007
  GL_R1UI_T2F_C4F_N3F_V3F_SUN* = 0x85CB
  GL_COMPUTE_SHADER* = 0x91B9
  GL_CLIP_DISTANCE6* = 0x3006
  GL_SRC_ATOP_NV* = 0x928E
  GL_DEPTH_COMPONENT16_OES* = 0x81A5
  GL_DOUBLE_MAT4* = 0x8F48
  GL_MAT_SHININESS_BIT_PGI* = 0x02000000
  GL_SAMPLER_BUFFER_AMD* = 0x9001
  GL_ARRAY_BUFFER_BINDING_ARB* = 0x8894
  GL_VOLATILE_APPLE* = 0x8A1A
  GL_ALPHA32UI_EXT* = 0x8D72
  GL_COLOR_BUFFER_BIT1_QCOM* = 0x00000002
  GL_VERTEX_PROGRAM_CALLBACK_MESA* = 0x8BB4
  GL_CULL_VERTEX_EXT* = 0x81AA
  GL_RENDERBUFFER_STENCIL_SIZE_EXT* = 0x8D55
  GL_SELECT* = 0x1C02
  GL_LUMINANCE12_ALPHA4* = 0x8046
  GL_IMAGE_BINDING_LEVEL_EXT* = 0x8F3B
  GL_MATRIX_PALETTE_ARB* = 0x8840
  GL_DUAL_ALPHA4_SGIS* = 0x8110
  GL_BACK_NORMALS_HINT_PGI* = 0x1A223
  GL_UNSIGNED_SHORT_15_1_MESA* = 0x8753
  GL_UNSIGNED_SHORT_4_4_4_4_REV* = 0x8365
  GL_BUFFER* = 0x82E0
  GL_RENDERBUFFER_INTERNAL_FORMAT_EXT* = 0x8D44
  GL_MATRIX5_NV* = 0x8635
  GL_ATOMIC_COUNTER_BUFFER* = 0x92C0
  GL_SMOOTH_QUADRATIC_CURVE_TO_NV* = 0x0E
  GL_VARIABLE_D_NV* = 0x8526
  GL_PINLIGHT_NV* = 0x92A8
  GL_VERTEX_ATTRIB_ARRAY_INTEGER_EXT* = 0x88FD
  GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS* = 0x92CF
  GL_Z6Y10Z6CB10Z6A10Z6Y10Z6CR10Z6A10_4224_NV* = 0x9034
  GL_RESAMPLE_REPLICATE_SGIX* = 0x842E
  GL_UNSIGNED_SHORT_5_6_5_REV* = 0x8364
  GL_VERTEX_ATTRIB_ARRAY2_NV* = 0x8652
  GL_3D_COLOR_TEXTURE* = 0x0603
  GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS* = 0x8B4C
  GL_DEBUG_TYPE_PERFORMANCE_KHR* = 0x8250
  GL_MATRIX_INDEX_ARRAY_OES* = 0x8844
  GL_TEXTURE_TOO_LARGE_EXT* = 0x8065
  GL_PACK_IMAGE_HEIGHT_EXT* = 0x806C
  GL_YCBYCR8_422_NV* = 0x9031
  GL_COLOR_ATTACHMENT8* = 0x8CE8
  GL_SAMPLE_COVERAGE_ARB* = 0x80A0
  GL_CURRENT_VERTEX_EXT* = 0x87E2
  GL_LINEAR* = 0x2601
  GL_STENCIL_TAG_BITS_EXT* = 0x88F2
  GL_T2F_IUI_V3F_EXT* = 0x81B2
  GL_TEXTURE_3D_BINDING_OES* = 0x806A
  GL_PATH_CLIENT_LENGTH_NV* = 0x907F
  GL_MAT_AMBIENT_BIT_PGI* = 0x00100000
  GL_DOUBLE_MAT4x3* = 0x8F4E
  GL_QUERY_BY_REGION_WAIT_NV* = 0x8E15
  GL_LEQUAL* = 0x0203
  GL_PROGRAM_ATTRIBS_ARB* = 0x88AC
  GL_BUFFER_MAPPED_ARB* = 0x88BC
  GL_VERTEX_SHADER_ARB* = 0x8B31
  GL_SOURCE1_ALPHA_EXT* = 0x8589
  GL_UNSIGNED_INT16_VEC3_NV* = 0x8FF2
  GL_MAX_PROGRAM_ADDRESS_REGISTERS_ARB* = 0x88B1
  GL_RGB16* = 0x8054
  GL_TEXTURE15_ARB* = 0x84CF
  GL_TEXTURE_GATHER_SHADOW* = 0x82A3
  GL_FENCE_APPLE* = 0x8A0B
  GL_TRIANGLES* = 0x0004
  GL_DOT4_ATI* = 0x8967
  GL_CURRENT_FOG_COORD* = 0x8453
  GL_DEPTH_CLAMP_NEAR_AMD* = 0x901E
  GL_SYNC_FENCE* = 0x9116
  GL_UNSIGNED_INT64_VEC3_NV* = 0x8FF6
  GL_DEPTH* = 0x1801
  GL_TEXTURE_COORD_NV* = 0x8C79
  GL_COMBINE* = 0x8570
  GL_MAX_VERTEX_UNITS_ARB* = 0x86A4
  GL_COLOR_INDEX2_EXT* = 0x80E3
  GL_POST_IMAGE_TRANSFORM_COLOR_TABLE_HP* = 0x8162
  GL_INT_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x900E
  GL_MIRROR_CLAMP_EXT* = 0x8742
  GL_STENCIL_VALUE_MASK* = 0x0B93
  GL_UNSIGNED_INT_SAMPLER_BUFFER* = 0x8DD8
  GL_TRACK_MATRIX_NV* = 0x8648
  GL_MAP1_VERTEX_3* = 0x0D97
  GL_OP_MOV_EXT* = 0x8799
  GL_MAP_INVALIDATE_RANGE_BIT_EXT* = 0x0004
  GL_MAX_CONVOLUTION_WIDTH_EXT* = 0x801A
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_OES* = 0x8518
  GL_RGBA_SNORM* = 0x8F93
  GL_MAX_TRACK_MATRICES_NV* = 0x862F
  GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS* = 0x886D
  GL_DOUBLE_VEC4_EXT* = 0x8FFE
  GL_COLOR_TABLE_BLUE_SIZE* = 0x80DC
  GL_T2F_C3F_V3F* = 0x2A2A
  GL_INTENSITY16_SNORM* = 0x901B
  GL_INT_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x905F
  GL_DEBUG_CATEGORY_UNDEFINED_BEHAVIOR_AMD* = 0x914C
  GL_NORMAL_MAP_EXT* = 0x8511
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS_NV* = 0x8C8B
  GL_DRAW_BUFFER4_EXT* = 0x8829
  GL_PIXEL_MAP_G_TO_G* = 0x0C77
  GL_TESS_GEN_POINT_MODE* = 0x8E79
  GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS* = 0x92CC
  GL_UNSIGNED_INT_SAMPLER_2D_RECT_EXT* = 0x8DD5
  GL_MULTISAMPLE_BUFFER_BIT2_QCOM* = 0x04000000
  GL_POST_COLOR_MATRIX_GREEN_BIAS_SGI* = 0x80B9
  GL_POST_COLOR_MATRIX_GREEN_BIAS* = 0x80B9
  GL_TEXTURE10* = 0x84CA
  GL_RGB32F* = 0x8815
  GL_DYNAMIC_READ_ARB* = 0x88E9
  GL_MODELVIEW22_ARB* = 0x8736
  GL_VERTEX_STREAM0_ATI* = 0x876C
  GL_TEXTURE_FETCH_BARRIER_BIT_EXT* = 0x00000008
  GL_COMBINER_INPUT_NV* = 0x8542
  GL_DRAW_BUFFER0_NV* = 0x8825
  GL_ALPHA_TEST* = 0x0BC0
  GL_PIXEL_UNPACK_BUFFER* = 0x88EC
  GL_SRC_IN_NV* = 0x928A
  GL_COMPRESSED_SIGNED_RED_RGTC1_EXT* = 0x8DBC
  GL_PACK_SUBSAMPLE_RATE_SGIX* = 0x85A0
  GL_FRAMEBUFFER_DEFAULT_SAMPLES* = 0x9313
  GL_ARRAY_OBJECT_OFFSET_ATI* = 0x8767
  GL_TEXTURE_CUBE_MAP_POSITIVE_X_OES* = 0x8515
  GL_STENCIL_BITS* = 0x0D57
  GL_DEPTH_COMPONENT24_OES* = 0x81A6
  GL_FRAMEBUFFER* = 0x8D40
  GL_8X_BIT_ATI* = 0x00000004
  GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY* = 0x9105
  GL_BOOL_VEC2* = 0x8B57
  GL_EXP* = 0x0800
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT* = 0x851A
  GL_STENCIL_INDEX16* = 0x8D49
  GL_FRAGMENT_LIGHTING_SGIX* = 0x8400
  GL_PACK_SKIP_PIXELS* = 0x0D04
  GL_TEXTURE_MIN_LOD* = 0x813A
  GL_COMPRESSED_RGB* = 0x84ED
  GL_MAP1_VERTEX_ATTRIB2_4_NV* = 0x8662
  GL_CONJOINT_NV* = 0x9284
  GL_MAX_COMPUTE_SHARED_MEMORY_SIZE* = 0x8262
  GL_INTENSITY8* = 0x804B
  GL_SAMPLER_2D_MULTISAMPLE* = 0x9108
  GL_MAX_LIST_NESTING* = 0x0B31
  GL_DOUBLE_MAT3* = 0x8F47
  GL_TEXTURE_DEPTH* = 0x8071
  GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION* = 0x8E4C
  GL_TEXTURE12_ARB* = 0x84CC
  GL_R1UI_T2F_V3F_SUN* = 0x85C9
  GL_REPLACE* = 0x1E01
  GL_MAX_NUM_ACTIVE_VARIABLES* = 0x92F7
  GL_RGBA_INTEGER_EXT* = 0x8D99
  GL_TEXTURE_COMPRESSED_BLOCK_SIZE* = 0x82B3
  GL_INDEX_CLEAR_VALUE* = 0x0C20
  GL_PROGRAM_ERROR_POSITION_ARB* = 0x864B
  GL_LINEARBURN_NV* = 0x92A5
  GL_TEXTURE_BINDING_CUBE_MAP_ARB* = 0x8514
  GL_TESSELLATION_FACTOR_AMD* = 0x9005
  GL_SHADER_IMAGE_STORE* = 0x82A5
  GL_COMPRESSED_SLUMINANCE_ALPHA_EXT* = 0x8C4B
  GL_MAX_PALETTE_MATRICES_ARB* = 0x8842
  GL_UNPACK_CONSTANT_DATA_SUNX* = 0x81D5
  GL_FLOAT_MAT3x4* = 0x8B68
  GL_DRAW_BUFFER8_NV* = 0x882D
  GL_ATTENUATION_EXT* = 0x834D
  GL_REG_25_ATI* = 0x893A
  GL_UNSIGNED_INT_SAMPLER_1D* = 0x8DD1
  GL_TEXTURE_1D_STACK_BINDING_MESAX* = 0x875D
  GL_SYNC_STATUS_APPLE* = 0x9114
  GL_TEXTURE_CUBE_MAP_ARRAY* = 0x9009
  GL_EXP2* = 0x0801
  GL_COMPRESSED_SIGNED_LUMINANCE_LATC1_EXT* = 0x8C71
  GL_BUFFER_ACCESS_ARB* = 0x88BB
  GL_LO_BIAS_NV* = 0x8715
  GL_MIRROR_CLAMP_ATI* = 0x8742
  GL_SAMPLE_COVERAGE_VALUE* = 0x80AA
  GL_UNSIGNED_INT_24_8_EXT* = 0x84FA
  GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN_EXT* = 0x8C88
  GL_R16UI* = 0x8234
  GL_BLEND_PREMULTIPLIED_SRC_NV* = 0x9280
  GL_COLOR_ATTACHMENT0* = 0x8CE0
  GL_GEOMETRY_VERTICES_OUT_EXT* = 0x8DDA
  GL_SAMPLE_MASK_NV* = 0x8E51
  GL_BGRA_INTEGER_EXT* = 0x8D9B
  GL_PALETTE8_RGBA8_OES* = 0x8B96
  GL_MAX_ARRAY_TEXTURE_LAYERS_EXT* = 0x88FF
  GL_TEXTURE_COLOR_TABLE_SGI* = 0x80BC
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS_EXT* = 0x8C80
  GL_TEXTURE10_ARB* = 0x84CA
  GL_TRIANGLES_ADJACENCY* = 0x000C
  GL_COLOR_ARRAY_EXT* = 0x8076
  GL_MAX_FRAMEBUFFER_SAMPLES* = 0x9318
  GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB* = 0x889F
  GL_IMAGE_TEXEL_SIZE* = 0x82A7
  GL_MAGNITUDE_BIAS_NV* = 0x8718
  GL_SHADOW_AMBIENT_SGIX* = 0x80BF
  GL_BUFFER_SERIALIZED_MODIFY_APPLE* = 0x8A12
  GL_TEXTURE_COORD_ARRAY_COUNT_EXT* = 0x808B
  GL_MAX_DRAW_BUFFERS_ARB* = 0x8824
  GL_MAX_OPTIMIZED_VERTEX_SHADER_INVARIANTS_EXT* = 0x87CD
  GL_PASS_THROUGH_TOKEN* = 0x0700
  GL_BLEND_EQUATION* = 0x8009
  GL_FOG_HINT* = 0x0C54
  GL_FLOAT_RGB16_NV* = 0x8888
  GL_OUTPUT_TEXTURE_COORD18_EXT* = 0x87AF
  GL_T2F_IUI_N3F_V2F_EXT* = 0x81B3
  GL_SAMPLER_EXTERNAL_OES* = 0x8D66
  GL_MAX_SUBROUTINES* = 0x8DE7
  GL_RED_BIT_ATI* = 0x00000001
  GL_SOURCE2_ALPHA* = 0x858A
  GL_AUX0* = 0x0409
  GL_OPERAND1_ALPHA_ARB* = 0x8599
  GL_TEXTURE_MAX_ANISOTROPY_EXT* = 0x84FE
  GL_VERTEX_PROGRAM_POINT_SIZE_NV* = 0x8642
  GL_MULTIVIEW_EXT* = 0x90F1
  GL_FOG_OFFSET_SGIX* = 0x8198
  GL_COLOR_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F7
  GL_ELEMENT_ARRAY_ATI* = 0x8768
  GL_ALPHA16_SNORM* = 0x9018
  GL_COMPRESSED_SLUMINANCE_EXT* = 0x8C4A
  GL_TEXTURE_OBJECT_VALID_QCOM* = 0x8BDB
  GL_STENCIL_BACK_FUNC* = 0x8800
  GL_CULL_FACE* = 0x0B44
  GL_MAP1_COLOR_4* = 0x0D90
  GL_SHADER_OBJECT_ARB* = 0x8B48
  GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG* = 0x8C01
  GL_TANGENT_ARRAY_EXT* = 0x8439
  GL_NUM_FRAGMENT_CONSTANTS_ATI* = 0x896F
  GL_COLOR_RENDERABLE* = 0x8286
  GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS* = 0x8B4D
  GL_TRANSFORM_FEEDBACK_RECORD_NV* = 0x8C86
  GL_COLOR_ATTACHMENT1_NV* = 0x8CE1
  GL_ALPHA_SNORM* = 0x9010
  GL_PIXEL_TRANSFORM_2D_MATRIX_EXT* = 0x8338
  GL_SMOOTH_POINT_SIZE_GRANULARITY* = 0x0B13
  GL_R8I* = 0x8231
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_EXT* = 0x8D56
  GL_POLYGON_OFFSET_BIAS_EXT* = 0x8039
  GL_DEPTH_COMPONENT24* = 0x81A6
  GL_TEXTURE_SWIZZLE_B* = 0x8E44
  GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS* = 0x8E81
  GL_MAP2_INDEX* = 0x0DB1
  GL_SAMPLER_CUBE_MAP_ARRAY* = 0x900C
  GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT* = 0x8CD6
  GL_UNSIGNED_INT_8_8_8_8_REV* = 0x8367
  GL_PATH_GEN_COEFF_NV* = 0x90B1
  GL_OPERAND3_ALPHA_NV* = 0x859B
  GL_LUMINANCE* = 0x1909
  GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS* = 0x8DE8
  GL_MAP_READ_BIT* = 0x0001
  GL_MAX_TEXTURE_STACK_DEPTH* = 0x0D39
  GL_ORDER* = 0x0A01
  GL_PATH_FILL_MODE_NV* = 0x9080
  GL_RENDERBUFFER_BLUE_SIZE* = 0x8D52
  GL_TEXTURE_INTENSITY_SIZE* = 0x8061
  GL_DRAW_BUFFER1_NV* = 0x8826
  GL_SCREEN_NV* = 0x9295
  GL_RGB8I_EXT* = 0x8D8F
  GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET* = 0x8E5E
  GL_DUAL_INTENSITY12_SGIS* = 0x811A
  GL_SPARE1_NV* = 0x852F
  GL_PALETTE8_R5_G6_B5_OES* = 0x8B97
  GL_COLOR_ATTACHMENT7_NV* = 0x8CE7
  GL_TEXTURE_HEIGHT* = 0x1001
  GL_RENDERBUFFER_BINDING* = 0x8CA7
  GL_DRAW_BUFFER7_EXT* = 0x882C
  GL_HISTOGRAM* = 0x8024
  GL_COLOR_ATTACHMENT0_OES* = 0x8CE0
  GL_BINORMAL_ARRAY_STRIDE_EXT* = 0x8441
  GL_DEBUG_SEVERITY_HIGH_AMD* = 0x9146
  GL_MIN_SPARSE_LEVEL_AMD* = 0x919B
  GL_MAP1_VERTEX_ATTRIB10_4_NV* = 0x866A
  GL_COEFF* = 0x0A00
  GL_COMPRESSED_RGBA_ASTC_6x5_KHR* = 0x93B3
  GL_TEXTURE_4D_BINDING_SGIS* = 0x814F
  GL_BUFFER_USAGE* = 0x8765
  GL_YCBCR_MESA* = 0x8757
  GL_CLAMP_VERTEX_COLOR* = 0x891A
  GL_RGBA8_EXT* = 0x8058
  GL_BITMAP_TOKEN* = 0x0704
  GL_IMAGE_SCALE_Y_HP* = 0x8156
  GL_OUTPUT_TEXTURE_COORD25_EXT* = 0x87B6
  GL_DEBUG_SOURCE_API* = 0x8246
  GL_STACK_UNDERFLOW* = 0x0504
  GL_COMBINER_CD_DOT_PRODUCT_NV* = 0x8546
  GL_FRAMEBUFFER_BINDING_EXT* = 0x8CA6
  GL_REG_20_ATI* = 0x8935
  GL_MAP1_TEXTURE_COORD_4* = 0x0D96
  GL_DEBUG_OUTPUT_SYNCHRONOUS* = 0x8242
  GL_ACCUM_ALPHA_BITS* = 0x0D5B
  GL_INT_10_10_10_2_OES* = 0x8DF7
  GL_FLOAT_MAT2_ARB* = 0x8B5A
  GL_FRONT_RIGHT* = 0x0401
  GL_COMBINER_AB_DOT_PRODUCT_NV* = 0x8545
  GL_LUMINANCE_ALPHA* = 0x190A
  GL_C4UB_V2F* = 0x2A22
  GL_COMBINER_MUX_SUM_NV* = 0x8547
  GL_MODELVIEW_STACK_DEPTH* = 0x0BA3
  GL_SAMPLES_ARB* = 0x80A9
  GL_ALPHA_TEST_FUNC* = 0x0BC1
  GL_DEPTH_CLAMP* = 0x864F
  GL_MAP2_VERTEX_ATTRIB8_4_NV* = 0x8678
  GL_INVALID_INDEX* = 0xFFFFFFFF
  GL_COMBINER_SCALE_NV* = 0x8548
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER* = 0x92CB
  GL_DOT_PRODUCT_TEXTURE_RECTANGLE_NV* = 0x864E
  GL_RELATIVE_SMALL_CW_ARC_TO_NV* = 0x15
  GL_UNSIGNED_INT_10_10_10_2_OES* = 0x8DF6
  GL_DISCARD_ATI* = 0x8763
  GL_PRIMITIVE_RESTART_INDEX_NV* = 0x8559
  GL_IMAGE_CLASS_2_X_8* = 0x82C0
  GL_MANUAL_GENERATE_MIPMAP* = 0x8294
  GL_FLOAT_R_NV* = 0x8880
  GL_SATURATE_BIT_ATI* = 0x00000040
  GL_BUFFER_SIZE* = 0x8764
  GL_FRAMEBUFFER_BARRIER_BIT_EXT* = 0x00000400
  GL_LUMINANCE8UI_EXT* = 0x8D80
  GL_T2F_IUI_V2F_EXT* = 0x81B1
  GL_OUTPUT_TEXTURE_COORD15_EXT* = 0x87AC
  GL_COVERAGE_AUTOMATIC_NV* = 0x8ED7
  GL_TEXTURE_INTERNAL_FORMAT_QCOM* = 0x8BD5
  GL_INT_IMAGE_CUBE_MAP_ARRAY* = 0x905F
  GL_BUFFER_UPDATE_BARRIER_BIT_EXT* = 0x00000200
  GL_GLYPH_WIDTH_BIT_NV* = 0x01
  GL_OP_MAX_EXT* = 0x878A
  GL_MINMAX_FORMAT_EXT* = 0x802F
  GL_R16I* = 0x8233
  GL_PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB* = 0x8809
  GL_TEXTURE_MAX_LEVEL* = 0x813D
  GL_GEOMETRY_SHADER* = 0x8DD9
  GL_MAX_RENDERBUFFER_SIZE* = 0x84E8
  GL_RGB16_EXT* = 0x8054
  GL_DUAL_INTENSITY16_SGIS* = 0x811B
  GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT* = 0x8CD6
  GL_BLUE_SCALE* = 0x0D1A
  GL_RGBA_FLOAT16_APPLE* = 0x881A
  GL_RGBA8UI* = 0x8D7C
  GL_COLOR_ATTACHMENT5* = 0x8CE5
  GL_UNSIGNED_IDENTITY_NV* = 0x8536
  GL_COMPRESSED_RGBA_ASTC_10x8_KHR* = 0x93BA
  GL_FRAGMENT_SHADER_ARB* = 0x8B30
  GL_R8* = 0x8229
  GL_IMAGE_BINDING_LAYERED* = 0x8F3C
  GL_RGBA_FLOAT32_ATI* = 0x8814
  GL_TEXTURE_RED_SIZE_EXT* = 0x805C
  GL_INT8_VEC2_NV* = 0x8FE1
  GL_NEGATE_BIT_ATI* = 0x00000004
  GL_ALL_BARRIER_BITS_EXT* = 0xFFFFFFFF
  GL_LIGHT_MODEL_COLOR_CONTROL_EXT* = 0x81F8
  GL_LUMINANCE_ALPHA16UI_EXT* = 0x8D7B
  GL_COUNT_UP_NV* = 0x9088
  GL_QUERY_RESULT_AVAILABLE_ARB* = 0x8867
  GL_DRAW_INDIRECT_BUFFER* = 0x8F3F
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_EXT* = 0x8CD3
  GL_OP_DOT3_EXT* = 0x8784
  GL_COLOR_ATTACHMENT10_NV* = 0x8CEA
  GL_STENCIL_INDEX4_OES* = 0x8D47
  GL_LUMINANCE_FLOAT32_ATI* = 0x8818
  GL_DRAW_BUFFER9_ARB* = 0x882E
  GL_RG8_EXT* = 0x822B
  GL_FONT_DESCENDER_BIT_NV* = 0x00400000
  GL_TEXTURE_ALPHA_SIZE_EXT* = 0x805F
  GL_Y_EXT* = 0x87D6
  GL_MAX_GEOMETRY_BINDABLE_UNIFORMS_EXT* = 0x8DE4
  GL_SAMPLER_3D_ARB* = 0x8B5F
  GL_INVERT_OVG_NV* = 0x92B4
  GL_REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x9308
  GL_TEXTURE_COORD_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F8
  GL_LIGHT4* = 0x4004
  GL_VERTEX_STATE_PROGRAM_NV* = 0x8621
  GL_ZERO* = 0
  GL_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x900C
  GL_SAMPLE_MASK_EXT* = 0x80A0
  GL_COMBINER_CD_OUTPUT_NV* = 0x854B
  GL_SAMPLE_ALPHA_TO_MASK_SGIS* = 0x809E
  GL_RGBA16* = 0x805B
  GL_PATH_TERMINAL_DASH_CAP_NV* = 0x907D
  GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB* = 0x889C
  GL_DEBUG_SEVERITY_HIGH_KHR* = 0x9146
  GL_DRAW_BUFFER14_EXT* = 0x8833
  GL_READ_FRAMEBUFFER* = 0x8CA8
  GL_UNSIGNED_SHORT_8_8_APPLE* = 0x85BA
  GL_OR* = 0x1507
  GL_ONE_MINUS_DST_ALPHA* = 0x0305
  GL_RGB12* = 0x8053
  GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_OES* = 0x8CDB
  GL_OUTPUT_TEXTURE_COORD26_EXT* = 0x87B7
  GL_LOCAL_CONSTANT_VALUE_EXT* = 0x87EC
  GL_SURFACE_REGISTERED_NV* = 0x86FD
  GL_FRAGMENT_PROGRAM_INTERPOLATION_OFFSET_BITS_NV* = 0x8E5D
  GL_COMPRESSED_RG_RGTC2* = 0x8DBD
  GL_MAX_VERTEX_ATTRIB_STRIDE* = 0x82E5
  GL_COLOR_ARRAY_ADDRESS_NV* = 0x8F23
  GL_MATRIX_INDEX_ARRAY_POINTER_ARB* = 0x8849
  GL_DUAL_ALPHA8_SGIS* = 0x8111
  GL_TEXTURE_MAX_LOD* = 0x813B
  GL_INTERNALFORMAT_SHARED_SIZE* = 0x8277
  GL_LINEAR_DETAIL_SGIS* = 0x8097
  GL_RG16F_EXT* = 0x822F
  GL_LIST_MODE* = 0x0B30
  GL_VIEWPORT_INDEX_PROVOKING_VERTEX* = 0x825F
  GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW* = 0x900D
  GL_COLOR_TABLE_LUMINANCE_SIZE* = 0x80DE
  GL_COLOR_ARRAY_POINTER* = 0x8090
  GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT* = 0x84FF
  GL_LUMINANCE32F_EXT* = 0x8818
  GL_FRAMEBUFFER_COMPLETE_OES* = 0x8CD5
  GL_MAX_PROGRAM_TEXTURE_GATHER_COMPONENTS_ARB* = 0x8F9F
  GL_FEEDBACK* = 0x1C01
  GL_UNSIGNED_INT_IMAGE_2D_ARRAY* = 0x9069
  GL_VERTEX_STREAM1_ATI* = 0x876D
  GL_SLUMINANCE_ALPHA_NV* = 0x8C44
  GL_MAX_TEXTURE_UNITS_ARB* = 0x84E2
  GL_MODELVIEW11_ARB* = 0x872B
  GL_DRAW_FRAMEBUFFER_BINDING_ANGLE* = 0x8CA6
  GL_NEGATIVE_W_EXT* = 0x87DC
  GL_MODELVIEW25_ARB* = 0x8739
  GL_NORMAL_ARRAY_LIST_STRIDE_IBM* = 103081
  GL_CON_0_ATI* = 0x8941
  GL_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x87CF
  GL_TRANSPOSE_PROGRAM_MATRIX_EXT* = 0x8E2E
  GL_TEXTURE_DEPTH_TYPE* = 0x8C16
  GL_PROGRAM_TARGET_NV* = 0x8646
  GL_MAX_OPTIMIZED_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x87CC
  GL_NORMAL_ARRAY_STRIDE_EXT* = 0x807F
  GL_INT_SAMPLER_2D* = 0x8DCA
  GL_MAP2_VERTEX_ATTRIB10_4_NV* = 0x867A
  GL_STEREO* = 0x0C33
  GL_UNSIGNED_INT_IMAGE_2D_RECT_EXT* = 0x9065
  GL_TESS_EVALUATION_PROGRAM_PARAMETER_BUFFER_NV* = 0x8C75
  GL_TRACE_ERRORS_BIT_MESA* = 0x0020
  GL_MAX_GEOMETRY_UNIFORM_BLOCKS* = 0x8A2C
  GL_CONVOLUTION_2D* = 0x8011
  GL_RGB_SCALE_ARB* = 0x8573
  GL_VIDEO_COLOR_CONVERSION_MAX_NV* = 0x902A
  GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS* = 0x90DD
  GL_TABLE_TOO_LARGE_EXT* = 0x8031
  GL_TRANSFORM_FEEDBACK_BINDING_NV* = 0x8E25
  GL_TEXTURE16_ARB* = 0x84D0
  GL_FRAGMENT_SHADER_DERIVATIVE_HINT* = 0x8B8B
  GL_IUI_N3F_V2F_EXT* = 0x81AF
  GL_CLIP_PLANE2_IMG* = 0x3002
  GL_VERTEX_ATTRIB_ARRAY10_NV* = 0x865A
  GL_TEXTURE_FETCH_BARRIER_BIT* = 0x00000008
  GL_DOT3_RGBA_EXT* = 0x8741
  GL_RENDERBUFFER_GREEN_SIZE_EXT* = 0x8D51
  GL_MAX_CLIENT_ATTRIB_STACK_DEPTH* = 0x0D3B
  GL_UNPACK_COMPRESSED_BLOCK_SIZE* = 0x912A
  GL_SAMPLE_BUFFERS_SGIS* = 0x80A8
  GL_MAP1_VERTEX_ATTRIB1_4_NV* = 0x8661
  GL_BUFFER_OBJECT_EXT* = 0x9151
  GL_INT_SAMPLER_1D_ARRAY* = 0x8DCE
  GL_POST_TEXTURE_FILTER_SCALE_SGIX* = 0x817A
  GL_RED_MAX_CLAMP_INGR* = 0x8564
  GL_POST_COLOR_MATRIX_RED_SCALE_SGI* = 0x80B4
  GL_TEXTURE_COORD_ARRAY_TYPE* = 0x8089
  GL_COMPRESSED_SIGNED_RG11_EAC* = 0x9273
  GL_MULTISAMPLE_FILTER_HINT_NV* = 0x8534
  GL_COMPRESSED_RGBA8_ETC2_EAC* = 0x9278
  GL_FONT_UNDERLINE_THICKNESS_BIT_NV* = 0x08000000
  GL_READ_WRITE_ARB* = 0x88BA
  GL_RENDER_MODE* = 0x0C40
  GL_MAX_NUM_COMPATIBLE_SUBROUTINES* = 0x92F8
  GL_PN_TRIANGLES_NORMAL_MODE_QUADRATIC_ATI* = 0x87F8
  GL_MODELVIEW0_STACK_DEPTH_EXT* = 0x0BA3
  GL_CONTEXT_FLAG_DEBUG_BIT* = 0x00000002
  GL_TRANSFORM_FEEDBACK_BUFFER_START_EXT* = 0x8C84
  GL_POINT_SIZE_MAX_EXT* = 0x8127
  GL_COLOR_ARRAY_LENGTH_NV* = 0x8F2D
  GL_COLOR_COMPONENTS* = 0x8283
  GL_LINEARDODGE_NV* = 0x92A4
  GL_TEXTURE20_ARB* = 0x84D4
  GL_UNSIGNED_INT64_VEC4_NV* = 0x8FF7
  GL_TEXTURE28* = 0x84DC
  GL_HISTOGRAM_FORMAT_EXT* = 0x8027
  GL_PROGRAM_MATRIX_EXT* = 0x8E2D
  GL_PIXEL_PACK_BUFFER_EXT* = 0x88EB
  GL_TEXTURE_CUBE_MAP_POSITIVE_X_EXT* = 0x8515
  GL_STANDARD_FONT_NAME_NV* = 0x9072
  GL_REG_13_ATI* = 0x892E
  GL_GREEN_SCALE* = 0x0D18
  GL_COLOR_BUFFER_BIT7_QCOM* = 0x00000080
  GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS* = 0x8264
  GL_LUMINANCE8_ALPHA8_SNORM* = 0x9016
  GL_GCCSO_SHADER_BINARY_FJ* = 0x9260
  GL_COORD_REPLACE_NV* = 0x8862
  GL_SOURCE2_RGB_EXT* = 0x8582
  GL_IR_INSTRUMENT1_SGIX* = 0x817F
  GL_CONTEXT_FLAG_DEBUG_BIT_KHR* = 0x00000002
  GL_SWIZZLE_STR_ATI* = 0x8976
  GL_OUTPUT_TEXTURE_COORD17_EXT* = 0x87AE
  GL_MODELVIEW2_ARB* = 0x8722
  GL_R1UI_C4F_N3F_V3F_SUN* = 0x85C8
  GL_MAX_TEXTURE_BUFFER_SIZE_ARB* = 0x8C2B
  GL_OUTPUT_TEXTURE_COORD0_EXT* = 0x879D
  GL_POINT_FADE_THRESHOLD_SIZE_EXT* = 0x8128
  GL_OUTPUT_TEXTURE_COORD30_EXT* = 0x87BB
  GL_EVAL_VERTEX_ATTRIB3_NV* = 0x86C9
  GL_SPHERE_MAP* = 0x2402
  GL_SHADER_IMAGE_ATOMIC* = 0x82A6
  GL_INDEX_BITS* = 0x0D51
  GL_INTERNALFORMAT_ALPHA_TYPE* = 0x827B
  GL_CON_15_ATI* = 0x8950
  GL_TESS_EVALUATION_TEXTURE* = 0x829D
  GL_EDGE_FLAG_ARRAY_STRIDE* = 0x808C
  GL_VERTEX_ATTRIB_ARRAY8_NV* = 0x8658
  GL_POST_COLOR_MATRIX_COLOR_TABLE* = 0x80D2
  GL_CLOSE_PATH_NV* = 0x00
  GL_SCALE_BY_TWO_NV* = 0x853E
  GL_PALETTE8_RGB8_OES* = 0x8B95
  GL_MAX_COMPUTE_ATOMIC_COUNTERS* = 0x8265
  GL_VERTEX_ATTRIB_ARRAY_NORMALIZED* = 0x886A
  GL_MAX_VERTEX_ATTRIBS* = 0x8869
  GL_PROGRAM_POINT_SIZE_EXT* = 0x8642
  GL_TRANSLATED_SHADER_SOURCE_LENGTH_ANGLE* = 0x93A0
  GL_SIGNED_NORMALIZED* = 0x8F9C
  GL_MAX_CUBE_MAP_TEXTURE_SIZE_OES* = 0x851C
  GL_OFFSET_TEXTURE_2D_SCALE_NV* = 0x86E2
  GL_COMPRESSED_SLUMINANCE* = 0x8C4A
  GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS* = 0x8E80
  GL_RASTER_POSITION_UNCLIPPED_IBM* = 0x19262
  GL_COMPRESSED_TEXTURE_FORMATS_ARB* = 0x86A3
  GL_TRANSPOSE_MODELVIEW_MATRIX* = 0x84E3
  GL_ALPHA_FLOAT16_APPLE* = 0x881C
  GL_PIXEL_MIN_FILTER_EXT* = 0x8332
  GL_MAX_SPARSE_TEXTURE_SIZE_AMD* = 0x9198
  GL_UNSIGNED_SHORT_5_6_5_REV_EXT* = 0x8364
  GL_DU8DV8_ATI* = 0x877A
  GL_COLOR_ARRAY_LIST_IBM* = 103072
  GL_RGBA8I_EXT* = 0x8D8E
  GL_MULTISAMPLE_BUFFER_BIT4_QCOM* = 0x10000000
  GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB* = 0x824D
  GL_MODELVIEW20_ARB* = 0x8734
  GL_COLOR_TABLE_RED_SIZE* = 0x80DA
  GL_UNIFORM_BARRIER_BIT* = 0x00000004
  GL_TEXTURE* = 0x1702
  GL_CLIP_PLANE0* = 0x3000
  GL_FOG_COORDINATE_ARRAY_POINTER* = 0x8456
  GL_CONSTANT_ALPHA_EXT* = 0x8003
  GL_NAME_STACK_DEPTH* = 0x0D70
  GL_COMPRESSED_RGBA_S3TC_DXT3_ANGLE* = 0x83F2
  GL_LINEAR_DETAIL_ALPHA_SGIS* = 0x8098
  GL_EDGE_FLAG_ARRAY_POINTER_EXT* = 0x8093
  GL_UNSIGNED_SHORT* = 0x1403
  GL_MAP2_VERTEX_ATTRIB1_4_NV* = 0x8671
  GL_DEPTH_CLAMP_FAR_AMD* = 0x901F
  GL_OPERAND3_RGB_NV* = 0x8593
  GL_TEXTURE_SWIZZLE_R_EXT* = 0x8E42
  GL_PATCHES* = 0x000E
  GL_TEXTURE12* = 0x84CC
  GL_COLOR_ATTACHMENT12_EXT* = 0x8CEC
  GL_MAP2_VERTEX_ATTRIB15_4_NV* = 0x867F
  GL_DRAW_BUFFER15_ATI* = 0x8834
  GL_GEOMETRY_INPUT_TYPE* = 0x8917
  GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC_OES* = 0x9279
  GL_RGBA32UI_EXT* = 0x8D70
  GL_RGBA_FLOAT32_APPLE* = 0x8814
  GL_NORMAL_MAP_OES* = 0x8511
  GL_MAP2_GRID_DOMAIN* = 0x0DD2
  GL_RELATIVE_HORIZONTAL_LINE_TO_NV* = 0x07
  GL_TANGENT_ARRAY_STRIDE_EXT* = 0x843F
  GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT* = 0x8CDB
  GL_OBJECT_POINT_SGIS* = 0x81F5
  GL_IMAGE_2D_ARRAY* = 0x9053
  GL_MAX_GEOMETRY_UNIFORM_COMPONENTS_ARB* = 0x8DDF
  GL_SPRITE_MODE_SGIX* = 0x8149
  GL_WEIGHT_ARRAY_OES* = 0x86AD
  GL_MAX_VERTEX_STREAMS* = 0x8E71
  GL_R16F_EXT* = 0x822D
  GL_VERSION_ES_CL_1_0* = 1
  GL_PROXY_TEXTURE_COLOR_TABLE_SGI* = 0x80BD
  GL_MAX_PROGRAM_INSTRUCTIONS_ARB* = 0x88A1
  GL_PURGEABLE_APPLE* = 0x8A1D
  GL_TEXTURE_SWIZZLE_G_EXT* = 0x8E43
  GL_FIRST_VERTEX_CONVENTION_EXT* = 0x8E4D
  GL_DEBUG_SEVERITY_LOW* = 0x9148
  GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT* = 0x00000001
  GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB* = 0x8B8A
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR* = 0x93D4
  GL_DOT_PRODUCT_CONST_EYE_REFLECT_CUBE_MAP_NV* = 0x86F3
  GL_RENDERBUFFER_DEPTH_SIZE* = 0x8D54
  GL_OPERAND1_RGB_ARB* = 0x8591
  GL_REFLECTION_MAP_NV* = 0x8512
  GL_MATRIX17_ARB* = 0x88D1
  GL_EYE_PLANE_ABSOLUTE_NV* = 0x855C
  GL_SRC1_ALPHA* = 0x8589
  GL_UNSIGNED_BYTE_2_3_3_REV* = 0x8362
  GL_RGB5_EXT* = 0x8050
  GL_TEXTURE_2D_ARRAY* = 0x8C1A
  GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB* = 0x8515
  GL_TEXTURE26* = 0x84DA
  GL_MAX_3D_TEXTURE_SIZE_OES* = 0x8073
  GL_PIXEL_TILE_WIDTH_SGIX* = 0x8140
  GL_PIXEL_UNPACK_BUFFER_BINDING_EXT* = 0x88EF
  GL_TEXTURE_ALPHA_SIZE* = 0x805F
  GL_RELATIVE_QUADRATIC_CURVE_TO_NV* = 0x0B
  GL_POINT_SIZE_ARRAY_BUFFER_BINDING_OES* = 0x8B9F
  GL_GEOMETRY_DEFORMATION_BIT_SGIX* = 0x00000002
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS* = 0x8DA8
  GL_NAMED_STRING_LENGTH_ARB* = 0x8DE9
  GL_IMAGE_1D_ARRAY* = 0x9052
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_OES* = 0x8CD4
  GL_MATRIX28_ARB* = 0x88DC
  GL_FRAGMENT_LIGHT1_SGIX* = 0x840D
  GL_HARDMIX_NV* = 0x92A9
  GL_DEBUG_SOURCE_THIRD_PARTY_KHR* = 0x8249
  GL_PACK_SWAP_BYTES* = 0x0D00
  GL_MAX_VERTEX_UNIFORM_COMPONENTS_ARB* = 0x8B4A
  GL_SOURCE2_ALPHA_EXT* = 0x858A
  GL_DOUBLE_MAT2x4* = 0x8F4A
  GL_MEDIUM_FLOAT* = 0x8DF1
  GL_PIXEL_TILE_BEST_ALIGNMENT_SGIX* = 0x813E
  GL_UNPACK_SKIP_ROWS* = 0x0CF3
  GL_PACK_COMPRESSED_BLOCK_SIZE* = 0x912E
  GL_UNSIGNED_INT_IMAGE_2D* = 0x9063
  GL_COLOR_ARRAY_TYPE_EXT* = 0x8082
  GL_BUFFER_MAP_POINTER_ARB* = 0x88BD
  GL_CALLIGRAPHIC_FRAGMENT_SGIX* = 0x8183
  GL_ONE_MINUS_CONSTANT_COLOR_EXT* = 0x8002
  GL_COMPRESSED_RGBA_FXT1_3DFX* = 0x86B1
  GL_CLIP_PLANE1* = 0x3001
  GL_COVERAGE_BUFFERS_NV* = 0x8ED3
  GL_ADD_BLEND_IMG* = 0x8C09
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR* = 0x93D5
  GL_PIXEL_TILE_HEIGHT_SGIX* = 0x8141
  GL_SAMPLE_COVERAGE_INVERT_ARB* = 0x80AB
  GL_MAP1_VERTEX_ATTRIB9_4_NV* = 0x8669
  GL_COLOR_TABLE_BIAS_SGI* = 0x80D7
  GL_EDGE_FLAG_ARRAY_COUNT_EXT* = 0x808D
  GL_SAMPLE_BUFFERS_EXT* = 0x80A8
  GL_COLOR_INDEX* = 0x1900
  GL_REPLACEMENT_CODE_SUN* = 0x81D8
  GL_INT_SAMPLER_CUBE_EXT* = 0x8DCC
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_ANGLE* = 0x8D56
  GL_VERTEX_ATTRIB_ARRAY_UNIFIED_NV* = 0x8F1E
  GL_DUAL_LUMINANCE_ALPHA8_SGIS* = 0x811D
  GL_PIXEL_TEX_GEN_ALPHA_LS_SGIX* = 0x8189
  GL_CLIP_DISTANCE7* = 0x3007
  GL_DOT3_RGB_ARB* = 0x86AE
  GL_TEXTURE_WRAP_T* = 0x2803
  GL_LUMINANCE12_EXT* = 0x8041
  GL_TEXTURE_CLIPMAP_VIRTUAL_DEPTH_SGIX* = 0x8174
  GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB* = 0x86A0
  GL_EVAL_2D_NV* = 0x86C0
  GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS* = 0x9314
  GL_CURRENT_WEIGHT_ARB* = 0x86A8
  GL_DEBUG_SOURCE_API_ARB* = 0x8246
  GL_FOG_SPECULAR_TEXTURE_WIN* = 0x80EC
  GL_BOOL_VEC4* = 0x8B59
  GL_FRAGMENTS_INSTRUMENT_SGIX* = 0x8313
  GL_GEOMETRY_OUTPUT_TYPE_EXT* = 0x8DDC
  GL_TEXTURE_2D* = 0x0DE1
  GL_MAT_AMBIENT_AND_DIFFUSE_BIT_PGI* = 0x00200000
  GL_TEXTURE_BINDING_RECTANGLE_ARB* = 0x84F6
  GL_SAMPLE_BUFFERS_3DFX* = 0x86B3
  GL_INDEX_OFFSET* = 0x0D13
  GL_MAX_COLOR_ATTACHMENTS* = 0x8CDF
  GL_PLUS_CLAMPED_NV* = 0x92B1
  GL_SIGNED_NEGATE_NV* = 0x853D
  GL_PROXY_TEXTURE_2D_STACK_MESAX* = 0x875C
  GL_MAX_VERTEX_UNIFORM_COMPONENTS* = 0x8B4A
  GL_SAMPLE_MASK_VALUE_SGIS* = 0x80AA
  GL_QUADRATIC_ATTENUATION* = 0x1209
  GL_LUMINANCE32F_ARB* = 0x8818
  GL_COVERAGE_COMPONENT4_NV* = 0x8ED1
  GL_MINMAX_FORMAT* = 0x802F
  GL_SRGB_DECODE_ARB* = 0x8299
  GL_FRAMEBUFFER_INCOMPLETE_FORMATS_EXT* = 0x8CDA
  GL_UNSIGNED_INT_SAMPLER_CUBE_EXT* = 0x8DD4
  GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2* = 0x9277
  GL_DISJOINT_NV* = 0x9283
  GL_TEXTURE_ENV_BIAS_SGIX* = 0x80BE
  GL_PROXY_TEXTURE_3D_EXT* = 0x8070
  GL_SGX_BINARY_IMG* = 0x8C0A
  GL_COPY_READ_BUFFER* = 0x8F36
  GL_POINT_FADE_THRESHOLD_SIZE_SGIS* = 0x8128
  GL_UNIFORM_MATRIX_STRIDE* = 0x8A3D
  GL_UNIFORM_BLOCK_NAME_LENGTH* = 0x8A41
  GL_HISTOGRAM_LUMINANCE_SIZE* = 0x802C
  GL_UNSIGNED_SHORT_4_4_4_4* = 0x8033
  GL_MAX_DEPTH* = 0x8280
  GL_IMAGE_1D* = 0x904C
  GL_LUMINANCE8_ALPHA8_EXT* = 0x8045
  GL_MAX_TEXTURE_IMAGE_UNITS* = 0x8872
  GL_MODELVIEW16_ARB* = 0x8730
  GL_CURRENT_PALETTE_MATRIX_OES* = 0x8843
  GL_SIGNED_HILO_NV* = 0x86F9
  GL_FRAMEBUFFER_DEFAULT_HEIGHT* = 0x9311
  GL_UNPACK_SKIP_IMAGES* = 0x806D
  GL_2_BYTES* = 0x1407
  GL_ALLOW_DRAW_FRG_HINT_PGI* = 0x1A210
  GL_INTENSITY16I_EXT* = 0x8D8B
  GL_MAX_SAMPLES_NV* = 0x8D57
  GL_VERTEX_ARRAY_STORAGE_HINT_APPLE* = 0x851F
  GL_LINE_STRIP_ADJACENCY_ARB* = 0x000B
  GL_COORD_REPLACE* = 0x8862
  GL_INDEX_MATERIAL_FACE_EXT* = 0x81BA
  GL_MODELVIEW15_ARB* = 0x872F
  GL_TEXTURE19* = 0x84D3
  GL_UNSIGNED_INT_IMAGE_1D_ARRAY_EXT* = 0x9068
  GL_SIGNED_INTENSITY8_NV* = 0x8708
  GL_TEXTURE_MAG_SIZE_NV* = 0x871F
  GL_DISPATCH_INDIRECT_BUFFER* = 0x90EE
  GL_MAP1_INDEX* = 0x0D91
  GL_TEXTURE_BUFFER_DATA_STORE_BINDING* = 0x8C2D
  GL_MAX_HEIGHT* = 0x827F
  GL_BLEND_DST_ALPHA* = 0x80CA
  GL_R1UI_C3F_V3F_SUN* = 0x85C6
  GL_TEXTURE_PRIORITY_EXT* = 0x8066
  GL_INT_IMAGE_2D* = 0x9058
  GL_MAX_MULTISAMPLE_COVERAGE_MODES_NV* = 0x8E11
  GL_DRAW_BUFFER4_ATI* = 0x8829
  GL_MAX_GEOMETRY_VARYING_COMPONENTS_ARB* = 0x8DDD
  GL_DEPTH_EXT* = 0x1801
  GL_SAMPLE_POSITION* = 0x8E50
  GL_INTERNALFORMAT_DEPTH_TYPE* = 0x827C
  GL_MATRIX23_ARB* = 0x88D7
  GL_DEBUG_TYPE_PUSH_GROUP* = 0x8269
  GL_POLYGON_OFFSET_FILL* = 0x8037
  GL_FRAGMENT_PROGRAM_BINDING_NV* = 0x8873
  GL_FRAMEBUFFER_SRGB_CAPABLE_EXT* = 0x8DBA
  GL_VERTEX_ATTRIB_BINDING* = 0x82D4
  GL_UNSIGNED_INT8_VEC2_NV* = 0x8FED
  GL_POLYGON_OFFSET_FACTOR* = 0x8038
  GL_BOLD_BIT_NV* = 0x01
  GL_CLAMP_TO_BORDER_ARB* = 0x812D
  GL_INDEX_MODE* = 0x0C30
  GL_SAMPLER_CUBE_SHADOW_NV* = 0x8DC5
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT* = 0x8C4F
  GL_MATRIX21_ARB* = 0x88D5
  GL_UNPACK_ROW_LENGTH_EXT* = 0x0CF2
  GL_FRAGMENT_NORMAL_EXT* = 0x834A
  GL_DOT3_ATI* = 0x8966
  GL_IMPLEMENTATION_COLOR_READ_TYPE_OES* = 0x8B9A
  GL_IMAGE_BINDING_ACCESS_EXT* = 0x8F3E
  GL_SYNC_CL_EVENT_ARB* = 0x8240
  GL_UNSIGNED_INT_24_8* = 0x84FA
  GL_2PASS_1_EXT* = 0x80A3
  GL_POST_TEXTURE_FILTER_BIAS_SGIX* = 0x8179
  GL_TEXTURE_COMPRESSED_IMAGE_SIZE* = 0x86A0
  GL_LUMINANCE_ALPHA32UI_EXT* = 0x8D75
  GL_FORCE_BLUE_TO_ONE_NV* = 0x8860
  GL_FRAMEBUFFER_DEFAULT* = 0x8218
  GL_VIRTUAL_PAGE_SIZE_Z_ARB* = 0x9197
  GL_TEXTURE_LIGHT_EXT* = 0x8350
  GL_MULTISAMPLE_BUFFER_BIT5_QCOM* = 0x20000000
  GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x910D
  GL_SYNC_CONDITION* = 0x9113
  GL_PERFMON_RESULT_SIZE_AMD* = 0x8BC5
  GL_PROGRAM_OBJECT_ARB* = 0x8B40
  GL_MAX_SHININESS_NV* = 0x8504
  GL_PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB* = 0x880A
  GL_RENDERBUFFER_COLOR_SAMPLES_NV* = 0x8E10
  GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS* = 0x8A31
  GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH* = 0x8E49
  GL_MODELVIEW29_ARB* = 0x873D
  GL_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB* = 0x900B
  GL_SIGNED_HILO16_NV* = 0x86FA
  GL_TRANSFORM_HINT_APPLE* = 0x85B1
  GL_STENCIL_INDEX4* = 0x8D47
  GL_EXTENSIONS* = 0x1F03
  GL_RG16F* = 0x822F
  GL_MAP_UNSYNCHRONIZED_BIT_EXT* = 0x0020
  GL_LUMINANCE16F_ARB* = 0x881E
  GL_UNSIGNED_INT_IMAGE_BUFFER* = 0x9067
  GL_COMPRESSED_RGBA_ASTC_8x8_KHR* = 0x93B7
  GL_AVERAGE_HP* = 0x8160
  GL_INDEX_MATERIAL_EXT* = 0x81B8
  GL_COLOR_TABLE* = 0x80D0
  GL_FOG_COORDINATE_ARRAY_LIST_IBM* = 103076
  GL_DEBUG_CATEGORY_OTHER_AMD* = 0x9150
  GL_R1UI_C4UB_V3F_SUN* = 0x85C5
  GL_SYSTEM_FONT_NAME_NV* = 0x9073
  GL_STATIC_VERTEX_ARRAY_IBM* = 103061
  GL_VERTEX_ATTRIB_ARRAY_DIVISOR_NV* = 0x88FE
  GL_SCALE_BY_ONE_HALF_NV* = 0x8540
  GL_INTENSITY_FLOAT32_ATI* = 0x8817
  GL_FRAGMENT_LIGHT6_SGIX* = 0x8412
  GL_DECR_WRAP_OES* = 0x8508
  GL_MODELVIEW23_ARB* = 0x8737
  GL_PROXY_TEXTURE_1D_ARRAY* = 0x8C19
  GL_REFERENCED_BY_VERTEX_SHADER* = 0x9306
  GL_MAX_NAME_LENGTH* = 0x92F6
  GL_AFFINE_2D_NV* = 0x9092
  GL_SYNC_OBJECT_APPLE* = 0x8A53
  GL_PLUS_DARKER_NV* = 0x9292
  GL_TESS_CONTROL_PROGRAM_NV* = 0x891E
  GL_RGB_SCALE* = 0x8573
  GL_RGBA16UI_EXT* = 0x8D76
  GL_COMPATIBLE_SUBROUTINES* = 0x8E4B
  GL_COLOR_TABLE_WIDTH* = 0x80D9
  GL_MAX_COMBINED_UNIFORM_BLOCKS* = 0x8A2E
  GL_BACK_SECONDARY_COLOR_NV* = 0x8C78
  GL_MAX_COMPUTE_VARIABLE_GROUP_INVOCATIONS_ARB* = 0x9344
  GL_SECONDARY_COLOR_NV* = 0x852D
  GL_RGB16UI_EXT* = 0x8D77
  GL_SHADER_STORAGE_BUFFER_SIZE* = 0x90D5
  GL_VERTEX_SUBROUTINE* = 0x92E8
  GL_MAP_COLOR* = 0x0D10
  GL_OBJECT_TYPE_ARB* = 0x8B4E
  GL_LAST_VIDEO_CAPTURE_STATUS_NV* = 0x9027
  GL_RGB12_EXT* = 0x8053
  GL_UNSIGNED_INT_IMAGE_3D_EXT* = 0x9064
  GL_LUMINANCE8_ALPHA8* = 0x8045
  GL_FLOAT_RGBA_MODE_NV* = 0x888E
  GL_CURRENT_RASTER_COLOR* = 0x0B04
  GL_CURRENT_RASTER_POSITION* = 0x0B07
  GL_UNIFORM_BLOCK_DATA_SIZE* = 0x8A40
  GL_MALI_PROGRAM_BINARY_ARM* = 0x8F61
  GL_QUERY_COUNTER_BITS_ARB* = 0x8864
  GL_VARIANT_ARRAY_EXT* = 0x87E8
  GL_VIDEO_CAPTURE_FIELD_UPPER_HEIGHT_NV* = 0x903A
  GL_DEPTH_COMPONENT24_ARB* = 0x81A6
  GL_UNSIGNED_INVERT_NV* = 0x8537
  GL_TEXTURE_IMMUTABLE_LEVELS* = 0x82DF
  GL_DRAW_BUFFER12_ATI* = 0x8831
  GL_MAP_FLUSH_EXPLICIT_BIT_EXT* = 0x0010
  GL_INDEX_WRITEMASK* = 0x0C21
  GL_POLYGON_SMOOTH* = 0x0B41
  GL_COMPRESSED_SIGNED_R11_EAC_OES* = 0x9271
  GL_TEXTURE_SWIZZLE_A_EXT* = 0x8E45
  GL_TEXTURE_COORD_ARRAY_STRIDE* = 0x808A
  GL_PIXEL_MAP_I_TO_R* = 0x0C72
  GL_CONVOLUTION_HEIGHT* = 0x8019
  GL_SIGNALED* = 0x9119
  GL_UNSIGNED_INT_24_8_OES* = 0x84FA
  GL_DRAW_BUFFER6_ARB* = 0x882B
  GL_BUFFER_SIZE_ARB* = 0x8764
  GL_CLEAR_BUFFER* = 0x82B4
  GL_LUMINANCE16UI_EXT* = 0x8D7A
  GL_FRAMEBUFFER_ATTACHMENT_ANGLE* = 0x93A3
  GL_STENCIL_ATTACHMENT* = 0x8D20
  GL_ALL_COMPLETED_NV* = 0x84F2
  GL_MIN* = 0x8007
  GL_COLOR_ATTACHMENT11* = 0x8CEB
  GL_PATH_STENCIL_FUNC_NV* = 0x90B7
  GL_MAX_LABEL_LENGTH* = 0x82E8
  GL_WEIGHT_ARRAY_TYPE_OES* = 0x86A9
  GL_ACCUM_BUFFER_BIT* = 0x00000200
  GL_WEIGHT_ARRAY_POINTER_ARB* = 0x86AC
  GL_WEIGHT_SUM_UNITY_ARB* = 0x86A6
  GL_COMPRESSED_SRGB_EXT* = 0x8C48
  GL_ATTRIB_ARRAY_TYPE_NV* = 0x8625
  GL_RED_INTEGER_EXT* = 0x8D94
  GL_ALWAYS_SOFT_HINT_PGI* = 0x1A20D
  GL_COMPRESSED_SRGB8_ETC2_OES* = 0x9275
  GL_LOW_FLOAT* = 0x8DF0
  GL_PIXEL_FRAGMENT_RGB_SOURCE_SGIS* = 0x8354
  GL_TEXTURE_LEQUAL_R_SGIX* = 0x819C
  GL_CONTEXT_COMPATIBILITY_PROFILE_BIT* = 0x00000002
  GL_INCR* = 0x1E02
  GL_3D* = 0x0601
  GL_SHADER_KHR* = 0x82E1
  GL_SRC_COLOR* = 0x0300
  GL_DRAW_BUFFER7_NV* = 0x882C
  GL_VERTEX_ARRAY_SIZE* = 0x807A
  GL_SAMPLER_2D_RECT* = 0x8B63
  GL_UNSIGNED_SHORT_4_4_4_4_REV_IMG* = 0x8365
  GL_READ_PIXEL_DATA_RANGE_NV* = 0x8879
  GL_EDGE_FLAG* = 0x0B43
  GL_TEXTURE_3D_EXT* = 0x806F
  GL_DOT_PRODUCT_TEXTURE_1D_NV* = 0x885C
  GL_COLOR_SUM_CLAMP_NV* = 0x854F
  GL_RGB10_A2* = 0x8059
  GL_BOOL_VEC3* = 0x8B58
  GL_REG_3_ATI* = 0x8924
  GL_LINEAR_SHARPEN_ALPHA_SGIS* = 0x80AE
  GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_EXT* = 0x8DA8
  GL_MAP1_VERTEX_ATTRIB5_4_NV* = 0x8665
  GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS* = 0x8F39
  GL_PIXEL_MAP_I_TO_B_SIZE* = 0x0CB4
  GL_TRANSFORM_FEEDBACK_BARRIER_BIT_EXT* = 0x00000800
  GL_COLOR_BUFFER_BIT6_QCOM* = 0x00000040
  GL_PROGRAM_TEMPORARIES_ARB* = 0x88A4
  GL_ELEMENT_ARRAY_BUFFER* = 0x8893
  GL_ALWAYS_FAST_HINT_PGI* = 0x1A20C
  GL_INTENSITY_FLOAT16_ATI* = 0x881D
  GL_ACTIVE_ATTRIBUTE_MAX_LENGTH* = 0x8B8A
  GL_CON_12_ATI* = 0x894D
  GL_LINEAR_MIPMAP_NEAREST* = 0x2701
  GL_TEXTURE_COVERAGE_SAMPLES_NV* = 0x9045
  GL_MAX_PROGRAM_NATIVE_PARAMETERS_ARB* = 0x88AB
  GL_DEPTH_SCALE* = 0x0D1E
  GL_SOURCE3_ALPHA_NV* = 0x858B
  GL_ACTIVE_VERTEX_UNITS_ARB* = 0x86A5
  GL_SWIZZLE_STR_DR_ATI* = 0x8978
  GL_RGB16I_EXT* = 0x8D89
  GL_INT_IMAGE_2D_RECT_EXT* = 0x905A
  GL_GREEN_BIAS* = 0x0D19
  GL_FRAMEBUFFER_RENDERABLE_LAYERED* = 0x828A
  GL_COMPRESSED_RGB8_ETC2* = 0x9274
  GL_COMPRESSED_RGBA_ARB* = 0x84EE
  GL_MAX_VERTEX_ATOMIC_COUNTERS* = 0x92D2
  GL_RGBA32I_EXT* = 0x8D82
  GL_WAIT_FAILED* = 0x911D
  GL_FOG_COORDINATE_SOURCE_EXT* = 0x8450
  GL_SAMPLE_MASK_VALUE_NV* = 0x8E52
  GL_OP_MUL_EXT* = 0x8786
  GL_FRAGMENT_TEXTURE* = 0x829F
  GL_GEOMETRY_PROGRAM_NV* = 0x8C26
  GL_MATRIX20_ARB* = 0x88D4
  GL_SECONDARY_COLOR_ARRAY_STRIDE_EXT* = 0x845C
  GL_UNSIGNED_INT_2_10_10_10_REV_EXT* = 0x8368
  GL_PHONG_HINT_WIN* = 0x80EB
  GL_EYE_DISTANCE_TO_LINE_SGIS* = 0x81F2
  GL_SAMPLES_PASSED* = 0x8914
  GL_MAX_COLOR_ATTACHMENTS_NV* = 0x8CDF
  GL_WEIGHT_ARRAY_POINTER_OES* = 0x86AC
  GL_MAX_DEBUG_GROUP_STACK_DEPTH* = 0x826C
  GL_TEXTURE_2D_STACK_BINDING_MESAX* = 0x875E
  GL_VARIANT_VALUE_EXT* = 0x87E4
  GL_TEXTURE_GEN_R* = 0x0C62
  GL_COMPRESSED_RG11_EAC* = 0x9272
  GL_IMAGE_ROTATE_ORIGIN_Y_HP* = 0x815B
  GL_BLEND_ADVANCED_COHERENT_NV* = 0x9285
  GL_DEBUG_CALLBACK_FUNCTION* = 0x8244
  GL_PROXY_TEXTURE_4D_SGIS* = 0x8135
  GL_OCCLUSION_TEST_RESULT_HP* = 0x8166
  GL_COLOR_ATTACHMENT13_EXT* = 0x8CED
  GL_LINE_STRIP_ADJACENCY* = 0x000B
  GL_DEBUG_CATEGORY_APPLICATION_AMD* = 0x914F
  GL_CIRCULAR_TANGENT_ARC_TO_NV* = 0xFC
  GL_MAX_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB* = 0x88B3
  GL_VERTEX_ATTRIB_ARRAY_STRIDE* = 0x8624
  GL_COMPRESSED_SRGB_ALPHA_EXT* = 0x8C49
  GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY* = 0x900F
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x906C
  GL_LIGHT_MODEL_COLOR_CONTROL* = 0x81F8
  GL_INT_VEC2_ARB* = 0x8B53
  GL_PARALLEL_ARRAYS_INTEL* = 0x83F4
  GL_COLOR_ATTACHMENT11_EXT* = 0x8CEB
  GL_SAMPLE_ALPHA_TO_ONE_SGIS* = 0x809F
  GL_FUNC_ADD_OES* = 0x8006
  GL_COMBINER_MAPPING_NV* = 0x8543
  GL_INT_IMAGE_BUFFER* = 0x905C
  GL_TEXTURE_SWIZZLE_A* = 0x8E45
  GL_FRAMEBUFFER_ATTACHMENT_LAYERED_ARB* = 0x8DA7
  GL_EXPAND_NEGATE_NV* = 0x8539
  GL_COVERAGE_EDGE_FRAGMENTS_NV* = 0x8ED6
  GL_PATH_OBJECT_BOUNDING_BOX_NV* = 0x908A
  GL_MAX_RECTANGLE_TEXTURE_SIZE* = 0x84F8
  GL_FONT_ASCENDER_BIT_NV* = 0x00200000
  GL_INDEX_SHIFT* = 0x0D12
  GL_LUMINANCE6_ALPHA2* = 0x8044
  GL_FLOAT_CLEAR_COLOR_VALUE_NV* = 0x888D
  GL_V2F* = 0x2A20
  GL_DRAW_BUFFER12_NV* = 0x8831
  GL_RIGHT* = 0x0407
  GL_CON_28_ATI* = 0x895D
  GL_SAMPLER_CUBE_ARB* = 0x8B60
  GL_OUTPUT_TEXTURE_COORD27_EXT* = 0x87B8
  GL_MAX_DEPTH_TEXTURE_SAMPLES* = 0x910F
  GL_MODULATE* = 0x2100
  GL_NUM_FILL_STREAMS_NV* = 0x8E29
  GL_DT_SCALE_NV* = 0x8711
  GL_ONE_MINUS_SRC_COLOR* = 0x0301
  GL_OPERAND2_ALPHA* = 0x859A
  GL_MATRIX15_ARB* = 0x88CF
  GL_MULTISAMPLE* = 0x809D
  GL_DEPTH32F_STENCIL8* = 0x8CAD
  GL_COMPRESSED_RGBA_ASTC_4x4_KHR* = 0x93B0
  GL_DUAL_ALPHA16_SGIS* = 0x8113
  GL_COMPRESSED_RGB_FXT1_3DFX* = 0x86B0
  GL_PROXY_TEXTURE_2D_ARRAY* = 0x8C1B
  GL_UNIFORM_NAME_LENGTH* = 0x8A39
  GL_COMPILE_AND_EXECUTE* = 0x1301
  GL_COMPRESSED_RGBA_PVRTC_4BPPV2_IMG* = 0x9138
  GL_PIXEL_CUBIC_WEIGHT_EXT* = 0x8333
  GL_GREEN_MIN_CLAMP_INGR* = 0x8561
  GL_MAX_TEXTURE_LOD_BIAS* = 0x84FD
  GL_NORMAL_MAP_NV* = 0x8511
  GL_PIXEL_UNPACK_BUFFER_BINDING_ARB* = 0x88EF
  GL_LUMINANCE_ALPHA32F_ARB* = 0x8819
  GL_LUMINANCE_FLOAT16_APPLE* = 0x881E
  GL_FACTOR_MIN_AMD* = 0x901C
  GL_BUFFER_GPU_ADDRESS_NV* = 0x8F1D
  GL_DEBUG_TYPE_PERFORMANCE_ARB* = 0x8250
  GL_TEXTURE_RESIDENT* = 0x8067
  GL_TESS_CONTROL_SHADER_BIT* = 0x00000008
  GL_VERTEX_SHADER* = 0x8B31
  GL_COLOR_ATTACHMENT15_EXT* = 0x8CEF
  GL_DRAW_BUFFER2_NV* = 0x8827
  GL_UNSIGNED_INT* = 0x1405
  GL_TEXTURE_SHARED_SIZE_EXT* = 0x8C3F
  GL_LIGHT5* = 0x4005
  GL_VERTEX_ARRAY_SIZE_EXT* = 0x807A
  GL_YCRCB_SGIX* = 0x8318
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x92C9
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_OES* = 0x8CD1
  GL_QUADRATIC_CURVE_TO_NV* = 0x0A
  GL_POINTS* = 0x0000
  GL_OPERAND1_RGB* = 0x8591
  GL_POINT_DISTANCE_ATTENUATION_ARB* = 0x8129
  GL_QUERY_BUFFER_BARRIER_BIT* = 0x00008000
  GL_QUAD_LUMINANCE4_SGIS* = 0x8120
  GL_GENERATE_MIPMAP_SGIS* = 0x8191
  GL_FRAMEBUFFER_UNSUPPORTED_EXT* = 0x8CDD
  GL_PALETTE4_RGB5_A1_OES* = 0x8B94
  GL_TEXTURE_CROP_RECT_OES* = 0x8B9D
  GL_COMPUTE_SHADER_BIT* = 0x00000020
  GL_OUTPUT_TEXTURE_COORD2_EXT* = 0x879F
  GL_PALETTE4_RGBA4_OES* = 0x8B93
  GL_TEXTURE_CLIPMAP_CENTER_SGIX* = 0x8171
  GL_BLUE_BITS* = 0x0D54
  GL_RELATIVE_LARGE_CCW_ARC_TO_NV* = 0x17
  GL_UNSIGNED_SHORT_5_6_5_EXT* = 0x8363
  GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS* = 0x8DE1
  GL_UNCORRELATED_NV* = 0x9282
  GL_TESS_EVALUATION_SUBROUTINE* = 0x92EA
  GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_ARB* = 0x8E5E
  GL_CON_11_ATI* = 0x894C
  GL_ACTIVE_TEXTURE* = 0x84E0
  GL_ASYNC_TEX_IMAGE_SGIX* = 0x835C
  GL_COLOR_CLEAR_VALUE* = 0x0C22
  GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x910C
  GL_TESS_CONTROL_TEXTURE* = 0x829C
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_OES* = 0x851A
  GL_HISTOGRAM_BLUE_SIZE_EXT* = 0x802A
  GL_PATCH_DEFAULT_OUTER_LEVEL* = 0x8E74
  GL_PROGRAM_MATRIX_STACK_DEPTH_EXT* = 0x8E2F
  GL_RENDERBUFFER_BINDING_ANGLE* = 0x8CA7
  GL_CONSTANT_ATTENUATION* = 0x1207
  GL_SHADER_CONSISTENT_NV* = 0x86DD
  GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS* = 0x92D4
  GL_EXTERNAL_VIRTUAL_MEMORY_BUFFER_AMD* = 0x9160
  GL_DETAIL_TEXTURE_FUNC_POINTS_SGIS* = 0x809C
  GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x9061
  GL_COUNT_DOWN_NV* = 0x9089
  GL_MATRIX12_ARB* = 0x88CC
  GL_MAX_VERTEX_SHADER_INVARIANTS_EXT* = 0x87C7
  GL_REPLICATE_BORDER_HP* = 0x8153
  GL_MODELVIEW9_ARB* = 0x8729
  GL_ANY_SAMPLES_PASSED_CONSERVATIVE_EXT* = 0x8D6A
  GL_PROGRAM_PARAMETERS_ARB* = 0x88A8
  GL_LIST_BIT* = 0x00020000
  GL_MAX_GEOMETRY_ATOMIC_COUNTERS* = 0x92D5
  GL_CONSTANT_COLOR1_NV* = 0x852B
  GL_AVERAGE_EXT* = 0x8335
  GL_SINGLE_COLOR_EXT* = 0x81F9
  GL_VERTEX_ARRAY* = 0x8074
  GL_COLOR_INDEX1_EXT* = 0x80E2
  GL_COMPUTE_PROGRAM_NV* = 0x90FB
  GL_LINES_ADJACENCY* = 0x000A
  GL_OP_ROUND_EXT* = 0x8790
  GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE* = 0x934C
  GL_MAX_DEEP_3D_TEXTURE_DEPTH_NV* = 0x90D1
  GL_REG_11_ATI* = 0x892C
  GL_SAMPLES_EXT* = 0x80A9
  GL_FUNC_REVERSE_SUBTRACT* = 0x800B
  GL_POINT_SPRITE_COORD_ORIGIN* = 0x8CA0
  GL_REG_27_ATI* = 0x893C
  GL_TEXTURE_VIEW_MIN_LEVEL* = 0x82DB
  GL_NICEST* = 0x1102
  GL_CLIP_PLANE4_IMG* = 0x3004
  GL_ARRAY_BUFFER_BINDING* = 0x8894
  GL_422_AVERAGE_EXT* = 0x80CE
  GL_RENDERER* = 0x1F01
  GL_OVERLAY_NV* = 0x9296
  GL_TEXTURE_SAMPLES_IMG* = 0x9136
  GL_DEBUG_SOURCE_SHADER_COMPILER_KHR* = 0x8248
  GL_EYE_DISTANCE_TO_POINT_SGIS* = 0x81F0
  GL_MAX_PROGRAM_GENERIC_ATTRIBS_NV* = 0x8DA5
  GL_FILTER4_SGIS* = 0x8146
  GL_LIGHT_MODEL_LOCAL_VIEWER* = 0x0B51
  GL_TRIANGLE_MESH_SUN* = 0x8615
  GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB* = 0x900D
  GL_DEPTH_COMPONENTS* = 0x8284
  GL_NUM_GENERAL_COMBINERS_NV* = 0x854E
  GL_CLIENT_ACTIVE_TEXTURE_ARB* = 0x84E1
  GL_FRAGMENT_DEPTH* = 0x8452
  GL_SEPARATE_ATTRIBS* = 0x8C8D
  GL_HALF_FLOAT_OES* = 0x8D61
  GL_PROXY_TEXTURE_2D* = 0x8064
  GL_VARIANT_ARRAY_TYPE_EXT* = 0x87E7
  GL_DRAW_BUFFER11_ATI* = 0x8830
  GL_MATRIX_INDEX_ARRAY_POINTER_OES* = 0x8849
  GL_CURRENT_INDEX* = 0x0B01
  GL_UNSIGNED_INT_24_8_MESA* = 0x8751
  GL_PROGRAM_SEPARABLE* = 0x8258
  GL_TEXTURE8_ARB* = 0x84C8
  GL_OPERAND0_ALPHA_EXT* = 0x8598
  GL_PER_STAGE_CONSTANTS_NV* = 0x8535
  GL_LINE_LOOP* = 0x0002
  GL_DRAW_PIXEL_TOKEN* = 0x0705
  GL_DRAW_BUFFER3* = 0x8828
  GL_GEOMETRY_DEFORMATION_SGIX* = 0x8194
  GL_MAX_CUBE_MAP_TEXTURE_SIZE_EXT* = 0x851C
  GL_GLYPH_VERTICAL_BEARING_X_BIT_NV* = 0x20
  GL_TEXTURE30* = 0x84DE
  GL_4PASS_1_EXT* = 0x80A5
  GL_RGB16F_EXT* = 0x881B
  GL_2PASS_0_SGIS* = 0x80A2
  GL_CON_27_ATI* = 0x895C
  GL_SAMPLE_ALPHA_TO_ONE* = 0x809F
  GL_POLYGON_SMOOTH_HINT* = 0x0C53
  GL_COLOR_ATTACHMENT_EXT* = 0x90F0
  GL_PATCH_DEFAULT_INNER_LEVEL* = 0x8E73
  GL_TEXTURE_MAX_CLAMP_T_SGIX* = 0x836A
  GL_WEIGHT_ARRAY_BUFFER_BINDING_OES* = 0x889E
  GL_TEXTURE1* = 0x84C1
  GL_LINES* = 0x0001
  GL_PIXEL_TILE_GRID_DEPTH_SGIX* = 0x8144
  GL_TEXTURE2* = 0x84C2
  GL_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x9054
  GL_DRAW_BUFFER4* = 0x8829
  GL_DRAW_BUFFER_EXT* = 0x0C01
  GL_STENCIL_INDEX1* = 0x8D46
  GL_DEPTH_COMPONENT32F_NV* = 0x8DAB
  GL_VERTEX_ATTRIB_ARRAY_POINTER* = 0x8645
  GL_DOUBLE_MAT4x2* = 0x8F4D
  GL_MOVE_TO_NV* = 0x02
  GL_OP_RECIP_SQRT_EXT* = 0x8795
  GL_SAMPLER_1D_ARRAY* = 0x8DC0
  GL_MIN_FRAGMENT_INTERPOLATION_OFFSET* = 0x8E5B
  GL_TEXTURE_DEPTH_EXT* = 0x8071
  GL_STENCIL_INDEX8* = 0x8D48
  GL_MAX_PROGRAM_TEX_INSTRUCTIONS_ARB* = 0x880C
  GL_INTERNALFORMAT_DEPTH_SIZE* = 0x8275
  GL_STATE_RESTORE* = 0x8BDC
  GL_SMALL_CW_ARC_TO_NV* = 0x14
  GL_LUMINANCE16* = 0x8042
  GL_VERTEX_ATTRIB_ARRAY1_NV* = 0x8651
  GL_TEXTURE_MAX_CLAMP_R_SGIX* = 0x836B
  GL_LUMINANCE_FLOAT16_ATI* = 0x881E
  GL_MAX_TEXTURE_UNITS* = 0x84E2
  GL_DRAW_BUFFER4_ARB* = 0x8829
  GL_DRAW_BUFFER12* = 0x8831
  GL_R8UI* = 0x8232
  GL_STENCIL_REF* = 0x0B97
  GL_VARIANT_EXT* = 0x87C1
  GL_VERTEX_ATTRIB_MAP2_DOMAIN_APPLE* = 0x8A09
  GL_QUERY_OBJECT_AMD* = 0x9153
  GL_PLUS_NV* = 0x9291
  GL_UNPACK_SWAP_BYTES* = 0x0CF0
  GL_MAX_UNIFORM_LOCATIONS* = 0x826E
  GL_GUILTY_CONTEXT_RESET_EXT* = 0x8253
  GL_DOT3_RGBA_IMG* = 0x86AF
  GL_X_EXT* = 0x87D5
  GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x900F
  GL_TEXTURE_COMPARE_FAIL_VALUE_ARB* = 0x80BF
  GL_ETC1_RGB8_OES* = 0x8D64
  GL_LUMINANCE_ALPHA_INTEGER_EXT* = 0x8D9D
  GL_MINMAX_SINK* = 0x8030
  GL_RG32F* = 0x8230
  GL_PROXY_TEXTURE_2D_MULTISAMPLE* = 0x9101
  GL_RGBA_UNSIGNED_DOT_PRODUCT_MAPPING_NV* = 0x86D9
  GL_R16* = 0x822A
  GL_BOUNDING_BOX_NV* = 0x908D
  GL_INVALID_ENUM* = 0x0500
  GL_MOVE_TO_RESETS_NV* = 0x90B5
  GL_SYNC_GPU_COMMANDS_COMPLETE_APPLE* = 0x9117
  GL_MAX_RECTANGLE_TEXTURE_SIZE_ARB* = 0x84F8
  GL_UNSIGNED_INT_10F_11F_11F_REV_EXT* = 0x8C3B
  GL_VERTEX_PRECLIP_HINT_SGIX* = 0x83EF
  GL_CLIENT_VERTEX_ARRAY_BIT* = 0x00000002
  GL_MAT_COLOR_INDEXES_BIT_PGI* = 0x01000000
  GL_PERFORMANCE_MONITOR_AMD* = 0x9152
  GL_QUAD_STRIP* = 0x0008
  GL_MAX_TEXTURE_COORDS_NV* = 0x8871
  GL_TESS_EVALUATION_SUBROUTINE_UNIFORM* = 0x92F0
  GL_DRAW_BUFFER1_EXT* = 0x8826
  GL_TEXTURE18* = 0x84D2
  GL_COLOR_ATTACHMENT5_NV* = 0x8CE5
  GL_MAX_COMPUTE_WORK_GROUP_SIZE* = 0x91BF
  GL_T2F_C4UB_V3F* = 0x2A29
  GL_MAP1_GRID_DOMAIN* = 0x0DD0
  GL_DEBUG_TYPE_PUSH_GROUP_KHR* = 0x8269
  GL_STATIC_READ* = 0x88E5
  GL_MAX_PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB* = 0x880E
  GL_DOUBLE_EXT* = 0x140A
  GL_MAX_FRAGMENT_UNIFORM_VECTORS* = 0x8DFD
  GL_R32F_EXT* = 0x822E
  GL_MAX_RENDERBUFFER_SIZE_EXT* = 0x84E8
  GL_COMPRESSED_TEXTURE_FORMATS* = 0x86A3
  GL_MAX_EXT* = 0x8008
  GL_VERTEX_ATTRIB_ARRAY_ENABLED_ARB* = 0x8622
  GL_INTERPOLATE* = 0x8575
  GL_QUERY_RESULT_NO_WAIT_AMD* = 0x9194
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X_OES* = 0x8516
  GL_LUMINANCE16_ALPHA16_SNORM* = 0x901A
  GL_SRC_ALPHA_SATURATE* = 0x0308
  GL_DRAW_INDIRECT_BUFFER_BINDING* = 0x8F43
  GL_T2F_IUI_N3F_V3F_EXT* = 0x81B4
  GL_MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB* = 0x8B49
  GL_MAX_ASYNC_READ_PIXELS_SGIX* = 0x8361
  GL_VERTEX_ARRAY_RANGE_APPLE* = 0x851D
  GL_SAMPLER_2D_SHADOW_ARB* = 0x8B62
  GL_ETC1_SRGB8_NV* = 0x88EE
  GL_COLORBURN_NV* = 0x929A
  GL_SAMPLER_2D_ARRAY_SHADOW_EXT* = 0x8DC4
  GL_ALL_BARRIER_BITS* = 0xFFFFFFFF
  GL_TRIANGLE_STRIP_ADJACENCY_EXT* = 0x000D
  GL_MAX_TEXTURE_BUFFER_SIZE* = 0x8C2B
  GL_ALIASED_POINT_SIZE_RANGE* = 0x846D
  GL_STENCIL_BACK_VALUE_MASK* = 0x8CA4
  GL_CMYK_EXT* = 0x800C
  GL_OPERAND1_ALPHA_EXT* = 0x8599
  GL_TEXTURE_SHADOW* = 0x82A1
  GL_LINEAR_CLIPMAP_LINEAR_SGIX* = 0x8170
  GL_MIPMAP* = 0x8293
  GL_LINE_SMOOTH_HINT* = 0x0C52
  GL_DEPTH_STENCIL_TEXTURE_MODE* = 0x90EA
  GL_BUFFER_ACCESS_OES* = 0x88BB
  GL_PROXY_TEXTURE_1D_ARRAY_EXT* = 0x8C19
  GL_OBJECT_LINEAR* = 0x2401
  GL_MAP1_TEXTURE_COORD_3* = 0x0D95
  GL_TEXTURE_RENDERBUFFER_NV* = 0x8E55
  GL_FRAMEBUFFER_RENDERABLE* = 0x8289
  GL_DOT3_RGB_EXT* = 0x8740
  GL_QUAD_LUMINANCE8_SGIS* = 0x8121
  GL_UNIFORM_BLOCK_INDEX* = 0x8A3A
  GL_DS_SCALE_NV* = 0x8710
  GL_TYPE* = 0x92FA
  GL_MATRIX_EXT* = 0x87C0
  GL_VERTEX_STREAM4_ATI* = 0x8770
  GL_TOP_LEVEL_ARRAY_STRIDE* = 0x930D
  GL_INT_SAMPLER_2D_EXT* = 0x8DCA
  GL_PATH_FORMAT_PS_NV* = 0x9071
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR* = 0x93D2
  GL_MAX_TEXTURE_COORDS* = 0x8871
  GL_MAX_FRAGMENT_INTERPOLATION_OFFSET* = 0x8E5C
  GL_REG_17_ATI* = 0x8932
  GL_WAIT_FAILED_APPLE* = 0x911D
  GL_TEXTURE_BINDING_3D* = 0x806A
  GL_TEXTURE_VIEW* = 0x82B5
  GL_DOT3_RGBA_ARB* = 0x86AF
  GL_MAX_VARYING_FLOATS_ARB* = 0x8B4B
  GL_UNIFORM_IS_ROW_MAJOR* = 0x8A3E
  GL_FRAGMENT_SHADER_BIT* = 0x00000002
  GL_MATRIX_INDEX_ARRAY_ARB* = 0x8844
  GL_PIXEL_PACK_BUFFER_BINDING_EXT* = 0x88ED
  GL_MATRIX_PALETTE_OES* = 0x8840
  GL_INTENSITY_SNORM* = 0x9013
  GL_COLOR_BUFFER_BIT0_QCOM* = 0x00000001
  GL_BITMAP* = 0x1A00
  GL_CURRENT_MATRIX_NV* = 0x8641
  GL_QUERY_BUFFER_AMD* = 0x9192
  GL_EDGE_FLAG_ARRAY_BUFFER_BINDING* = 0x889B
  GL_4PASS_3_EXT* = 0x80A7
  GL_TEXTURE_4DSIZE_SGIS* = 0x8136
  GL_PATH_COORD_COUNT_NV* = 0x909E
  GL_SLUMINANCE* = 0x8C46
  GL_POINT_SMOOTH_HINT* = 0x0C51
  GL_ADJACENT_PAIRS_NV* = 0x90AE
  GL_BUFFER_BINDING* = 0x9302
  GL_ARRAY_OBJECT_BUFFER_ATI* = 0x8766
  GL_PATH_INITIAL_DASH_CAP_NV* = 0x907C
  GL_RGBA4* = 0x8056
  GL_PACK_LSB_FIRST* = 0x0D01
  GL_IMAGE_BINDING_NAME_EXT* = 0x8F3A
  GL_UNSIGNED_INT_SAMPLER_2D_EXT* = 0x8DD2
  GL_RGBA12_EXT* = 0x805A
  GL_COMBINER0_NV* = 0x8550
  GL_COLOR_BUFFER_BIT4_QCOM* = 0x00000010
  GL_TIME_ELAPSED* = 0x88BF
  GL_TRANSFORM_FEEDBACK_BUFFER_START* = 0x8C84
  GL_COMPRESSED_RGBA_ASTC_5x5_KHR* = 0x93B2
  GL_MAX_SPARSE_3D_TEXTURE_SIZE_AMD* = 0x9199
  GL_RENDERBUFFER_HEIGHT_EXT* = 0x8D43
  GL_QUARTER_BIT_ATI* = 0x00000010
  GL_TEXTURE_COMPRESSION_HINT_ARB* = 0x84EF
  GL_DRAW_BUFFER13* = 0x8832
  GL_CURRENT_MATRIX_STACK_DEPTH_ARB* = 0x8640
  GL_DEPENDENT_HILO_TEXTURE_2D_NV* = 0x8858
  GL_DST_NV* = 0x9287
  GL_DEBUG_OBJECT_MESA* = 0x8759
  GL_NUM_INSTRUCTIONS_TOTAL_ATI* = 0x8972
  GL_FLAT* = 0x1D00
  GL_EVAL_VERTEX_ATTRIB8_NV* = 0x86CE
  GL_VERTEX_PROGRAM_CALLBACK_FUNC_MESA* = 0x8BB6
  GL_TEXTURE_COORD_ARRAY_EXT* = 0x8078
  GL_LOCATION_INDEX* = 0x930F
  GL_SLIM10U_SGIX* = 0x831E
  GL_PHONG_WIN* = 0x80EA
  GL_EVAL_VERTEX_ATTRIB1_NV* = 0x86C7
  GL_SMOOTH_LINE_WIDTH_RANGE* = 0x0B22
  GL_SAMPLER_RENDERBUFFER_NV* = 0x8E56
  GL_UNPACK_LSB_FIRST* = 0x0CF1
  GL_SELECTION_BUFFER_POINTER* = 0x0DF3
  GL_PIXEL_SUBSAMPLE_4444_SGIX* = 0x85A2
  GL_COMPRESSED_R11_EAC* = 0x9270
  GL_MAX_CLIP_PLANES* = 0x0D32
  GL_POST_CONVOLUTION_GREEN_BIAS* = 0x8021
  GL_COLOR_EXT* = 0x1800
  GL_VENDOR* = 0x1F00
  GL_MAP1_VERTEX_ATTRIB8_4_NV* = 0x8668
  GL_TEXTURE_ALPHA_TYPE* = 0x8C13
  GL_CURRENT_VERTEX_ATTRIB_ARB* = 0x8626
  GL_COLOR_BUFFER_BIT2_QCOM* = 0x00000004
  GL_VERTEX_ATTRIB_ARRAY15_NV* = 0x865F
  GL_OFFSET_PROJECTIVE_TEXTURE_2D_NV* = 0x8850
  GL_DRAW_BUFFER5_ARB* = 0x882A
  GL_SAMPLES_PASSED_ARB* = 0x8914
  GL_PRIMITIVE_RESTART_NV* = 0x8558
  GL_FRAGMENT_LIGHT3_SGIX* = 0x840F
  GL_COLOR_INDEX16_EXT* = 0x80E7
  GL_RGBA8_OES* = 0x8058
  GL_PACK_CMYK_HINT_EXT* = 0x800E
  GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE* = 0x8214
  GL_MODELVIEW0_EXT* = 0x1700
  GL_RETAINED_APPLE* = 0x8A1B
  GL_DRAW_PIXELS_APPLE* = 0x8A0A
  GL_POINT_BIT* = 0x00000002
  GL_PIXEL_MAP_B_TO_B_SIZE* = 0x0CB8
  GL_RELATIVE_SMALL_CCW_ARC_TO_NV* = 0x13
  GL_VERTEX_ATTRIB_ARRAY_STRIDE_ARB* = 0x8624
  GL_DOT_PRODUCT_AFFINE_DEPTH_REPLACE_NV* = 0x885D
  GL_CON_2_ATI* = 0x8943
  GL_SAMPLER_2D_ARRAY* = 0x8DC1
  GL_LINE_STIPPLE_PATTERN* = 0x0B25
  GL_IMPLEMENTATION_COLOR_READ_FORMAT* = 0x8B9B
  GL_TRANSPOSE_AFFINE_2D_NV* = 0x9096
  GL_COLOR_ATTACHMENT7* = 0x8CE7
  GL_COLOR_ATTACHMENT14* = 0x8CEE
  GL_SHADER* = 0x82E1
  GL_SKIP_MISSING_GLYPH_NV* = 0x90A9
  GL_VERTEX_ARRAY_TYPE* = 0x807B
  GL_OP_POWER_EXT* = 0x8793
  GL_MAX_BINDABLE_UNIFORM_SIZE_EXT* = 0x8DED
  GL_SRGB8* = 0x8C41
  GL_INTERNALFORMAT_ALPHA_SIZE* = 0x8274
  GL_IMAGE_2D_MULTISAMPLE* = 0x9055
  GL_VIDEO_CAPTURE_FRAME_HEIGHT_NV* = 0x9039
  GL_NEVER* = 0x0200
  GL_MAP2_TEXTURE_COORD_2* = 0x0DB4
  GL_PROGRAM_RESULT_COMPONENTS_NV* = 0x8907
  GL_SHADER_STORAGE_BARRIER_BIT* = 0x00002000
  GL_SLIM8U_SGIX* = 0x831D
  GL_DRAW_BUFFER7_ATI* = 0x882C
  GL_CLAMP_TO_EDGE* = 0x812F
  GL_LUMINANCE32I_EXT* = 0x8D86
  GL_NORMAL_ARRAY_POINTER* = 0x808F
  GL_ALPHA_TEST_REF_QCOM* = 0x0BC2
  GL_MATRIX7_NV* = 0x8637
  GL_REFERENCED_BY_FRAGMENT_SHADER* = 0x930A
  GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG* = 0x8C02
  GL_DEBUG_TYPE_MARKER* = 0x8268
  GL_DEBUG_OUTPUT_SYNCHRONOUS_KHR* = 0x8242
  GL_CON_26_ATI* = 0x895B
  GL_COMBINER7_NV* = 0x8557
  GL_MAP2_TANGENT_EXT* = 0x8445
  GL_COMPRESSED_RGBA_ASTC_10x6_KHR* = 0x93B9
  GL_RG8* = 0x822B
  GL_INT_SAMPLER_1D_ARRAY_EXT* = 0x8DCE
  GL_POINT_SPRITE_R_MODE_NV* = 0x8863
  GL_ATOMIC_COUNTER_BUFFER_BINDING* = 0x92C1
  GL_INTENSITY16F_ARB* = 0x881D
  GL_DEFORMATIONS_MASK_SGIX* = 0x8196
  GL_PATH_TERMINAL_END_CAP_NV* = 0x9078
  GL_VERTEX_BINDING_DIVISOR* = 0x82D6
  GL_WIDE_LINE_HINT_PGI* = 0x1A222
  GL_LIGHTING* = 0x0B50
  GL_CURRENT_BIT* = 0x00000001
  GL_LOSE_CONTEXT_ON_RESET_ARB* = 0x8252
  GL_COLOR_ATTACHMENT15* = 0x8CEF
  GL_REGISTER_COMBINERS_NV* = 0x8522
  GL_UNSIGNED_INT64_VEC2_NV* = 0x8FF5
  GL_TEXTURE_CLIPMAP_DEPTH_SGIX* = 0x8176
  GL_HISTOGRAM_WIDTH* = 0x8026
  GL_RENDERBUFFER_ALPHA_SIZE* = 0x8D53
  GL_POST_CONVOLUTION_BLUE_BIAS_EXT* = 0x8022
  GL_SCALED_RESOLVE_FASTEST_EXT* = 0x90BA
  GL_DRAW_BUFFER15* = 0x8834
  GL_LUMINANCE4_ALPHA4* = 0x8043
  GL_SWIZZLE_STRQ_DQ_ATI* = 0x897B
  GL_OP_MADD_EXT* = 0x8788
  GL_MAX_ATTRIB_STACK_DEPTH* = 0x0D35
  GL_DEBUG_GROUP_STACK_DEPTH_KHR* = 0x826D
  GL_ACTIVE_VARYINGS_NV* = 0x8C81
  GL_DEBUG_SEVERITY_HIGH* = 0x9146
  GL_SRGB8_EXT* = 0x8C41
  GL_STENCIL_WRITEMASK* = 0x0B98
  GL_REG_14_ATI* = 0x892F
  GL_PROGRAM_BINARY_ANGLE* = 0x93A6
  GL_RENDERBUFFER_DEPTH_SIZE_EXT* = 0x8D54
  GL_ALPHA_BIAS* = 0x0D1D
  GL_STATIC_ATI* = 0x8760
  GL_MATRIX_INDEX_ARRAY_BUFFER_BINDING_OES* = 0x8B9E
  GL_SOFTLIGHT_NV* = 0x929C
  GL_INDEX_ARRAY_COUNT_EXT* = 0x8087
  GL_RENDERBUFFER_BLUE_SIZE_EXT* = 0x8D52
  GL_SHARED_TEXTURE_PALETTE_EXT* = 0x81FB
  GL_VERTEX_SHADER_OPTIMIZED_EXT* = 0x87D4
  GL_MAX_SAMPLE_MASK_WORDS_NV* = 0x8E59
  GL_MAX_MATRIX_PALETTE_STACK_DEPTH_ARB* = 0x8841
  GL_MATRIX30_ARB* = 0x88DE
  GL_NORMAL_ARRAY_POINTER_EXT* = 0x808F
  GL_PIXEL_MAP_A_TO_A* = 0x0C79
  GL_MATRIX18_ARB* = 0x88D2
  GL_UNPACK_SKIP_ROWS_EXT* = 0x0CF3
  GL_INVARIANT_DATATYPE_EXT* = 0x87EB
  GL_INT_IMAGE_1D_EXT* = 0x9057
  GL_OUTPUT_TEXTURE_COORD24_EXT* = 0x87B5
  GL_MAP_WRITE_BIT_EXT* = 0x0002
  GL_MODELVIEW28_ARB* = 0x873C
  GL_MAX_VARYING_COMPONENTS_EXT* = 0x8B4B
  GL_OUTPUT_TEXTURE_COORD4_EXT* = 0x87A1
  GL_UNSIGNED_INT_VEC2_EXT* = 0x8DC6
  GL_READ_ONLY* = 0x88B8
  GL_SECONDARY_COLOR_ARRAY_LIST_STRIDE_IBM* = 103087
  GL_UNSIGNED_INT64_NV* = 0x140F
  GL_REPLACEMENT_CODE_ARRAY_STRIDE_SUN* = 0x85C2
  GL_DEPTH_BUFFER_BIT0_QCOM* = 0x00000100
  GL_VERTEX_ATTRIB_MAP2_SIZE_APPLE* = 0x8A06
  GL_POST_CONVOLUTION_ALPHA_SCALE* = 0x801F
  GL_TEXTURE_COLOR_SAMPLES_NV* = 0x9046
  GL_DEBUG_SEVERITY_HIGH_ARB* = 0x9146
  GL_MAP_WRITE_BIT* = 0x0002
  GL_SRC1_RGB* = 0x8581
  GL_LIGHT0* = 0x4000
  GL_READ_PIXELS_FORMAT* = 0x828D
  GL_COMBINE_RGB_EXT* = 0x8571
  GL_MATRIX2_NV* = 0x8632
  GL_INT16_VEC4_NV* = 0x8FE7
  GL_INT_SAMPLER_CUBE* = 0x8DCC
  GL_LUMINANCE_ALPHA8I_EXT* = 0x8D93
  GL_TRIANGLE_STRIP_ADJACENCY* = 0x000D
  GL_MAX_TEXTURE_BUFFER_SIZE_EXT* = 0x8C2B
  GL_COLOR_TABLE_BIAS* = 0x80D7
  GL_MAX_GEOMETRY_INPUT_COMPONENTS* = 0x9123
  GL_TEXTURE_RANGE_POINTER_APPLE* = 0x85B8
  GL_PIXEL_SUBSAMPLE_2424_SGIX* = 0x85A3
  GL_RESAMPLE_REPLICATE_OML* = 0x8986
  GL_ALL_STATIC_DATA_IBM* = 103060
  GL_DEBUG_CATEGORY_PERFORMANCE_AMD* = 0x914D
  GL_ALPHA_TEST_QCOM* = 0x0BC0
  GL_PREVIOUS_TEXTURE_INPUT_NV* = 0x86E4
  GL_SIGNED_RGBA_NV* = 0x86FB
  GL_GLOBAL_ALPHA_SUN* = 0x81D9
  GL_RGB_FLOAT16_APPLE* = 0x881B
  GL_PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB* = 0x8808
  GL_UTF8_NV* = 0x909A
  GL_ALLOW_DRAW_OBJ_HINT_PGI* = 0x1A20E
  GL_INT_IMAGE_3D* = 0x9059
  GL_PACK_ROW_LENGTH* = 0x0D02
  GL_MAX_TEXTURE_LOD_BIAS_EXT* = 0x84FD
  GL_SCALED_RESOLVE_NICEST_EXT* = 0x90BB
  GL_422_EXT* = 0x80CC
  GL_SAMPLER_1D_ARRAY_SHADOW_EXT* = 0x8DC3
  GL_PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT* = 0x8336
  GL_COMPRESSED_RED* = 0x8225
  GL_MAX_RATIONAL_EVAL_ORDER_NV* = 0x86D7
  GL_MAX_COMBINED_IMAGE_UNIFORMS* = 0x90CF
  GL_GLYPH_HORIZONTAL_BEARING_ADVANCE_BIT_NV* = 0x10
  GL_TEXTURE_BINDING_1D_ARRAY* = 0x8C1C
  GL_FRAMEBUFFER_COMPLETE* = 0x8CD5
  GL_RG8I* = 0x8237
  GL_COLOR_ATTACHMENT2_NV* = 0x8CE2
  GL_INT64_VEC4_NV* = 0x8FEB
  GL_OP_SET_GE_EXT* = 0x878C
  GL_READ_WRITE* = 0x88BA
  GL_OPERAND1_RGB_EXT* = 0x8591
  GL_SHADER_STORAGE_BLOCK* = 0x92E6
  GL_TEXTURE_UPDATE_BARRIER_BIT* = 0x00000100
  GL_MAX_FRAGMENT_ATOMIC_COUNTERS* = 0x92D6
  GL_SHADER_INCLUDE_ARB* = 0x8DAE
  GL_UNSIGNED_SHORT_1_5_5_5_REV* = 0x8366
  GL_PROGRAM_PIPELINE* = 0x82E4
  GL_MAP1_TEXTURE_COORD_2* = 0x0D94
  GL_FOG_COORDINATE_ARRAY_STRIDE_EXT* = 0x8455
  GL_WEIGHT_ARRAY_SIZE_OES* = 0x86AB
  GL_R11F_G11F_B10F* = 0x8C3A
  GL_WRITE_PIXEL_DATA_RANGE_NV* = 0x8878
  GL_UNSIGNED_SHORT_8_8_REV_APPLE* = 0x85BB
  GL_CND_ATI* = 0x896A
  GL_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x9056
  GL_MAX_TEXTURE_IMAGE_UNITS_NV* = 0x8872
  GL_COMPRESSED_SIGNED_RG11_EAC_OES* = 0x9273
  GL_DOT_PRODUCT_TEXTURE_3D_NV* = 0x86EF
  GL_IMAGE_TRANSLATE_Y_HP* = 0x8158
  GL_NORMAL_ARRAY_TYPE_EXT* = 0x807E
  GL_PIXEL_COUNT_NV* = 0x8866
  GL_INT_IMAGE_3D_EXT* = 0x9059
  GL_TEXTURE_TYPE_QCOM* = 0x8BD7
  GL_COMBINE_ALPHA_EXT* = 0x8572
  GL_POINT_TOKEN* = 0x0701
  GL_QUAD_ALPHA4_SGIS* = 0x811E
  GL_SIGNED_HILO8_NV* = 0x885F
  GL_MULTISAMPLE_ARB* = 0x809D
  GL_TEXTURE25* = 0x84D9
  GL_CURRENT_VERTEX_WEIGHT_EXT* = 0x850B
  GL_BLEND_DST_ALPHA_OES* = 0x80CA
  GL_UNSIGNED_SHORT_8_8_REV_MESA* = 0x85BB
  GL_CLAMP_TO_EDGE_SGIS* = 0x812F
  GL_PATH_STENCIL_REF_NV* = 0x90B8
  GL_DEBUG_OUTPUT* = 0x92E0
  GL_OBJECT_TYPE_APPLE* = 0x9112
  GL_TEXTURE_COMPARE_MODE_ARB* = 0x884C
  GL_CONSTANT* = 0x8576
  GL_RGB5_A1_OES* = 0x8057
  GL_INT16_VEC2_NV* = 0x8FE5
  GL_CONVOLUTION_BORDER_MODE_EXT* = 0x8013
  GL_CONTEXT_FLAGS* = 0x821E
  GL_MAX_PROGRAM_SUBROUTINE_NUM_NV* = 0x8F45
  GL_SPRITE_SGIX* = 0x8148
  GL_CURRENT_QUERY* = 0x8865
  GL_STENCIL_OP_VALUE_AMD* = 0x874C
  GL_UNIFORM* = 0x92E1
  GL_TEXTURE_BINDING_RECTANGLE* = 0x84F6
  GL_TRIANGLES_ADJACENCY_EXT* = 0x000C
  GL_PROVOKING_VERTEX_EXT* = 0x8E4F
  GL_INT64_VEC2_NV* = 0x8FE9
  GL_INVERSE_NV* = 0x862B
  GL_CON_29_ATI* = 0x895E
  GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE_NV* = 0x8E24
  GL_FRONT_AND_BACK* = 0x0408
  GL_MAX_LABEL_LENGTH_KHR* = 0x82E8
  GL_TRANSFORM_FEEDBACK_BUFFER_START_NV* = 0x8C84
  GL_EQUAL* = 0x0202
  GL_RGB10_EXT* = 0x8052
  GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_ARB* = 0x8C29
  GL_OP_ADD_EXT* = 0x8787
  GL_REPLACEMENT_CODE_ARRAY_POINTER_SUN* = 0x85C3
  GL_NORMAL_ARRAY_LIST_IBM* = 103071
  GL_RENDERBUFFER_GREEN_SIZE* = 0x8D51
  GL_TESS_CONTROL_PROGRAM_PARAMETER_BUFFER_NV* = 0x8C74
  GL_CURRENT_PALETTE_MATRIX_ARB* = 0x8843
  GL_DEBUG_TYPE_ERROR* = 0x824C
  GL_UNIFORM_BUFFER* = 0x8A11
  GL_NEAREST_CLIPMAP_LINEAR_SGIX* = 0x844E
  GL_LAST_VERTEX_CONVENTION* = 0x8E4E
  GL_COMPRESSED_RGBA_ASTC_12x10_KHR* = 0x93BC
  GL_FENCE_STATUS_NV* = 0x84F3
  GL_POST_CONVOLUTION_BLUE_BIAS* = 0x8022
  GL_BLEND_OVERLAP_NV* = 0x9281
  GL_COMBINE_RGB_ARB* = 0x8571
  GL_TESS_GEN_MODE* = 0x8E76
  GL_TEXTURE_ENV* = 0x2300
  GL_VERTEX_ATTRIB_ARRAY11_NV* = 0x865B
  GL_SHININESS* = 0x1601
  GL_DYNAMIC_STORAGE_BIT* = 0x0100
  GL_MODELVIEW30_ARB* = 0x873E
  GL_WRAP_BORDER_SUN* = 0x81D4
  GL_SKIP_COMPONENTS1_NV* = -6
  GL_DEPTH_CLAMP_NV* = 0x864F
  GL_PROGRAM_BINARY_FORMATS* = 0x87FF
  GL_CURRENT_RASTER_POSITION_VALID* = 0x0B08
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER* = 0x92C8
  GL_T2F_C4F_N3F_V3F* = 0x2A2C
  GL_R16F* = 0x822D
  GL_SECONDARY_COLOR_ARRAY_LENGTH_NV* = 0x8F31
  GL_SEPARATE_ATTRIBS_EXT* = 0x8C8D
  GL_NEGATIVE_Z_EXT* = 0x87DB
  GL_Z400_BINARY_AMD* = 0x8740
  GL_DRAW_INDIRECT_UNIFIED_NV* = 0x8F40
  GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS_NV* = 0x8C8A
  GL_UNSIGNED_INT_S8_S8_8_8_NV* = 0x86DA
  GL_SRGB8_NV* = 0x8C41
  GL_DEBUG_SEVERITY_MEDIUM_AMD* = 0x9147
  GL_MAX_DRAW_BUFFERS_ATI* = 0x8824
  GL_TEXTURE_COORD_ARRAY_POINTER_EXT* = 0x8092
  GL_RESAMPLE_AVERAGE_OML* = 0x8988
  GL_NO_ERROR* = 0
  GL_RGB5* = 0x8050
  GL_OP_CLAMP_EXT* = 0x878E
  GL_PROGRAM_RESIDENT_NV* = 0x8647
  GL_PROGRAM_ALU_INSTRUCTIONS_ARB* = 0x8805
  GL_ELEMENT_ARRAY_UNIFIED_NV* = 0x8F1F
  GL_SECONDARY_COLOR_ARRAY_LIST_IBM* = 103077
  GL_INTENSITY12_EXT* = 0x804C
  GL_STENCIL_BUFFER_BIT7_QCOM* = 0x00800000
  GL_SAMPLER* = 0x82E6
  GL_MAD_ATI* = 0x8968
  GL_STENCIL_BACK_FAIL* = 0x8801
  GL_LIGHT_MODEL_TWO_SIDE* = 0x0B52
  GL_UNPACK_SKIP_PIXELS* = 0x0CF4
  GL_PIXEL_TEX_GEN_SGIX* = 0x8139
  GL_FRACTIONAL_ODD* = 0x8E7B
  GL_LOW_INT* = 0x8DF3
  GL_MODELVIEW* = 0x1700
  GL_POST_CONVOLUTION_RED_SCALE_EXT* = 0x801C
  GL_DRAW_BUFFER11_EXT* = 0x8830
  GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH* = 0x8A35
  GL_CONVOLUTION_BORDER_MODE* = 0x8013
  GL_COMPRESSED_ALPHA_ARB* = 0x84E9
  GL_DEPTH_ATTACHMENT* = 0x8D00
  GL_ALPHA8_SNORM* = 0x9014
  GL_DOUBLE_MAT4x3_EXT* = 0x8F4E
  GL_INTERNALFORMAT_STENCIL_SIZE* = 0x8276
  GL_BOOL_VEC2_ARB* = 0x8B57
  GL_FASTEST* = 0x1101
  GL_MAX_FRAGMENT_INPUT_COMPONENTS* = 0x9125
  GL_STENCIL_BACK_FUNC_ATI* = 0x8800
  GL_POLYGON* = 0x0009
  GL_SAMPLER_1D_ARRAY_EXT* = 0x8DC0
  GL_OUTPUT_COLOR1_EXT* = 0x879C
  GL_IMAGE_2D_RECT* = 0x904F
  GL_RECT_NV* = 0xF6
  GL_OUTPUT_TEXTURE_COORD21_EXT* = 0x87B2
  GL_NOR* = 0x1508
  GL_FOG_COORD_ARRAY* = 0x8457
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y_OES* = 0x8517
  GL_TANGENT_ARRAY_POINTER_EXT* = 0x8442
  GL_DST_OUT_NV* = 0x928D
  GL_RENDERBUFFER_BINDING_OES* = 0x8CA7
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR* = 0x93D3
  GL_TEXTURE_GEN_S* = 0x0C60
  GL_SLIM12S_SGIX* = 0x831F
  GL_VERTEX_ARRAY_BINDING* = 0x85B5
  GL_TRACE_PRIMITIVES_BIT_MESA* = 0x0002
  GL_MAX_DEBUG_MESSAGE_LENGTH* = 0x9143
  GL_EVAL_VERTEX_ATTRIB4_NV* = 0x86CA
  GL_ACTIVE_SUBROUTINE_UNIFORMS* = 0x8DE6
  GL_ACCUM_ADJACENT_PAIRS_NV* = 0x90AD
  GL_NEGATIVE_ONE_EXT* = 0x87DF
  GL_UNPACK_RESAMPLE_SGIX* = 0x842D
  GL_ACTIVE_SUBROUTINE_MAX_LENGTH* = 0x8E48
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT* = 0x8518
  GL_DEBUG_CATEGORY_API_ERROR_AMD* = 0x9149
  GL_INTERNALFORMAT_BLUE_SIZE* = 0x8273
  GL_DRAW_BUFFER13_NV* = 0x8832
  GL_DEBUG_SOURCE_THIRD_PARTY_ARB* = 0x8249
  GL_R8_EXT* = 0x8229
  GL_GENERATE_MIPMAP* = 0x8191
  cGL_SHORT* = 0x1402
  GL_PACK_REVERSE_ROW_ORDER_ANGLE* = 0x93A4
  GL_PATH_DASH_OFFSET_RESET_NV* = 0x90B4
  GL_PACK_SKIP_VOLUMES_SGIS* = 0x8130
  GL_TEXTURE_RED_TYPE* = 0x8C10
  GL_MAX_COLOR_ATTACHMENTS_EXT* = 0x8CDF
  GL_MAP2_VERTEX_ATTRIB5_4_NV* = 0x8675
  GL_CONSTANT_ALPHA* = 0x8003
  GL_COLOR_INDEX8_EXT* = 0x80E5
  GL_DOUBLE_MAT3_EXT* = 0x8F47
  GL_ATOMIC_COUNTER_BUFFER_INDEX* = 0x9301
  GL_LINES_ADJACENCY_EXT* = 0x000A
  GL_RENDERBUFFER_SAMPLES_IMG* = 0x9133
  GL_COLOR_TABLE_FORMAT* = 0x80D8
  GL_VERTEX_ATTRIB_ARRAY_TYPE* = 0x8625
  GL_QUERY_OBJECT_EXT* = 0x9153
  GL_STREAM_READ_ARB* = 0x88E1
  GL_MIRROR_CLAMP_TO_EDGE_ATI* = 0x8743
  GL_FRAGMENT_SUBROUTINE_UNIFORM* = 0x92F2
  GL_UNIFORM_BUFFER_EXT* = 0x8DEE
  GL_SOURCE2_RGB* = 0x8582
  GL_PROGRAM_NATIVE_ATTRIBS_ARB* = 0x88AE
  GL_LUMINANCE12_ALPHA12* = 0x8047
  GL_INT_SAMPLER_1D_EXT* = 0x8DC9
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_SAMPLES_EXT* = 0x8D6C
  GL_DEPTH_RENDERABLE* = 0x8287
  GL_INTERNALFORMAT_BLUE_TYPE* = 0x827A
  GL_SLUMINANCE8_ALPHA8_EXT* = 0x8C45
  GL_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB* = 0x900A
  GL_COLOR_MATRIX* = 0x80B1
  GL_RGB8_SNORM* = 0x8F96
  GL_COLOR_ARRAY_SIZE* = 0x8081
  GL_DRAW_BUFFER4_NV* = 0x8829
  GL_VIDEO_BUFFER_INTERNAL_FORMAT_NV* = 0x902D
  GL_PRESENT_TIME_NV* = 0x8E2A
  GL_COPY_WRITE_BUFFER* = 0x8F37
  GL_UNPACK_SKIP_PIXELS_EXT* = 0x0CF4
  GL_PRIMITIVES_GENERATED_NV* = 0x8C87
  GL_INT_SAMPLER_BUFFER* = 0x8DD0
  GL_GLYPH_HORIZONTAL_BEARING_X_BIT_NV* = 0x04
  GL_FOG_COORDINATE_EXT* = 0x8451
  GL_VERTEX_ARRAY_ADDRESS_NV* = 0x8F21
  GL_RENDERBUFFER_RED_SIZE_OES* = 0x8D50
  GL_BGR_INTEGER_EXT* = 0x8D9A
  GL_UNSIGNED_BYTE_3_3_2* = 0x8032
  GL_VBO_FREE_MEMORY_ATI* = 0x87FB
  GL_PATH_COMPUTED_LENGTH_NV* = 0x90A0
  GL_COLOR_MATRIX_STACK_DEPTH_SGI* = 0x80B2
  GL_STACK_OVERFLOW* = 0x0503
  GL_MODELVIEW1_MATRIX_EXT* = 0x8506
  GL_CURRENT_BINORMAL_EXT* = 0x843C
  GL_OP_MULTIPLY_MATRIX_EXT* = 0x8798
  GL_CLIENT_ATTRIB_STACK_DEPTH* = 0x0BB1
  GL_VERTEX_PROGRAM_TWO_SIDE_NV* = 0x8643
  GL_HISTOGRAM_WIDTH_EXT* = 0x8026
  GL_OBJECT_INFO_LOG_LENGTH_ARB* = 0x8B84
  GL_SAMPLER_2D_ARRAY_SHADOW* = 0x8DC4
  GL_UNSIGNED_INT_IMAGE_1D* = 0x9062
  GL_MAX_IMAGE_UNITS* = 0x8F38
  GL_TEXTURE31_ARB* = 0x84DF
  GL_CUBIC_HP* = 0x815F
  GL_OFFSET_HILO_PROJECTIVE_TEXTURE_2D_NV* = 0x8856
  GL_ARRAY_STRIDE* = 0x92FE
  GL_DEPTH_PASS_INSTRUMENT_SGIX* = 0x8310
  GL_COMMAND_BARRIER_BIT* = 0x00000040
  GL_STATIC_DRAW_ARB* = 0x88E4
  GL_RGB16F* = 0x881B
  GL_INDEX_MATERIAL_PARAMETER_EXT* = 0x81B9
  GL_UNPACK_SKIP_VOLUMES_SGIS* = 0x8132
  GL_TEXTURE_1D* = 0x0DE0
  GL_VERTEX_PROGRAM_NV* = 0x8620
  GL_COLOR_ATTACHMENT0_NV* = 0x8CE0
  GL_READ_PIXEL_DATA_RANGE_LENGTH_NV* = 0x887B
  GL_FLOAT_32_UNSIGNED_INT_24_8_REV* = 0x8DAD
  GL_LINE_RESET_TOKEN* = 0x0707
  GL_WEIGHT_ARRAY_ARB* = 0x86AD
  GL_TEXTURE17* = 0x84D1
  GL_DEPTH_COMPONENT32_ARB* = 0x81A7
  GL_REFERENCED_BY_TESS_CONTROL_SHADER* = 0x9307
  GL_INVERT* = 0x150A
  GL_FOG_COORDINATE_ARRAY_STRIDE* = 0x8455
  GL_COMPRESSED_SIGNED_RG_RGTC2* = 0x8DBE
  GL_UNSIGNED_SHORT_8_8_MESA* = 0x85BA
  GL_ELEMENT_ARRAY_TYPE_ATI* = 0x8769
  GL_CLAMP_VERTEX_COLOR_ARB* = 0x891A
  GL_POINT_SIZE_ARRAY_STRIDE_OES* = 0x898B
  GL_RGB8* = 0x8051
  GL_MATRIX1_ARB* = 0x88C1
  GL_TEXTURE_POST_SPECULAR_HP* = 0x8168
  GL_TEXTURE_WRAP_Q_SGIS* = 0x8137
  GL_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x910B
  GL_INVALID_FRAMEBUFFER_OPERATION_OES* = 0x0506
  GL_VERTEX_ID_SWIZZLE_AMD* = 0x91A5
  GL_USE_MISSING_GLYPH_NV* = 0x90AA
  GL_LUMINANCE8_EXT* = 0x8040
  GL_INT_VEC2* = 0x8B53
  GL_TEXTURE9* = 0x84C9
  GL_RGB32UI_EXT* = 0x8D71
  GL_FENCE_CONDITION_NV* = 0x84F4
  GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION_EXT* = 0x8E4C
  GL_HSL_SATURATION_NV* = 0x92AE
  GL_CMYKA_EXT* = 0x800D
  GL_TRANSFORM_FEEDBACK_BUFFER_NV* = 0x8C8E
  GL_BUFFER_MAP_POINTER_OES* = 0x88BD
  GL_STORAGE_CLIENT_APPLE* = 0x85B4
  GL_VERTEX_ARRAY_BUFFER_BINDING_ARB* = 0x8896
  GL_TEXTURE_INTERNAL_FORMAT* = 0x1003
  GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED* = 0x8E23
  GL_UNSIGNED_INT_VEC3* = 0x8DC7
  GL_TRACE_MASK_MESA* = 0x8755
  GL_MAP_READ_BIT_EXT* = 0x0001
  GL_READ_FRAMEBUFFER_EXT* = 0x8CA8
  GL_HISTOGRAM_GREEN_SIZE* = 0x8029
  GL_COLOR_TABLE_INTENSITY_SIZE_SGI* = 0x80DF
  GL_SMALL_CCW_ARC_TO_NV* = 0x12
  GL_RELATIVE_LARGE_CW_ARC_TO_NV* = 0x19
  GL_POST_COLOR_MATRIX_BLUE_BIAS_SGI* = 0x80BA
  GL_SCISSOR_BIT* = 0x00080000
  GL_DRAW_BUFFER0_ATI* = 0x8825
  GL_GEOMETRY_SHADER_BIT* = 0x00000004
  GL_CLIP_FAR_HINT_PGI* = 0x1A221
  GL_TEXTURE_COMPARE_FUNC_EXT* = 0x884D
  GL_IS_ROW_MAJOR* = 0x9300
  GL_MAP1_VERTEX_4* = 0x0D98
  GL_OUTPUT_TEXTURE_COORD8_EXT* = 0x87A5
  GL_MAX_VERTEX_IMAGE_UNIFORMS* = 0x90CA
  GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE* = 0x8211
  GL_SOURCE1_ALPHA_ARB* = 0x8589
  GL_VIRTUAL_PAGE_SIZE_X_AMD* = 0x9195
  GL_CULL_FRAGMENT_NV* = 0x86E7
  GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS* = 0x92DC
  GL_QUERY_COUNTER_BITS_EXT* = 0x8864
  GL_RGB565* = 0x8D62
  GL_OFFSET_TEXTURE_RECTANGLE_NV* = 0x864C
  GL_CONVOLUTION_FORMAT_EXT* = 0x8017
  GL_EYE_POINT_SGIS* = 0x81F4
  GL_ALPHA32F_ARB* = 0x8816
  GL_TEXTURE_DEPTH_SIZE* = 0x884A
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR* = 0x93D1
  GL_PRIMARY_COLOR_NV* = 0x852C
  GL_BLEND_DST_ALPHA_EXT* = 0x80CA
  GL_NORMALIZE* = 0x0BA1
  GL_POST_CONVOLUTION_GREEN_BIAS_EXT* = 0x8021
  GL_HI_SCALE_NV* = 0x870E
  GL_TESS_EVALUATION_PROGRAM_NV* = 0x891F
  GL_MAX_DUAL_SOURCE_DRAW_BUFFERS* = 0x88FC
  GL_SWIZZLE_STRQ_ATI* = 0x897A
  GL_READ_FRAMEBUFFER_NV* = 0x8CA8
  GL_MATRIX_INDEX_ARRAY_STRIDE_OES* = 0x8848
  GL_MIN_SPARSE_LEVEL_ARB* = 0x919B
  GL_RG32UI* = 0x823C
  GL_SAMPLER_2D_ARRAY_EXT* = 0x8DC1
  GL_TEXTURE22_ARB* = 0x84D6
  GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS* = 0x8A32
  GL_CULL_VERTEX_EYE_POSITION_EXT* = 0x81AB
  GL_TEXTURE_BUFFER* = 0x8C2A
  GL_MAX_CUBE_MAP_TEXTURE_SIZE_ARB* = 0x851C
  GL_NORMAL_ARRAY_COUNT_EXT* = 0x8080
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_NV* = 0x8D56
  GL_ELEMENT_ARRAY_BARRIER_BIT_EXT* = 0x00000002
  GL_VERTEX_ARRAY_COUNT_EXT* = 0x807D
  GL_PROGRAM_ERROR_STRING_NV* = 0x8874
  GL_INVALID_FRAMEBUFFER_OPERATION* = 0x0506
  GL_RGB9_E5* = 0x8C3D
  GL_GREEN_BITS* = 0x0D53
  GL_CLIP_DISTANCE0* = 0x3000
  GL_COMBINER_SUM_OUTPUT_NV* = 0x854C
  GL_COLOR_ARRAY* = 0x8076
  GL_RGBA8_SNORM* = 0x8F97
  GL_PROGRAM_BINDING_ARB* = 0x8677
  GL_4PASS_0_EXT* = 0x80A4
  GL_STATIC_DRAW* = 0x88E4
  GL_TEXTURE_COMPRESSED_BLOCK_WIDTH* = 0x82B1
  GL_TEXTURE_STORAGE_SPARSE_BIT_AMD* = 0x00000001
  GL_MEDIUM_INT* = 0x8DF4
  GL_TEXTURE13_ARB* = 0x84CD
  GL_LUMINANCE_ALPHA16F_ARB* = 0x881F
  GL_CONTEXT_CORE_PROFILE_BIT* = 0x00000001
  GL_LOCATION_COMPONENT* = 0x934A
  GL_TEXTURE_RECTANGLE* = 0x84F5
  GL_SAMPLER_2D_ARB* = 0x8B5E
  GL_FLOAT_RG32_NV* = 0x8887
  GL_SKIP_DECODE_EXT* = 0x8A4A
  GL_LIGHT6* = 0x4006
  GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD* = 0x87EE
  GL_NOOP* = 0x1505
  GL_DEPTH_BUFFER_BIT* = 0x00000100
  GL_FRAMEBUFFER_BINDING_ANGLE* = 0x8CA6
  GL_DEBUG_TYPE_POP_GROUP_KHR* = 0x826A
  GL_SAMPLER_2D_RECT_SHADOW* = 0x8B64
  GL_CONSERVE_MEMORY_HINT_PGI* = 0x1A1FD
  GL_QUERY_BY_REGION_NO_WAIT* = 0x8E16
  GL_UNSIGNED_INT_SAMPLER_CUBE* = 0x8DD4
  GL_LUMINANCE4_EXT* = 0x803F
  GL_COLOR_ARRAY_STRIDE* = 0x8083
  GL_SAMPLER_2D_ARRAY_SHADOW_NV* = 0x8DC4
  GL_REFERENCED_BY_GEOMETRY_SHADER* = 0x9309
  GL_SIGNED_RGB_UNSIGNED_ALPHA_NV* = 0x870C
  GL_OBJECT_PLANE* = 0x2501
  GL_Q* = 0x2003
  GL_MAX_SPOT_EXPONENT_NV* = 0x8505
  GL_VERTEX_ATTRIB_ARRAY_LONG* = 0x874E
  GL_COLOR_ATTACHMENT3* = 0x8CE3
  GL_TEXTURE_BINDING_RENDERBUFFER_NV* = 0x8E53
  GL_EXCLUSION_NV* = 0x92A0
  GL_EDGE_FLAG_ARRAY_ADDRESS_NV* = 0x8F26
  GL_PRIMARY_COLOR_ARB* = 0x8577
  GL_LUMINANCE_ALPHA_FLOAT16_ATI* = 0x881F
  GL_TRACE_TEXTURES_BIT_MESA* = 0x0008
  GL_FRAMEBUFFER_OES* = 0x8D40
  GL_PIXEL_MAG_FILTER_EXT* = 0x8331
  GL_IMAGE_BINDING_LAYERED_EXT* = 0x8F3C
  GL_PATH_MITER_LIMIT_NV* = 0x907A
  GL_PROJECTION_MATRIX* = 0x0BA7
  GL_TEXTURE23_ARB* = 0x84D7
  GL_VERTEX_ATTRIB_MAP2_COEFF_APPLE* = 0x8A07
  GL_RGB32F_ARB* = 0x8815
  GL_RED_SCALE* = 0x0D14
  GL_GEOMETRY_INPUT_TYPE_ARB* = 0x8DDB
  GL_EVAL_VERTEX_ATTRIB13_NV* = 0x86D3
  GL_INT64_NV* = 0x140E
  GL_VIEW_CLASS_24_BITS* = 0x82C9
  GL_FRAGMENT_LIGHT2_SGIX* = 0x840E
  GL_LUMINANCE12_ALPHA12_EXT* = 0x8047
  GL_MAP2_VERTEX_ATTRIB2_4_NV* = 0x8672
  GL_POINT_SIZE_MIN_SGIS* = 0x8126
  GL_DEBUG_TYPE_OTHER_ARB* = 0x8251
  GL_MAP2_VERTEX_ATTRIB0_4_NV* = 0x8670
  GL_DEBUG_PRINT_MESA* = 0x875A
  GL_TEXTURE_PRIORITY* = 0x8066
  GL_PIXEL_MAP_I_TO_G* = 0x0C73
  GL_VERTEX_ATTRIB_ARRAY_DIVISOR* = 0x88FE
  GL_TEXTURE_CUBE_MAP_ARB* = 0x8513
  GL_LUMINANCE8_SNORM* = 0x9015
  GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT* = 0x00004000
  GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS* = 0x8E1F
  GL_BUFFER_STORAGE_FLAGS* = 0x8220
  GL_DEPTH_COMPONENT24_SGIX* = 0x81A6
  GL_UNIFORM_OFFSET* = 0x8A3B
  GL_TEXTURE_DT_SIZE_NV* = 0x871E
  GL_POST_COLOR_MATRIX_ALPHA_SCALE_SGI* = 0x80B7
  GL_DEPTH32F_STENCIL8_NV* = 0x8DAC
  GL_STENCIL_FUNC* = 0x0B92
  GL_NEAREST_MIPMAP_LINEAR* = 0x2702
  GL_COMPRESSED_LUMINANCE_LATC1_EXT* = 0x8C70
  GL_TEXTURE_BORDER* = 0x1005
  GL_COLOR_ATTACHMENT14_NV* = 0x8CEE
  GL_TEXTURE_STORAGE_HINT_APPLE* = 0x85BC
  GL_VERTEX_ARRAY_RANGE_NV* = 0x851D
  GL_COLOR_ARRAY_SIZE_EXT* = 0x8081
  GL_INTERNALFORMAT_SUPPORTED* = 0x826F
  GL_MULTISAMPLE_BIT_ARB* = 0x20000000
  GL_RGB* = 0x1907
  GL_TRANSFORM_FEEDBACK_PAUSED* = 0x8E23
  GL_ALPHA8* = 0x803C
  GL_STENCIL_FAIL* = 0x0B94
  GL_PACK_SKIP_IMAGES_EXT* = 0x806B
  GL_FOG_COORDINATE_ARRAY_TYPE_EXT* = 0x8454
  GL_RESCALE_NORMAL_EXT* = 0x803A
  GL_LERP_ATI* = 0x8969
  GL_MATRIX_INDEX_ARRAY_STRIDE_ARB* = 0x8848
  GL_PROGRAM_LENGTH_NV* = 0x8627
  GL_UNSIGNED_INT_SAMPLER_3D_EXT* = 0x8DD3
  GL_COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT* = 0x8DBE
  GL_UNSIGNED_INT_24_8_NV* = 0x84FA
  GL_POINT_SIZE_MIN_ARB* = 0x8126
  GL_COMP_BIT_ATI* = 0x00000002
  GL_NORMAL_ARRAY_ADDRESS_NV* = 0x8F22
  GL_TEXTURE9_ARB* = 0x84C9
  GL_MAX_GEOMETRY_OUTPUT_COMPONENTS* = 0x9124
  GL_DOUBLEBUFFER* = 0x0C32
  GL_OFFSET_TEXTURE_2D_BIAS_NV* = 0x86E3
  GL_ACTIVE_PROGRAM_EXT* = 0x8B8D
  GL_PARTIAL_SUCCESS_NV* = 0x902E
  GL_SUBTRACT* = 0x84E7
  GL_DUAL_INTENSITY4_SGIS* = 0x8118
  GL_FILL* = 0x1B02
  GL_COMPRESSED_SRGB_ALPHA* = 0x8C49
  GL_RENDERBUFFER_OES* = 0x8D41
  GL_PIXEL_MAP_R_TO_R_SIZE* = 0x0CB6
  GL_TEXTURE_LUMINANCE_TYPE_ARB* = 0x8C14
  GL_TEXTURE_BUFFER_FORMAT_EXT* = 0x8C2E
  GL_OUTPUT_TEXTURE_COORD13_EXT* = 0x87AA
  GL_LINES_ADJACENCY_ARB* = 0x000A
  GL_MAX_PROGRAM_SUBROUTINE_PARAMETERS_NV* = 0x8F44
  GL_INTENSITY32UI_EXT* = 0x8D73
  GL_PACK_IMAGE_HEIGHT* = 0x806C
  GL_HI_BIAS_NV* = 0x8714
  GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB* = 0x824E
  GL_LINE_STIPPLE* = 0x0B24
  GL_INDEX_LOGIC_OP* = 0x0BF1
  GL_CON_18_ATI* = 0x8953
  GL_QUERY_RESULT* = 0x8866
  GL_FRAGMENT_PROGRAM_NV* = 0x8870
  GL_MATRIX1_NV* = 0x8631
  GL_FUNC_SUBTRACT_OES* = 0x800A
  GL_PIXEL_MAP_I_TO_A_SIZE* = 0x0CB5
  GL_UNSIGNED_SHORT_4_4_4_4_REV_EXT* = 0x8365
  GL_OUTPUT_TEXTURE_COORD20_EXT* = 0x87B1
  GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT_EXT* = 0x00000001
  GL_TRIANGULAR_NV* = 0x90A5
  GL_TEXTURE_COMPARE_MODE_EXT* = 0x884C
  GL_SECONDARY_COLOR_ARRAY_SIZE_EXT* = 0x845A
  GL_FRAMEBUFFER_ATTACHMENT_LAYERED_EXT* = 0x8DA7
  GL_COMPRESSED_RGBA_S3TC_DXT5_ANGLE* = 0x83F3
  GL_MAX_COMPUTE_VARIABLE_GROUP_SIZE_ARB* = 0x9345
  GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB* = 0x889A
  GL_PROGRAM_FORMAT_ARB* = 0x8876
  GL_QUAD_INTENSITY4_SGIS* = 0x8122
  GL_REPLICATE_BORDER* = 0x8153
  GL_PN_TRIANGLES_ATI* = 0x87F0
  GL_DEPTH_TEXTURE_MODE* = 0x884B
  GL_VARIABLE_C_NV* = 0x8525
  GL_CLIP_PLANE0_IMG* = 0x3000
  GL_FRONT_LEFT* = 0x0400
  GL_MATRIX3_ARB* = 0x88C3
  GL_BLEND_EQUATION_ALPHA_EXT* = 0x883D
  GL_BGRA8_EXT* = 0x93A1
  GL_INTERLACE_READ_INGR* = 0x8568
  GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE* = 0x8E24
  GL_MAP1_VERTEX_ATTRIB13_4_NV* = 0x866D
  GL_PIXEL_TEX_GEN_Q_FLOOR_SGIX* = 0x8186
  GL_UNSIGNED_INT_SAMPLER_2D_ARRAY* = 0x8DD7
  GL_ALL_SHADER_BITS_EXT* = 0xFFFFFFFF
  GL_ONE_MINUS_SRC1_ALPHA* = 0x88FB
  GL_VERTEX_ARRAY_RANGE_LENGTH_APPLE* = 0x851E
  GL_PROXY_COLOR_TABLE_SGI* = 0x80D3
  GL_MAX_RENDERBUFFER_SIZE_OES* = 0x84E8
  GL_VERTEX_ATTRIB_ARRAY_ENABLED* = 0x8622
  GL_TEXTURE_BINDING_2D_MULTISAMPLE* = 0x9104
  GL_STENCIL_BUFFER_BIT0_QCOM* = 0x00010000
  GL_IMAGE_BINDING_FORMAT_EXT* = 0x906E
  GL_RENDERBUFFER_SAMPLES_NV* = 0x8CAB
  GL_ACCUM_GREEN_BITS* = 0x0D59
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER* = 0x90ED
  GL_FRAMEBUFFER_UNDEFINED* = 0x8219
  GL_OFFSET_TEXTURE_2D_NV* = 0x86E8
  GL_POST_CONVOLUTION_RED_BIAS* = 0x8020
  GL_DRAW_BUFFER8* = 0x882D
  GL_MAP_INVALIDATE_RANGE_BIT* = 0x0004
  GL_ALWAYS* = 0x0207
  GL_ALPHA_MIN_SGIX* = 0x8320
  GL_SOURCE0_RGB_ARB* = 0x8580
  GL_POINT_SIZE_ARRAY_POINTER_OES* = 0x898C
  GL_CUBIC_EXT* = 0x8334
  GL_MAP2_NORMAL* = 0x0DB2
  GL_TEXTURE_RESIDENT_EXT* = 0x8067
  GL_TEXTURE_BUFFER_DATA_STORE_BINDING_ARB* = 0x8C2D
  GL_BUMP_NUM_TEX_UNITS_ATI* = 0x8777
  GL_TEXTURE_LOD_BIAS_T_SGIX* = 0x818F
  GL_FONT_UNDERLINE_POSITION_BIT_NV* = 0x04000000
  GL_NORMAL_ARRAY_STRIDE* = 0x807F
  GL_CONDITION_SATISFIED_APPLE* = 0x911C
  GL_POINT_SIZE_MIN* = 0x8126
  GL_SPARE0_PLUS_SECONDARY_COLOR_NV* = 0x8532
  GL_LAYOUT_DEFAULT_INTEL* = 0
  GL_FRAMEBUFFER_BINDING* = 0x8CA6
  GL_HIGH_FLOAT* = 0x8DF2
  GL_NO_RESET_NOTIFICATION_ARB* = 0x8261
  GL_OFFSET_TEXTURE_RECTANGLE_SCALE_NV* = 0x864D
  GL_VERTEX_ATTRIB_ARRAY_ADDRESS_NV* = 0x8F20
  GL_VIEW_CLASS_96_BITS* = 0x82C5
  GL_BACK_RIGHT* = 0x0403
  GL_BLEND_EQUATION_ALPHA* = 0x883D
  GL_DISTANCE_ATTENUATION_SGIS* = 0x8129
  GL_PROXY_TEXTURE_CUBE_MAP_ARRAY* = 0x900B
  GL_RG16* = 0x822C
  GL_UNDEFINED_VERTEX* = 0x8260
  GL_PATH_DASH_OFFSET_NV* = 0x907E
  GL_ALL_ATTRIB_BITS* = 0xFFFFFFFF
  GL_VERTEX_ATTRIB_MAP1_ORDER_APPLE* = 0x8A04
  GL_MAX_COLOR_MATRIX_STACK_DEPTH_SGI* = 0x80B3
  GL_TIME_ELAPSED_EXT* = 0x88BF
  GL_MAP2_VERTEX_3* = 0x0DB7
  GL_MAX_PROGRAM_RESULT_COMPONENTS_NV* = 0x8909
  GL_SAMPLER_2D_RECT_SHADOW_ARB* = 0x8B64
  GL_REFERENCE_PLANE_SGIX* = 0x817D
  GL_LUMINANCE4_ALPHA4_EXT* = 0x8043
  GL_PATH_FILL_MASK_NV* = 0x9081
  GL_FILTER* = 0x829A
  GL_INT_SAMPLER_2D_ARRAY* = 0x8DCF
  GL_MAX_PROGRAM_ATTRIB_COMPONENTS_NV* = 0x8908
  GL_EVAL_VERTEX_ATTRIB2_NV* = 0x86C8
  GL_NAND* = 0x150E
  GL_BLEND_SRC_RGB* = 0x80C9
  GL_OPERAND2_ALPHA_EXT* = 0x859A
  GL_IMAGE_1D_EXT* = 0x904C
  GL_CONVOLUTION_FILTER_SCALE* = 0x8014
  GL_IMAGE_CLASS_2_X_16* = 0x82BD
  GL_VIEW_CLASS_BPTC_FLOAT* = 0x82D3
  GL_PROGRAM_INPUT* = 0x92E3
  GL_1PASS_SGIS* = 0x80A1
  GL_FOG_DISTANCE_MODE_NV* = 0x855A
  GL_STENCIL_INDEX16_EXT* = 0x8D49
  GL_POST_CONVOLUTION_RED_BIAS_EXT* = 0x8020
  GL_PIXEL_MAP_R_TO_R* = 0x0C76
  GL_3DC_XY_AMD* = 0x87FA
  GL_POINT_SIZE_MAX* = 0x8127
  GL_DOUBLE_MAT3x2* = 0x8F4B
  GL_DOUBLE_MAT4x2_EXT* = 0x8F4D
  GL_TEXTURE_HI_SIZE_NV* = 0x871B
  GL_MATRIX4_NV* = 0x8634
  GL_SPRITE_TRANSLATION_SGIX* = 0x814B
  GL_TEXTURE_FILTER_CONTROL_EXT* = 0x8500
  GL_SMOOTH_LINE_WIDTH_GRANULARITY* = 0x0B23
  GL_TEXTURE_BINDING_BUFFER* = 0x8C2C
  GL_INTENSITY4* = 0x804A
  GL_MAX_IMAGE_SAMPLES_EXT* = 0x906D
  GL_COLOR_ATTACHMENT12* = 0x8CEC
  GL_CLAMP_READ_COLOR* = 0x891C
  GL_ELEMENT_ARRAY_BUFFER_ARB* = 0x8893
  GL_MAP2_VERTEX_ATTRIB6_4_NV* = 0x8676
  GL_CONVOLUTION_HEIGHT_EXT* = 0x8019
  GL_SGX_PROGRAM_BINARY_IMG* = 0x9130
  GL_MAP1_TEXTURE_COORD_1* = 0x0D93
  GL_COMPRESSED_RGBA_ASTC_6x6_KHR* = 0x93B4
  GL_TEXTURE_APPLICATION_MODE_EXT* = 0x834F
  GL_TEXTURE_GATHER* = 0x82A2
  GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS* = 0x90DC
  GL_DEBUG_LOGGED_MESSAGES_KHR* = 0x9145
  GL_TEXTURE_VIEW_NUM_LEVELS* = 0x82DC
  GL_ENABLE_BIT* = 0x00002000
  GL_VERTEX_PROGRAM_TWO_SIDE_ARB* = 0x8643
  GL_INDEX_TEST_EXT* = 0x81B5
  GL_TEXTURE_WRAP_R* = 0x8072
  GL_MAX* = 0x8008
  GL_UNPACK_IMAGE_DEPTH_SGIS* = 0x8133
  GL_COLOR_ATTACHMENT13_NV* = 0x8CED
  GL_FOG_BIT* = 0x00000080
  GL_GEOMETRY_SHADER_EXT* = 0x8DD9
  GL_ALPHA_TEST_FUNC_QCOM* = 0x0BC1
  GL_DRAW_BUFFER10_EXT* = 0x882F
  GL_MAX_PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB* = 0x880F
  GL_STENCIL_BACK_REF* = 0x8CA3
  GL_SAMPLER_1D_ARB* = 0x8B5D
  GL_DRAW_BUFFER* = 0x0C01
  GL_CLIENT_PIXEL_STORE_BIT* = 0x00000001
  GL_TEXTURE_STENCIL_SIZE* = 0x88F1
  GL_ELEMENT_ARRAY_APPLE* = 0x8A0C
  GL_CON_21_ATI* = 0x8956
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER* = 0x92C7
  GL_PIXEL_MAP_I_TO_B* = 0x0C74
  GL_VERTEX_ATTRIB_MAP1_COEFF_APPLE* = 0x8A03
  GL_FOG_INDEX* = 0x0B61
  GL_PROXY_POST_CONVOLUTION_COLOR_TABLE_SGI* = 0x80D4
  GL_OUTPUT_TEXTURE_COORD29_EXT* = 0x87BA
  GL_TESS_CONTROL_SUBROUTINE* = 0x92E9
  GL_IMAGE_CUBE_MAP_ARRAY* = 0x9054
  GL_RGB_FLOAT32_ATI* = 0x8815
  GL_OBJECT_SHADER_SOURCE_LENGTH_ARB* = 0x8B88
  GL_COLOR_INDEX4_EXT* = 0x80E4
  GL_DRAW_BUFFER14* = 0x8833
  GL_PATH_STENCIL_DEPTH_OFFSET_UNITS_NV* = 0x90BE
  GL_NATIVE_GRAPHICS_HANDLE_PGI* = 0x1A202
  GL_UNSIGNED_SHORT_5_6_5* = 0x8363
  GL_GREATER* = 0x0204
  GL_DATA_BUFFER_AMD* = 0x9151
  GL_GLYPH_VERTICAL_BEARING_Y_BIT_NV* = 0x40
  GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2* = 0x9276
  GL_RELATIVE_MOVE_TO_NV* = 0x03
  GL_BLUE_INTEGER* = 0x8D96
  GL_BLUE_BIAS* = 0x0D1B
  GL_SHADER_TYPE* = 0x8B4F
  GL_TRANSFORM_FEEDBACK_BINDING* = 0x8E25
  GL_TEXTURE17_ARB* = 0x84D1
  GL_GREEN* = 0x1904
  GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS* = 0x8E89
  GL_DRAW_BUFFER6* = 0x882B
  GL_VALIDATE_STATUS* = 0x8B83
  GL_TEXTURE_COORD_ARRAY_ADDRESS_NV* = 0x8F25
  GL_MVP_MATRIX_EXT* = 0x87E3
  GL_PIXEL_BUFFER_BARRIER_BIT_EXT* = 0x00000080
  GL_MAX_VERTEX_VARYING_COMPONENTS_EXT* = 0x8DDE
  GL_STACK_OVERFLOW_KHR* = 0x0503
  GL_MAX_PROJECTION_STACK_DEPTH* = 0x0D38
  GL_SKIP_COMPONENTS3_NV* = -4
  GL_DEBUG_ASSERT_MESA* = 0x875B
  GL_INSTRUMENT_BUFFER_POINTER_SGIX* = 0x8180
  GL_SAMPLE_ALPHA_TO_MASK_EXT* = 0x809E
  GL_REG_29_ATI* = 0x893E
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_NV* = 0x8C4E
  GL_DEBUG_CATEGORY_DEPRECATION_AMD* = 0x914B
  GL_DEPTH_STENCIL_TO_BGRA_NV* = 0x886F
  GL_UNSIGNED_INT_VEC3_EXT* = 0x8DC7
  GL_VERTEX_SHADER_EXT* = 0x8780
  GL_LIST_BASE* = 0x0B32
  GL_TEXTURE_STENCIL_SIZE_EXT* = 0x88F1
  GL_ACTIVE_PROGRAM* = 0x8259
  GL_RGBA_SIGNED_COMPONENTS_EXT* = 0x8C3C
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR* = 0x93DC
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE* = 0x8CD0
  GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE* = 0x8217
  GL_MATRIX7_ARB* = 0x88C7
  GL_FLOAT_VEC3_ARB* = 0x8B51
  GL_PACK_ROW_BYTES_APPLE* = 0x8A15
  GL_PIXEL_TILE_GRID_HEIGHT_SGIX* = 0x8143
  GL_UNIFORM_BLOCK* = 0x92E2
  GL_VIEWPORT_BIT* = 0x00000800
  GL_RENDERBUFFER_COVERAGE_SAMPLES_NV* = 0x8CAB
  GL_MAP1_BINORMAL_EXT* = 0x8446
  GL_SAMPLER_3D* = 0x8B5F
  GL_RENDERBUFFER_SAMPLES_APPLE* = 0x8CAB
  GL_DEPTH_WRITEMASK* = 0x0B72
  GL_MAP2_VERTEX_ATTRIB9_4_NV* = 0x8679
  GL_TEXTURE_COMPARE_FUNC* = 0x884D
  GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT_ARB* = 0x00000004
  GL_READ_BUFFER* = 0x0C02
  GL_ONE_MINUS_SRC1_COLOR* = 0x88FA
  GL_PROGRAM_FORMAT_ASCII_ARB* = 0x8875
  GL_DRAW_FRAMEBUFFER_APPLE* = 0x8CA9
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_OES* = 0x8CD0
  GL_BLEND_DST* = 0x0BE0
  GL_SHADER_OBJECT_EXT* = 0x8B48
  GL_UNSIGNALED* = 0x9118
  GL_VERTEX4_BIT_PGI* = 0x00000008
  GL_DRAW_FRAMEBUFFER_BINDING_APPLE* = 0x8CA6
  GL_IMAGE_CUBE_EXT* = 0x9050
  GL_CONTEXT_ROBUST_ACCESS_EXT* = 0x90F3
  GL_TEXTURE14_ARB* = 0x84CE
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y* = 0x8517
  GL_OFFSET_HILO_PROJECTIVE_TEXTURE_RECTANGLE_NV* = 0x8857
  GL_COMPRESSED_RG11_EAC_OES* = 0x9272
  GL_OP_DOT4_EXT* = 0x8785
  GL_FRAMEBUFFER_COMPLETE_EXT* = 0x8CD5
  GL_TEXTURE_COMPARE_FUNC_ARB* = 0x884D
  GL_TEXTURE_FILTER4_SIZE_SGIS* = 0x8147
  GL_ELEMENT_ARRAY_BUFFER_BINDING* = 0x8895
  GL_UNSIGNED_INT_IMAGE_BUFFER_EXT* = 0x9067
  GL_IMAGE_1D_ARRAY_EXT* = 0x9052
  GL_CLAMP_READ_COLOR_ARB* = 0x891C
  GL_COMPUTE_SUBROUTINE* = 0x92ED
  GL_R3_G3_B2* = 0x2A10
  GL_PATH_DASH_ARRAY_COUNT_NV* = 0x909F
  GL_SPOT_EXPONENT* = 0x1205
  GL_NUM_PROGRAM_BINARY_FORMATS_OES* = 0x87FE
  GL_SWIZZLE_STQ_ATI* = 0x8977
  GL_SYNC_FLUSH_COMMANDS_BIT_APPLE* = 0x00000001
  GL_VERTEX_STREAM6_ATI* = 0x8772
  GL_FRAGMENT_COLOR_MATERIAL_SGIX* = 0x8401
  GL_DYNAMIC_ATI* = 0x8761
  GL_SUB_ATI* = 0x8965
  GL_PREVIOUS_EXT* = 0x8578
  GL_MAP2_TEXTURE_COORD_1* = 0x0DB3
  GL_COLOR_SAMPLES_NV* = 0x8E20
  GL_HILO_NV* = 0x86F4
  GL_SHADER_STORAGE_BUFFER_BINDING* = 0x90D3
  GL_DUP_LAST_CUBIC_CURVE_TO_NV* = 0xF4
  GL_ACTIVE_SUBROUTINES* = 0x8DE5
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_IMG* = 0x9134
  GL_INTENSITY16* = 0x804D
  GL_MAX_PROGRAM_NATIVE_ATTRIBS_ARB* = 0x88AF
  GL_TIMESTAMP_EXT* = 0x8E28
  GL_CLIENT_ACTIVE_TEXTURE* = 0x84E1
  GL_TEXTURE_BINDING_2D_ARRAY* = 0x8C1D
  GL_INT_SAMPLER_2D_RECT_EXT* = 0x8DCD
  GL_PREFER_DOUBLEBUFFER_HINT_PGI* = 0x1A1F8
  GL_TEXTURE_WIDTH* = 0x1000
  GL_CPU_OPTIMIZED_QCOM* = 0x8FB1
  GL_TEXTURE_IMAGE_TYPE* = 0x8290
  GL_MAX_VERTEX_UNIFORM_VECTORS* = 0x8DFB
  GL_MODULATE_SUBTRACT_ATI* = 0x8746
  GL_SYNC_STATUS* = 0x9114
  GL_IMAGE_2D_RECT_EXT* = 0x904F
  GL_MATRIX6_NV* = 0x8636
  GL_SOURCE1_RGB_ARB* = 0x8581
  GL_MAX_COMBINED_ATOMIC_COUNTERS* = 0x92D7
  GL_MAX_COMPUTE_LOCAL_INVOCATIONS* = 0x90EB
  GL_SAMPLER_CUBE* = 0x8B60
  GL_ALPHA_FLOAT32_ATI* = 0x8816
  GL_COMPRESSED_LUMINANCE_ARB* = 0x84EA
  GL_COMPRESSED_RGB8_ETC2_OES* = 0x9274
  GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_KHR* = 0x8243
  GL_MINUS_CLAMPED_NV* = 0x92B3
  GL_REG_31_ATI* = 0x8940
  GL_ELEMENT_ARRAY_ADDRESS_NV* = 0x8F29
  GL_SRC1_COLOR* = 0x88F9
  GL_DEBUG_SEVERITY_LOW_ARB* = 0x9148
  GL_CON_3_ATI* = 0x8944
  GL_R32I* = 0x8235
  GL_BLEND_COLOR* = 0x8005
  GL_CLIP_PLANE4* = 0x3004
  GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT* = 0x00000001
  GL_FLOAT16_VEC4_NV* = 0x8FFB
  GL_DST_IN_NV* = 0x928B
  GL_VIRTUAL_PAGE_SIZE_Y_ARB* = 0x9196
  GL_COLOR_ATTACHMENT8_NV* = 0x8CE8
  GL_TESS_GEN_VERTEX_ORDER* = 0x8E78
  GL_LOSE_CONTEXT_ON_RESET_EXT* = 0x8252
  GL_PROGRAM_INSTRUCTIONS_ARB* = 0x88A0
  GL_TEXTURE_IMAGE_VALID_QCOM* = 0x8BD8
  GL_SAMPLE_MASK_VALUE_EXT* = 0x80AA
  GL_CURRENT_MATRIX_ARB* = 0x8641
  GL_DECR_WRAP_EXT* = 0x8508
  GL_BLUE_INTEGER_EXT* = 0x8D96
  GL_COMPRESSED_RG* = 0x8226
  GL_MAX_PROGRAM_EXEC_INSTRUCTIONS_NV* = 0x88F4
  GL_MINMAX_EXT* = 0x802E
  GL_FLOAT_MAT4_ARB* = 0x8B5C
  GL_TEXTURE_CLIPMAP_FRAME_SGIX* = 0x8172
  GL_PIXEL_UNPACK_BUFFER_EXT* = 0x88EC
  GL_TEXTURE5_ARB* = 0x84C5
  GL_UNSIGNED_INT_IMAGE_2D_RECT* = 0x9065
  GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS* = 0x91BC
  GL_DEPTH_COMPONENT* = 0x1902
  GL_RG32F_EXT* = 0x8230
  GL_FACTOR_ALPHA_MODULATE_IMG* = 0x8C07
  GL_VERTEX_ARRAY_TYPE_EXT* = 0x807B
  GL_DS_BIAS_NV* = 0x8716
  GL_NATIVE_GRAPHICS_BEGIN_HINT_PGI* = 0x1A203
  GL_ALPHA16UI_EXT* = 0x8D78
  GL_DOUBLE_VEC2* = 0x8FFC
  GL_MAP1_VERTEX_ATTRIB12_4_NV* = 0x866C
  GL_4D_COLOR_TEXTURE* = 0x0604
  GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS* = 0x90D6
  GL_SPECULAR* = 0x1202
  GL_TOP_LEVEL_ARRAY_SIZE* = 0x930C
  GL_MAX_SPARSE_ARRAY_TEXTURE_LAYERS_ARB* = 0x919A
  GL_COVERAGE_SAMPLES_NV* = 0x8ED4
  GL_SIGNALED_APPLE* = 0x9119
  GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_KHR* = 0x824D
  GL_BUFFER_KHR* = 0x82E0
  GL_GEOMETRY_TEXTURE* = 0x829E
  GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_NV* = 0x8E5E
  GL_EVAL_VERTEX_ATTRIB7_NV* = 0x86CD
  GL_GLYPH_VERTICAL_BEARING_ADVANCE_BIT_NV* = 0x80
  GL_BINORMAL_ARRAY_POINTER_EXT* = 0x8443
  GL_AUX3* = 0x040C
  GL_MULTISAMPLE_BIT_EXT* = 0x20000000
  GL_COLOR_TABLE_FORMAT_SGI* = 0x80D8
  GL_VERTEX_PROGRAM_POINT_SIZE* = 0x8642
  GL_LINE_WIDTH_GRANULARITY* = 0x0B23
  GL_MAX_VERTEX_ATTRIB_BINDINGS* = 0x82DA
  GL_TEXTURE_BINDING_2D_ARRAY_EXT* = 0x8C1D
  GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST* = 0x82AC
  GL_SCALE_BY_FOUR_NV* = 0x853F
  GL_VIRTUAL_PAGE_SIZE_Z_AMD* = 0x9197
  GL_TEXTURE16* = 0x84D0
  GL_DSDT8_MAG8_NV* = 0x870A
  GL_OP_FLOOR_EXT* = 0x878F
  GL_MAX_PROGRAM_IF_DEPTH_NV* = 0x88F6
  GL_VERTEX_ARRAY_LIST_IBM* = 103070
  GL_COMPRESSED_SIGNED_RED_RGTC1* = 0x8DBC
  GL_CUBIC_CURVE_TO_NV* = 0x0C
  GL_PROXY_POST_CONVOLUTION_COLOR_TABLE* = 0x80D4
  GL_SIGNED_IDENTITY_NV* = 0x853C
  GL_EVAL_VERTEX_ATTRIB6_NV* = 0x86CC
  GL_MODELVIEW10_ARB* = 0x872A
  GL_MULTISAMPLE_3DFX* = 0x86B2
  GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG* = 0x8C00
  GL_DSDT_MAG_VIB_NV* = 0x86F7
  GL_TEXCOORD4_BIT_PGI* = 0x80000000
  GL_TRANSFORM_FEEDBACK_BARRIER_BIT* = 0x00000800
  GL_EVAL_VERTEX_ATTRIB10_NV* = 0x86D0
  GL_DRAW_BUFFER13_ARB* = 0x8832
  GL_RENDERBUFFER_STENCIL_SIZE_OES* = 0x8D55
  GL_INTENSITY8I_EXT* = 0x8D91
  GL_STENCIL_BACK_PASS_DEPTH_FAIL* = 0x8802
  GL_INTENSITY32F_ARB* = 0x8817
  GL_CURRENT_ATTRIB_NV* = 0x8626
  GL_POLYGON_BIT* = 0x00000008
  GL_COMBINE_RGB* = 0x8571
  GL_MAX_FRAMEBUFFER_HEIGHT* = 0x9316
  GL_FRAMEBUFFER_BINDING_OES* = 0x8CA6
  GL_TEXTURE_GREEN_TYPE* = 0x8C11
  GL_LINE_TO_NV* = 0x04
  GL_FUNC_ADD_EXT* = 0x8006
  GL_TEXTURE_LOD_BIAS* = 0x8501
  GL_QUAD_INTENSITY8_SGIS* = 0x8123
  GL_SECONDARY_COLOR_ARRAY_EXT* = 0x845E
  GL_UNPACK_COMPRESSED_SIZE_SGIX* = 0x831A
  GL_RGBA_INTEGER* = 0x8D99
  GL_ATOMIC_COUNTER_BUFFER_SIZE* = 0x92C3
  GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE* = 0x8D56
  GL_OBJECT_DISTANCE_TO_LINE_SGIS* = 0x81F3
  GL_DEPTH_BUFFER_BIT3_QCOM* = 0x00000800
  GL_RGB16_SNORM* = 0x8F9A
  GL_MATRIX_INDEX_ARRAY_TYPE_ARB* = 0x8847
  GL_TRANSLATE_X_NV* = 0x908E
  GL_BUFFER_ACCESS_FLAGS* = 0x911F
  GL_IS_PER_PATCH* = 0x92E7
  GL_PATH_GEN_MODE_NV* = 0x90B0
  GL_ALPHA_MIN_CLAMP_INGR* = 0x8563
  GL_LUMINANCE_ALPHA32I_EXT* = 0x8D87
  GL_BUFFER_USAGE_ARB* = 0x8765
  GL_POINT_SIZE* = 0x0B11
  GL_INVARIANT_EXT* = 0x87C2
  GL_IMAGE_BINDING_NAME* = 0x8F3A
  GL_BLEND_SRC_ALPHA* = 0x80CB
  GL_OUTPUT_TEXTURE_COORD23_EXT* = 0x87B4
  GL_EYE_PLANE* = 0x2502
  GL_BOOL_VEC4_ARB* = 0x8B59
  GL_MITER_REVERT_NV* = 0x90A7
  GL_SYNC_X11_FENCE_EXT* = 0x90E1
  GL_GEOMETRY_SHADER_INVOCATIONS* = 0x887F
  GL_DRAW_BUFFER5_ATI* = 0x882A
  GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB* = 0x889D
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_EXT* = 0x906B
  GL_PIXEL_TEX_GEN_Q_ROUND_SGIX* = 0x8185
  GL_DOUBLE_MAT3x2_EXT* = 0x8F4B
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB* = 0x8516
  GL_MOV_ATI* = 0x8961
  GL_COLOR4_BIT_PGI* = 0x00020000
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR* = 0x93DD
  GL_DEPTH_BOUNDS_TEST_EXT* = 0x8890
  GL_DST_OVER_NV* = 0x9289
  GL_PIXEL_MAP_I_TO_I_SIZE* = 0x0CB0
  GL_ALPHA16F_EXT* = 0x881C
  GL_RENDERBUFFER_BINDING_EXT* = 0x8CA7
  GL_MATRIX25_ARB* = 0x88D9
  GL_OUTPUT_TEXTURE_COORD19_EXT* = 0x87B0
  GL_NORMAL_MAP* = 0x8511
  GL_GPU_ADDRESS_NV* = 0x8F34
  GL_STREAM_READ* = 0x88E1
  GL_MIRRORED_REPEAT* = 0x8370
  GL_TEXTURE_SWIZZLE_RGBA* = 0x8E46
  GL_HALF_BIAS_NORMAL_NV* = 0x853A
  GL_STENCIL_BACK_OP_VALUE_AMD* = 0x874D
  GL_TEXTURE_BLUE_TYPE_ARB* = 0x8C12
  GL_MODELVIEW_PROJECTION_NV* = 0x8629
  GL_ACTIVE_UNIFORM_MAX_LENGTH* = 0x8B87
  GL_TEXTURE_SWIZZLE_RGBA_EXT* = 0x8E46
  GL_TEXTURE_GEN_T* = 0x0C61
  GL_HILO16_NV* = 0x86F8
  GL_CURRENT_QUERY_EXT* = 0x8865
  GL_FLOAT16_VEC2_NV* = 0x8FF9
  GL_RGBA_FLOAT_MODE_ARB* = 0x8820
  GL_POINT_SIZE_ARRAY_TYPE_OES* = 0x898A
  GL_GENERATE_MIPMAP_HINT* = 0x8192
  GL_1PASS_EXT* = 0x80A1
  GL_SWIZZLE_STQ_DQ_ATI* = 0x8979
  GL_VERTICAL_LINE_TO_NV* = 0x08
  GL_MINMAX* = 0x802E
  GL_RENDERBUFFER_ALPHA_SIZE_EXT* = 0x8D53
  GL_DEPTH_COMPONENT32F* = 0x8CAC
  GL_NEXT_VIDEO_CAPTURE_BUFFER_STATUS_NV* = 0x9025
  GL_CLIP_PLANE5_IMG* = 0x3005
  GL_TEXTURE_2D_MULTISAMPLE* = 0x9100
  GL_PREVIOUS* = 0x8578
  GL_CULL_MODES_NV* = 0x86E0
  GL_TRACE_ARRAYS_BIT_MESA* = 0x0004
  GL_MAX_ACTIVE_LIGHTS_SGIX* = 0x8405
  GL_PRIMITIVE_ID_NV* = 0x8C7C
  GL_DEPTH_COMPONENT16* = 0x81A5
  GL_FRAMEBUFFER_ATTACHMENT_LAYERED* = 0x8DA7
  GL_MAX_FRAGMENT_UNIFORM_BLOCKS* = 0x8A2D
  GL_OUTPUT_COLOR0_EXT* = 0x879B
  GL_RGBA16F_EXT* = 0x881A
  GL_MAX_PALETTE_MATRICES_OES* = 0x8842
  GL_VIEW_CLASS_64_BITS* = 0x82C6
  GL_TRACE_ALL_BITS_MESA* = 0xFFFF
  GL_REPLACE_VALUE_AMD* = 0x874B
  GL_PROXY_POST_IMAGE_TRANSFORM_COLOR_TABLE_HP* = 0x8163
  GL_BGR_INTEGER* = 0x8D9A
  GL_MAX_DEBUG_LOGGED_MESSAGES_ARB* = 0x9144
  GL_FOG_COLOR* = 0x0B66
  GL_MAX_MULTIVIEW_BUFFERS_EXT* = 0x90F2
  GL_TRANSFORM_FEEDBACK_BUFFER* = 0x8C8E
  GL_E_TIMES_F_NV* = 0x8531
  GL_COLOR_TABLE_WIDTH_SGI* = 0x80D9
  GL_VERTEX_ATTRIB_ARRAY_SIZE* = 0x8623
  GL_422_REV_AVERAGE_EXT* = 0x80CF
  GL_WRITE_DISCARD_NV* = 0x88BE
  GL_DRAW_BUFFER0_EXT* = 0x8825
  GL_FONT_HEIGHT_BIT_NV* = 0x00800000
  GL_INTERLACE_OML* = 0x8980
  GL_FUNC_REVERSE_SUBTRACT_EXT* = 0x800B
  GL_MAX_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x87C8
  GL_PRIMARY_COLOR* = 0x8577
  GL_RGBA16I* = 0x8D88
  GL_TEXTURE6* = 0x84C6
  GL_PATH_FILL_BOUNDING_BOX_NV* = 0x90A1
  GL_WEIGHT_ARRAY_BUFFER_BINDING* = 0x889E
  GL_COLOR_CLEAR_UNCLAMPED_VALUE_ATI* = 0x8835
  GL_YCRCB_422_SGIX* = 0x81BB
  GL_RGB5_A1* = 0x8057
  GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT* = 0x8211
  GL_DRAW_FRAMEBUFFER_BINDING_EXT* = 0x8CA6
  GL_TEXTURE_1D_ARRAY* = 0x8C18
  GL_CLAMP_FRAGMENT_COLOR_ARB* = 0x891B
  GL_FULL_RANGE_EXT* = 0x87E1
  GL_GEOMETRY_PROGRAM_PARAMETER_BUFFER_NV* = 0x8DA3
  GL_CON_24_ATI* = 0x8959
  GL_2D* = 0x0600
  GL_DRAW_BUFFER5_NV* = 0x882A
  GL_PALETTE4_RGBA8_OES* = 0x8B91
  GL_READ_ONLY_ARB* = 0x88B8
  GL_NUM_SAMPLE_COUNTS* = 0x9380
  GL_MATRIX_STRIDE* = 0x92FF
  GL_HISTOGRAM_RED_SIZE* = 0x8028
  GL_COLOR_ATTACHMENT4* = 0x8CE4
  GL_PATH_INITIAL_END_CAP_NV* = 0x9077
  GL_TEXTURE_USAGE_ANGLE* = 0x93A2
  GL_DOUBLE_MAT2* = 0x8F46
  GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE* = 0x8212
  GL_SECONDARY_COLOR_ARRAY_POINTER* = 0x845D
  GL_MAX_VIEWPORTS* = 0x825B
  GL_TRANSFORM_FEEDBACK_BUFFER_EXT* = 0x8C8E
  GL_FRAMEBUFFER_SRGB_EXT* = 0x8DB9
  GL_STORAGE_SHARED_APPLE* = 0x85BF
  GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH* = 0x8C76
  GL_TRANSFORM_FEEDBACK_NV* = 0x8E22
  GL_MIRRORED_REPEAT_ARB* = 0x8370
  GL_MAX_VERTEX_OUTPUT_COMPONENTS* = 0x9122
  GL_BUFFER_MAP_LENGTH* = 0x9120
  GL_BUFFER_OBJECT_APPLE* = 0x85B3
  GL_INT_VEC4_ARB* = 0x8B55
  GL_COMBINER3_NV* = 0x8553
  GL_INT16_VEC3_NV* = 0x8FE6
  GL_MAX_3D_TEXTURE_SIZE_EXT* = 0x8073
  GL_GENERATE_MIPMAP_HINT_SGIS* = 0x8192
  GL_SRC0_ALPHA* = 0x8588
  GL_IMAGE_2D* = 0x904D
  GL_VIEW_CLASS_S3TC_DXT1_RGB* = 0x82CC
  GL_DOT3_RGBA* = 0x86AF
  GL_TEXTURE_GREEN_SIZE* = 0x805D
  GL_DOUBLE_MAT2x3* = 0x8F49
  GL_COORD_REPLACE_OES* = 0x8862
  GL_MAX_DEBUG_MESSAGE_LENGTH_ARB* = 0x9143
  GL_TEXTURE_IMMUTABLE_FORMAT_EXT* = 0x912F
  GL_INDEX_ARRAY_POINTER_EXT* = 0x8091
  GL_NUM_SHADING_LANGUAGE_VERSIONS* = 0x82E9
  GL_DEBUG_CALLBACK_FUNCTION_ARB* = 0x8244
  GL_OFFSET_TEXTURE_MATRIX_NV* = 0x86E1
  GL_INTENSITY32I_EXT* = 0x8D85
  GL_BUMP_TEX_UNITS_ATI* = 0x8778
  GL_RENDERBUFFER* = 0x8D41
  GL_UPPER_LEFT* = 0x8CA2
  GL_GUILTY_CONTEXT_RESET_ARB* = 0x8253
  GL_MAP2_GRID_SEGMENTS* = 0x0DD3
  GL_REG_23_ATI* = 0x8938
  GL_UNSIGNED_INT16_NV* = 0x8FF0
  GL_TEXTURE_COORD_ARRAY_LIST_STRIDE_IBM* = 103084
  GL_INVARIANT_VALUE_EXT* = 0x87EA
  GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN_NV* = 0x8C88
  GL_TEXTURE2_ARB* = 0x84C2
  GL_UNSIGNED_INT_SAMPLER_2D_ARRAY_EXT* = 0x8DD7
  GL_IMAGE_CUBE* = 0x9050
  GL_MAX_PROGRAM_MATRICES_ARB* = 0x862F
  GL_SIGNED_LUMINANCE8_ALPHA8_NV* = 0x8704
  GL_INDEX_ARRAY_LIST_IBM* = 103073
  GL_EVAL_VERTEX_ATTRIB5_NV* = 0x86CB
  GL_SHADER_SOURCE_LENGTH* = 0x8B88
  GL_TEXTURE4* = 0x84C4
  GL_VERTEX_ATTRIB_ARRAY6_NV* = 0x8656
  GL_PROXY_TEXTURE_1D_STACK_MESAX* = 0x875B
  GL_MAP_ATTRIB_V_ORDER_NV* = 0x86C4
  GL_DSDT_NV* = 0x86F5
  GL_DEBUG_SEVERITY_NOTIFICATION_KHR* = 0x826B
  GL_FOG_COORDINATE_ARRAY_LIST_STRIDE_IBM* = 103086
  GL_COMPRESSED_RGBA_ASTC_8x6_KHR* = 0x93B6
  GL_LINEAR_ATTENUATION* = 0x1208
  GL_Z4Y12Z4CB12Z4Y12Z4CR12_422_NV* = 0x9035
  GL_CONVOLUTION_FILTER_BIAS* = 0x8015
  GL_IMAGE_MIN_FILTER_HP* = 0x815D
  GL_EYE_RADIAL_NV* = 0x855B
  GL_TEXTURE_MIN_LOD_SGIS* = 0x813A
  GL_TRANSFORM_FEEDBACK_BUFFER_BINDING_NV* = 0x8C8F
  GL_TRANSLATE_2D_NV* = 0x9090
  GL_CONSTANT_ARB* = 0x8576
  GL_FLOAT_MAT2x3* = 0x8B65
  GL_MULTISAMPLE_COVERAGE_MODES_NV* = 0x8E12
  GL_TRANSPOSE_COLOR_MATRIX* = 0x84E6
  GL_PROGRAM_STRING_NV* = 0x8628
  GL_UNSIGNED_INT_SAMPLER_1D_EXT* = 0x8DD1
  GL_BLEND_SRC_ALPHA_OES* = 0x80CB
  GL_RGB32F_EXT* = 0x8815
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_EXT* = 0x8CD4
  GL_RESTART_PATH_NV* = 0xF0
  GL_MAP2_VERTEX_ATTRIB11_4_NV* = 0x867B
  GL_VIEW_CLASS_16_BITS* = 0x82CA
  GL_BUFFER_DATA_SIZE* = 0x9303
  GL_BUFFER_FLUSHING_UNMAP_APPLE* = 0x8A13
  GL_RELATIVE_VERTICAL_LINE_TO_NV* = 0x09
  GL_SRGB_WRITE* = 0x8298
  GL_TEXTURE_LUMINANCE_SIZE_EXT* = 0x8060
  GL_VERTEX_PRECLIP_SGIX* = 0x83EE
  GL_LINEAR_DETAIL_COLOR_SGIS* = 0x8099
  GL_SOURCE2_ALPHA_ARB* = 0x858A
  GL_PATH_FOG_GEN_MODE_NV* = 0x90AC
  GL_RGB10_A2UI* = 0x906F
  GL_MULTISAMPLE_BIT_3DFX* = 0x20000000
  GL_PIXEL_MAP_G_TO_G_SIZE* = 0x0CB7
  GL_COVERAGE_BUFFER_BIT_NV* = 0x00008000
  GL_TEXTURE_COMPRESSED* = 0x86A1
  GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER* = 0x92CA
  GL_NAMED_STRING_TYPE_ARB* = 0x8DEA
  GL_RESCALE_NORMAL* = 0x803A
  GL_OUTPUT_TEXTURE_COORD3_EXT* = 0x87A0
  GL_RENDERBUFFER_EXT* = 0x8D41
  GL_QUERY_NO_WAIT* = 0x8E14
  GL_SAMPLE_ALPHA_TO_COVERAGE* = 0x809E
  GL_RG8UI* = 0x8238
  GL_MATRIX3_NV* = 0x8633
  GL_SAMPLE_BUFFERS_ARB* = 0x80A8
  GL_VERTEX_CONSISTENT_HINT_PGI* = 0x1A22B
  GL_SPRITE_AXIAL_SGIX* = 0x814C
  GL_MODELVIEW_MATRIX* = 0x0BA6
  GL_SAMPLE_PATTERN_SGIS* = 0x80AC
  GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE* = 0x906B
  GL_FLOAT_RG16_NV* = 0x8886
  GL_IMAGE_TRANSLATE_X_HP* = 0x8157
  GL_FRAMEBUFFER_SRGB* = 0x8DB9
  GL_DRAW_BUFFER7* = 0x882C
  GL_CONVOLUTION_BORDER_COLOR* = 0x8154
  GL_DRAW_BUFFER5* = 0x882A
  GL_GEOMETRY_INPUT_TYPE_EXT* = 0x8DDB
  GL_IUI_V2F_EXT* = 0x81AD
  GL_FLOAT_RG_NV* = 0x8881
  GL_VERTEX_SHADER_INVARIANTS_EXT* = 0x87D1
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_NV* = 0x8C4D
  GL_MAX_PROGRAM_MATRIX_STACK_DEPTH_ARB* = 0x862E
  GL_SAMPLE_PATTERN_EXT* = 0x80AC
  GL_DIFFERENCE_NV* = 0x929E
  GL_POST_CONVOLUTION_ALPHA_BIAS_EXT* = 0x8023
  GL_COLOR_ATTACHMENT1_EXT* = 0x8CE1
  GL_TEXTURE_ALPHA_MODULATE_IMG* = 0x8C06
  GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED_NV* = 0x8E23
  GL_MAX_TEXTURE_IMAGE_UNITS_ARB* = 0x8872
  GL_FIXED_OES* = 0x140C
  GL_ALREADY_SIGNALED_APPLE* = 0x911A
  GL_SET* = 0x150F
  GL_PERFMON_RESULT_AMD* = 0x8BC6
  GL_VARIABLE_G_NV* = 0x8529
  GL_DRAW_FRAMEBUFFER_ANGLE* = 0x8CA9
  GL_GEOMETRY_SUBROUTINE_UNIFORM* = 0x92F1
  GL_COMPARE_REF_DEPTH_TO_TEXTURE_EXT* = 0x884E
  GL_POINT* = 0x1B00
  GL_FONT_MAX_ADVANCE_WIDTH_BIT_NV* = 0x01000000
  GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS* = 0x90CB
  GL_PLUS_CLAMPED_ALPHA_NV* = 0x92B2
  GL_DRAW_BUFFER3_ATI* = 0x8828
  GL_LUMINANCE_ALPHA16I_EXT* = 0x8D8D
  GL_SUBPIXEL_BITS* = 0x0D50
  GL_POINT_SPRITE* = 0x8861
  GL_DRAW_BUFFER0* = 0x8825
  GL_DEPTH_BIAS* = 0x0D1F
  GL_COLOR_ARRAY_TYPE* = 0x8082
  GL_DEPENDENT_GB_TEXTURE_2D_NV* = 0x86EA
  GL_MAX_SAMPLES_ANGLE* = 0x8D57
  GL_ALLOW_DRAW_MEM_HINT_PGI* = 0x1A211
  GL_GEOMETRY_OUTPUT_TYPE* = 0x8918
  GL_MAX_DEBUG_LOGGED_MESSAGES_KHR* = 0x9144
  GL_VERTEX_ATTRIB_ARRAY0_NV* = 0x8650
  GL_PRIMITIVES_GENERATED_EXT* = 0x8C87
  GL_TEXTURE_FLOAT_COMPONENTS_NV* = 0x888C
  GL_CLIP_VOLUME_CLIPPING_HINT_EXT* = 0x80F0
  GL_FRAGMENT_PROGRAM_POSITION_MESA* = 0x8BB0
  GL_MAX_FRAGMENT_IMAGE_UNIFORMS* = 0x90CE
  GL_VERTEX_ARRAY_BINDING_APPLE* = 0x85B5
  GL_SHADER_GLOBAL_ACCESS_BARRIER_BIT_NV* = 0x00000010
  GL_FIRST_VERTEX_CONVENTION* = 0x8E4D
  GL_DECR_WRAP* = 0x8508
  GL_IMAGE_CLASS_1_X_32* = 0x82BB
  GL_MAX_CLIP_PLANES_IMG* = 0x0D32
  GL_MAX_VARYING_COMPONENTS* = 0x8B4B
  GL_POST_COLOR_MATRIX_RED_BIAS_SGI* = 0x80B8
  GL_DSDT_MAG_NV* = 0x86F6
  GL_DEBUG_SOURCE_APPLICATION* = 0x824A
  GL_OPERAND0_RGB_ARB* = 0x8590
  GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE* = 0x82AE
  GL_VIDEO_COLOR_CONVERSION_MATRIX_NV* = 0x9029
  GL_MAP2_VERTEX_ATTRIB13_4_NV* = 0x867D
  GL_DOT2_ADD_ATI* = 0x896C
  GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS* = 0x8A33
  GL_IMAGE_BINDING_LAYER_EXT* = 0x8F3D
  GL_FRAGMENT_COLOR_MATERIAL_FACE_SGIX* = 0x8402
  GL_PACK_IMAGE_DEPTH_SGIS* = 0x8131
  GL_MAX_GEOMETRY_UNIFORM_COMPONENTS_EXT* = 0x8DDF
  GL_Z_EXT* = 0x87D7
  GL_MAP1_VERTEX_ATTRIB15_4_NV* = 0x866F
  GL_RG8_SNORM* = 0x8F95
  GL_OUTPUT_TEXTURE_COORD5_EXT* = 0x87A2
  GL_TEXTURE_BINDING_1D_ARRAY_EXT* = 0x8C1C
  GL_OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB* = 0x8B87
  GL_PATH_END_CAPS_NV* = 0x9076
  GL_COLOR_TABLE_GREEN_SIZE* = 0x80DB
  GL_MAX_ELEMENTS_INDICES_EXT* = 0x80E9
  GL_TEXTURE_IMMUTABLE_FORMAT* = 0x912F
  GL_WRITE_ONLY_ARB* = 0x88B9
  GL_COLOR_ATTACHMENT10_EXT* = 0x8CEA
  GL_INVERT_RGB_NV* = 0x92A3
  GL_CURRENT_RASTER_DISTANCE* = 0x0B09
  GL_DEPTH_STENCIL_TO_RGBA_NV* = 0x886E
  GL_INVERTED_SCREEN_W_REND* = 0x8491
  GL_TABLE_TOO_LARGE* = 0x8031
  GL_REG_16_ATI* = 0x8931
  GL_BLEND_EQUATION_ALPHA_OES* = 0x883D
  GL_DRAW_FRAMEBUFFER_BINDING_NV* = 0x8CA6
  GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS* = 0x8E47
  GL_TEXTURE_BLUE_SIZE_EXT* = 0x805E
  GL_TEXTURE_BORDER_VALUES_NV* = 0x871A
  GL_PROGRAM_LENGTH_ARB* = 0x8627
  GL_BOUNDING_BOX_OF_BOUNDING_BOXES_NV* = 0x909C
  GL_DOT_PRODUCT_NV* = 0x86EC
  GL_TRANSPOSE_PROJECTION_MATRIX_ARB* = 0x84E4
  GL_TEXTURE_2D_MULTISAMPLE_ARRAY* = 0x9102
  GL_MIN_PROGRAM_TEXEL_OFFSET_NV* = 0x8904
  GL_MAP2_BINORMAL_EXT* = 0x8447
  GL_COLOR_ARRAY_BUFFER_BINDING* = 0x8898
  GL_TEXTURE_COORD_ARRAY_POINTER* = 0x8092
  GL_TEXTURE4_ARB* = 0x84C4
  GL_VARIABLE_A_NV* = 0x8523
  GL_CURRENT_FOG_COORDINATE_EXT* = 0x8453
  GL_TEXTURE_CUBE_MAP_POSITIVE_X* = 0x8515
  GL_DEPENDENT_AR_TEXTURE_2D_NV* = 0x86E9
  GL_TEXTURE29_ARB* = 0x84DD
  GL_INVERSE_TRANSPOSE_NV* = 0x862D
  GL_TEXTURE_COLOR_WRITEMASK_SGIS* = 0x81EF
  GL_HISTOGRAM_SINK* = 0x802D
  GL_ALPHA12_EXT* = 0x803D
  GL_TEXTURE_CLIPMAP_LOD_OFFSET_SGIX* = 0x8175
  GL_DSDT_MAG_INTENSITY_NV* = 0x86DC
  GL_ATC_RGB_AMD* = 0x8C92
  GL_PROGRAM_ATTRIB_COMPONENTS_NV* = 0x8906
  GL_UNIFORM_BLOCK_BINDING* = 0x8A3F
  GL_POLYGON_STIPPLE* = 0x0B42
  GL_BACK* = 0x0405
  GL_DEPTH_COMPONENT16_NONLINEAR_NV* = 0x8E2C
  GL_ALPHA32F_EXT* = 0x8816
  GL_CLAMP_TO_BORDER* = 0x812D
  GL_FLOAT_RGBA16_NV* = 0x888A
  GL_VERTEX_ARRAY_RANGE_LENGTH_NV* = 0x851E
  GL_UNSIGNED_INT_SAMPLER_RENDERBUFFER_NV* = 0x8E58
  GL_SAMPLER_2D* = 0x8B5E
  GL_SMOOTH_POINT_SIZE_RANGE* = 0x0B12
  GL_DEPTH_PASS_INSTRUMENT_MAX_SGIX* = 0x8312
  GL_INTERPOLATE_ARB* = 0x8575
  GL_VERTEX_ARRAY_LENGTH_NV* = 0x8F2B
  GL_FUNC_SUBTRACT_EXT* = 0x800A
  GL_OUTPUT_TEXTURE_COORD14_EXT* = 0x87AB
  GL_HISTOGRAM_SINK_EXT* = 0x802D
  GL_RG_EXT* = 0x8227
  GL_SHARPEN_TEXTURE_FUNC_POINTS_SGIS* = 0x80B0
  GL_COLOR_TABLE_SCALE* = 0x80D6
  GL_CURRENT_RASTER_TEXTURE_COORDS* = 0x0B06
  GL_PIXEL_BUFFER_BARRIER_BIT* = 0x00000080
  GL_SHADING_LANGUAGE_VERSION* = 0x8B8C
  GL_TEXTURE_MATRIX_FLOAT_AS_INT_BITS_OES* = 0x898F
  GL_DUAL_LUMINANCE_ALPHA4_SGIS* = 0x811C
  GL_CLAMP* = 0x2900
  GL_4PASS_2_EXT* = 0x80A6
  GL_POLYGON_OFFSET_LINE* = 0x2A02
  GL_LOGIC_OP* = 0x0BF1
  GL_RENDERBUFFER_HEIGHT* = 0x8D43
  GL_COPY_INVERTED* = 0x150C
  GL_NONE* = 0
  GL_COLOR_ENCODING* = 0x8296
  GL_ONE_MINUS_CONSTANT_ALPHA_EXT* = 0x8004
  GL_DEBUG_TYPE_ERROR_KHR* = 0x824C
  GL_PIXEL_TILE_GRID_WIDTH_SGIX* = 0x8142
  GL_UNIFORM_SIZE* = 0x8A38
  GL_VERTEX_SHADER_BINDING_EXT* = 0x8781
  GL_BLEND_DST_RGB_EXT* = 0x80C8
  GL_QUADS* = 0x0007
  cGL_INT* = 0x1404
  GL_PIXEL_TEX_GEN_MODE_SGIX* = 0x832B
  GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB* = 0x8E8F
  GL_SAMPLE_ALPHA_TO_ONE_ARB* = 0x809F
  GL_RGBA32F_EXT* = 0x8814
  GL_VERTEX_PROGRAM_POSITION_MESA* = 0x8BB4
  GL_GEOMETRY_SUBROUTINE* = 0x92EB
  GL_UNSIGNED_INT_SAMPLER_1D_ARRAY_EXT* = 0x8DD6
  GL_IMAGE_BINDING_LAYER* = 0x8F3D
  GL_PIXEL_PACK_BUFFER_ARB* = 0x88EB
  GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x84F1
  GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB* = 0x8623
  GL_ALPHA8UI_EXT* = 0x8D7E
  GL_RELATIVE_SMOOTH_CUBIC_CURVE_TO_NV* = 0x11
  GL_CAVEAT_SUPPORT* = 0x82B8
  GL_ACCUM* = 0x0100
  GL_DRAW_BUFFER3_NV* = 0x8828
  GL_DEBUG_TYPE_OTHER_KHR* = 0x8251
  GL_TESS_GEN_SPACING* = 0x8E77
  GL_FLOAT_MAT4x2* = 0x8B69
  GL_TEXTURE_GEN_STR_OES* = 0x8D60
  GL_NUM_COMPATIBLE_SUBROUTINES* = 0x8E4A
  GL_CLIP_DISTANCE1* = 0x3001
  GL_DEPTH_COMPONENT32_SGIX* = 0x81A7
  GL_FRAMEZOOM_SGIX* = 0x818B
  GL_COLOR_ATTACHMENT14_EXT* = 0x8CEE
  GL_POLYGON_TOKEN* = 0x0703
  GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE* = 0x8213
  GL_DRAW_BUFFER2_EXT* = 0x8827
  GL_MATRIX_INDEX_ARRAY_TYPE_OES* = 0x8847
  GL_HISTOGRAM_LUMINANCE_SIZE_EXT* = 0x802C
  GL_DEPTH_BOUNDS_EXT* = 0x8891
  GL_TEXTURE24* = 0x84D8
  GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES* = 0x8A43
  GL_MAX_PATCH_VERTICES* = 0x8E7D
  GL_COMPILE_STATUS* = 0x8B81
  GL_MODELVIEW4_ARB* = 0x8724
  GL_SHADER_BINARY_VIV* = 0x8FC4
  GL_CON_10_ATI* = 0x894B
  GL_FRAGMENT_LIGHT5_SGIX* = 0x8411
  GL_CONVOLUTION_1D_EXT* = 0x8010
  GL_CONSTANT_BORDER_HP* = 0x8151
  GL_SAMPLE_BUFFERS* = 0x80A8
  GL_RGB8UI* = 0x8D7D
  GL_FRAGMENT_MATERIAL_EXT* = 0x8349
  GL_OP_RECIP_EXT* = 0x8794
  GL_SHADER_OPERATION_NV* = 0x86DF
  GL_COMPUTE_SUBROUTINE_UNIFORM* = 0x92F3
  GL_VIDEO_BUFFER_PITCH_NV* = 0x9028
  GL_UNKNOWN_CONTEXT_RESET_ARB* = 0x8255
  GL_COLOR_ATTACHMENT3_EXT* = 0x8CE3
  GL_QUERY_WAIT* = 0x8E13
  GL_SOURCE1_RGB* = 0x8581
  GL_DELETE_STATUS* = 0x8B80
  GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_ARB* = 0x8243
  GL_HILO8_NV* = 0x885E
  GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x906A
  GL_LUMINANCE_ALPHA_FLOAT16_APPLE* = 0x881F
  GL_LUMINANCE16_SNORM* = 0x9019
  GL_MAX_CLIPMAP_VIRTUAL_DEPTH_SGIX* = 0x8178
  GL_RENDER* = 0x1C00
  GL_RED_INTEGER* = 0x8D94
  GL_DEBUG_TYPE_ERROR_ARB* = 0x824C
  GL_IMAGE_BINDING_ACCESS* = 0x8F3E
  GL_COVERAGE_COMPONENT_NV* = 0x8ED0
  GL_TEXTURE_BINDING_BUFFER_EXT* = 0x8C2C
  GL_MAX_PROGRAM_PATCH_ATTRIBS_NV* = 0x86D8
  GL_DUAL_LUMINANCE12_SGIS* = 0x8116
  GL_QUAD_ALPHA8_SGIS* = 0x811F
  GL_COMPRESSED_RED_GREEN_RGTC2_EXT* = 0x8DBD
  GL_PACK_INVERT_MESA* = 0x8758
  GL_OUTPUT_TEXTURE_COORD11_EXT* = 0x87A8
  GL_DYNAMIC_DRAW_ARB* = 0x88E8
  GL_RGB565_OES* = 0x8D62
  GL_LINE* = 0x1B01
  GL_T2F_V3F* = 0x2A27
  GL_DIFFUSE* = 0x1201
  GL_FOG_COORDINATE_SOURCE* = 0x8450
  GL_TEXTURE_1D_ARRAY_EXT* = 0x8C18
  GL_TEXTURE_RECTANGLE_NV* = 0x84F5
  GL_STENCIL_INDEX4_EXT* = 0x8D47
  GL_VERTEX_PROGRAM_TWO_SIDE* = 0x8643
  GL_REDUCE* = 0x8016
  GL_DEBUG_CALLBACK_USER_PARAM_KHR* = 0x8245
  GL_DEBUG_LOGGED_MESSAGES_AMD* = 0x9145
  GL_FONT_UNITS_PER_EM_BIT_NV* = 0x00100000
  GL_INVALID_FRAMEBUFFER_OPERATION_EXT* = 0x0506
  GL_NORMAL_ARRAY_BUFFER_BINDING_ARB* = 0x8897
  GL_SAMPLE_MASK_INVERT_SGIS* = 0x80AB
  GL_MAX_SHADER_BUFFER_ADDRESS_NV* = 0x8F35
  GL_PIXEL_MAP_I_TO_A* = 0x0C75
  GL_MINOR_VERSION* = 0x821C
  GL_TEXTURE_BUFFER_EXT* = 0x8C2A
  GL_SKIP_COMPONENTS4_NV* = -3
  GL_FLOAT16_NV* = 0x8FF8
  GL_FEEDBACK_BUFFER_TYPE* = 0x0DF2
  GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT* = 0x8C72
  GL_REG_6_ATI* = 0x8927
  GL_EDGE_FLAG_ARRAY_LIST_IBM* = 103075
  GL_MATRIX26_ARB* = 0x88DA
  GL_ALPHA16* = 0x803E
  GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME* = 0x8CD1
  GL_HISTOGRAM_ALPHA_SIZE* = 0x802B
  GL_COLOR_MATRIX_STACK_DEPTH* = 0x80B2
  GL_INTERNALFORMAT_GREEN_TYPE* = 0x8279
  GL_YCRCBA_SGIX* = 0x8319
  GL_VIEW_CLASS_48_BITS* = 0x82C7
  GL_VERTEX_ATTRIB_ARRAY3_NV* = 0x8653
  GL_CLIENT_STORAGE_BIT* = 0x0200
  GL_MIN_SAMPLE_SHADING_VALUE_ARB* = 0x8C37
  GL_PROXY_TEXTURE_CUBE_MAP* = 0x851B
  GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES* = 0x8F39
  GL_TEXTURE15* = 0x84CF
  GL_COLOR* = 0x1800
  GL_LIGHT1* = 0x4001
  GL_LUMINANCE_ALPHA16F_EXT* = 0x881F
  GL_TEXTURE_VIEW_NUM_LAYERS* = 0x82DE
  GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS* = 0x8E82
  GL_INTERLEAVED_ATTRIBS_NV* = 0x8C8C
  GL_INT_SAMPLER_BUFFER_EXT* = 0x8DD0
  GL_EVAL_VERTEX_ATTRIB14_NV* = 0x86D4
  GL_FRAGMENT_PROGRAM_CALLBACK_MESA* = 0x8BB1
  GL_EMISSION* = 0x1600
  GL_WEIGHT_ARRAY_STRIDE_ARB* = 0x86AA
  GL_ACTIVE_VARIABLES* = 0x9305
  GL_TIMEOUT_IGNORED* = 0xFFFFFFFFFFFFFFFF
  GL_VERTEX_STREAM5_ATI* = 0x8771
  GL_INDEX_ARRAY_POINTER* = 0x8091
  GL_POST_COLOR_MATRIX_ALPHA_SCALE* = 0x80B7
  GL_TESS_CONTROL_SHADER* = 0x8E88
  GL_POLYGON_MODE* = 0x0B40
  GL_ASYNC_DRAW_PIXELS_SGIX* = 0x835D
  GL_RGBA16_SNORM* = 0x8F9B
  GL_TEXTURE_NORMAL_EXT* = 0x85AF
  GL_REG_22_ATI* = 0x8937
  GL_FRAMEBUFFER_DEFAULT_WIDTH* = 0x9310
  GL_TEXCOORD1_BIT_PGI* = 0x10000000
  GL_REFERENCE_PLANE_EQUATION_SGIX* = 0x817E
  GL_COLOR_ALPHA_PAIRING_ATI* = 0x8975
  GL_SINGLE_COLOR* = 0x81F9
  GL_MODELVIEW21_ARB* = 0x8735
  GL_FORMAT_SUBSAMPLE_24_24_OML* = 0x8982
  GL_SOURCE1_ALPHA* = 0x8589
  GL_LINEARLIGHT_NV* = 0x92A7
  GL_REG_2_ATI* = 0x8923
  GL_QUERY_RESULT_AVAILABLE* = 0x8867
  GL_PERSPECTIVE_CORRECTION_HINT* = 0x0C50
  GL_COMBINE_ALPHA_ARB* = 0x8572
  GL_HISTOGRAM_ALPHA_SIZE_EXT* = 0x802B
  GL_SIGNED_RGB8_NV* = 0x86FF
  GL_DEPTH_TEXTURE_MODE_ARB* = 0x884B
  GL_PRESENT_DURATION_NV* = 0x8E2B
  GL_TRIANGLES_ADJACENCY_ARB* = 0x000C
  GL_TEXTURE_BUFFER_OFFSET* = 0x919D
  GL_PROGRAM_STRING_ARB* = 0x8628
  GL_UNSIGNED_INT_IMAGE_1D_EXT* = 0x9062
  GL_COLOR_ATTACHMENT2* = 0x8CE2
  GL_DOT_PRODUCT_TEXTURE_2D_NV* = 0x86EE
  GL_QUERY_BUFFER* = 0x9192
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z* = 0x851A
  GL_PIXEL_TEX_GEN_ALPHA_REPLACE_SGIX* = 0x8187
  GL_FULL_SUPPORT* = 0x82B7
  GL_MAX_PROGRAM_ENV_PARAMETERS_ARB* = 0x88B5
  GL_MAX_COMPUTE_WORK_GROUP_COUNT* = 0x91BE
  GL_DEBUG_TYPE_PERFORMANCE* = 0x8250
  GL_DRAW_BUFFER12_EXT* = 0x8831
  GL_UNSIGNED_INT_SAMPLER_BUFFER_AMD* = 0x9003
  GL_CURRENT_FOG_COORDINATE* = 0x8453
  GL_INTENSITY_EXT* = 0x8049
  GL_TRANSPOSE_NV* = 0x862C
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_NV* = 0x8C4F
  GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS* = 0x8C80
  GL_COLOR_ARRAY_POINTER_EXT* = 0x8090
  GL_TEXTURE_BUFFER_DATA_STORE_BINDING_EXT* = 0x8C2D
  GL_GEOMETRY_VERTICES_OUT_ARB* = 0x8DDA
  GL_RELATIVE_SMOOTH_QUADRATIC_CURVE_TO_NV* = 0x0F
  GL_OP_INDEX_EXT* = 0x8782
  GL_REG_1_ATI* = 0x8922
  GL_OFFSET* = 0x92FC
  GL_PATH_COVER_DEPTH_FUNC_NV* = 0x90BF
  GL_UNPACK_COMPRESSED_BLOCK_DEPTH* = 0x9129
  GL_POLYGON_OFFSET_UNITS* = 0x2A00
  GL_INDEX_TEST_FUNC_EXT* = 0x81B6
  GL_POINT_SMOOTH* = 0x0B10
  GL_SCALEBIAS_HINT_SGIX* = 0x8322
  GL_COMPRESSED_RGBA_ASTC_5x4_KHR* = 0x93B1
  GL_SEPARATE_SPECULAR_COLOR* = 0x81FA
  GL_VERTEX_ATTRIB_ARRAY14_NV* = 0x865E
  GL_INTENSITY16_EXT* = 0x804D
  GL_R8_SNORM* = 0x8F94
  GL_DEBUG_LOGGED_MESSAGES* = 0x9145
  GL_ALPHA8I_EXT* = 0x8D90
  GL_OPERAND2_RGB* = 0x8592
  GL_EMBOSS_LIGHT_NV* = 0x855D
  GL_EDGE_FLAG_ARRAY_STRIDE_EXT* = 0x808C
  GL_VERTEX_ATTRIB_ARRAY_INTEGER_NV* = 0x88FD
  GL_NUM_LOOPBACK_COMPONENTS_ATI* = 0x8974
  GL_DEBUG_SOURCE_APPLICATION_KHR* = 0x824A
  GL_COMPRESSED_RGB_S3TC_DXT1_EXT* = 0x83F0
  GL_DEBUG_SOURCE_OTHER_ARB* = 0x824B
  cGL_DOUBLE* = 0x140A
  GL_STENCIL_TEST_TWO_SIDE_EXT* = 0x8910
  GL_MIN_PROGRAM_TEXEL_OFFSET* = 0x8904
  GL_3DC_X_AMD* = 0x87F9
  GL_FLOAT_RGB32_NV* = 0x8889
  GL_SECONDARY_COLOR_ARRAY_POINTER_EXT* = 0x845D
  GL_OPERAND2_ALPHA_ARB* = 0x859A
  GL_IMAGE_3D* = 0x904E
  GL_SECONDARY_COLOR_ARRAY_SIZE* = 0x845A
  GL_RELEASED_APPLE* = 0x8A19
  GL_RENDER_DIRECT_TO_FRAMEBUFFER_QCOM* = 0x8FB3
  GL_FRAMEBUFFER_DEFAULT_LAYERS* = 0x9312
  GL_INTENSITY* = 0x8049
  GL_RENDERBUFFER_BLUE_SIZE_OES* = 0x8D52
  GL_FLOAT_RGB_NV* = 0x8882
  GL_ARRAY_ELEMENT_LOCK_FIRST_EXT* = 0x81A8
  GL_CON_4_ATI* = 0x8945
  GL_ROUND_NV* = 0x90A4
  GL_CLIP_DISTANCE2* = 0x3002
  GL_MAX_PROGRAM_ALU_INSTRUCTIONS_ARB* = 0x880B
  GL_PROGRAM_ERROR_STRING_ARB* = 0x8874
  GL_STORAGE_CACHED_APPLE* = 0x85BE
  GL_LIGHTEN_NV* = 0x9298
  GL_TEXTURE23* = 0x84D7
  GL_SAMPLER_CUBE_SHADOW* = 0x8DC5
  GL_VERTEX_PROGRAM_ARB* = 0x8620
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT* = 0x8C4E
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB* = 0x851A
  GL_RENDERBUFFER_SAMPLES* = 0x8CAB
  GL_RENDERBUFFER_STENCIL_SIZE* = 0x8D55
  GL_VIRTUAL_PAGE_SIZE_INDEX_ARB* = 0x91A7
  GL_CLIP_PLANE5* = 0x3005
  GL_VERTEX_WEIGHT_ARRAY_POINTER_EXT* = 0x8510
  GL_COLOR_BUFFER_BIT5_QCOM* = 0x00000020
  GL_DOUBLE_MAT2x3_EXT* = 0x8F49
  GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS* = 0x8A42
  GL_COLOR_ATTACHMENT8_EXT* = 0x8CE8
  GL_UNIFORM_BUFFER_BINDING_EXT* = 0x8DEF
  GL_MATRIX8_ARB* = 0x88C8
  GL_COUNTER_TYPE_AMD* = 0x8BC0
  GL_INT8_VEC3_NV* = 0x8FE2
  GL_TEXTURE_BINDING_3D_OES* = 0x806A
  GL_DEPTH_PASS_INSTRUMENT_COUNTERS_SGIX* = 0x8311
  GL_IMAGE_BINDING_LEVEL* = 0x8F3B
  GL_STENCIL_BACK_FAIL_ATI* = 0x8801
  GL_TRANSFORM_FEEDBACK_ATTRIBS_NV* = 0x8C7E
  GL_COLOR_TABLE_INTENSITY_SIZE* = 0x80DF
  GL_TEXTURE_2D_BINDING_EXT* = 0x8069
  GL_CW* = 0x0900
  GL_COLOR_ATTACHMENT6* = 0x8CE6
  GL_R32UI* = 0x8236
  GL_PROXY_TEXTURE_3D* = 0x8070
  GL_FLOAT_VEC2_ARB* = 0x8B50
  GL_C3F_V3F* = 0x2A24
  GL_MAX_PROGRAM_PARAMETER_BUFFER_BINDINGS_NV* = 0x8DA0
  GL_EVAL_VERTEX_ATTRIB11_NV* = 0x86D1
  GL_MAX_VERTEX_ARRAY_RANGE_ELEMENT_NV* = 0x8520
  GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER_OES* = 0x8CDC
  GL_MAX_VIEWPORT_DIMS* = 0x0D3A
  GL_STENCIL_CLEAR_TAG_VALUE_EXT* = 0x88F3
  GL_TEXTURE_BUFFER_FORMAT_ARB* = 0x8C2E
  GL_PROGRAM_NATIVE_PARAMETERS_ARB* = 0x88AA
  GL_FLOAT_MAT3x2* = 0x8B67
  GL_BLUE_BIT_ATI* = 0x00000004
  GL_COLOR_ATTACHMENT6_NV* = 0x8CE6
  GL_AND_INVERTED* = 0x1504
  GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS* = 0x90D7
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR* = 0x93D0
  GL_PACK_COMPRESSED_BLOCK_DEPTH* = 0x912D
  GL_TEXTURE_COMPARE_SGIX* = 0x819A
  GL_SYNC_CL_EVENT_COMPLETE_ARB* = 0x8241
  GL_DEBUG_TYPE_PORTABILITY* = 0x824F
  GL_IMAGE_BINDING_FORMAT* = 0x906E
  GL_RESAMPLE_DECIMATE_OML* = 0x8989
  GL_MAX_PROGRAM_TEMPORARIES_ARB* = 0x88A5
  GL_ALL_SHADER_BITS* = 0xFFFFFFFF
  GL_TRANSFORM_FEEDBACK_VARYING* = 0x92F4
  GL_TRANSFORM_FEEDBACK_BUFFER_BINDING* = 0x8C8F
  GL_ACTIVE_STENCIL_FACE_EXT* = 0x8911
  GL_MAP1_VERTEX_ATTRIB4_4_NV* = 0x8664
  GL_LINK_STATUS* = 0x8B82
  GL_SYNC_FLUSH_COMMANDS_BIT* = 0x00000001
  GL_BLEND* = 0x0BE2
  GL_OUTPUT_TEXTURE_COORD12_EXT* = 0x87A9
  GL_DRAW_BUFFER11_ARB* = 0x8830
  GL_OBJECT_BUFFER_USAGE_ATI* = 0x8765
  GL_COLORDODGE_NV* = 0x9299
  GL_SHADER_IMAGE_LOAD* = 0x82A4
  GL_EMBOSS_CONSTANT_NV* = 0x855E
  GL_MAP_TESSELLATION_NV* = 0x86C2
  GL_MAX_DRAW_BUFFERS_EXT* = 0x8824
  GL_VERTEX_WEIGHT_ARRAY_TYPE_EXT* = 0x850E
  GL_TEXTURE_ENV_COLOR* = 0x2201
  GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER* = 0x8A46
  GL_DOT_PRODUCT_REFLECT_CUBE_MAP_NV* = 0x86F2
  GL_QUERY_KHR* = 0x82E3
  GL_RG* = 0x8227
  GL_MAX_TEXTURE_SIZE* = 0x0D33
  GL_TEXTURE_NUM_LEVELS_QCOM* = 0x8BD9
  GL_MAP2_VERTEX_ATTRIB3_4_NV* = 0x8673
  GL_LUMINANCE_FLOAT32_APPLE* = 0x8818
  GL_MAP2_VERTEX_ATTRIB7_4_NV* = 0x8677
  GL_GEOMETRY_SHADER_ARB* = 0x8DD9
  GL_SYNC_FENCE_APPLE* = 0x9116
  GL_SAMPLE_MASK_VALUE* = 0x8E52
  GL_PROXY_TEXTURE_RECTANGLE_NV* = 0x84F7
  GL_DEPTH_FUNC* = 0x0B74
  GL_S* = 0x2000
  GL_CONSTANT_COLOR_EXT* = 0x8001
  GL_MAX_PROGRAM_LOOP_COUNT_NV* = 0x88F8
  GL_VIEW_COMPATIBILITY_CLASS* = 0x82B6
  GL_INT_SAMPLER_BUFFER_AMD* = 0x9002
  GL_COMPRESSED_SRGB* = 0x8C48
  GL_PROGRAM_SEPARABLE_EXT* = 0x8258
  GL_FOG_FUNC_POINTS_SGIS* = 0x812B
  GL_MITER_TRUNCATE_NV* = 0x90A8
  GL_POLYGON_OFFSET_POINT* = 0x2A01
  GL_SRGB_READ* = 0x8297
  GL_INDEX_ARRAY_ADDRESS_NV* = 0x8F24
  GL_MAX_FRAMEBUFFER_WIDTH* = 0x9315
  GL_COMPRESSED_RED_RGTC1_EXT* = 0x8DBB
  GL_RGB_INTEGER_EXT* = 0x8D98
  GL_OP_NEGATE_EXT* = 0x8783
  GL_POINT_SIZE_MAX_ARB* = 0x8127
  GL_TEXTURE_DEFORMATION_BIT_SGIX* = 0x00000001
  GL_SIGNED_LUMINANCE8_NV* = 0x8702
  GL_OPERAND2_RGB_EXT* = 0x8592
  GL_MAX_PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT* = 0x8337
  GL_RECIP_ADD_SIGNED_ALPHA_IMG* = 0x8C05
  GL_VERTEX_STREAM7_ATI* = 0x8773
  GL_MODELVIEW1_STACK_DEPTH_EXT* = 0x8502
  GL_DYNAMIC_DRAW* = 0x88E8
  GL_DRAW_BUFFER15_EXT* = 0x8834
  GL_TEXTURE_COMPARE_OPERATOR_SGIX* = 0x819B
  GL_SQUARE_NV* = 0x90A3
  GL_COMPRESSED_SRGB_S3TC_DXT1_EXT* = 0x8C4C
  GL_DRAW_BUFFER0_ARB* = 0x8825
  GL_GPU_OPTIMIZED_QCOM* = 0x8FB2
  GL_VERTEX_WEIGHT_ARRAY_STRIDE_EXT* = 0x850F
  GL_SPRITE_EYE_ALIGNED_SGIX* = 0x814E
  GL_MAP1_VERTEX_ATTRIB3_4_NV* = 0x8663
  GL_SAMPLE_MASK_SGIS* = 0x80A0
  GL_TEXTURE_SAMPLES* = 0x9106
  GL_AND_REVERSE* = 0x1502
  GL_COMBINER4_NV* = 0x8554
  GL_FONT_Y_MIN_BOUNDS_BIT_NV* = 0x00020000
  GL_VIEW_CLASS_32_BITS* = 0x82C8
  GL_BGRA_EXT* = 0x80E1
  GL_TANGENT_ARRAY_TYPE_EXT* = 0x843E
  GL_BLEND_EQUATION_RGB_OES* = 0x8009
  GL_TRANSPOSE_TEXTURE_MATRIX_ARB* = 0x84E5
  GL_GET_TEXTURE_IMAGE_FORMAT* = 0x8291
  GL_PACK_MAX_COMPRESSED_SIZE_SGIX* = 0x831B
  GL_UNIFORM_ARRAY_STRIDE* = 0x8A3C
  GL_REFLECTION_MAP_ARB* = 0x8512
  GL_RGBA_FLOAT16_ATI* = 0x881A
  GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS* = 0x8E83
  GL_RED_BITS* = 0x0D52
  GL_VERTEX_TEXTURE* = 0x829B
  GL_UNSIGNALED_APPLE* = 0x9118
  GL_RENDERBUFFER_ALPHA_SIZE_OES* = 0x8D53
  GL_DRAW_BUFFER14_NV* = 0x8833
  GL_STREAM_COPY_ARB* = 0x88E2
  GL_SECONDARY_COLOR_ARRAY_TYPE* = 0x845B
  GL_MATRIX22_ARB* = 0x88D6
  GL_VERTEX_ARRAY_RANGE_WITHOUT_FLUSH_NV* = 0x8533
  GL_IUI_N3F_V3F_EXT* = 0x81B0
  GL_SPARE0_NV* = 0x852E
  GL_FOG_COORD* = 0x8451
  GL_DRAW_BUFFER8_ARB* = 0x882D
  GL_MATRIX24_ARB* = 0x88D8
  GL_MAX_DEBUG_MESSAGE_LENGTH_AMD* = 0x9143
  GL_POST_COLOR_MATRIX_BLUE_SCALE* = 0x80B6
  GL_TEXTURE_HEIGHT_QCOM* = 0x8BD3
  GL_NUM_FRAGMENT_REGISTERS_ATI* = 0x896E
  GL_IMAGE_3D_EXT* = 0x904E
  GL_TEXTURE_FILTER_CONTROL* = 0x8500
  GL_VIDEO_BUFFER_NV* = 0x9020
  GL_CURRENT_MATRIX_INDEX_ARB* = 0x8845
  GL_STENCIL_BUFFER_BIT4_QCOM* = 0x00100000
  GL_SIGNED_INTENSITY_NV* = 0x8707
  GL_RASTERIZER_DISCARD_NV* = 0x8C89
  GL_MAX_DEFORMATION_ORDER_SGIX* = 0x8197
  GL_SAMPLES_3DFX* = 0x86B4
  GL_DOT_PRODUCT_PASS_THROUGH_NV* = 0x885B
  GL_RGB_SCALE_EXT* = 0x8573
  GL_TEXTURE_UNSIGNED_REMAP_MODE_NV* = 0x888F
  GL_MIRROR_CLAMP_TO_EDGE_EXT* = 0x8743
  GL_NATIVE_GRAPHICS_END_HINT_PGI* = 0x1A204
  GL_UNPACK_CLIENT_STORAGE_APPLE* = 0x85B2
  GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER* = 0x8CDC
  GL_FOG_START* = 0x0B63
  GL_MAX_PROGRAM_CALL_DEPTH_NV* = 0x88F5
  GL_MODELVIEW18_ARB* = 0x8732
  GL_MAX_FRAMEZOOM_FACTOR_SGIX* = 0x818D
  GL_EDGE_FLAG_ARRAY_POINTER* = 0x8093
  GL_GREEN_INTEGER* = 0x8D95
  GL_IMAGE_BUFFER* = 0x9051
  GL_PROJECTION* = 0x1701
  GL_UNSIGNED_INT_VEC4_EXT* = 0x8DC8
  GL_PALETTE8_RGB5_A1_OES* = 0x8B99
  GL_RENDERBUFFER_SAMPLES_EXT* = 0x8CAB
  GL_TEXTURE3* = 0x84C3
  GL_CURRENT_RASTER_INDEX* = 0x0B05
  GL_INTERLEAVED_ATTRIBS_EXT* = 0x8C8C
  GL_STENCIL_BACK_WRITEMASK* = 0x8CA5
  GL_POINT_SPRITE_ARB* = 0x8861
  GL_TRANSPOSE_TEXTURE_MATRIX* = 0x84E5
  GL_DRAW_BUFFER1_ARB* = 0x8826
  GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS* = 0x92D0
  GL_DEPTH_ATTACHMENT_OES* = 0x8D00
  GL_COMPRESSED_RGBA_PVRTC_2BPPV2_IMG* = 0x9137
  GL_SRGB_ALPHA* = 0x8C42
  GL_UNSIGNED_INT64_ARB* = 0x140F
  GL_LAST_VERTEX_CONVENTION_EXT* = 0x8E4E
  GL_IMAGE_CLASS_1_X_8* = 0x82C1
  GL_COMPRESSED_RGBA_S3TC_DXT1_EXT* = 0x83F1
  GL_REFLECTION_MAP* = 0x8512
  GL_MAX_IMAGE_UNITS_EXT* = 0x8F38
  GL_DEPTH_STENCIL_NV* = 0x84F9
  GL_PROGRAM_TEX_INDIRECTIONS_ARB* = 0x8807
  GL_BINNING_CONTROL_HINT_QCOM* = 0x8FB0
  GL_T4F_V4F* = 0x2A28
  GL_FLOAT_VEC4* = 0x8B52
  GL_CONVEX_HULL_NV* = 0x908B
  GL_TEXTURE26_ARB* = 0x84DA
  GL_INDEX_BIT_PGI* = 0x00080000
  GL_TEXTURE_COORD_ARRAY_TYPE_EXT* = 0x8089
  GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_OES* = 0x8CD2
  GL_MAX_ARRAY_TEXTURE_LAYERS* = 0x88FF
  GL_COLOR_ATTACHMENT4_EXT* = 0x8CE4
  GL_SAMPLE_COVERAGE_VALUE_ARB* = 0x80AA
  GL_VERTEX_ATTRIB_MAP2_ORDER_APPLE* = 0x8A08
  GL_MAX_LAYERS* = 0x8281
  GL_FOG_COORDINATE_ARRAY_POINTER_EXT* = 0x8456
  GL_INDEX_TEST_REF_EXT* = 0x81B7
  GL_GREEN_BIT_ATI* = 0x00000002
  GL_STRICT_SCISSOR_HINT_PGI* = 0x1A218
  GL_MAP2_VERTEX_ATTRIB4_4_NV* = 0x8674
  GL_MAX_GEOMETRY_OUTPUT_VERTICES_EXT* = 0x8DE0
  GL_OUTPUT_TEXTURE_COORD31_EXT* = 0x87BC
  GL_XOR* = 0x1506
  GL_VIDEO_CAPTURE_FRAME_WIDTH_NV* = 0x9038
  GL_RGBA* = 0x1908

{.deprecated: [
  cGL_TRANSFORM_FEEDBACK_VARYINGS_EXT: GL_TRANSFORM_FEEDBACK_VARYINGS_EXT,
  cGL_BLEND_EQUATION_EXT: GL_BLEND_EQUATION_EXT,
  cGL_VERTEX_BLEND_ARB: GL_VERTEX_BLEND_ARB,
  cGL_TESSELLATION_MODE_AMD: GL_TESSELLATION_MODE_AMD,
  cGL_POLYGON_OFFSET_EXT: GL_POLYGON_OFFSET_EXT,
  cGL_BLEND_COLOR_EXT: GL_BLEND_COLOR_EXT,
  cGL_TRANSFORM_FEEDBACK_VARYINGS_NV: GL_TRANSFORM_FEEDBACK_VARYINGS_NV,
  cGL_COLOR_MATERIAL: GL_COLOR_MATERIAL,
  cGL_READ_BUFFER_NV: GL_READ_BUFFER_NV,
  cGL_FOG_FUNC_SGIS: GL_FOG_FUNC_SGIS,
  cGL_HISTOGRAM_EXT: GL_HISTOGRAM_EXT,
  cGL_LINE_WIDTH: GL_LINE_WIDTH,
  cGL_PROVOKING_VERTEX: GL_PROVOKING_VERTEX,
  cGL_SHADE_MODEL: GL_SHADE_MODEL,
  cGL_FRONT_FACE: GL_FRONT_FACE,
  cGL_PRIMITIVE_RESTART_INDEX: GL_PRIMITIVE_RESTART_INDEX,
  cGL_READ_PIXELS: GL_READ_PIXELS,
  cGL_VIEWPORT: GL_VIEWPORT,
  cGL_DEPTH_RANGE: GL_DEPTH_RANGE,
  cGL_COLOR_TABLE_SGI: GL_COLOR_TABLE_SGI,
  cGL_CLEAR: GL_CLEAR,
  cGL_ASYNC_MARKER_SGIX: GL_ASYNC_MARKER_SGIX,
  cGL_ACTIVE_TEXTURE_ARB: GL_ACTIVE_TEXTURE_ARB,
  cGL_SAMPLE_COVERAGE: GL_SAMPLE_COVERAGE,
  cGL_BLEND_EQUATION_OES: GL_BLEND_EQUATION_OES,
  cGL_MATRIX_MODE: GL_MATRIX_MODE,
  cGL_TRANSFORM_FEEDBACK_VARYINGS: GL_TRANSFORM_FEEDBACK_VARYINGS,
  cGL_SAMPLE_COVERAGE_ARB: GL_SAMPLE_COVERAGE_ARB,
  cGL_TRACK_MATRIX_NV: GL_TRACK_MATRIX_NV,
  cGL_COMBINER_INPUT_NV: GL_COMBINER_INPUT_NV,
  cGL_TESSELLATION_FACTOR_AMD: GL_TESSELLATION_FACTOR_AMD,
  cGL_BLEND_EQUATION: GL_BLEND_EQUATION,
  cGL_CULL_FACE: GL_CULL_FACE,
  cGL_HISTOGRAM: GL_HISTOGRAM,
  cGL_PRIMITIVE_RESTART_INDEX_NV: GL_PRIMITIVE_RESTART_INDEX_NV,
  cGL_SAMPLE_MASK_EXT: GL_SAMPLE_MASK_EXT,
  cGL_RENDER_MODE: GL_RENDER_MODE,
  cGL_CURRENT_PALETTE_MATRIX_OES: GL_CURRENT_PALETTE_MATRIX_OES,
  cGL_VERTEX_ATTRIB_BINDING: GL_VERTEX_ATTRIB_BINDING,
  cGL_TEXTURE_LIGHT_EXT: GL_TEXTURE_LIGHT_EXT,
  cGL_INDEX_MATERIAL_EXT: GL_INDEX_MATERIAL_EXT,
  cGL_COLOR_TABLE: GL_COLOR_TABLE,
  cGL_PATH_STENCIL_FUNC_NV: GL_PATH_STENCIL_FUNC_NV,
  cGL_EDGE_FLAG: GL_EDGE_FLAG,
  cGL_ACTIVE_TEXTURE: GL_ACTIVE_TEXTURE,
  cGL_CLIENT_ACTIVE_TEXTURE_ARB: GL_CLIENT_ACTIVE_TEXTURE_ARB,
  cGL_VERTEX_ARRAY_RANGE_APPLE: GL_VERTEX_ARRAY_RANGE_APPLE,
  cGL_TEXTURE_VIEW: GL_TEXTURE_VIEW,
  cGL_BITMAP: GL_BITMAP,
  cGL_PRIMITIVE_RESTART_NV: GL_PRIMITIVE_RESTART_NV,
  cGL_VERTEX_BINDING_DIVISOR: GL_VERTEX_BINDING_DIVISOR,
  cGL_STENCIL_OP_VALUE_AMD: GL_STENCIL_OP_VALUE_AMD,
  cGL_PROVOKING_VERTEX_EXT: GL_PROVOKING_VERTEX_EXT,
  cGL_CURRENT_PALETTE_MATRIX_ARB: GL_CURRENT_PALETTE_MATRIX_ARB,
  cGL_PIXEL_TEX_GEN_SGIX: GL_PIXEL_TEX_GEN_SGIX,
  cGL_GENERATE_MIPMAP: GL_GENERATE_MIPMAP,
  cGL_UNIFORM_BUFFER_EXT: GL_UNIFORM_BUFFER_EXT,
  cGL_STENCIL_FUNC: GL_STENCIL_FUNC,
  cGL_VERTEX_ARRAY_RANGE_NV: GL_VERTEX_ARRAY_RANGE_NV,
  cGL_ACTIVE_PROGRAM_EXT: GL_ACTIVE_PROGRAM_EXT,
  cGL_LINE_STIPPLE: GL_LINE_STIPPLE,
  cGL_REFERENCE_PLANE_SGIX: GL_REFERENCE_PLANE_SGIX,
  cGL_DRAW_BUFFER: GL_DRAW_BUFFER,
  cGL_LIST_BASE: GL_LIST_BASE,
  cGL_READ_BUFFER: GL_READ_BUFFER,
  cGL_FRAGMENT_COLOR_MATERIAL_SGIX: GL_FRAGMENT_COLOR_MATERIAL_SGIX,
  cGL_CLIENT_ACTIVE_TEXTURE: GL_CLIENT_ACTIVE_TEXTURE,
  cGL_BLEND_COLOR: GL_BLEND_COLOR,
  cGL_MINMAX_EXT: GL_MINMAX_EXT,
  cGL_POINT_SIZE: GL_POINT_SIZE,
  cGL_MINMAX: GL_MINMAX,
  cGL_SAMPLE_PATTERN_SGIS: GL_SAMPLE_PATTERN_SGIS,
  cGL_SAMPLE_PATTERN_EXT: GL_SAMPLE_PATTERN_EXT,
  cGL_UNIFORM_BLOCK_BINDING: GL_UNIFORM_BLOCK_BINDING,
  cGL_POLYGON_STIPPLE: GL_POLYGON_STIPPLE,
  cGL_LOGIC_OP: GL_LOGIC_OP,
  cGL_ACCUM: GL_ACCUM,
  cGL_FRAMEZOOM_SGIX: GL_FRAMEZOOM_SGIX,
  cGL_DEPTH_BOUNDS_EXT: GL_DEPTH_BOUNDS_EXT,
  cGL_TEXTURE_BUFFER_EXT: GL_TEXTURE_BUFFER_EXT,
  cGL_POLYGON_MODE: GL_POLYGON_MODE,
  cGL_TEXTURE_NORMAL_EXT: GL_TEXTURE_NORMAL_EXT,
  cGL_PROGRAM_STRING_ARB: GL_PROGRAM_STRING_ARB,
  cGL_PATH_COVER_DEPTH_FUNC_NV: GL_PATH_COVER_DEPTH_FUNC_NV,
  cGL_TRANSFORM_FEEDBACK_ATTRIBS_NV: GL_TRANSFORM_FEEDBACK_ATTRIBS_NV,
  cGL_ACTIVE_STENCIL_FACE_EXT: GL_ACTIVE_STENCIL_FACE_EXT,
  cGL_DEPTH_FUNC: GL_DEPTH_FUNC,
  cGL_SAMPLE_MASK_SGIS: GL_SAMPLE_MASK_SGIS
].}
