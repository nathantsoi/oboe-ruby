# Copyright (c) 2012 by Tracelytics, Inc.
# All rights reserved.

require 'mkmf'
require 'rbconfig'

dir_config('oboe')

# Check if we're running in JRuby
if RbConfig::CONFIG.has_key?('arch')
  # nil meaning java string not found
  jruby = (RbConfig::CONFIG['arch'] =~ /java/i) != nil
else
  jruby = false
end

if not jruby and have_library('oboe')
  $libs = append_library($libs, "oboe")
  $libs = append_library($libs, "stdc++")

  $CFLAGS << " #{ENV["CFLAGS"]}"
  $CPPFLAGS << " #{ENV["CPPFLAGS"]}"
  $LIBS << " #{ENV["LIBS"]}"

  cpp_command('g++') if RUBY_VERSION < '1.9'
  create_makefile('oboe_metal', 'src')
else
  $stderr.puts "Error: Could not find the base liboboe libraries.  No tracing will occur."
  create_makefile('oboe_noop', 'noop')
end

