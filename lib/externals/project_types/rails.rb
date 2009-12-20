module Externals
  module RailsProjectType
    def self.install
      #obj.send(:extend, Externals::RailsProjectType::Project)
      Externals::OldProject.send(:include, Externals::RailsProjectType::Project)
    end

    class DefaultPathCalculator
      def default_path name
        if name
          (name == 'rails') ? File.join("vendor","rails") : File.join("vendor","plugins", name)
        else
          raise "couldn't figure out project name..."
        end
      end
    end

    module Project
      def default_path
        if name
          (name == 'rails') ? File.join("vendor","rails") : File.join("vendor","plugins", name)
        else
          raise "couldn't figure out project name..."
        end
      end
    end
  end


  class RailsDetector
    def self.detected?
      boot_path = File.join('config','boot.rb')
      if File.exists? boot_path
        open(boot_path) do |f|
          f.read =~ /^\s*module\s+Rails/
        end
      end
    end
  end
end