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
  end
end