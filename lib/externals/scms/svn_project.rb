require File.join(File.dirname(__FILE__), '..', 'project')

module Externals
  class SvnProject < Project
    def default_branch
      nil
    end

    private
    def co_or_up command
      opts = resolve_opts(command)

      (rmdircmd = "rmdir #{path}")

      `#{rmdircmd}` if File.exists? path

      url = repository

      if branch
        url = [url, branch].join("/")
      end

      puts(svncocmd = "svn #{opts} co #{url} #{path}")
      puts `#{svncocmd}`

      change_to_revision command
    end

    public
    def co *args
      co_or_up "co"
    end

    def change_to_revision command = ""
      opts = resolve_opts(command)

      if revision
        Dir.chdir path do
          puts `svn #{opts} up -r #{revision}`
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
      puts(svncocmd = "svn #{scm_opts_ex} export #{repository} #{path}")
      puts `#{svncocmd}`
    end

    def up *args
      if File.exists? path
        puts "updating #{path}:"
        if revision
          change_to_revision "up"
        else
          Dir.chdir path do
            puts `svn #{scm_opts_up} up .`
          end
        end
      else
        co_or_up "up"
      end
    end

    def st *args
      puts "\nstatus for #{path}:"
      Dir.chdir path do
        puts `svn #{scm_opts_st} status`
      end
    end

    def self.scm_path? path
      return true if path =~ /^svn(\+ssh)?:/

      # Look for http(s)://svn.*/*
      if path =~ /^https?:\/\/([\w+\-_]+)\.(?:[\w+\-_]+\.)*[\w\-_]+(?:\/|$)/
        return true if $1.downcase == "svn"
      end

      # Look for http(s)://*/*svn*/
      if path =~ /^https?:\/\/(?:[\w+\-_]+\.?)+\/(\w+)/
        return true if $1.downcase.include? "svn"
      end

      false
    end

    def self.fill_in_opts opts, main_options, sub_options
      opts.on("--svn", "--subversion", "same as '--scm svn'  Uses subversion to checkout/export the main project",
        Integer) {sub_options[:scm] = main_options[:scm] = 'svn'}
    end

    def self.detected?
      File.exists? ".svn"
    end

    #this is a test helper method
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
        puts `svn #{scm_opts} propset svn:ignore "#{rows.compact.join("\n")}\n" .`
        raise "Could not ignore path, something went wrong in svn." unless $? == 0
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
        puts `svn #{scm_opts} propset svn:ignore "#{rows.compact.join("\n")}\n" .`
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
        ignore_text = `svn #{scm_opts} propget svn:ignore`
      end
      ignore_text
    end

    def current_revision
      Dir.chdir path do
        if `svn #{scm_opts} info` =~ /Revision:\s*(\d+)\s*$/
          $1
        end
      end
    end

    def freeze_involves_branch?
      false
    end

  end
end
