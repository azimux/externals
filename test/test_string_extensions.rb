$:.unshift File.join(File.dirname(__FILE__),'..','lib') if $0 == __FILE__

require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestStringExtensions < TestCase
    include ExtTestCase
    
    def test_classify
      assert_equal "yourmom".classify, "Yourmom"
      assert_equal "your_mom".classify, "YourMom"
      assert_equal "lol_your_mom".classify, "LolYourMom"
      assert_equal "".classify, ""
    end

    def test_lines_by_width
      assert_equal [
        "this",
        "is a",
        "test"
        ],
          "this is a test".lines_by_width(4)

      assert_equal [
        "this",
        "is",
        "a",
        "test"
        ],
          "this is a test".lines_by_width(2)

      assert_equal ["this is a test"], "this is a test".lines_by_width

      assert_equal [
        "The working directory to execute",
        "commands from. Use this if for",
        "some reason you cannot execute",
        "ext from the main project's",
        "directory (or if it's just",
        "inconvenient, such as in a",
        "script or in a Capistrano task)"
      ],
        "The working directory to execute commands from.  Use this if for some reason you
        cannot execute ext from the main project's directory (or if it's just inconvenient, such as in a script
        or in a Capistrano task)".lines_by_width
    end
  end
end