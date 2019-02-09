require 'repository'
require 'git_repository_from_bundle'
require 'svn_repository_from_dump'
require 'svn_repository_helper'
require 'fake_rails_repository'
require 'modules_svn_repository'
require 'rails_app_unmanaged'
require 'some_subproject_with_edge'

module Externals
  module Test
    class RailsAppSvnRepository < Repository
      include SvnRepositoryHelper

      def initialize
        super "rails_app", "svn2"
        dependents.merge!(
          :acts_as_list => GitRepositoryFromBundle.new("acts_as_list"),
          :ssl_requirement => GitRepositoryFromBundle.new("ssl_requirement"),
          :engines => SomeSubprojectWithEdge.new,
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
            raise " could not create .externals"  unless File.exist?('.externals')

            # this line is necessary as ext can't perform the necessary
            # ignores otherwise if vendor and vendor/plugins haven't been added
            SvnProject.add_all
            #            puts `svn commit -m "added .externals file"`
            #            raise unless $? == 0

            #install some git subprojects
            Ext.run "install", dependents[:acts_as_list].clean_dir
            #we have to use file:// to test export, because without that
            #git clone optimizes by copying and igores --depth
            Ext.run "install", "file://#{dependents[:rails].clean_dir}"

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
