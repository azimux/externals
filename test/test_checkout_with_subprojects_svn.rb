$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
$:.unshift File.join(File.dirname(__FILE__), 'support') if $0 == __FILE__

require 'ext_test_case'
require 'externals/ext'
require 'rails_app_svn_repository'

module Externals
  module Test
    class TestCheckoutWithSubprojectsSvn < ::Test::Unit::TestCase
      include ExtTestCase

      def test_checkout_with_subproject
        repository = RailsAppSvnRepository.new
        repository.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout")
        rm_rf_ie workdir
        mkdir_p workdir
        Dir.chdir workdir do
          source = repository.clean_url

          puts "About to checkout #{source}"
          Ext.run "checkout", "--svn", source, 'rails_app'

          Dir.chdir 'rails_app' do
            assert File.exist?('.svn')

            %w(redhillonrails_core acts_as_list).each do |proj|
              puts(ignore_text = `svn propget svn:ignore vendor/plugins`)
              assert(ignore_text =~ /^#{proj}$/)
            end

            puts(ignore_text = `svn propget svn:ignore vendor`)
            assert(ignore_text =~ /^rails$/)

            %w(redhillonrails_core acts_as_list some_subproject_with_edge).each do |proj|
              assert File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
            end

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            assert File.exist?(File.join('vendor', 'rails', '.git'))

            Dir.chdir File.join('vendor', 'rails') do
              heads = File.readlines("heads").map(&:strip)
              assert_equal 3, heads.size
              heads.each do |head|
                assert head =~ /^[0-9a-f]{40}$/
              end

              assert `git show #{heads[0]}` =~
                /^\s*commit\s+#{heads[0]}\s*$/
            end

            assert File.exist?(File.join('modules', 'modules.txt'))

            assert File.read(File.join('modules', 'modules.txt')) =~ /line1 of/

            Dir.chdir File.join('vendor', 'plugins', 'some_subproject_with_edge') do
              assert(`git branch -a` =~ /^\*\s*edge\s*$/)
              assert(`git branch -a` !~ /^\*\s*master\s*$/)
            end
          end
        end
      end

      def test_update_with_missing_subproject_git
        repository = RailsAppSvnRepository.new
        repository.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout")
        rm_rf_ie workdir
        mkdir_p workdir
        Dir.chdir workdir do
          source = repository.clean_url

          puts "About to checkout #{source}"
          Ext.run "checkout", "--svn", source, 'rails_app'

          Dir.chdir 'rails_app' do
            pretests = proc do
              assert File.exist?('.svn')
              assert !File.exist?(File.join('vendor', 'plugins', 'ssl_requirement', 'lib'))
              assert File.read(".externals") =~ /rails/
              assert File.read(".externals") !~ /ssl_requirement/
            end

            pretests.call

            #add a project
            workdir2 = File.join("workdir2")
            rm_rf_ie workdir2
            mkdir_p workdir2

            Dir.chdir workdir2 do
              puts "About to checkout #{source}"
              Ext.run "checkout", "--svn", source, 'rails_app'

              Dir.chdir "rails_app" do
                #install a new project
                subproject = GitRepositoryFromBundle.new("ssl_requirement")
                Ext.run "install", subproject.clean_dir

                SvnProject.add_all

                repository.mark_dirty
                puts `svn commit -m "added another subproject (ssl_requirement)"`
              end
            end

            pretests.call

            #update the project and make sure ssl_requirement was added and checked out
            Ext.run "update"
            assert File.read(".externals") =~ /ssl_requirement/
            assert File.exist?(File.join('vendor', 'plugins', 'ssl_requirement', 'lib'))
          end
        end
      end

      def test_update_with_missing_subproject_by_revision_git
        repository = RailsAppSvnRepository.new
        repository.prepare
        subproject = GitRepositoryFromBundle.new("ssl_requirement")
        subproject.prepare
        revision = "aa2dded823f8a9b378c22ba0159971508918928a"
        subproject_name = subproject.name.gsub(".git", "")

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout")
        rm_rf_ie workdir
        mkdir_p workdir
        Dir.chdir workdir do
          source = repository.clean_url

          puts "About to checkout #{source}"
          Ext.run "checkout", "--svn", source, 'rails_app'

          Dir.chdir 'rails_app' do

            pretests = proc do
              assert File.exist?('.svn')
              assert !File.exist?(File.join('vendor', 'plugins', subproject_name, 'lib'))
              assert File.read(".externals") =~ /rails/
              assert File.read(".externals") !~ /#{subproject}/
            end

            pretests.call

            #add a project
            workdir2 = "workdir2"
            rm_rf_ie workdir2
            mkdir_p workdir2

            Dir.chdir workdir2 do

              #install a new project
              puts "About to checkout #{source}"
              Ext.run "checkout", "--svn", source, 'rails_app'

              Dir.chdir "rails_app" do
                Ext.run "install", subproject.clean_dir

                Dir.chdir File.join("vendor", 'plugins', subproject_name) do
                  assert `git show HEAD` !~ /^\s*commit\s*#{revision}\s*$/i
                end
                #freeze it to a revision
                Ext.run "freeze", subproject_name, revision
                Dir.chdir File.join("vendor", 'plugins', subproject_name) do
                  regex = /^\s*commit\s*#{revision}\s*$/i
                  output = `git show HEAD`
                  result = output =~ regex
                  unless result
                    puts "Expecting output to match #{regex} but it was: #{output}"
                  end
                  assert result
                end

                SvnProject.add_all

                repository.mark_dirty
                puts `svn commit -m "added another subproject (#{subproject}) frozen to #{revision}"`
              end
            end

            pretests.call

            #update the project and make sure ssl_requirement was added and checked out at the right revision
            Ext.run "update"
            assert File.read(".externals") =~ /ssl_requirement/

            assert File.exist?(File.join('vendor', 'plugins', subproject_name, 'lib'))

            Dir.chdir File.join("vendor",'plugins', subproject_name) do
              assert `git show HEAD` =~ /^\s*commit\s*#{revision}\s*$/i
            end
          end
        end
      end

      def test_update_with_missing_subproject_svn
        repository = RailsAppSvnRepository.new
        repository.prepare
        subproject = SvnRepositoryFromDump.new("empty_plugin")
        subproject.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout")
        rm_rf_ie workdir
        mkdir_p workdir
        Dir.chdir workdir do
          source = repository.clean_url

          puts "About to checkout #{source}"
          Ext.run "checkout", "--svn", source, 'rails_app'

          Dir.chdir 'rails_app' do
            pretests = proc do
              assert File.exist?('.svn')
              assert !File.exist?(File.join('vendor', 'plugins', subproject.name, 'lib'))
              assert File.read(".externals") =~ /rails/
              assert File.read(".externals") !~ /empty_plugin/
            end

            pretests.call

            #add a project
            workdir2 = File.join "workdir2", "svn"
            rm_rf_ie workdir2
            mkdir_p workdir2

            Dir.chdir workdir2 do
              puts "About to checkout #{source}"
              Ext.run "checkout", "--svn", source, 'rails_app'

              Dir.chdir 'rails_app' do
                #install a new project
                Ext.run "install", "--svn", subproject.clean_url

                SvnProject.add_all

                repository.mark_dirty
                puts `svn commit -m "added another subproject (#{subproject.name})"`
              end
            end

            pretests.call

            #update the project and make sure ssl_requirement was added and checked out
            Ext.run "update"
            assert File.read(".externals") =~ /empty_plugin/
            assert File.exist?(File.join('vendor', 'plugins', subproject.name, 'lib'))
          end
        end
      end

      def test_export_with_subproject
        repository = RailsAppSvnRepository.new
        repository.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "export")
        rm_rf_ie workdir
        mkdir_p workdir
        Dir.chdir workdir do
          source = repository.clean_url

          puts "About to export #{source}"
          Ext.run "export", "--svn", source, 'rails_app'

          Dir.chdir 'rails_app' do
            assert !File.exist?('.svn')

            Dir.chdir File.join('vendor', 'rails') do
              heads = File.readlines("heads").map(&:strip)
              assert_equal 3, heads.size
              heads.each do |head|
                assert head =~ /^[0-9a-f]{40}$/
              end

              assert `git show #{heads[0]}` !~
                /^\s*commit\s+#{heads[0]}\s*$/
            end

            %w(redhillonrails_core acts_as_list).each do |proj|
              puts "filethere? #{proj}: #{File.exist?(File.join('vendor', 'plugins', proj, 'lib'))}"
              if !File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
                puts "here"
              end
              assert File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
            end

            %w(redhillonrails_core).each do |proj|
              assert !File.exist?(File.join('vendor', 'plugins',proj, '.svn'))
            end

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            # Check that engines subproject has content expected for edge branch
            ext = Ext.new

            assert_equal(ext.configuration["vendor/plugins/some_subproject_with_edge"]["branch"], "edge")
            assert_equal(ext.configuration["vendor/plugins/some_subproject_with_edge"]["revision"], nil)

            Dir.chdir File.join("vendor", "plugins", "some_subproject_with_edge") do
              assert(File.read(File.join("lib", "somelib.rb")) =~ /living on the edge/)
            end
          end
        end
      end

      def test_export_with_subproject_by_revision
        # figure out the revision to set it to.
        sub_project_revision = nil
        sub_repository = SomeSubprojectWithEdge.new
        sub_repository.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "export")
        rm_rf_ie workdir
        mkdir_p workdir

        Dir.chdir workdir do
          `git clone #{sub_repository.clean_dir}`
          raise unless $? == 0

          Dir.chdir sub_repository.name do
            git_show = `git show origin/master`
            raise unless $? == 0

            sub_project_revision = /^commit:?\s*([a-f\d]+)$/.match(git_show)[1]
            assert(sub_project_revision =~ /^[a-f\d]+$/)
          end
        end

        # Change the project to use a revision instead of a branch
        repository = RailsAppSvnRepository.new
        repository.prepare
        repository.mark_dirty

        rm_rf_ie workdir
        mkdir_p workdir

        Dir.chdir workdir do
          Ext.run "checkout", "--svn", repository.clean_url

          Dir.chdir repository.name do
            assert(sub_project_revision)
            Ext.run "freeze", "some_subproject_with_edge", sub_project_revision
            ext = Ext.new
            ext.configuration["vendor/plugins/some_subproject_with_edge"].rm_setting("branch")
            ext.configuration.write

            SvnProject.add_all
            `svn commit -m "changed some_subproject_with_edge to use a revision instead"`
            raise unless $? == 0
          end
        end

        rm_rf_ie workdir
        mkdir_p workdir
        Dir.chdir workdir do
          source = repository.clean_url

          puts "About to export #{source}"
          Ext.run "export", "--svn", source, 'rails_app'

          Dir.chdir 'rails_app' do
            assert !File.exist?('.svn')

            # Check that engines subproject has content expected for sub_project_revision
            ext = Ext.new

            assert_equal(ext.configuration["vendor/plugins/some_subproject_with_edge"]["branch"], nil)
            assert_equal(ext.configuration["vendor/plugins/some_subproject_with_edge"]["revision"], sub_project_revision)

            Dir.chdir File.join("vendor", "plugins", "some_subproject_with_edge") do
              assert(File.read(File.join("lib", "somelib.rb")) !~ /living on the edge/)
              assert(File.read(File.join("lib", "somelib.rb")) =~ /'double lulz!'/)
            end
          end
        end
      end

    end
  end
end
