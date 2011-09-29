$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'
require 'stringio'

module Externals
  module Test
    class TestVersion < TestCase
      include ExtTestCase

      def test_version
        version_regex = /(?:[^\.\d]|^)(\d+\.\d+\.\d+)(?:[^\.\d]|$)/

        assert Externals::VERSION =~ version_regex

        ["version", "--version"].each do |options|
          out = StringIO.new
          old_stdout = $stdout

          begin
            $stdout = out
            Ext.run options
          ensure
            $stdout = old_stdout
          end

          assert(out.string =~ version_regex)
          assert_equal $1, Externals::VERSION.strip
        end
      end
    end
  end
end