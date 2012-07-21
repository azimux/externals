require 'externals/test/repository'
require 'externals/test/svn_repository_helper'

module Externals
  module Test
    class SvnRepositoryFromDump < Repository
      include SvnRepositoryHelper

      def initialize name, subpath = nil
        super name, subpath || "svn"
      end

      #builds the test repository in the current directory
      def build_here
        cp_a File.join(root_dir, "test", "setup", "#{name}.svn.gz"), "."

        puts `gzip -f -d #{name}.svn.gz`
        raise unless $? == 0
        puts `svnadmin create #{name}`
        raise unless $? == 0
        puts `svnadmin load #{name} < #{name}.svn`
        raise unless $? == 0
      end

    end
  end
end