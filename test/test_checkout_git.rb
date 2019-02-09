$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'ext_test_case'
require 'externals/ext'
require 'basic_git_repository'

module Externals
  module Test
    class TestCheckoutGit < ::Test::Unit::TestCase
      include ExtTestCase

      def test_checkout
        repository = BasicGitRepository.new
        repository.prepare

        assert File.exist?(repository.clean_dir)

        workdir = File.join(root_dir, 'test', "tmp", "workdir")
        mkdir_p workdir

        Dir.chdir workdir do
          if File.exist?(repository.name)
            rm_r repository.name
          end

          Ext.run "checkout", "--git", repository.clean_dir

          assert File.exist?(File.join(repository.name, "readme.txt"))
        end
      end
    end
  end
end
