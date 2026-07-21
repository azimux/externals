require "pathname"
require 'simplecov'

SimpleCov.start do
  add_filter "test/"
end

# WARNING! We have to require test/unit after SimpleCov.start and not really sure why??
require 'test/unit'

libdir = File.join(__dir__, "..", "..", "lib")
libdir = Pathname(libdir).realpath
unless $LOAD_PATH.include?(libdir)
  $LOAD_PATH << libdir
end

support_dir = File.join(__dir__, "..", "support")
support_dir = Pathname(support_dir).realpath
unless $LOAD_PATH.include?(support_dir)
  $LOAD_PATH << support_dir
end

require "ext_test_case"
