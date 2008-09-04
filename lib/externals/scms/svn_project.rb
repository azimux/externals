module Externals
  class SvnProject < Project
    def co *args
      (rmdircmd = "rmdir #{path}")

      `#{rmdircmd}` if File.exists? path
      puts(svncocmd = "svn co #{repository} #{path}")
      puts `#{svncocmd}`
    end

    def ex *args
      (rmdircmd = "rmdir #{path}")

      `#{rmdircmd}` if File.exists? path
      puts(svncocmd = "svn export #{repository} #{path}")
      puts `#{svncocmd}`
    end

    def up *args
      puts "updating #{path}:"
      Dir.chdir path do
        puts `svn up .`
      end
    end

    def st *args
      puts "\nstatus for #{path}:"
      Dir.chdir path do
        puts `svn status`
      end
    end

    def self.scm_path? path
      return true if path =~ /^svn(\+ssh)?:/
      if path =~ /^https?:\/\/([\w+\-_]+)\.(?:[\w+\-_]+\.)*[\w\-_]+(?:\/|$)/
        return true if $1.downcase == "svn"

        if path =~ /^https?:\/\/(?:[\w_\-]+\.)*[\w\-_]+\/(\w+)\//
          return true if $1.downcase == "svn"
        end
      end

      false
    end

    def self.fill_in_opts opts, main_options, sub_options
      opts.on("--svn", "--subversion","-s", "same as '--scm svn'  Uses subversion to checkout/export the main project",
        Integer) {sub_options[:scm] = main_options[:scm] = 'svn'}
    end

    def self.scm
      "svn"
    end

    def self.detected?
      File.exists? ".svn"
    end

    def self.add_all
      status = `svn st`

      status.split("\n").grep(/^\?/).each do |to_add|
        puts `svn add #{to_add.gsub(/^\?\s*/,"")}`
      end
    end


    protected
    def ignore_contains? path
      ignore_text(path) =~ Regexp.new("^\\s*#{File.basename(path)}\\s*$")
    end

    def append_ignore path
      parent = File.dirname(path)
      child = File.basename(path)

      rows = ignore_text(path).split(/\n/)

      return if rows.detect {|row| row.strip == child.strip}

      rows << child.strip

      rows.delete_if {|row| row =~ /^\s*$/}

      Dir.chdir(parent) do
        puts `svn propset svn:ignore "#{rows.compact.join("\n")}\n" .`
      end
    end

    def ignore_text(path)
      ignore_text = ''
      Dir.chdir File.dirname(path) do
        puts(ignore_text = `svn propget svn:ignore`)
      end
      ignore_text
    end
  end
end