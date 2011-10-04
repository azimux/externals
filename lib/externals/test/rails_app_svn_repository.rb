require 'externals/test/repository'
require 'externals/test/git_repository_from_internet'
require 'externals/test/svn_repository_from_dump'
require 'externals/test/svn_repository_helper'
require 'externals/test/fake_rails_repository'
require 'externals/test/modules_svn_repository'
require 'externals/test/rails_app_unmanaged'
require 'externals/test/engines'

module Externals
  module Test
    class RailsAppSvnRepository < Repository
      include SvnRepositoryHelper

      def initialize
        super "rails_app", "svn"
        dependents.merge!(
          :acts_as_list => GitRepositoryFromInternet.new("acts_as_list.git"),
          :ssl_requirement => GitRepositoryFromInternet.new("ssl_requirement.git"),
          :engines => Engines.new,
          :redhillonrails_core => SvnRepositoryFromDump.new("redhillonrails_core"),
          :empty_plugin => SvnRepositoryFromDump.new("empty_plugin"),
          #fkm seems to cause problems when running tests, concerning a corrupt repository.
          #commenting out for now.
          #:foreign_key_migrations => SvnRepositoryFromDump.new("foreign_key_migrations", ""),
          :rails => FakeRailsRepository.new,
          :modules => ModulesSvnRepository.new,
          :rails_app_unmanaged => RailsAppUnmanaged.new
        )

        dependents[:ssl_requirement].attributes[:revision] =
          "aa2dded823f8a9b378c22ba0159971508918928a"
      end

      def build_here
        puts `svnadmin create #{name}`
        raise unless $? == 0

        mkdir_p "workdir"
        Dir.chdir 'workdir' do
          rm_rf_ie name

          cmd = "svn checkout \"#{clean_url}\""
          puts `#{cmd}`
          raise unless $? == 0

          Dir.entries(dependents[:rails_app_unmanaged].clean_dir).each do |file|
            unless %w(.. .).include? file.to_s
              cp_a File.join(dependents[:rails_app_unmanaged].clean_dir, file), name
            end
          end

          Dir.chdir name do
            SvnProject.add_all
            puts `svn commit -m "created initial project"`
            raise unless $? == 0

            `svn up`
            raise unless $? == 0

            Ext.run "init"
            raise " could not create .externals"  unless File.exists? '.externals'

            # this line is necessary as ext can't perform the necessary
            # ignores otherwise if vendor and vendor/plugins haven't been added
            SvnProject.add_all
            #            puts `svn commit -m "added .externals file"`
            #            raise unless $? == 0

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

            #install project with a non-default path
            Ext.run "install", "--svn",
              "#{dependents[:modules].clean_url}",
              "modules"

            SvnProject.add_all

            puts `svn commit -m "created empty rails app with some subprojects"`
            unless $? == 0
              raise
            end
          end

          rm_rf "workdir"
        end
      end
    end

  end
end
