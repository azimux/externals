require 'git_repository'
require 'find'
require 'git_repository_from_bundle'

module Externals
  module Test
    class FakeRailsRepository < GitRepositoryFromBundle
      def initialize
        super "rails", "fake", "fake_rails"
      end

      #def build_here
      #  repository = GitRepositoryFromInternet.new("rails")
      #  repository.prepare
      #
      #  rm_rf "fake_rails"
      #
      #  `git clone #{repository.clean_dir} fake_rails`
      #  raise unless $? == 0
      #
      #  #let's make the repo smaller by removing all but 1 file from each
      #  #directory to save time
      #  Dir.chdir 'fake_rails' do
      #    rm_rf ".git"
      #  end
      #
      #  delete_all_but_1_file :depth => 3
      #
      #  raise "why is rails already here?" if File.exist?('rails.git')
      #
      #  Dir.mkdir('rails.git')
      #
      #  Dir.chdir('rails.git') do
      #    puts `git init --bare`
      #    raise unless $? == 0
      #  end
      #
      #  Dir.chdir 'fake_rails' do
      #    puts `git init`
      #    raise unless $? == 0
      #    puts `git add .`
      #    raise unless $? == 0
      #    puts `git commit -m "rails with all but 1 file per directory deleted"`
      #    raise unless $? == 0
      #    puts `git push ../rails.git HEAD:master`
      #    raise unless $? == 0
      #
      #    head1 = nil
      #    head2 = nil
      #    # let's make a couple commits...
      #    open "heads", "a" do |file|
      #      head1 = `git show HEAD`.match(/^\s*commit\s+([0-9a-f]{40})\s*$/)[1]
      #      raise unless head1
      #      file.puts head1
      #      raise unless $? == 0
      #    end
      #    puts `git add .`
      #    raise unless $? == 0
      #    puts `git commit -m "dummy commit 1"`
      #    raise unless $? == 0
      #    puts `git push ../rails.git HEAD:master`
      #    raise unless $? == 0
      #
      #    open "heads", "a" do |file|
      #      head2 = `git show HEAD`.match(/^\s*commit\s+([0-9a-f]{40})\s*$/)[1]
      #      raise unless head2
      #      raise unless head1 != head2
      #      file.puts head2
      #      raise unless $? == 0
      #    end
      #    puts `git add .`
      #    raise unless $? == 0
      #    puts `git commit -m "dummy commit 2"`
      #    raise unless $? == 0
      #    puts `git push ../rails.git HEAD:master`
      #    raise unless $? == 0
      #
      #    open "heads", "a" do |file|
      #      head2 = `git show HEAD`.match(/^\s*commit\s+([0-9a-f]{40})\s*$/)[1]
      #      raise unless head2
      #      raise unless head1 != head2
      #      file.puts head2
      #      raise unless $? == 0
      #    end
      #    puts `git add .`
      #    raise unless $? == 0
      #    puts `git commit -m "dummy commit 3"`
      #    raise unless $? == 0
      #    puts `git push ../rails.git HEAD:master`
      #    raise unless $? == 0
      #  end
      #  rm_rf "fake_rails"
      #end

      #private
      #def delete_all_but_1_file options = {}
      #  files        = Dir.entries(Dir.pwd) - %w(. ..)
      #  file_skipped = false
      #
      #  files.each do |file|
      #    if File.file?(file)
      #      if file_skipped
      #        File.delete(file)
      #      else
      #        file_skipped = true
      #      end
      #    elsif File.directory?(file)
      #      if options[:depth] && options[:depth] <= 0
      #        rm_rf(file)
      #      else
      #        new_options = options.dup
      #
      #        if new_options[:depth]
      #          new_options[:depth] -= 1
      #        end
      #        Dir.chdir(file) do
      #          delete_all_but_1_file(new_options)
      #        end
      #      end
      #    end
      #  end
      #end

    end
  end
end
