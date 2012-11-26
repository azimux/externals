$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'ext_test_case'
require 'externals/ext'
require 'basic_git_repository'

module Externals
  module Test
    class TestHelp < ::Test::Unit::TestCase
      include ExtTestCase

      def test_help
        capture = StringIO.new
        begin
          $stdout = capture

          Ext.run "help"
        ensure
          $stdout = STDOUT
        end
        capture = capture.string


        assert capture =~ /ext \[OPTIONS\] <command>/
      end
    end
  end
end