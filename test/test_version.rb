require_relative "support/prepare_test_suite"
require 'externals/ext'
require 'stringio'

module Externals
  module Test
    class TestVersion < ::Test::Unit::TestCase
      include ExtTestCase

      def test_version
        version_regex = /(?:[^.\d]|^)(\d+\.\d+\.\d+)(?:[^.\d]|$)/

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
