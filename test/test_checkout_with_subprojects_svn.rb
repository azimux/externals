$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestCheckoutWithSubprojectsSvn < TestCase
    def setup
      destroy_rails_application
      create_rails_application
      destroy_test_repository 'svn'
      initialize_test_svn_repository

      Dir.chdir File.join(root_dir, 'test') do
        parts = 'workdir/checkout/rails_app/vendor/plugins/foreign_key_migrations/lib/red_hill_consulting/foreign_key_migrations/active_record/connection_adapters/.svn/text-base/table_definition.rb.svn-base'.split('/')
        if File.exists? File.join(*parts)
          Dir.chdir File.join(*(parts[0..-2])) do
            File.delete parts[-1]
          end
        end

        `rm -rf workdir`
        repo_url = repository_dir('svn')
        if windows?
          repo_url = repo_url.gsub(/\\/, "/")
        end

        puts `svn co file:///#{repository_dir('svn')} #{File.join("workdir","rails_app")}`
        Dir.chdir File.join('workdir', "rails_app") do
          puts `cp -r #{rails_application_dir}/* .`

          SvnProject.add_all

          Ext.run "init"
          raise " could not create .externals"  unless File.exists? '.externals'
          %w(rails acts_as_list).each do |proj|
            Ext.run "add", "git://github.com/rails/#{proj}.git"
          end

          #add a couple svn managed subprojects
          %w(foreign_key_migrations redhillonrails_core).each do |proj|
            Ext.run "add", "svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/#{proj}"
          end

          SvnProject.add_all

          puts `svn commit -m "created empty rails app with some subprojects"`
        end
      end
    end

    def teardown
      destroy_rails_application

      #      Dir.chdir File.join(root_dir, 'test') do
      #        `rm -rf workdir`
      #      end
      #XXX
    end


    def test_checkout_with_subproject
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir checkout`
          Dir.chdir 'checkout' do

            puts "Currently in #{Dir.pwd}"
            source = repository_dir('svn')

            if windows?
              source = source.gsub(/\\/, "/")
            end
            source = "file:///#{source}"


            puts "About to checkout #{source}"
            Ext.run "checkout", "--svn", source, 'rails_app'

            Dir.chdir 'rails_app' do
              assert File.exists?('.svn')

              %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
                puts(ignore_text = `svn propget svn:ignore vendor/plugins`)
                assert(ignore_text =~ /^#{proj}$/)
              end

              puts(ignore_text = `svn propget svn:ignore vendor`)
              assert(ignore_text =~ /^rails$/)
              
              Dir.chdir File.join('vendor', 'rails') do
                assert `git show 92f944818eece9fe4bc62ffb39accdb71ebc32be` =~ /azimux/
              end

              %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
                assert File.exists?(File.join('vendor', 'plugins',proj, 'lib'))
              end

              assert File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))
            end
          end
        end
      end
    end
    
    def test_export_with_subproject
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir export`
          Dir.chdir 'export' do

            puts "Currently in #{Dir.pwd}"
            source = repository_dir('svn')

            if windows?
              source = source.gsub(/\\/, "/")
            end
            source = "file:///#{source}"


            puts "About to export #{source}"
            Ext.run "export", "--svn", source, 'rails_app'

            Dir.chdir 'rails_app' do
              assert File.exists?('.svn')

              %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
                puts(ignore_text = `svn propget svn:ignore vendor/plugins`)
                assert(ignore_text =~ /^#{proj}$/)
              end

              puts(ignore_text = `svn propget svn:ignore vendor`)
              assert(ignore_text =~ /^rails$/)
              
              Dir.chdir File.join('vendor', 'rails') do
                assert `git show 92f944818eece9fe4bc62ffb39accdb71ebc32be` !~ /azimux/
              end

              %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
                assert File.exists?(File.join('vendor', 'plugins',proj, 'lib'))
              end
              %w(foreign_key_migrations redhillonrails_core).each do |proj|
                assert !File.exists?(File.join('vendor', 'plugins',proj, '.svn'))
              end

              assert File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))
            end
          end
        end
      end
    end
  end
end