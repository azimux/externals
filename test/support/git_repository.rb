require 'externals/test/repository'

module Externals
  module Test
    class GitRepository < Repository
      def clean_dir
        "#{super}.git"
      end

      def pristine_dir
        "#{super}.git"
      end
    end
  end
end
