require 'git_repository'
require 'git_repository_from_bundle'
require 'svn_repository_from_dump'
require 'engines_with_branch1'
require 'fake_rails_repository'
require 'rails_app_unmanaged'

module Externals
  module Test
    class RailsAppGitBranches < GitRepository
      def initialize
        super("rails_app", File.join("git", "branches"))
        dependents.merge!(
          :acts_as_list => GitRepositoryFromBundle.new("acts_as_list"),
          :redhillonrails_core => SvnRepositoryFromDump.new("redhillonrails_core"),
          :foreign_key_migrations => SvnRepositoryFromDump.new("foreign_key_migrations"),
          :engines => EnginesWithBranch1.new,
          :rails => FakeRailsRepository.new,
          :rails_app_unmanaged => RailsAppUnmanaged.new
        )
        dependents[:foreign_key_migrations].attributes[:revision] = "2"
        dependents[:acts_as_list].attributes[:revision] =
          "9baff190a52c05cc542bfcaa7f77a91ce669f2f8"
      end

      def build_here
        mkdir "#{name}.git"
        Dir.chdir "#{name}.git" do
          `git init --bare -b master`
          raise unless $? == 0
        end

        cp_a dependents[:rails_app_unmanaged].clean_dir, "#{name}.working"

        Dir.chdir "#{name}.working" do
          Ext.run "touch_emptydirs"

          `git init -b master`
          raise unless $? == 0

          Ext.run "init"
          raise " could not create .externals" unless File.exist?('.externals')

          proj = dependents[:acts_as_list]
          Ext.run "install", proj.clean_dir, "vendor/plugins/#{proj.name}"

          #install a couple svn managed subprojects
          [:foreign_key_migrations, :redhillonrails_core].each do |project_name|
            proj = dependents[project_name]
            Ext.run "install", "--svn", 'file:///' + proj.clean_dir, "vendor/plugins/#{proj.name}"
          end

          ext = Ext.new
          main_project = ext.main_project

          if main_project.ignore_contains? "vendor/plugins/engines"
            raise
          end

          #install project with a branch
          proj = dependents[:engines]
          Ext.run "install", proj.clean_dir, "-b", "edge", "vendor/plugins/#{proj.name}"
          unless main_project.ignore_contains? "vendor/plugins/#{proj.name}"
            raise
          end

          #install fake_rails
          if main_project.ignore_contains? "vendor/rails"
            raise
          end

          proj = dependents[:rails]
          Ext.run "install", proj.clean_dir, "vendor/#{proj.name}"

          unless main_project.ignore_contains? "vendor/#{proj.name}"
            raise
          end

          GitProject.add_all
          `git commit -m "created empty rails app with some subprojects"`
          raise unless $? == 0

          `git push ../#{name}.git HEAD:master`
          raise unless $? == 0

          #let's create a branch for the main project called 'new_branch' and a
          #branch for the engines subproject called 'new_branch' and make sure
          #that checking one out and doing "ext up" correctly changes the branch
          #of the subproject
          `git checkout -b new_branch`
          raise unless $? == 0

          ext = Ext.new
          main_project = ext.main_project

          #update .externals
          ext.configuration["vendor/plugins/engines"]["branch"] = "branch1"
          ext.configuration.write

          #let's uninstall rails
          Ext.run "uninstall", "-f", "rails"
          raise if File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

          GitProject.add_all
          raise unless $? == 0

          `git commit -m "changed branch on engines subproject, removed rails"`
          raise unless $? == 0

          `git push ../#{name}.git HEAD:new_branch`
          raise unless $? == 0
        end

        rm_rf "#{name}.working"
      end
    end
  end
end
