$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'
require 'externals/test/basic_git_repository'

module Externals
  module Test
    class TestCheckoutGit < TestCase
      include ExtTestCase

      def test_checkout
        repository = BasicGitRepository.new
        repository.prepare

        assert File.exists?(File.join(repository.clean_dir, ".git"))

        workdir = File.join(root_dir, 'test', "tmp", "workdir")
        FileUtils.mkdir_p workdir

        Dir.chdir workdir do
          if File.exists?(repository.name)
            rm_r repository.name
          end

          Ext.run "checkout", "--git", repository.clean_dir

          assert File.exists?(File.join(repository.name, "readme.txt"))
        end
      end
    end
  end
end