require 'externals/test/repository'
require 'externals/test/svn_repository_helper'

module Externals
  module Test
    class ModulesSvnBranchesRepository < Repository
      include SvnRepositoryHelper

      def initialize
        super "modules_with_branches", "svn"
      end

      def build_here
        puts `svnadmin create #{name}`

        `mkdir workdir` unless File.exists? 'workdir'
        Dir.chdir 'workdir' do
          `rm -rf #{name}`

          cmd = "svn checkout \"#{clean_url}\""
          puts "about to run #{cmd}"
          puts `#{cmd}`
          raise unless $? == 0

          Dir.chdir name do
            `mkdir branches`
            raise unless $? == 0
            `mkdir current`
            raise unless $? == 0

            SvnProject.add_all
            puts `svn commit -m "created branch directory structure"`
            raise unless $? == 0

            `svn switch #{[clean_url, 'current'].join("/")}`
            raise unless $? == 0

            open("modules.txt", "w") do |f|
              f.write "line1 of modules.txt\n"
            end

            SvnProject.add_all
            puts `svn commit -m "created modules.txt"`
            raise unless $? == 0

            `svn copy #{
            [clean_url, "current"].join("/")
} #{[clean_url, "branches", "branch2"].join("/")
} -m "created branch2"`
            raise unless $? == 0

            puts `svn switch #{
            [clean_url, "branches", "branch2"].join("/")
}`
            raise unless $? == 0

            open("modules.txt", "w") do |f|
              f.write 'line 2 of modules.txt ... this is branch2!\n'
            end

            SvnProject.add_all
            puts `svn commit -m "changed modules.txt"`
            raise unless $? == 0
          end

          `rm -rf #{name}`
          raise unless $? == 0
        end
      end

    end
  end
end