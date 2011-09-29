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

        assert File.exists?(File.join(repository.clean_dir, ".git"))

        workdir = File.join(root_dir, 'test', "tmp", "workdir")
        FileUtils.mkdir_p workdir

        Dir.chdir workdir do
          delete_if_dirty(repository.name)
          if !File.exists?(repository.name)
            `cp -a #{repository.clean_dir} .`
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