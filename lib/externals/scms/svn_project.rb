require File.join(File.dirname(__FILE__), '..', 'project')

module Externals
  class SvnProject < Project
    def default_branch
      raise "There is no default_branch for SvnProject"
    end

    public
    def co *args
      # delete path if empty
      rmdir_ie path unless path == "."

      dest = path
      dest = '' if dest == '.'
      dest = "\"#{dest}\"" if dest && !dest.empty?

      if File.exist?(dest)
        up
      else
        opts = resolve_opts "co"

        url = repository

        if branch
          require_repository
          url = [url, branch].join("/")
        end

        puts(svncocmd = "svn #{opts} co #{url} #{dest}")
        puts `#{svncocmd}`
        unless $? == 0
          raise
        end

        change_to_revision "co"
      end
    end

    def change_to_revision command = ""
      opts = resolve_opts(command)

      if revision
        Dir.chdir path do
          puts `svn #{opts} up -r #{revision}`
          raise unless $? == 0
        end
      end
    end

    def ex *args
      # delete path if  empty
      rmdir_ie path unless path == "."

      dest = path
      dest = '' if dest == '.'
      dest = "\"#{dest}\"" if dest && !dest.empty?

      url = repository

      if branch
        require_repository
        url = [url, branch].join("/")
      end

      if revision
        url += "@#{revision}"
      end

      puts(svncocmd = "svn #{scm_opts_ex} export #{url} #{dest}")
      puts `#{svncocmd}`
    end

    def switch branch_name, options = {}
      require_repository

      if current_branch != branch_name
        Dir.chdir path do
          url = [repository, branch_name].join("/")
          `svn #{scm_opts} switch #{url}`
          unless $? == 0
            raise "Could not switch to #{url}"
          end
        end
      end
    end

    def up *args
      # delete path if empty
      rmdir_if_empty_ie path

      if File.exist?(path)
        puts "updating #{path}:"

        if branch
          switch branch
        end

        if revision
          change_to_revision "up"
        else
          Dir.chdir path do
            puts `svn #{scm_opts_up} up .`
          end
        end
      else
        co
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
      if path =~ /^https?:\/\/([\w+\-]+)\.(?:[\w+\-]+\.)*[\w\-]+(?:\/|$)/
        return true if $1.downcase == "svn"
      end

      # Look for http(s)://*/*svn*/
      if path =~ /^https?:\/\/(?:[\w+\-]+\.?)+\/(\w+)/
        return true if $1.downcase.include? "svn"
      end

      false
    end

    def self.fill_in_opts opts, main_options, sub_options, options = {}
      opts.on("--svn", "--subversion",
        Integer,
        *"same as '--scm svn'  Uses subversion to
        checkout/export the main project".lines_by_width(options[:summary_width])
        ) {sub_options[:scm] = main_options[:scm] = 'svn'}
    end

    def self.detected?
      File.exist?(".svn")
    end

    #this is a test helper method
    def self.add_all
      status = `svn st`

      status.split("\n").grep(/^\?/).each do |to_add|
        puts `svn add #{to_add.gsub(/^\?\s*/,"")}`
        raise unless $? == 0
      end
    end

    def ignore_contains? path
      ignore_text(path) =~ Regexp.new("^\\s*#{File.basename(path)}\\s*$")
    end

    def current_branch
      require_repository

      branch = info_url.downcase.gsub(/\/+/, "/").gsub(repository.downcase.gsub(/\/+/, "/"), "")
      if branch == repository
        raise "Could not determine branch from URL #{info_url}.
    Does not appear have a substring of #{repository}"
      end
      if branch !~ /^\//
        raise "Was expecting the branch and repository to be separated by '/'
      Please file an issue about this at http://github.com/azimux/externals"
      end
      branch.gsub(/^\//, "")
    end

    def self.extract_repository url, branch
      repository = url.gsub(branch, "")
      if url == repository
        raise "Could not determine repository from URL #{info_url}.
    Does not appear to have the branch #{branch} as a substring"
      end
      if repository !~ /\/$/
        raise "Was expecting the branch and repository to be separated by '/'
      Please file an issue about this at http://github.com/azimux/externals"
      end
      repository.gsub(/\/$/, "")
    end

    def require_repository
      if repository.nil? || repository.empty?
        url = info_url
        info_url = "svn+ssh://server/path/repository" unless url
        puts "to use any branching features with a subversion project, the
repository must be present in the .externals file.

See http://nopugs.com/ext-svn-branches for more info

The name of the branch should be excluded from the repository URL.

You might need to change your .externals file to contain something like this:

[.]
scm = svn
repository = #{info_url}
        "
        raise "Cannot use subversion branching features without a repository in .externals file"
      end
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

    def self.info_url scm_opts = ""
      if `svn #{scm_opts} info` =~ /^\s*URL:\s*([^\s]+)\s*$/
        $1
      else
        raise "Could not get URL from svn info"
      end
    end

    def info_url
      Dir.chdir path do
        self.class.info_url scm_opts
      end
    end

  end
end
