require 'externals/test/repository'
require 'find'
require 'externals/test/git_repository_from_internet'

module Externals
  module Test
    class FakeRailsRepository < Repository
      def initialize
        super "rails.git", "fake"
      end

      def build_here
        repository = GitRepositoryFromInternet.new("rails")
        repository.prepare

        rm_rf "fake_rails"

        `git clone #{repository.clean_dir} fake_rails`
        
        #let's make the repo smaller by removing all but 1 file from each
        #directory to save time
        Dir.chdir 'fake_rails' do
          rm_rf ".git"
        end

        dirs = []
        Find.find('fake_rails') do |f|
          dirs << f if File.directory?(f)
        end

        dirs.each do |dir|
          files = Dir.entries(dir)

          Dir.chdir(dir) do
            files = files.select {|e|e != ".gitignore" && File.file?(e)}.sort
            files.shift #let's keep the first file in the list.
            files.each do |file|
              File.delete(file)
            end
          end
        end

        raise "why is rails already here?" if File.exists? 'rails.git'

        Dir.mkdir('rails.git')

        Dir.chdir('rails.git') do
          puts `git init --bare`
        end

        Dir.chdir 'fake_rails' do
          puts `git init`
          puts `git add .`
          puts `git commit -m "rails with all but 1 file per directory deleted"`
          puts `git push ../rails.git master`
        end
        rm_rf "fake_rails"
      end

    end
  end
end
