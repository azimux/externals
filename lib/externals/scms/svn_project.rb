module Externals
  class SvnProject < Project
    def co *args
      puts(rmdircmd = "rmdir #{path}")

      puts `#{rmdircmd}`
      puts(svncocmd = "svn co #{repository} #{path}")
      puts `#{svncocmd}`
    end

    def ex *args
      puts(rmdircmd = "rmdir #{path}")

      puts `#{rmdircmd}`
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
      puts "status for #{path}:"
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
      opts.on("--svn", "--subversion","-s", "Use subversion to checkout/export the main project",
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
      parent = File.dirname(path)
      child = File.basename(path)

      ignore_text = ''
      Dir.chdir parent do
        puts(ignore_text = `svn propget svn:ignore`)
      end
      ignore_text =~ Regexp.new("^\\s*#{child}\\s*$")
    end

    def append_ignore path
      parent = File.dirname(path)
      child = File.basename(path)

      Dir.chdir(parent) do
        ignore_text = `svn propget svn:ignore`
        ignore_text += "\n#{child}"

        puts `svn propset svn:ignore "#{ignore_text}" .`
      end
    end
  end
end