$:.unshift File.join(File.dirname(__FILE__),'..','lib') if $0 == __FILE__

require 'ext_test_case'
require 'externals/ext'
require 'rails_app_unmanaged'

module Externals
  module Test
    class TestRailsDetection < ::Test::Unit::TestCase
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
