require 'externals/test/repository'

module Externals
  module Test
    class BasicGitRepository < Repository
      def initialize
        super "basic", "git"
      end

      def build_here
        mkdir name

        Dir.chdir("#{name}") do
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
        end
      end

    end
  end
end
