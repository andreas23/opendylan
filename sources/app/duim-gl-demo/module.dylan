Module:    dylan-user
Synopsis:  DUIM OpenGL demo
Author:    Keith Playford
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define module duim-gl-demo
  use functional-dylan;
  use simple-format;
  use duim;
  use duim-internals, exclude: { position };
  use win32-duim;
  // use duim-gl;
  use c-ffi;
  use win32-common, exclude: { <POINT> };
  use win32-gdi, exclude: { <PATTERN> };
  use win32-gl;
  use win32-glu;
end module duim-gl-demo;
