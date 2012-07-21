require 'externals/test/git_repository'

module Externals
  module Test
    class BasicGitRepository < GitRepository
      def initialize
        super "basic", "git"
      end

      def build_here
        repo_name = "#{name}.git"

        mkdir repo_name

        Dir.chdir("#{repo_name}") do
          `git init --bare`

          raise unless $? == 0
        end

        mkdir "#{name}.local"

        Dir.chdir("#{name}.local") do
          `git init`

          raise unless $? == 0

          open 'readme.txt', 'w' do |f|
            f.write "readme.txt Line 1
            Line 2
            Line 3"
          end

          `git add .`
          raise unless $? == 0
          `git commit -m "added readme.txt"`
          raise unless $? == 0

          open 'readme.txt', 'a' do |f|
            f.write "line 4"
          end

          `git add .`
          raise unless $? == 0
          `git commit -m "added a line to readme.txt"`
          raise unless $? == 0

          puts `git push ../#{repo_name} HEAD:master`
          raise unless $? == 0
        end

        rm_rf "#{name}.local"
      end

    end
  end
end
