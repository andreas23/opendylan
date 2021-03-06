Module: dfmc-llvm-back-end
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              Additional code is Copyright 2009-2011 Gwydion Dylan Maintainers
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// FIXME get this from release-info
define constant $debug-producer = "Open Dylan 1.0";

define method llvm-compilation-record-dbg-compile-unit
    (back-end :: <llvm-back-end>, cr :: <compilation-record>)
 => (compile-unit :: <llvm-metadata-value>);
  let sr = cr.compilation-record-source-record;
  let location = sr.source-record-location;
  llvm-make-dbg-compile-unit($DW-LANG-Dylan,
                             location.locator-name,
                             location.locator-directory,
                             $debug-producer)
end method;

define method llvm-source-record-dbg-file
    (back-end :: <llvm-back-end>, sr :: <source-record>)
 => (dbg-file :: <llvm-metadata-value>);
  element(back-end.%source-record-dbg-file-table, sr, default: #f)
    | begin
        let location = source-record-location(sr);
        back-end.%source-record-dbg-file-table[sr]
          := llvm-make-dbg-file(back-end.llvm-back-end-dbg-compile-unit,
                                location.locator-name,
                                location.locator-directory)
      end
end method;

define method emit-lambda-dbg-function
    (back-end :: <llvm-back-end>, o :: <&iep>) => ()
  let fun = function(o);
  let signature = ^function-signature(fun);
  let sig-spec = signature-spec(fun);

  // Compute the source location
  let loc = fun.model-source-location;
  let (dbg-file, dbg-line)
    = if (instance?(loc, <source-location>))
        source-location-dbg-file-line(back-end, loc)
      else
        let cr = fun.model-compilation-record;
        let sr = cr.compilation-record-source-record;
        values(llvm-source-record-dbg-file(back-end, sr), 0)
      end if;

  // Compute the function type
  let (return-type :: false-or(<llvm-metadata-value>),
       parameter-types :: <sequence>)
    = llvm-signature-dbg-types(back-end, o, sig-spec, signature);
  let dbg-function-type
    = llvm-make-dbg-function-type(dbg-file, return-type, parameter-types);

  // Construct the function metadata
  let module = back-end.llvm-builder-module;
  let function-name = o.code.llvm-global-name;
  let dbg-name = if (o.binding-name) as(<string>, o.binding-name) else "" end;
  let dbg-function
    = llvm-make-dbg-function(dbg-file,
                             dbg-name,
                             function-name,
                             dbg-file,
                             dbg-line,
                             dbg-function-type,
                             definition?: #t,
                             function: o.code,
                             module: module);
  back-end.llvm-back-end-dbg-function := dbg-function;

  // Emit a llvm.dbg.value call for each parameter
  ins--dbg(back-end, dbg-line, 0, dbg-function, #f);
  for (index from 1, param in parameters(o), param-type in parameter-types)
    let v
      = make(<llvm-metadata-node>,
             function-local?: #t,
             node-values: list(temporary-value(param)));
    let lv
      = llvm-make-dbg-local-variable(#"argument",
                                     dbg-function,
                                     as(<string>, param.name),
                                     dbg-file, dbg-line,
                                     param-type,
                                     arg: index,
                                     module: module,
                                     function-name: function-name);
    ins--call-intrinsic(back-end, "llvm.dbg.value", vector(v, i64(0), lv));
  end for;
end method;

define method llvm-signature-dbg-types
    (back-end :: <llvm-back-end>, o :: <&iep>,
     sig-spec :: <signature-spec>, signature :: <&signature>)
 => (return-type :: false-or(<llvm-metadata-value>),
     parameter-types :: <sequence>);
  let obj-type = dylan-value(#"<object>");

  let return-type
    = if (~signature | spec-value-rest?(sig-spec))
        llvm-reference-dbg-type(back-end, obj-type)
      else
        llvm-reference-dbg-type
          (back-end, first(^signature-values(signature), default: obj-type))
      end if;

  let parameter-types = make(<stretchy-object-vector>);

  // Required arguments
  for (type in ^signature-required(signature),
       i from 0 below ^signature-number-required(signature))
    add!(parameter-types, llvm-reference-dbg-type(back-end, type));
  end for;
  // Optional arguments
  if (^signature-optionals?(signature))
    add!(parameter-types, llvm-reference-dbg-type(back-end, obj-type));
  end if;
  // Keyword arguments
  for (spec in spec-argument-key-variable-specs(sig-spec))
    add!(parameter-types, llvm-reference-dbg-type(back-end, obj-type));
  end for;

  values(return-type, parameter-types)
end method;

define method llvm-reference-dbg-type
    (back-end :: <llvm-back-end>, o :: <&raw-type>)
 => (dbg-type :: <llvm-metadata-value>);
  error("raw dbg type ref %=", o);
end method;

define method llvm-reference-dbg-type
    (back-end :: <llvm-back-end>, o)
 => (dbg-type :: <llvm-metadata-value>);
  let obj-type = dylan-value(#"<object>");
  let word-size = back-end-word-size(back-end);
  element(back-end.%dbg-type-table, obj-type, default: #f)
    | (back-end.%dbg-type-table[obj-type]
         := llvm-make-dbg-derived-type(#"pointer",
                                       back-end.llvm-back-end-dbg-compile-unit,
                                       "<object>",
                                       #f, #f,
                                       8 * word-size, 8 * word-size, 0,
                                       #f))
end method;


/// Computation source line tracking

define function op--scl(back-end :: <llvm-back-end>, c :: <computation>) => ()
  let loc = dfm-source-location(c);
  if (instance?(loc, <source-location>))
    let sr = source-location-source-record(loc);
    let start-offset = source-location-start-offset(loc);
    let start-line = source-offset-line(start-offset);
    ins--dbg(back-end, start-line + source-record-start-line(sr), 0,
             back-end.llvm-back-end-dbg-function, #f);
  end if;
end function;

define function source-location-dbg-file-line
    (back-end :: <llvm-back-end>, loc :: <source-location>)
 => (dbg-file :: <llvm-metadata-value>, dbg-line :: <integer>)
  let sr = source-location-source-record(loc);
  let start-offset = source-location-start-offset(loc);
  let start-line = source-offset-line(start-offset);
  values(llvm-source-record-dbg-file(back-end, sr),
         start-line + source-record-start-line(sr))
end function;
