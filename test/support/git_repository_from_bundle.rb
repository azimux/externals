require 'git_repository'

module Externals
  module Test
    class GitRepositoryFromBundle < GitRepository
      attr_accessor :bundle_name

      def initialize name, subpath = nil, bundle_name = nil
        super name, subpath || "gitbundle"
        self.bundle_name = bundle_name || self.name
      end

      #builds the test repository in the current directory
      def build_here
        `git clone #{bundle_path} -b master #{name}.git`
        raise unless $? == 0
      end

      def bundle_path
        File.join(root_dir, "test", "setup", "#{bundle_name}.bundle")
      end
    end
  end
end
