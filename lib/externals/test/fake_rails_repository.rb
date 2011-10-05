require 'externals/test/repository'
require 'find'
require 'externals/test/git_repository_from_internet'

module Externals
  module Test
    class FakeRailsRepository < Repository
      def initialize
        super "rails.git", "fake3"
      end

      def build_here
        repository = GitRepositoryFromInternet.new("rails")
        repository.prepare

        rm_rf "fake_rails"

        `git clone #{repository.clean_dir} fake_rails`
        raise unless $? == 0

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
          raise unless $? == 0
        end

        Dir.chdir 'fake_rails' do
          puts `git init`
          raise unless $? == 0
          puts `git add .`
          raise unless $? == 0
          puts `git commit -m "rails with all but 1 file per directory deleted"`
          raise unless $? == 0
          puts `git push ../rails.git master`
          raise unless $? == 0

          head1 = nil
          head2 = nil
          # let's make a couple commits...
          open "heads", "a" do |file|
            head1 = `git show HEAD`.match(/^\s*commit\s+([0-9a-f]{40})\s*$/)[1]
            raise unless head1
            file.puts head1
            raise unless $? == 0
          end
          puts `git add .`
          raise unless $? == 0
          puts `git commit -m "dummy commit 1"`
          raise unless $? == 0
          puts `git push ../rails.git master`
          raise unless $? == 0

          open "heads", "a" do |file|
            head2 = `git show HEAD`.match(/^\s*commit\s+([0-9a-f]{40})\s*$/)[1]
            raise unless head2
            raise unless head1 != head2
            file.puts head2
            raise unless $? == 0
          end
          puts `git add .`
          raise unless $? == 0
          puts `git commit -m "dummy commit 2"`
          raise unless $? == 0
          puts `git push ../rails.git master`
          raise unless $? == 0

          open "heads", "a" do |file|
            head2 = `git show HEAD`.match(/^\s*commit\s+([0-9a-f]{40})\s*$/)[1]
            raise unless head2
            raise unless head1 != head2
            file.puts head2
            raise unless $? == 0
          end
          puts `git add .`
          raise unless $? == 0
          puts `git commit -m "dummy commit 3"`
          raise unless $? == 0
          puts `git push ../rails.git master`
          raise unless $? == 0
        end
        rm_rf "fake_rails"
      end

    end
  end
end
