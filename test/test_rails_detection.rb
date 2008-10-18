$:.unshift File.join(File.dirname(__FILE__),'..','lib') if $0 == __FILE__

require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestRailsDetection < TestCase
    include ExtTestCase
    
    def setup
      destroy_rails_application
      create_rails_application
    end
    
    def teardown
      destroy_rails_application
    end
    
    def test_detection
      detector = Ext.project_type_detector('rails')

      assert !detector.detected?
      Dir.chdir(rails_application_dir) do
        assert detector.detected?
      end
    end
  end
end
