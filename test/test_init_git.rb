$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'ext_test_case'
require 'externals/ext'
require 'basic_git_repository'

module Externals
  module Test
    class TestInitGit < ::Test::Unit::TestCase
      include ExtTestCase

      def setup
        repository = BasicGitRepository.new
        repository.prepare

        assert File.exist?(repository.clean_dir)

        workdir = File.join(root_dir, 'test', "tmp", "workdir")
        mkdir_p workdir

        Dir.chdir workdir do
          delete_if_dirty(repository.name)
          if !File.exist?(repository.name)
            `git clone #{repository.clean_dir} #{repository.name}`
            raise unless $? == 0
          end

          mark_dirty(repository.name)
        end

        @workdir = workdir
        @repository = repository
      end

      def test_init
        Dir.chdir @workdir do
          Dir.chdir @repository.name do
            assert !File.exist?('.externals')

            rescue_exit { Ext.run "init" }

            config = Externals::Configuration::Configuration.new(File.read('.externals'))
            assert_equal(config['.']['scm'], 'git')
          end
        end
      end

      def test_init_rails_project
        Dir.chdir @workdir do
          Dir.chdir @repository.name do
            assert !File.exist?('.externals')

            rescue_exit { Ext.run "init", "--type", "rails" }

            config = Externals::Configuration::Configuration.new(File.read('.externals'))
            assert_equal(config['.']['scm'], 'git')
            assert_equal(config['.']['type'], 'rails')
          end
        end
      end
    end
  end
end
