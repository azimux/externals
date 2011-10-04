require 'externals/test/repository'

module Externals
  module Test
    class Engines < GitRepositoryFromInternet
      def initialize
        super "engines.git", "git", "git://github.com/azimux"
      end
    end
  end
end