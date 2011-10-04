require 'externals/test/repository'

module Externals
  module Test
    class GitRepositoryFromInternet < Repository
      attr_accessor :url
      def initialize name, subpath = nil, url = nil
        super name, subpath || "git"
        self.url = url || "git://github.com/rails"
      end

      #builds the test repository in the current directory
      def build_here
        puts `git clone --bare #{url}/#{name} #{name}`
        raise unless $? == 0
      end
    end
  end
end