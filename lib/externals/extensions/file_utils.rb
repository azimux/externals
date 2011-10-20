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

  # calls rmdir if the file exists and is empty
  def rmdir_if_empty_ie path
    rmdir path if File.exists?(path) && dir_empty?(path)
  end

  # calls rmdir if the file exists
  def rmdir_ie path
    rmdir path if File.exists?(path)
  end

  alias rm_rf_old rm_rf
  #going to try to give a delay after calling rm if necessary...
  def rm_rf *args
    tries = 0

    rm = proc do
      rm_rf_old *args

      while File.exists?(args[0]) && tries < 10
        sleep 1
        tries += 1
      end
    end

    rm.call
    if tries >= 10
      puts "WARNING: deleted #{args[0]} didn't work, trying again"
      tries = 0
      rm.call

      if tries >= 10
        raise "Could not delete #{args[0]}"
      end
    end
  end

  def dir_empty? path
    File.directory?(path) &&
      File.exists?(path) &&
      !Dir.entries(path).detect{|entry| !["..","."].include?(entry)}
  end
end