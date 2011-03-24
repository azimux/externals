require File.join(File.dirname(__FILE__), '..', 'project')

module Externals
  class SvnProject < Project

    def default_branch
      nil
    end

    def co *args
      (rmdircmd = "rmdir #{path}")
      `#{rmdircmd}` if File.exists? path

      opts = ""
      opts += args[1] if args[0] == "opts"

      rev = ""
      rev += "-r #{revision}" if revision

      puts(svncocmd = "svn #{opts} co #{rev} #{repository} #{path}")
      puts `#{svncocmd}`
    end

    def change_to_revision
      if revision
        Dir.chdir path do
          puts `svn --non-interactive --trust-server-cert up -r #{revision}`
        end
      end
    end

    def ex *args
      (rmdircmd = "rmdir #{path}")

      url = repository

      if revision
        url += "@#{revision}"
      end

      `#{rmdircmd}` if File.exists? path
      puts(svncocmd = "svn export #{repository} #{path}")
      puts `#{svncocmd}`
    end

    def up *args
      if File.exists? path
        if revision
          change_to_revision
        else
          puts "updating #{path}:"
          Dir.chdir path do
            puts `svn --non-interactive --trust-server-cert up .`
          end
        end
      else
        co("opts","--non-interactive --trust-server-cert", *args)
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

# Look for http(s)://svn.*/*
      if path =~ /^https?:\/\/([\w+\-_]+)\.(?:[\w+\-_]+\.)*[\w\-_]+(?:\/|$)/
        return true if $1.downcase == "svn"
      end

# Look for http(s)://*/svn*
#	test = path.sub(/^https?:\/\/(?:[\w+\-_]+\.?)+\/(\w+)/, "MATCHED")
#	puts "RESULT: #{test} - #{$1}"
      if path =~ /^https?:\/\/(?:[\w+\-_]+\.?)+\/(\w+)/
        return true if $1.downcase.include? "svn"
      end

      false
    end

    def self.fill_in_opts opts, main_options, sub_options
      opts.on("--svn", "--subversion", "same as '--scm svn'  Uses subversion to checkout/export the main project",
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

    def ignore_contains? path
      ignore_text(path) =~ Regexp.new("^\\s*#{File.basename(path)}\\s*$")
    end

    def append_ignore path
      parent = File.dirname(path)
      child = File.basename(path)

      rows = ignore_rows(path)

      return if rows.detect {|row| row.strip == child.strip}

      rows << child.strip

      Dir.chdir(parent) do
        puts `svn propset svn:ignore "#{rows.compact.join("\n")}\n" .`
      end
    end

    def drop_from_ignore path
      parent = File.dirname(path)
      child = File.basename(path).strip

      ir = ignore_rows(path)
      rows = ir.select {|row| row.strip != child}

      if rows.size == ir.size
        raise "row not found matching #{path} in svn propget svn:ignore"
      end

      if ir.size - rows.size != 1
        raise "More than one row found matching #{path} in svn propget svn:ignore"
      end

      Dir.chdir(parent) do
        puts `svn propset svn:ignore "#{rows.compact.join("\n")}\n" .`
      end
    end

    def ignore_rows(path)
      rows = ignore_text(path).split(/\n/)

      rows.delete_if {|row| row =~ /^\s*$/}

      rows
    end

    def ignore_text(path)
      ignore_text = ''
      Dir.chdir File.dirname(path) do
        ignore_text = `svn propget svn:ignore`
      end
      ignore_text
    end

    def current_revision
      Dir.chdir path do
        if `svn info` =~ /Revision:\s*(\d+)\s*$/
          $1
        end
      end
    end

    def freeze_involves_branch?
      false
    end

  end
end
