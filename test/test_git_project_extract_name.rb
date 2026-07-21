require_relative "support/prepare_test_suite"
require 'externals/ext'
require 'stringio'

module Externals
  module Test
    class TestGitProjectExtractName < ::Test::Unit::TestCase
      include ExtTestCase

      def test_extract_name
        project = Externals::GitProject.new({})
        assert_equal "test", project.extract_name("git://domain.com/test.git")
        assert_equal "test", project.extract_name("git@domain.com:test.git")
        assert_equal "test", project.extract_name("test.git")
        assert_equal "test", project.extract_name("test")
      end
    end
  end
end
