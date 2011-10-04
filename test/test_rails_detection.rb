$:.unshift File.join(File.dirname(__FILE__),'..','lib') if $0 == __FILE__

require 'externals/test_case'
require 'externals/ext'
require 'externals/test/rails_app_unmanaged'

module Externals
  module Test
    class TestRailsDetection < TestCase
      include ExtTestCase

      def test_detection
        repository = RailsAppUnmanaged.new
        detector = Ext.project_type_detector('rails')

        assert !detector.detected?
        Dir.chdir(repository.clean_dir) do
          assert detector.detected?
        end
      end
    end
  end
end
