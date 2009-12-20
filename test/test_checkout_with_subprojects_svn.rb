$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestCheckoutWithSubprojectsSvn < TestCase
    include ExtTestCase

    def setup
      destroy_rails_application
      create_rails_application
      destroy_test_repository 'svn'
      initialize_test_svn_repository
      destroy_test_modules_repository 'svn'
      create_test_modules_repository 'svn'

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
            Ext.run "install", File.join(root_dir, 'test', 'cleanreps', "#{proj}.git")
          end

          #install a couple svn managed subprojects
          %w(foreign_key_migrations redhillonrails_core).each do |proj|
            Ext.run "install", "--svn", "file:///#{File.join(root_dir, 'test', 'cleanreps', proj)}"
          end

          #install project with a branch
          Ext.run "install", File.join(root_dir, 'test', 'cleanreps', 'engines.git'), "-b", "edge"

          #install project with a non-default path
          Ext.run "install", "--svn", "file:///#{modules_repository_dir('svn')}", "modules"

          SvnProject.add_all

          puts `svn commit -m "created empty rails app with some subprojects"`
        end
      end
    end

    def teardown
      destroy_rails_application
      destroy_test_repository 'svn'
      destroy_test_modules_repository 'svn'


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

              %w(foreign_key_migrations redhillonrails_core acts_as_list engines).each do |proj|
                assert File.exists?(File.join('vendor', 'plugins', proj, 'lib'))
              end

              assert File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))

              assert File.exists?(File.join('vendor', 'rails', '.git'))

              assert File.exists?(File.join('modules', 'modules.txt'))

              assert File.read(File.join('modules', 'modules.txt')) =~ /line1 of/

              Dir.chdir File.join('vendor','plugins','engines') do
                assert(`git branch -a` =~ /^\*\s*edge\s*$/)
                assert(`git branch -a` !~ /^\*\s*master\s*$/)
              end
            end
          end
        end
      end
    end

    def test_update_with_missing_subproject_git
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir update`
          Dir.chdir 'update' do
            source = repository_dir('svn')

            if windows?
              source = source.gsub(/\\/, "/")
            end
            source = "file:///#{source}"


            puts "About to checkout #{source}"
            Ext.run "checkout", "--svn", source, 'rails_app'

            Dir.chdir 'rails_app' do
              pretests = proc do
                assert File.exists?('.svn')
                assert !File.exists?(File.join('vendor', 'plugins', 'ssl_requirement', 'lib'))
                assert File.read(".externals") =~ /rails/
                assert File.read(".externals") !~ /ssl_requirement/
              end

              pretests.call

              #add a project
              Dir.chdir File.join(root_dir, 'test') do
                Dir.chdir File.join('workdir', "rails_app") do
                  #install a new project
                  Ext.run "install", File.join(root_dir, 'test', 'cleanreps', 'ssl_requirement.git')

                  SvnProject.add_all

                  puts `svn commit -m "added another subproject (ssl_requirement)"`
                end
              end

              pretests.call

              #update the project and make sure ssl_requirement was added and checked out
              Ext.run "update"
              assert File.read(".externals") =~ /ssl_requirement/
              assert File.exists?(File.join('vendor', 'plugins', 'ssl_requirement', 'lib'))
            end
          end
        end
      end
    end

    def test_update_with_missing_subproject_by_revision_git
      subproject = "ssl_requirement"
      revision = "aa2dded823f8a9b378c22ba0159971508918928a"

      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir update`
          Dir.chdir 'update' do
            source = repository_dir('svn')

            if windows?
              source = source.gsub(/\\/, "/")
            end
            source = "file:///#{source}"


            puts "About to checkout #{source}"
            Ext.run "checkout", "--svn", source, 'rails_app'

            Dir.chdir 'rails_app' do
              pretests = proc do
                assert File.exists?('.svn')
                assert !File.exists?(File.join('vendor', 'plugins', subproject, 'lib'))
                assert File.read(".externals") =~ /rails/
                assert File.read(".externals") !~ /#{subproject}/
              end

              pretests.call

              #add a project
              Dir.chdir File.join(root_dir, 'test') do
                Dir.chdir File.join('workdir', "rails_app") do
                  #install a new project
                  Ext.run "install", File.join(root_dir, 'test', 'cleanreps', "#{subproject}.git")
                  Dir.chdir File.join("vendor",'plugins', subproject) do
                    assert `git show HEAD` !~ /^\s*commit\s*#{revision}\s*$/i
                  end
                  #freeze it to a revision
                  Ext.run "freeze", subproject,  revision
                  Dir.chdir File.join("vendor",'plugins', subproject) do
                    assert `git show HEAD` =~ /^\s*commit\s*#{revision}\s*$/i
                  end

                  SvnProject.add_all

                  puts `svn commit -m "added another subproject (#{subproject}) frozen to #{revision}"`
                end
              end

              pretests.call

              #update the project and make sure ssl_requirement was added and checked out at the right revision
              Ext.run "update"
              assert File.read(".externals") =~ /ssl_requirement/

              assert File.exists?(File.join('vendor', 'plugins', subproject, 'lib'))

              Dir.chdir File.join("vendor",'plugins', subproject) do
                assert `git show HEAD` =~ /^\s*commit\s*#{revision}\s*$/i
              end
            end
          end
        end
      end
    end

    def test_update_with_missing_subproject_svn
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir update`
          Dir.chdir 'update' do
            source = repository_dir('svn')

            if windows?
              source = source.gsub(/\\/, "/")
            end
            source = "file:///#{source}"


            puts "About to checkout #{source}"
            Ext.run "checkout", "--svn", source, 'rails_app'

            Dir.chdir 'rails_app' do
              pretests = proc do
                assert File.exists?('.svn')
                assert !File.exists?(File.join('vendor', 'plugins', 'empty_plugin', 'lib'))
                assert File.read(".externals") =~ /rails/
                assert File.read(".externals") !~ /empty_plugin/
              end

              pretests.call

              #add a project
              Dir.chdir File.join(root_dir, 'test') do
                Dir.chdir File.join('workdir', "rails_app") do
                  #install a new project
                  Ext.run "install", "--svn", "file:///#{File.join(root_dir, 'test', 'cleanreps', 'empty_plugin')}"

                  SvnProject.add_all

                  puts `svn commit -m "added another subproject (empty_plugin)"`
                end
              end

              pretests.call

              #update the project and make sure ssl_requirement was added and checked out
              Ext.run "update"
              assert File.read(".externals") =~ /empty_plugin/
              assert File.exists?(File.join('vendor', 'plugins', 'empty_plugin', 'lib'))
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
            source = repository_dir('svn')

            if windows?
              source.gsub!(/\\/, "/")
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
                #can't check this if it's local.  It seems --depth 1 is ignored for
                #repositories on the local machine.
                #assert `git show 92f944818eece9fe4bc62ffb39accdb71ebc32be` !~ /azimux/
              end

              %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
                puts "filethere? #{proj}: #{File.exists?(File.join('vendor', 'plugins', proj, 'lib'))}"
                if !File.exists?(File.join('vendor', 'plugins', proj, 'lib'))
                  puts "here"
                end
                assert File.exists?(File.join('vendor', 'plugins', proj, 'lib'))
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

    def test_uninstall
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir checkout`
          Dir.chdir 'checkout' do
            #source = File.join(root_dir, 'test', 'workdir', 'rails_app')
            source = repository_dir('svn')

            if windows?
              source = source.gsub(/\\/, "/")
              #source.gsub!(/^[A-Z]:[\/\\]/, "")
            end
            source = "file:///#{source}"

            puts "About to checkout #{source}"
            Ext.run "checkout", "--svn", source, "rails_app"

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