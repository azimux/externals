require_relative "support/prepare_test_suite"

require 'externals/ext'

module Externals
  module Test
    class TestFileUtilsExtensions < ::Test::Unit::TestCase
      include ExtTestCase

      def test_dir_empty
        workdir = File.join root_dir, "test", "tmp", "extensions", "file_utils"
        rm_rf_ie workdir

        mkdir_p workdir

        assert dir_empty?(workdir)
        somefile = File.join(workdir, "somefile")
        touch somefile
        assert !dir_empty?(workdir)

        rm_rf somefile
        assert dir_empty? workdir
      end
    end
  end
end
