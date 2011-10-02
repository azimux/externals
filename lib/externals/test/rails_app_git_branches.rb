require 'externals/test/repository'
require 'externals/test/git_repository_from_internet'
require 'externals/test/svn_repository_from_dump'
require 'externals/test/engines_with_branch1'
require 'externals/test/fake_rails_repository'

module Externals
  module Test
    class RailsAppGitBranches < Repository
      def initialize
        super "rails_app", File.join("git", "branches")
        dependents.merge!(
          :acts_as_list => GitRepositoryFromInternet.new("acts_as_list.git"),
          :redhillonrails_core => SvnRepositoryFromDump.new("redhillonrails_core"),
          :foreign_key_migrations => SvnRepositoryFromDump.new("foreign_key_migrations"),
          :engines => EnginesWithBranch1.new,
          :rails => FakeRailsRepository.new
        )
        dependents[:foreign_key_migrations].attributes[:revision] = "2"
        dependents[:acts_as_list].attributes[:revision] =
          "9baff190a52c05cc542bfcaa7f77a91ce669f2f8"
      end

      def build_here
        if rails_version =~ /^3([^\d]|$)/
          puts `#{rails_exe} new #{name}`
          raise unless $? == 0
        elsif rails_version =~ /^2([^\d]|$)/
          puts `#{rails_exe} #{name}`
          raise unless $? == 0
        else
          raise "can't determine rails version"
        end

        Dir.chdir name do
          Ext.run "touch_emptydirs"

          `git init`
          raise unless $? == 0
          Ext.run "init"
          raise " could not create .externals"  unless File.exists? '.externals'
          Ext.run "install", dependents[:acts_as_list].clean_dir

          #install a couple svn managed subprojects
          [:foreign_key_migrations, :redhillonrails_core].each do |proj|
            Ext.run "install", "--svn", 'file:///' + dependents[proj].clean_dir
          end

          ext = Ext.new
          main_project = ext.main_project

          unless !main_project.ignore_contains? "vendor/plugins/engines"
            raise
          end
          #install project with a branch
          Ext.run "install", dependents[:engines].clean_dir, "-b", "edge"
          unless main_project.ignore_contains? "vendor/plugins/engines"
            raise
          end

          #install fake_rails
          unless !main_project.ignore_contains? "vendor/rails"
            raise
          end
          Ext.run "install",
            dependents[:rails].clean_dir
          unless main_project.ignore_contains? "vendor/rails"
            raise
          end

          GitProject.add_all
          `git commit -m "created empty rails app with some subprojects"`
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
          raise if File.exists?(File.join('vendor', 'rails', 'activerecord', 'lib'))

          GitProject.add_all
          raise unless $? == 0
          `git commit -m "changed branch on engines subproject, removed rails"`
          raise unless $? == 0

          #switch back to master...
          `git checkout master`
          raise unless $? == 0
        end
      end

    end
  end
end
