Module:    environment-property-pages
Synopsis:  Environment property pages
Author:    Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Stack frame objects

define sideways method frame-property-types
    (frame :: <environment-frame>, class :: subclass(<stack-frame-object>))
 => (types :: <list>)
  concatenate(next-method(), #(#"source"))
end method frame-property-types;

