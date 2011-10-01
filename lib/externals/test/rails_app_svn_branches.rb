require 'externals/test/repository'
require 'externals/test/git_repository_from_internet'
require 'externals/test/svn_repository_from_dump'
require 'externals/test/svn_repository_helper'
require 'externals/test/engines_with_branch1'
require 'externals/test/fake_rails_repository'
require 'externals/test/modules_svn_branches_repository'

module Externals
  module Test
    class RailsAppSvnBranches < Repository
      include SvnRepositoryHelper

      def initialize
        super "rails_app_svn_branches", "svn"
        dependents.merge!(
          :acts_as_list => GitRepositoryFromInternet.new("acts_as_list.git"),
          :ssl_requirement => GitRepositoryFromInternet.new("ssl_requirement.git"),
          :engines => EnginesWithBranch1.new,
          :redhillonrails_core => SvnRepositoryFromDump.new("redhillonrails_core"),
          :empty_plugin => SvnRepositoryFromDump.new("empty_plugin"),
          #fkm seems to cause problems when running tests, concerning a corrupt repository.
          #commenting out for now.
          #:foreign_key_migrations => SvnRepositoryFromDump.new("foreign_key_migrations", ""),
          :rails => FakeRailsRepository.new,
          :modules => ModulesSvnBranchesRepository.new
        )

        dependents[:ssl_requirement].attributes[:revision] =
          "aa2dded823f8a9b378c22ba0159971508918928a"
      end

      def build_here
        puts `svnadmin create #{name}`

        `mkdir workdir` unless File.exists? 'workdir'
        Dir.chdir 'workdir' do
          `rm -r #{name}`
          cmd = "svn checkout \"#{clean_url}\""
          puts "about to run #{cmd}"
          puts `#{cmd}`
          raise unless $? == 0

          Dir.chdir name do
            `mkdir branches`
            raise unless $? == 0

            if rails_version =~ /^3([^\d]|$)/
              puts `#{rails_exe} new #{name}`
              raise unless $? == 0
            elsif rails_version =~ /^2([^\d]|$)/
              puts `#{rails_exe} #{name}`
              raise unless $? == 0
            else
              raise "can't determine rails version"
            end

            `mv #{name} current`
            raise unless $? == 0

            SvnProject.add_all
            puts `svn commit -m "created branch directory structure"`
            raise unless $? == 0

            puts `svn switch #{[clean_url, "current"].join("/")}`
            raise unless $? == 0

            Ext.run "init", "-b", "current"
            raise " could not create .externals"  unless File.exists? '.externals'

            # this line is necessary as ext can't perform the necessary
            # ignores otherwise if vendor and vendor/plugins haven't been added
            SvnProject.add_all

            #install some git subprojects
            [:rails, :acts_as_list].each do |proj|
              Ext.run "install", dependents[proj].clean_dir
            end

            #install a couple svn managed subprojects
            [
              #:foreign_key_migrations,
              :redhillonrails_core
            ].each do |proj|
              Ext.run "install", "--svn", dependents[proj].clean_url
            end

            #install project with a git branch
            Ext.run "install", dependents[:engines].clean_dir, "-b", "edge"

            #install project with a non-default path and svn branching
            Ext.run "install", "--svn",
              "#{dependents[:modules].clean_url}",
              "-b", "current",
              "modules"

            SvnProject.add_all

            puts `svn commit -m "created empty rails app with some subprojects"`
            raise unless $? == 0

            # now let's make a branch in the main project called new_branch
            `svn copy #{
            [clean_url, "current"].join("/")
} #{[clean_url, "branches", "new_branch"].join("/")} -m "creating branch" `
            raise unless $? == 0

            # let's update the .externals file in new_branch to reflect these changes
            `svn switch #{[clean_url, "branches", "new_branch"].join("/")}`
            raise unless $? == 0

            # let's remove rails from this branch
            Ext.run "uninstall", "-f", "rails"

            # add a git managed project...
            Ext.run "install", dependents[:ssl_requirement].clean_dir,
              "-r", dependents[:ssl_requirement].attributes[:revision]

            # add a svn managed project
            Ext.run "install", "--svn", dependents[:empty_plugin].clean_url

            ext = Ext.new
            ext.configuration["vendor/plugins/engines"]["branch"] = "branch1"
            ext.configuration["modules"]["branch"] = "branches/branch2"
            ext.configuration.write

            SvnProject.add_all
            `svn commit -m "updated .externals to point to new branches."`
            raise unless $? == 0
          end

          `rm -r #{name}`
          raise unless $? == 0
        end
      end

    end
  end

end
