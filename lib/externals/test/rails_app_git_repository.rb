require 'externals/test/repository'
require 'externals/test/git_repository_from_internet'
require 'externals/test/svn_repository_from_dump'

module Externals
  module Test
    class RailsAppGitRepository < Repository
      def initialize
        super "rails_app", "git"
        dependents.merge!(
          :acts_as_list => GitRepositoryFromInternet.new("acts_as_list.git"),
          :redhillonrails_core => SvnRepositoryFromDump.new("redhillonrails_core"),
          :foreign_key_migrations => SvnRepositoryFromDump.new("foreign_key_migrations")
        )
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
          #        parts = 'workdir/checkout/rails_app/vendor/plugins/foreign_key_migrations/lib/red_hill_consulting/foreign_key_migrations/active_record/connection_adapters/.svn/text-base/table_definition.rb.svn-base'.split('/')
          #        if File.exists? File.join(*parts)
          #          Dir.chdir File.join(*(parts[0..-2])) do
          #            File.delete parts[-1]
          #          end
          #        end
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

          Dir.chdir File.join('vendor', 'plugins', 'foreign_key_migrations') do
            raise unless `svn info` !~ /^.*:\s*2\s*$/i
            raise unless $? == 0
          end

          Ext.run "freeze", "foreign_key_migrations", "2"
          Ext.run "freeze", "acts_as_list", "9baff190a52c05cc542bfcaa7f77a91ce669f2f8"

          GitProject.add_all
          `git commit -m "created empty rails app with some subprojects"`
          raise unless $? == 0
        end
      end
      
    end
  end
end
