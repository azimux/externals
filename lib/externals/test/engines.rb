require 'externals/test/git_repository_from_internet'

module Externals
  module Test
    class Engines < GitRepositoryFromInternet
      def initialize
        super "engines", "git", "git://github.com/azimux"
      end
    end
  end
end