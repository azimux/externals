$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'
require 'externals/test/basic_git_repository'

module Externals
  module Test
    class TestInitGit < TestCase
      include ExtTestCase

      def test_init
        repository = BasicGitRepository.new
        repository.prepare

        assert File.exists?(repository.clean_dir)

        workdir = File.join(root_dir, 'test', "tmp", "workdir")
        mkdir_p workdir

        Dir.chdir workdir do
          delete_if_dirty(repository.name)
          if !File.exists?(repository.name)
            `git clone #{repository.clean_dir} #{repository.name}`
            raise unless $? == 0
          end

          mark_dirty(repository.name)
          Dir.chdir repository.name do
            assert !File.exists?('.externals')

            Ext.run "init"

            assert File.exists?('.externals')
            assert(File.read('.externals') =~ /^\s*scm\s*=\s*git\s*$/)
          end
        end
      end
    end
  end
end