require 'externals/test/repository'
require 'externals/test/basic_git_repository'

module Externals
  module Test
    class SimpleGitWithSub < Repository
      def initialize
        super "simple_wth_sub", File.join("git", "5")
        dependents.merge!(
          :basic => BasicGitRepository.new
          )
      end

      def build_here
        mkdir name

        Dir.chdir("#{name}") do
          `git init`
          raise unless $? == 0

          open 'simple_readme.txt', 'w' do |f|
            f.write "simple_readme.txt Line 1
            Line 2
            Line 3
            "
          end

          `git add .`
          raise unless $? == 0
          `git commit -m "added simple_readme.txt"`
          raise unless $? == 0

          open 'simple_readme.txt', 'a' do |f|
            f.write "line 4"
          end

          `git add .`
          raise unless $? == 0
          `git commit -m "added a line to simple_readme.txt"`
          raise unless $? == 0

          # initialize externals
          Ext.run "init"

          mkdir "subs"

          Ext.run "touch_emptydirs"

          # adding a branch here exposes a bug
          Ext.run "install", "-g", "-b", "master",
            dependents[:basic].clean_dir, "subs/#{dependents[:basic].name}"

          `git add .`
          raise unless $? == 0
          `git commit -m "added basic subproject under subs"`
          raise unless $? == 0
        end
      end

    end
  end
end
