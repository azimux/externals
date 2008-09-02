$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestInitGit < TestCase
    def setup
      initialize_test_git_repository
      Dir.chdir File.join(root_dir, 'test') do
        `mkdir workdir`

        Dir.chdir 'workdir' do
          `cp -r #{repository_dir('git')} .`
        end
      end
    end

    def teardown
      destroy_test_repository 'git'
      
      Dir.chdir File.join(root_dir, 'test') do
        `rm -rf workdir`
      end
    end

    def test_repository_created
      assert File.exists?(File.join(repository_dir('git'), '.git'))
    end

    def test_init
      Dir.chdir File.join(root_dir, 'test') do
        `mkdir workdir`

        Dir.chdir 'workdir' do
          Dir.chdir 'gitrepo' do
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