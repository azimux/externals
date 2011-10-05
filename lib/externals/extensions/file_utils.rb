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

  alias rm_rf_old rm_rf
  #going to try to give a delay after calling rm if necessary...
  def rm_rf *args
    rm_rf_old *args
    tries = 0
    while File.exists?(args[0]) && tries < 10
      sleep 1
      tries += 1
    end
  end
end