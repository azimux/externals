require 'git_repository'

module Externals
  module Test
    class GitRepositoryFromBundle < GitRepository
      attr_accessor :bundle_name

      def initialize name, subpath = nil, bundle_name = nil
        super name, subpath || "git"
        self.bundle_name = bundle_name || self.name
      end

      #builds the test repository in the current directory
      def build_here
        mkdir "#{name}.git"
        Dir.chdir("#{name}.git") do
          `git init --bare`
          raise unless $? == 0

          bundle_path = File.join(root_dir, "test", "setup", "#{bundle_name}.bundle")
          `git fetch #{bundle_path} master:master`
          raise unless $? == 0
        end
      end
    end
  end
end