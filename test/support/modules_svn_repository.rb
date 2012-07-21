require 'repository'
require 'svn_repository_helper'

module Externals
  module Test
    class ModulesSvnRepository < Repository
      include SvnRepositoryHelper

      def initialize
        super "modules", "svn"
      end

      def build_here
        puts `svnadmin create #{name}`

        mkdir_p "workdir"
        Dir.chdir 'workdir' do
          rm_rf name

          cmd = "svn checkout \"#{clean_url}\""
          puts "about to run #{cmd}"
          puts `#{cmd}`
          raise unless $? == 0

          Dir.chdir name do
            open("modules.txt", "w") do |f|
              f.write "line1 of modules.txt\n"
            end

            SvnProject.add_all
            puts `svn commit -m "created modules.txt"`
            raise unless $? == 0
          end

          rm_rf name
        end
      end

    end
  end
end