Module:	      system-internals
Author:       Gary Palter
Synopsis:     UNIX implementation of the File System library API
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


/// From <sys/stat.h> ...
// define constant $S_ISUID = #o0004000;	// set user id on execution
// define constant $S_ISGID = #o0002000;	// set group id on execution
define constant    $S_IRWXU = #o0000700;	// read,write,execute perm: owner
define constant    $S_IRUSR = #o0000400;	// read permission: owner
define constant    $S_IWUSR = #o0000200;	// write permission: owner
define constant    $S_IXUSR = #o0000100;	// execute/search permission: owner
define constant    $S_IRWXG = #o0000070;	// read,write,execute perm: group
define constant    $S_IRGRP = #o0000040;	// read permission: group
define constant    $S_IWGRP = #o0000020;	// write permission: group
define constant    $S_IXGRP = #o0000010;	// execute/search permission: group
define constant    $S_IRWXO = #o0000007;	// read,write,execute perm: other
define constant    $S_IROTH = #o0000004;	// read permission: other
define constant    $S_IWOTH = #o0000002;	// write permission: other
define constant    $S_IXOTH = #o0000001;	// execute/search permission: other
define constant    $S_IFMT  = #o0170000;	// type of file mask
define constant    $S_IFDIR = #o0040000;	// directory
define constant    $S_IFLNK = #o0120000;	// symbolic link

/// From <unistd.h> ...
// define constant $F_OK = #o0;
define constant    $X_OK = #o1;
define constant    $W_OK = #o2;
define constant    $R_OK = #o4;

/// From <errno.h>
define constant $ENOENT  =  2;
define constant $EINTR   =  4;
define constant $EACCESS = 13;
define constant $EINVAL  = 22;
define constant $ETXTBSY = 26;
define constant $EROFS   = 30;


/// Used instead of define C-struct to avoid relying on the C-FFI library ...

/// From <sys/stat.h> ...

define system-offset stat-size (x86-linux 22, ppc-linux 22, x86-freebsd 24, amd64-freebsd 15, x86-darwin 24, ppc-darwin 24, x86_64-linux 18) 18;
define system-offset st-mode (x86-linux 4, ppc-linux 4, x86-freebsd 2, amd64-freebsd 1, x86-darwin 2, ppc-darwin 2, x86_64-linux 6) 2;
//XXX: st-uid is 12 on FreeBSD-amd64, so it should be 1.5 here...
define system-offset st-uid (x86-linux 6, ppc-linux 6, x86-freebsd 3, amd64-freebsd 2, x86-darwin 3, ppc-darwin 3, x86_64-linux 7) 4;
define system-offset st-gid (x86-linux 7, ppc-linux 7, x86-freebsd 4, amd64-freebsd 2, x86-darwin 4, ppc-darwin 4, x86_64-linux 8) 5;
define system-offset st-size (x86-linux 11, ppc-linux 11, x86-freebsd 12, amd64-freebsd 9, x86-darwin 12, ppc-darwin 12, x86_64-linux 6) 7;
define system-offset st-atime (x86-linux 14, ppc-linux 14, x86-freebsd 6, amd64-freebsd 3, x86-darwin 6, ppc-darwin 6, x86_64-linux 16) 8;
define system-offset st-mtime (x86-linux 16, ppc-linux 16, x86-freebsd 8, amd64-freebsd 5, x86-darwin 8, ppc-darwin 8, x86_64-linux 22) 10;
define system-offset st-ctime (x86-linux 18, ppc-linux 18, x86-freebsd 10, amd64-freebsd 7, x86-darwin 10, ppc-darwin 10, x86_64-linux 26) 12;

define constant $STAT_SIZE = 
  $stat-size-offset * raw-as-integer(primitive-word-size());

define macro with-stack-stat
  { with-stack-stat (?st:name, ?file:expression) ?:body end }
  => { with-storage (?st, $STAT_SIZE) ?body end }
end macro with-stack-stat;

define inline-only function st-mode (st :: <machine-word>) => (mode :: <integer>)
  raw-as-integer
  (primitive-c-unsigned-int-at(primitive-unwrap-machine-word(st),
			       integer-as-raw($st-mode-offset),
			       integer-as-raw(0)))
end function st-mode;

define inline-only function st-uid (st :: <machine-word>) => (uid :: <integer>)
  raw-as-integer
  (primitive-c-unsigned-int-at(primitive-unwrap-machine-word(st),
			       integer-as-raw($st-uid-offset),
			       integer-as-raw(0)))
end function st-uid;

