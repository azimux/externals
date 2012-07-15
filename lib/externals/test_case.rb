require 'test/unit'
require 'fileutils'

module Externals
  TestCase = Test::Unit::TestCase
  module ExtTestCase
    include FileUtils

    protected

    def mark_dirty file
      File.open working_file_name(file), "w" do |file|
        file.puts "dirty"
      end
    end

    def unmark_dirty file
      File.delete working_file_name(file)
    end

    def working_file_name file
      ".working_#{file}"
    end

    def dirty?(file)
      File.exists? working_file_name(file)
    end

    def delete_if_dirty file
      if File.exists? file
        if dirty?(file)
          rm_rf file
        end
      end
    end

    def rails_version
      /[\d\.]+/.match(`#{rails_exe} --version`)[0]
    end

    def rails_exe
      "jruby -S rails"
      "rails"
    end

    def windows?
      ENV['OS'] =~ /^Win/i
    end

    def root_dir
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    end
  end
end