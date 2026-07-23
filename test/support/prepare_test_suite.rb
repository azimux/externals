require "pathname"
require "simplecov"
require "fileutils"

SimpleCov.start do
  skip "test/"

  # enable_coverage :branch
  minimum_coverage line: 100
  # TODO: enable this? worth it to get to 100% branch coverage?
  # minimum_coverage line: 100, branch: 100
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

cached_repos_dir = File.join(__dir__, "..", "tmp")
cached_repos_dir = Pathname(cached_repos_dir).realpath.to_s

unless cached_repos_dir.end_with?("/test/tmp")
  raise "Too scared to delete #{cached_repos_dir}"
end

FileUtils.rm_rf(cached_repos_dir)

require "ext_test_case"
