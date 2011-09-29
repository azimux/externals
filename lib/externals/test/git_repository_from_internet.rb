require 'externals/test/repository'

module Externals
  module Test
    class GitRepositoryFromInternet < Repository
      def initialize name, subpath = nil
        super name, subpath || "git"
      end

      #builds the test repository in the current directory
      def build_here
        puts `git clone --bare git://github.com/rails/#{name} #{name}`
      end
    end
  end
end