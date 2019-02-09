module Externals
  module RailsProjectType
    class DefaultPathCalculator
      def default_path name
        if name
          if name == 'rails'
            File.join("vendor","rails")
          else
            File.join("vendor","plugins", name)
          end
        else
          raise "couldn't figure out project name..."
        end
      end
    end
  end

  class RailsDetector
    def self.detected?
      application_path = File.join('config', 'application.rb')
      if File.exist?(application_path)
        open(application_path) do |f|
          f.read =~ /<\s*Rails::Application/
        end
      else
        boot_path = File.join('config', 'boot.rb')
        if File.exist?(boot_path)
          open(boot_path) do |f|
            f.read =~ /^\s*module\s+Rails/
          end
        end
      end
    end
  end
end
