$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestRailsDetection < TestCase
    def setup
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
