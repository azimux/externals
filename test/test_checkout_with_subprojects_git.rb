$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'ext_test_case'
require 'externals/ext'
require 'rails_app_git_branches'

module Externals
  module Test
    class TestCheckoutWithSubprojectsGit < ::Test::Unit::TestCase
      include ExtTestCase

      def test_checkout_with_subproject
        repository = RailsAppGitBranches.new
        repository.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "branches", "git")
        mkdir_p workdir

        if File.exist?(File.join(workdir,"rails_app"))
          rm_rf File.join(workdir, "rails_app")
        end

        Dir.chdir workdir do
          source = repository.clean_dir
          puts "About to checkout #{source}"
          Ext.run "checkout", "--git", source

          Dir.chdir 'rails_app' do
            assert File.exist?('.git')

            assert File.exist?('.gitignore')

            ext = Ext.new
            main_project = ext.main_project
            engines = ext.subproject("engines")

            main_project.assert_e_dne_i_ni proc{|a|assert(a)},%w(foreign_key_migrations redhillonrails_core acts_as_list)

            # let's test switching branches via altering .externals and running "ext up"
            assert_equal "master", main_project.current_branch
            assert_equal "edge", engines.current_branch
            assert_equal "edge", ext.configuration["vendor/plugins/engines"]["branch"]

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            `git checkout --track -b new_branch origin/new_branch`
            raise unless $? == 0

            assert_equal "new_branch", main_project.current_branch
            assert_equal "edge", engines.current_branch

            assert_equal "new_branch", main_project.current_branch


            ext = Ext.new
            assert_equal "branch1", ext.configuration["vendor/plugins/engines"]["branch"]

            assert !main_project.ignore_contains?("vendor/rails")

            rm_rf "vendor/rails"
            raise if File.exist?(File.join("vendor", "rails"))

            `git checkout master`
            raise unless $? == 0

            assert_equal "master", main_project.current_branch
            assert_equal "edge", engines.current_branch

            Ext.run "up"
            assert_equal "master", main_project.current_branch
            assert_equal "edge", engines.current_branch
            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            `git checkout new_branch`
            assert_equal "new_branch", main_project.current_branch
            assert_equal "edge", engines.current_branch

            Ext.run "up"
            assert_equal "new_branch", main_project.current_branch
            assert_equal "branch1", engines.current_branch

            `git checkout master`
            Ext.run "up"
            assert_equal "master", main_project.current_branch
            assert_equal "edge", engines.current_branch

            assert main_project.ignore_contains?("vendor/rails")

            #let's test the switch command!
            Ext.run "switch", "new_branch"
            assert_equal "new_branch", main_project.current_branch
            assert_equal "branch1", engines.current_branch

            assert !main_project.ignore_contains?("vendor/rails")
            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))
            rm_rf "vendor/rails"

            Ext.run "switch", "master"
            assert_equal "master", main_project.current_branch
            assert_equal "edge", engines.current_branch

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            assert main_project.ignore_contains?("vendor/rails")
          end

          #now let's check it out again to test "ext checkout -b new_branch"
          rm_rf "rails_app"
          if File.exist?("rails_app")
            raise
          end

          Ext.run "checkout", "--git", "-b", "new_branch", source

          Dir.chdir 'rails_app' do
            ext = Ext.new
            main_project = ext.main_project
            engines = ext.subproject("engines")

            assert_equal "new_branch", main_project.current_branch
            assert_equal "branch1", engines.current_branch
          end
        end
      end

      def test_uninstall
        repository = RailsAppGitBranches.new
        repository.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "branches", "uninstall", "git")
        mkdir_p workdir

        if File.exist?(File.join(workdir,"rails_app"))
          rm_rf File.join(workdir, "rails_app")
        end

        Dir.chdir workdir do
          source = repository.clean_dir
          puts "About to checkout #{source}"
          Ext.run "checkout", "--git", source

          Dir.chdir 'rails_app' do
            mp = Ext.new.main_project

            projs = %w(foreign_key_migrations redhillonrails_core acts_as_list)
            projs_i = projs.dup
            projs_ni = []

            #let's uninstall acts_as_list
            Ext.run "uninstall", "acts_as_list"

            projs_ni << projs_i.delete('acts_as_list')

            mp.assert_e_dne_i_ni proc{|a|assert(a)}, projs, [], projs_i, projs_ni

            Ext.run "uninstall", "-f", "foreign_key_migrations"

            projs_ni << projs_i.delete('foreign_key_migrations')

            projs_dne = []
            projs_dne << projs.delete('foreign_key_migrations')

            mp.assert_e_dne_i_ni proc{|a|assert(a)}, projs, projs_dne, projs_i, projs_ni
          end
        end
      end
    end

  end
end