define inline-only function st-gid (st :: <machine-word>) => (gid :: <integer>)
  raw-as-integer
  (primitive-c-unsigned-int-at(primitive-unwrap-machine-word(st),
			       integer-as-raw($st-gid-offset),
			       integer-as-raw(0)))
end function st-gid;
ignore(st-gid);

define inline-only function st-size (st :: <machine-word>) => (size :: <abstract-integer>)
  raw-as-abstract-integer
  (primitive-c-signed-long-at(primitive-unwrap-machine-word(st),
			      integer-as-raw($st-size-offset),
			      integer-as-raw(0)))
end function st-size;

define inline-only function st-atime (st :: <machine-word>) => (atime :: <abstract-integer>)
  raw-as-abstract-integer
  (primitive-c-signed-int-at(primitive-unwrap-machine-word(st),
			     integer-as-raw($st-atime-offset),
			     integer-as-raw(0)))
end function st-atime;

define inline-only function st-mtime (st :: <machine-word>) => (mtime :: <abstract-integer>)
  raw-as-abstract-integer
  (primitive-c-signed-int-at(primitive-unwrap-machine-word(st),
			     integer-as-raw($st-mtime-offset),
			     integer-as-raw(0)))
end function st-mtime;

define inline-only function st-ctime (st :: <machine-word>) => (ctime :: <abstract-integer>)
  raw-as-abstract-integer
  (primitive-c-signed-int-at(primitive-unwrap-machine-word(st),
			     integer-as-raw($st-ctime-offset),
			     integer-as-raw(0)))
end function st-ctime;


/// Used instead of define C-struct to avoid relying on the C-FFI library ...

/// From <pwd.h> ...

define system-offset passwd-name () 0;
define system-offset passwd-dir (alpha-linux 4, x86-freebsd 7, x86-darwin 7, ppc-darwin 7) 5;

define inline-only function passwd-name (passwd :: <machine-word>) => (name :: <byte-string>)
  primitive-raw-as-string
    (primitive-c-pointer-at(primitive-unwrap-machine-word(passwd),
			    integer-as-raw($passwd-name-offset),
			    integer-as-raw(0)))
end function passwd-name;

define inline-only function passwd-dir (passwd :: <machine-word>) => (dir :: <byte-string>)
  primitive-raw-as-string
    (primitive-c-pointer-at(primitive-unwrap-machine-word(passwd),
			    integer-as-raw($passwd-dir-offset),
			    integer-as-raw(0)))
end function passwd-dir;


/// From <grp.h> ...

define system-offset group-name () 0;

define inline-only function group-name (group :: <machine-word>) => (name :: <byte-string>)
  primitive-raw-as-string
    (primitive-c-pointer-at(primitive-unwrap-machine-word(group),
			    integer-as-raw($group-name-offset),
			    integer-as-raw(0)))
end function group-name;


/// Used instead of define C-struct to avoid relying on the C-FFI library ...

/// From <dirent.h> ...

define system-offset dirent-name (x86-linux 11, ppc-linux 11, x86-freebsd 8, x86-darwin 8, ppc-darwin 8) 8;

define inline-only function dirent-name (dirent :: <machine-word>) => (name :: <byte-string>)
  primitive-raw-as-string
    (primitive-cast-raw-as-pointer
       (primitive-machine-word-add(primitive-unwrap-machine-word(dirent),
				   integer-as-raw($dirent-name-offset))))
end function dirent-name;

/// Error handling

define function unix-errno () => (errno :: <integer>)
  raw-as-integer
    (%call-c-function("io_errno") ()=>(result :: <raw-c-signed-int>)() end)
end function;

define function unix-last-error-message () => (message :: <string>)
  let message :: <byte-string>
    = primitive-raw-as-string
       (%call-c-function ("strerror")
	    (errno :: <raw-c-signed-int>) => (message :: <raw-byte-string>)
	  (integer-as-raw(unix-errno()))
	end);
  // Make a copy to avoid it being overwritten ...
  copy-sequence(message)
end function unix-last-error-message;

define function unix-file-error
    (operation :: <string>, additional-information, #rest additional-information-args)
 => (will-never-return :: <bottom>)
  let status-message = unix-last-error-message();
  if (additional-information)
    error(make(<file-system-error>,
	       format-string: concatenate("%s: Can't %s ", additional-information),
	       format-arguments: concatenate(list(status-message),
					     list(operation),
					     map(method (x)
						   if (instance?(x, <locator>))
						     as(<string>, x)
						   else
						     x
						   end
						 end method,
						 additional-information-args))))
  else
    error(make(<file-system-error>,
	       format-string: "%s: Can't %s",
	       format-arguments: list(status-message, operation)))
  end;
end function unix-file-error;
