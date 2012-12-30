require 'repository'

module Externals
  module Test
    class RailsAppUnmanaged < Repository
      def initialize
        super "rails_app", "unmanaged"
      end

      def build_here
        rm_rf name

        # git-bundle is just used as an alternative here to avoid creating
        # a dependency on something such as tar
        rails3_app = GitRepositoryFromBundle.new("rails3_app")
        rm_rf rails3_app.name

        `git clone #{rails3_app.bundle_path} -b master #{name}`
        raise unless $? == 0

        Dir.chdir(name) do
          rm_rf ".git"
        end
      end

    end
  end
end
