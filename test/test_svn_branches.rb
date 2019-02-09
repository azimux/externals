$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
$:.unshift File.join(File.dirname(__FILE__), 'support') if $0 == __FILE__
require 'ext_test_case'
require 'externals/ext'
require 'rails_app_svn_branches'

module Externals
  module Test
    class TestSvnBranches < ::Test::Unit::TestCase
      include ExtTestCase

      def test_checkout_with_subproject
        mode = "checkout"
        repository = RailsAppSvnBranches.new
        repository.prepare

        assert File.exist?(File.join(repository.clean_dir, "db"))

        workdir = File.join(root_dir, 'test', "tmp", "workdir", mode, "svn", "branches")
        mkdir_p workdir

        if File.exist?(File.join(workdir, "rails_app"))
          rm_r File.join(workdir, "rails_app")
        end

        Dir.chdir workdir do
          source = repository.clean_url
          if windows?
            source = source.gsub(/\\/, "/")
          end

          puts "About to #{mode} #{source}"
          Ext.run mode, "--svn", source, "-b", "current", 'rails_app'

          Dir.chdir 'rails_app' do
            assert File.exist?('.svn')

            %w(redhillonrails_core acts_as_list).each do |proj|
              ignore_text = `svn propget svn:ignore vendor/plugins`
              puts "ignore_text is:"
              puts ignore_text
              assert(ignore_text =~ /^#{proj}$/)
            end

            ignore_text = `svn propget svn:ignore vendor`
            assert(ignore_text =~ /^rails$/)

            %w(redhillonrails_core acts_as_list engines).each do |proj|
              assert File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
            end

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            assert File.exist?(File.join('vendor', 'rails', '.git'))

            assert File.exist?(File.join('modules', 'modules.txt'))

            assert File.read(File.join('modules', 'modules.txt')) =~ /line1 of/

            ext = Ext.new
            main_project = ext.main_project
            engines = ext.subproject("engines")
            modules = ext.subproject("modules")

            assert_equal "current", main_project.current_branch

            assert_equal "edge", engines.current_branch
            assert_equal "edge", ext.configuration["vendor/plugins/engines"]["branch"]

            assert_equal "current", modules.current_branch
            assert_equal "current", ext.configuration["modules"]["branch"]

            assert !File.exist?(File.join(%w(vendor plugins ssl_requirement)))
            assert !File.exist?(File.join(%w(vendor plugins empty_plugin)))

            #let's run update.  This can expose certain errors.
            Ext.run "update"

            `svn switch #{[source, "branches", "new_branch"].join("/")}`
            unless $? == 0
              raise
            end

            assert !File.exist?(File.join(%w(vendor plugins ssl_requirement)))
            assert !File.exist?(File.join(%w(vendor plugins empty_plugin)))

            assert !main_project.ignore_contains?("vendor/rails")

            ext = Ext.new
            main_project = ext.main_project
            engines = ext.subproject("engines")
            modules = ext.subproject("modules")

            assert_equal "branches/new_branch", main_project.current_branch

            assert_equal "edge", engines.current_branch
            assert_equal "branch1", ext.configuration["vendor/plugins/engines"]["branch"]

            assert_equal "current", modules.current_branch
            assert_equal "branches/branch2", ext.configuration["modules"]["branch"]

            Ext.run "up"

            assert File.exist?(File.join(%w(vendor plugins ssl_requirement)))
            assert File.exist?(File.join(%w(vendor plugins empty_plugin)))

            Dir.chdir File.join("vendor",'plugins', "ssl_requirement") do
              assert `git show HEAD` =~ /^\s*commit\s*#{
              repository.dependents[:ssl_requirement].attributes[:revision]
}\s*$/i
            end

            assert_equal "branches/new_branch", main_project.current_branch

            assert_equal "branch1", engines.current_branch
            assert_equal "branch1", ext.configuration["vendor/plugins/engines"]["branch"]

            assert_equal "branches/branch2", modules.current_branch
            assert_equal "branches/branch2", ext.configuration["modules"]["branch"]

            assert File.read(File.join('modules', 'modules.txt')) =~
              /line 2 of modules.txt ... this is branch2!/

            #let's run update.  This can expose certain errors.
            Ext.run "update"

            `svn switch #{[source, "current"].join("/")}`
            ext = Ext.new
            main_project = ext.main_project
            engines = ext.subproject("engines")
            modules = ext.subproject("modules")

            assert_equal "current", main_project.current_branch

            assert_equal "branch1", engines.current_branch
            assert_equal "edge", ext.configuration["vendor/plugins/engines"]["branch"]

            assert_equal "branches/branch2", modules.current_branch
            assert_equal "current", ext.configuration["modules"]["branch"]
            assert File.read(File.join('modules', 'modules.txt')) =~
              /line 2 of modules.txt ... this is branch2!/

            Ext.run "up"
            ext = Ext.new
            main_project = ext.main_project
            engines = ext.subproject("engines")
            modules = ext.subproject("modules")

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            assert File.exist?(File.join('vendor', 'rails', '.git'))

            assert_equal "current", main_project.current_branch

            assert_equal "edge", engines.current_branch
            assert_equal "edge", ext.configuration["vendor/plugins/engines"]["branch"]

            assert_equal "current", modules.current_branch
            assert_equal "current", ext.configuration["modules"]["branch"]
            assert File.read(File.join('modules', 'modules.txt')) !~
              /line 2 of modules.txt ... this is branch2!/
            assert File.read(File.join('modules', 'modules.txt')) =~ /line1 of/

            assert main_project.ignore_contains?("vendor/rails")

            # let's test the switch command.
            capture = StringIO.new
            begin
              $stdout = capture

              Ext.run "switch", "branches/new_branch"

              ext = Ext.new
              main_project = ext.main_project
              engines = ext.subproject("engines")
              modules = ext.subproject("modules")

            ensure
              $stdout = STDOUT
            end
            capture = capture.string

            assert_equal "branches/new_branch", main_project.current_branch

            assert_equal "branch1", engines.current_branch
            assert_equal "branch1", ext.configuration["vendor/plugins/engines"]["branch"]

            assert_equal "branches/branch2", modules.current_branch
            assert_equal "branches/branch2", ext.configuration["modules"]["branch"]

            assert capture =~ /WARNING:/
            assert capture =~ /rm\s+-rf?\s+vendor.rails/
            assert capture.scan(/rm/).size == 1

            assert !main_project.ignore_contains?("vendor/rails")

            [
              %w(vendor rails),
              %w(vendor plugins ssl_requirement),
              %w(vendor plugins empty_plugin)
            ].each do |dir|
              rm_r File.join(*dir)
              unless $? == 0
                raise
              end
            end

            assert File.read(File.join('modules', 'modules.txt')) =~
              /line 2 of modules.txt ... this is branch2!/

            capture = StringIO.new
            begin
              $stdout = capture

              Ext.run "switch", "current"
              ext = Ext.new
              main_project = ext.main_project
              engines = ext.subproject("engines")
              modules = ext.subproject("modules")

            ensure
              $stdout = STDOUT
            end

            capture = capture.string

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            assert File.exist?(File.join('vendor', 'rails', '.git'))


            assert_equal "current", main_project.current_branch

            assert_equal "edge", engines.current_branch
            assert_equal "edge", ext.configuration["vendor/plugins/engines"]["branch"]

            assert_equal "current", modules.current_branch
            assert_equal "current", ext.configuration["modules"]["branch"]

            assert capture !~ /WARNING:/
            assert capture !~ /rm\s+-rf?\s+vendor.rails/
            assert main_project.ignore_contains?("vendor/rails")
            assert capture.scan(/rm/).size == 0

            assert File.read(File.join('modules', 'modules.txt')) !~
              /line 2 of modules.txt ... this is branch2!/
            assert File.read(File.join('modules', 'modules.txt')) =~ /line1 of/
          end
        end
      end

      def test_export_with_subproject
        mode = "export"

        repository = RailsAppSvnBranches.new
        repository.prepare

        assert File.exist?(File.join(repository.clean_dir, "db"))

        workdir = File.join(root_dir, 'test', "tmp", "workdir", mode, "svn", "branch_test")
        rm_rf workdir
        mkdir_p workdir

        if File.exist?(File.join(workdir,"rails_app"))
          rm_r File.join(workdir, "rails_app")
        end

        Dir.chdir workdir do
          source = repository.clean_url
          if windows?
            source = source.gsub(/\\/, "/")
          end

          puts "About to #{mode} #{source}"
          Ext.run mode, "--svn", source, "-b", "current", 'rails_app'

          Dir.chdir 'rails_app' do
            assert !File.exist?('.svn')

            %w(redhillonrails_core).each do |proj|
              assert !File.exist?(File.join('vendor', 'plugins', proj, '.svn'))
            end

            %w(redhillonrails_core acts_as_list engines).each do |proj|
              assert File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
            end

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            assert File.exist?(File.join('vendor', 'rails', '.git'))

            assert File.exist?(File.join('modules', 'modules.txt'))

            assert File.read(File.join('modules', 'modules.txt')) =~ /line1 of/

            ext = Ext.new
            assert_equal "edge", ext.configuration["vendor/plugins/engines"]["branch"]
            assert_equal "current", ext.configuration["modules"]["branch"]

            assert !File.exist?(File.join(%w(vendor plugins ssl_requirement)))
            assert !File.exist?(File.join(%w(vendor plugins empty_plugin)))
          end
        end
      end

      def test_uninstall
        repository = RailsAppSvnBranches.new
        repository.prepare

        assert File.exist?(File.join(repository.clean_dir, "db"))

        workdir = File.join(root_dir, 'test', "tmp", "workdir","uninstall","svn","branches")
        mkdir_p workdir

        if File.exist?(File.join(workdir,"rails_app"))
          rm_r File.join(workdir, "rails_app")
        end

        Dir.chdir workdir do
          source = repository.clean_url

          puts "About to checkout #{source}"
          Ext.run "checkout", "--svn", "-b", "current", source, "rails_app"

          Dir.chdir 'rails_app' do
            mp = Ext.new.main_project

            projs = %w(redhillonrails_core acts_as_list)
            projs_i = projs.dup
            projs_ni = []

            #let's uninstall acts_as_list
            Ext.run "uninstall", "acts_as_list"

            projs_ni << projs_i.delete('acts_as_list')

            mp.assert_e_dne_i_ni proc{|a|assert(a)}, projs, [], projs_i, projs_ni

            Ext.run "uninstall", "-f", "redhillonrails_core"

            projs_ni << projs_i.delete('redhillonrails_core')

            projs_dne = []
            projs_dne << projs.delete('redhillonrails_core')

            mp.assert_e_dne_i_ni proc{|a|assert(a)}, projs, projs_dne, projs_i, projs_ni
          end
        end
      end

    end
  end
end
