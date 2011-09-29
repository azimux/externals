# To change this template, choose Tools | Templates
# and open the template in the editor.

module Externals
  module Test
    class SvnRepositoryFromDump < Repository
      def initialize name, subpath = nil
        super name, subpath || "svn"
      end

      #builds the test repository in the current directory
      def build_here
        puts `cp #{
        File.join root_dir, "test", "setup", "#{name}.svn.gz"
} .`

        raise unless $? == 0
        puts `gzip -d #{name}.svn.gz`
        raise unless $? == 0
        puts `svnadmin create #{name}`
        raise unless $? == 0
        puts `svnadmin load #{name} < #{name}.svn`
        raise unless $? == 0
      end
    end
  end
end