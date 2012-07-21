require 'repository'

module Externals
  module Test
    class RailsAppUnmanaged < Repository
      def initialize
        super "rails_app", "unmanaged"
      end

      def build_here
        rm_rf name
        if rails_version =~ /^3([^\d]|$)/
          puts `#{rails_exe} new #{name}`
          raise unless $? == 0
        elsif rails_version =~ /^2([^\d]|$)/
          puts `#{rails_exe} #{name}`
          raise unless $? == 0
        else
          raise "can't determine rails version"
        end
      end

    end
  end
end
