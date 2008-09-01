module Externals
  module RailsProjectType
    def self.install
      Externals::Project.send(:include, Externals::RailsProjectType::Project)
    end

    module Project
      def default_path row
        if row.repository =~ /\/([\w_-]*)(?:.git)?$/
          ($1 == 'rails') ? File.join("vendor","rails") : File.join("vendor","plugins", $1)
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