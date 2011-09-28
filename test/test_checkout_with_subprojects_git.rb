$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestCheckoutWithSubprojectsGit < TestCase
    include ExtTestCase

    def setup
      destroy_rails_application
      create_rails_application

      Dir.chdir File.join(root_dir, 'test') do
        parts = 'workdir/checkout/rails_app/vendor/plugins/foreign_key_migrations/lib/red_hill_consulting/foreign_key_migrations/active_record/connection_adapters/.svn/text-base/table_definition.rb.svn-base'.split('/')
        if File.exists? File.join(*parts)
          Dir.chdir File.join(*(parts[0..-2])) do
            File.delete parts[-1]
          end
        end
        `rm -rf workdir`
        `mkdir workdir`
        `cp -r #{rails_application_dir} workdir`
        Dir.chdir File.join('workdir','rails_app') do
          Ext.run "touch_emptydirs"

          `git init`
          Ext.run "init"
          raise " could not create .externals"  unless File.exists? '.externals'
          Ext.run "install", File.join(root_dir, 'test', 'cleanreps', "acts_as_list.git")

          #install a couple svn managed subprojects
          %w(foreign_key_migrations redhillonrails_core).each do |proj|
            Ext.run "install", "--svn", 'file:///' +
              File.join(root_dir, 'test', 'cleanreps', proj)
          end

          ext = Ext.new
          main_project = ext.main_project

          unless !main_project.ignore_contains? "vendor/plugins/engines"
            raise
          end
          #install project with a branch
          Ext.run "install", File.join(root_dir, 'test', 'cleanreps', 'engines.git'), "-b", "edge"
          unless main_project.ignore_contains? "vendor/plugins/engines"
            raise
          end

          #install fake_rails
          unless !main_project.ignore_contains? "vendor/rails"
            raise
          end
          Ext.run "install",
            "--git",
            File.join(root_dir, 'test', 'cleanreps', 'fake_rails'),
            "vendor/rails"
          unless main_project.ignore_contains? "vendor/rails"
            raise
          end


          GitProject.add_all
          `git commit -m "created empty rails app with some subprojects"`
        end
      end
    end

    def teardown
      destroy_rails_application

      Dir.chdir File.join(root_dir, 'test') do
        parts = 'workdir/checkout/rails_app/vendor/plugins/foreign_key_migrations/lib/red_hill_consulting/foreign_key_migrations/active_record/connection_adapters/.svn/text-base/table_definition.rb.svn-base'.split('/')
        if File.exists? File.join(*parts)
          Dir.chdir File.join(*(parts[0..-2])) do
            File.delete parts[-1]
          end
        end
        `rm -rf workdir`
      end
      Dir.chdir File.join(root_dir, 'test') do
        `rm -rf workdir`
      end
    end

    def test_checkout_with_subproject
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir checkout`
          Dir.chdir 'checkout' do
            source = File.join(root_dir, 'test', 'workdir', 'rails_app')
            puts "About to checkout #{source}"
            Ext.run "checkout", "--git", source

            Dir.chdir 'rails_app' do
              assert File.exists?('.git')

              assert File.exists?('.gitignore')

              ext = Ext.new
              main_project = ext.main_project
              engines = ext.subproject("engines")

              main_project.assert_e_dne_i_ni proc{|a|assert(a)},%w(foreign_key_migrations redhillonrails_core acts_as_list)

              # let's test switching branches via altering .externals and running "ext up"
              assert_equal "master", main_project.current_branch
              assert_equal "edge", engines.current_branch
              assert_equal "edge", ext.configuration["vendor/plugins/engines"]["branch"]

              #let's create a branch for the main project called 'new_branch' and a
              #branch for the engines subproject called 'new_branch' and make sure
              #that checking one out and doing "ext up" correctly changes the branch
              #of the subproject

              `git push origin master:new_branch`
              raise unless $? == 0

              `git fetch origin`
              raise unless $? == 0

              `git checkout --track -b new_branch origin/new_branch`
              raise unless $? == 0

              assert_equal "new_branch", main_project.current_branch
              assert_equal "edge", engines.current_branch

              Dir.chdir File.join(%w(vendor plugins engines)) do
                `git push origin master:new_branch`
                raise unless $? == 0
              end
              assert_equal "new_branch", main_project.current_branch

              #update .externals
              ext.configuration["vendor/plugins/engines"]["branch"] = "new_branch"
              ext.configuration.write

              ext = Ext.new
              assert_equal "new_branch", ext.configuration["vendor/plugins/engines"]["branch"]

              assert File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))
              #let's uninstall rails
              Ext.run "uninstall", "-f", "rails"
              assert !File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))

              GitProject.add_all
              raise unless $? == 0
              `git commit -m "changed branch on engines subproject"`
              raise unless $? == 0
              `git push`
              raise unless $? == 0

              `git checkout master`
              raise unless $? == 0

              assert_equal "master", main_project.current_branch
              assert_equal "edge", engines.current_branch

              Ext.run "up"
              assert_equal "master", main_project.current_branch
              assert_equal "edge", engines.current_branch
              assert File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))

              `git checkout new_branch`
              assert_equal "new_branch", main_project.current_branch
              assert_equal "edge", engines.current_branch

              Ext.run "up"
              assert_equal "new_branch", main_project.current_branch
              assert_equal "new_branch", engines.current_branch

              `git checkout master`
              Ext.run "up"
              assert_equal "master", main_project.current_branch
              assert_equal "edge", engines.current_branch

              assert main_project.ignore_contains?("vendor/rails")

              #let's test the switch command!
              Ext.run "switch", "new_branch"
              assert_equal "new_branch", main_project.current_branch
              assert_equal "new_branch", engines.current_branch

              assert !main_project.ignore_contains?("vendor/rails")
              assert File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))
              `rm -rf vendor/rails`
              assert !File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))
              raise unless $? == 0

              Ext.run "switch", "master"
              assert_equal "master", main_project.current_branch
              assert_equal "edge", engines.current_branch

              assert File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))

              assert main_project.ignore_contains?("vendor/rails")
            end

            #now let's check it out again to test "ext checkout -b new_branch"
            `rm -rf rails_app`
            raise unless $? == 0

            Ext.run "checkout", "--git", "-b", "new_branch", source

            Dir.chdir 'rails_app' do
              ext = Ext.new
              main_project = ext.main_project
              engines = ext.subproject("engines")

              assert_equal "new_branch", main_project.current_branch
              assert_equal "new_branch", engines.current_branch
            end
          end
        end
      end
    end

    def test_uninstall
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir checkout`
          Dir.chdir 'checkout' do
            source = File.join(root_dir, 'test', 'workdir', 'rails_app')
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
end