require 'git_repository'

module Externals
  module Test

    class SomeSubprojectWithEdge < GitRepository
      def initialize
        super "some_subproject_with_edge", File.join("git")
      end

      def build_here
        mkdir "#{name}.git"
        Dir.chdir "#{name}.git" do
          `git init --bare`
          raise unless $? == 0
        end

        mkdir "#{name}.working"

        Dir.chdir("#{name}.working") do
          `git clone #{File.join("..", "/#{name}.git")}`
          raise unless $? == 0

          Dir.chdir(name) do
            open 'some_subproject_with_edge_readme.txt', 'w' do |f|
              f.write "Line 1
            Line 2
            Line 3
            "
            end

            mkdir "lib"

            Dir.chdir("lib") do
              open("somelib.rb", "w") do |f|
                f.write "#!/bin/ruby
puts 'lulz!'
"
              end
            end

            `git add .`
            raise unless $? == 0
            `git commit -m "added some_subproject_with_edge_readme.txt and somelib.rb"`
            raise unless $? == 0

            open 'simple_readme.txt', 'a' do |f|
              f.write "line 4"
            end

            Dir.chdir("lib") do
              open("somelib.rb", "w") do |f|
                f.write "#!/bin/ruby
puts 'double lulz!'
"
              end
            end

            `git add .`
            raise unless $? == 0
            `git commit -m "added a line to simple_readme.txt and modified somelib.rb"`
            raise unless $? == 0

            `git checkout -b edge`
            raise unless $? == 0

            Dir.chdir("lib") do
              open("somelib.rb", "w") do |f|
                f.write "#!/bin/ruby
puts 'living on the edge'
"
              end
            end

            `git add .`
            raise unless $? == 0
            `git commit -m "on the edge"`
            raise unless $? == 0

            `git push origin master:master`
            raise unless $? == 0
            `git push origin edge:edge`
            raise unless $? == 0
          end
        end

        rm_rf "#{name}.working"
      end
    end
  end
end
