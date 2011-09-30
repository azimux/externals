require 'externals/test/repository'
require 'find'

module Externals
  module Test
    class FakeRailsRepository < Repository
      def initialize
        super "rails.git", "fake"
      end

      def build_here
        `rm -r fake_rails`
        `rm -r full_rails`
        if File.exists? 'C:\\tmp\\rails'
          puts `cp -a C:\\tmp\\rails full_rails`
          raise unless $? == 0
        elsif File.exists? '/tmp/rails'
          puts `cp -a /tmp/rails full_rails`
          raise unless $? == 0
        else
          puts `git clone git://github.com/rails/rails.git full_rails`
          raise unless $? == 0
        end
        puts `cp -a full_rails fake_rails`
        raise unless $? == 0

        #let's make the repo smaller by removing all but 1 file from each
        #directory to save time
        Dir.chdir 'fake_rails' do
          puts `rm -rf .git`
          raise unless $? == 0
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
        `rm -r fake_rails`
        `rm -r full_rails`
      end

    end
  end
end
