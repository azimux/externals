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
            Ext.run "install", "--svn", 'file:///' + File.join(root_dir, 'test', 'cleanreps', proj)
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
              mp = Ext.new.main_project

              mp.assert_e_dne_i_ni proc{|a|assert(a)},%w(foreign_key_migrations redhillonrails_core acts_as_list)
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