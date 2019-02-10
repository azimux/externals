if RUBY_VERSION =~ /^1\.9/
  require 'simplecov'
  SimpleCov.start do
    add_filter "test/"
  end
end

require 'test/unit'
require 'fileutils'

module Externals
  module ExtTestCase
    include FileUtils

    protected

    def mark_dirty file
      File.write(working_file_name(file), "dirty")
    end

    def unmark_dirty file
      File.delete working_file_name(file)
    end

    def working_file_name file
      ".working_#{file}"
    end

    def dirty?(file)
      File.exist?(working_file_name(file))
    end

    def delete_if_dirty file
      if File.exist?(file)
        if dirty?(file)
          rm_rf file
        end
      end
    end

    def rails_version
      /[\d\.]+/.match(`#{rails_exe} --version`)[0]
    end

    def rails_exe
      # "jruby -S rails"
      "rails"
    end

    def windows?
      ENV['OS'] =~ /^Win/i
    end

    def root_dir
      File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    end

    def rescue_exit
      yield
    rescue SystemExit
      # We don't want to end the test suite just because `exit` was called
    end
  end
end
