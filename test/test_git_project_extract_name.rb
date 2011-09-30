$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'
require 'stringio'

module Externals
  module Test
    class TestGitProjectExtractName < TestCase
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