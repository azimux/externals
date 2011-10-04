require 'fileutils'

FileUtils.class_eval do
  # simulates cp -a
  def cp_a source, dest, options = {}
    cp_r source, dest, options.merge(:preserve => true)
  end

  # calls rm_rf if the file exists
  def rm_rf_ie file, options = {}
    rm_rf file, options if File.exists? file
  end
end