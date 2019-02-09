require 'git_repository'
require 'git_repository_from_bundle'
require 'svn_repository_from_dump'
require 'rails_app_unmanaged'

module Externals
  module Test
    class RailsAppGitRepository < GitRepository
      def initialize
        super "rails_app", "git"
        dependents.merge!(
          :acts_as_list => GitRepositoryFromBundle.new("acts_as_list"),
          :redhillonrails_core => SvnRepositoryFromDump.new("redhillonrails_core"),
          :foreign_key_migrations => SvnRepositoryFromDump.new("foreign_key_migrations"),
          :rails_app_unmanaged => RailsAppUnmanaged.new
        )
        dependents[:foreign_key_migrations].attributes[:revision] = "2"
        dependents[:acts_as_list].attributes[:revision] =
          "9baff190a52c05cc542bfcaa7f77a91ce669f2f8"
      end

      def build_here
        mkdir "#{name}.git"
        Dir.chdir "#{name}.git" do
          `git init --bare`
          raise unless $? == 0
        end

        cp_a dependents[:rails_app_unmanaged].clean_dir, "#{name}.working"

        Dir.chdir "#{name}.working" do
          Ext.run "touch_emptydirs"

          `git init`
          raise unless $? == 0
          Ext.run "init"
          raise " could not create .externals"  unless File.exist?('.externals')
          Ext.run "install", dependents[:acts_as_list].clean_dir

          #install a couple svn managed subprojects
          [:foreign_key_migrations, :redhillonrails_core].each do |proj|
            Ext.run "install", "--svn", 'file:///' + dependents[proj].clean_dir
          end

          Dir.chdir File.join('vendor', 'plugins', 'foreign_key_migrations') do
            raise unless `svn info` !~ /^.*:\s*2\s*$/i
            raise unless $? == 0
          end

          Ext.run "freeze", "foreign_key_migrations", "2"
          Ext.run "freeze", "acts_as_list", "9baff190a52c05cc542bfcaa7f77a91ce669f2f8"

          GitProject.add_all
          `git commit -m "created empty rails app with some subprojects"`
          raise unless $? == 0

          `git push ../#{name}.git HEAD:master`
          raise unless $? == 0
        end

        rm_rf "#{name}.working"
      end

    end
  end
end
