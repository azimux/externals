require 'externals/test/repository'

module Externals
  module Test
    class EnginesWithBranch1 < Repository
      def initialize
        super "engines.git", File.join("git", "with_branch1")
        dependents.merge!(
          :other_engines => GitRepositoryFromInternet.new(
            "engines.git",
            nil,
            "git://github.com/azimux"
          )
        )
      end

      #builds the test repository in the current directory
      def build_here
        `rm -r #{name}`
        
        puts `git clone --bare #{dependents[:other_engines].clean_dir} #{name}`
        raise unless $? == 0

        `rm -r workdir`
        `mkdir workdir`
        Dir.chdir 'workdir' do
          `git clone #{clean_dir}`
          raise unless $? == 0
          Dir.chdir name.gsub(".git", "") do
            `git push origin master:branch1`
            raise unless $? == 0
          end
        end
        `rm -r workdir`
        raise unless $? == 0
      end

    end
  end
end