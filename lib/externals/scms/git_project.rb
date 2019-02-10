require File.join(File.dirname(__FILE__), '..', 'project')

module Externals
  class GitProject < Project
    def default_branch
      'master'
    end

    private
    def do_clone command, extra_opts = ""
      opts = resolve_opts(command)

      puts "path is #{path} repository is #{repository}"
      if path != '.'
        rmdir_ie path
      end

      dest = path
      dest = '' if dest == '.'
      dest = "\"#{dest}\"" if dest && !dest.empty?

      puts(gitclonecmd = "git #{opts} clone #{extra_opts} \"#{repository}\" #{dest}")
      puts `#{gitclonecmd}`
      unless $? == 0
        raise "git clone of #{repository} failed."
      end
    end

    public
    def co *args
      do_up "co"
    end

    private
    # make sure you have already entered Dir.chdir(path) in your calling code!
    def branch_exists branch_name
      opts = resolve_opts
      `git #{opts} branch -a` =~ /^\s*#{branch_name}\s*$/
    end

    # make sure you have already entered Dir.chdir(path) in your calling code!

    public
    # this method fetches/pulls/changes branches/changes revisions/changes the oil in your geo metro/brings world peace
    def change_to_branch_revision command = ""
      opts = resolve_opts(command)

      pulled = false

      project_path = if path == "."
        name || "."
      else
        path
      end

      Dir.chdir project_path do
        do_fetch command
      end


      if branch
        cb = current_branch

        # This allows the main project to be checked out to a directory
        # that doesn't match it's name.
        Dir.chdir project_path do
          if cb != branch
            # let's see if the branch exists in the remote repository
            # and if not, fetch it.
            if !branch_exists("origin/#{branch}")
              do_fetch command
            end

            # if the local branch doens't exist, add --track -b
            if branch_exists(branch)
              puts `git #{opts} checkout #{branch}`
            else
              puts `git #{opts} checkout --track -b #{branch} origin/#{branch}`
            end
            unless $? == 0
              raise "Could not checkout origin/#{branch}"
            end
          end
        end

        # on the right branch, let's pull
        Dir.chdir project_path do
          `git #{opts} pull`
          raise unless $? == 0
          pulled = true
        end
      end

      if revision
        Dir.chdir project_path do
          puts `git #{opts} checkout #{revision}`
          unless $? == 0
            raise "Could not checkout #{revision}"
          end
        end
      else
        unless pulled
          Dir.chdir project_path do
            `git #{opts} pull`
            raise unless $? == 0
          end
        end
      end
    end

    def switch branch_name, options = {}
      cb = current_branch
      if cb == branch_name
        puts "Already on branch #{branch_name}"
      else
        # This allows the main project to be checked out to a directory
        # that doesn't match it's name.
        Dir.chdir path do
          # let's see if the branch exists in the remote repository
          # and if not, fetch it.
          if !branch_exists("origin/#{branch_name}")
            puts `git #{scm_opts} fetch`
          end

          # if the local branch doens't exist, add --track -b
          if branch_exists(branch_name)
            puts `git #{scm_opts} checkout #{branch_name}`
          else
            puts `git #{resolve_opts("co")} checkout --track -b #{branch_name} origin/#{branch_name}`
          end
          unless $? == 0
            raise "Could not checkout origin/#{branch_name}"
          end
        end
      end
    end

    def ex *args
      if revision
        # No clean reliable way to clone something that's not a branch or tag.
        # just call up instead.
        up(*args)
      else
        clone_opts = "--depth 1"
        if branch
          clone_opts << " -b #{branch}"
        end
        do_clone "ex", clone_opts
      end
    end

    def up *args
      do_up "up"
    end

    private
    def do_fetch command
      opts = resolve_opts(command)
      `git #{opts} fetch`
      raise unless $? == 0
    end

    def do_up command
      project_path = if path == "."
        name || "." # if no name is specified then we are expected to already be in the right path.
        # this is a little confusing and should be cleaned up.
        # When we are doing a checkout, the name is set manually in Ext.checkout.
        # we are then in the parent directory.
        # When we are doing an update, the main project has no name.
        # we are then in the correct directory.
      else
        path
      end

      puts "Updating #{path}..."

      if !File.exist?(project_path)
        do_clone command
      end
      change_to_branch_revision command
    end

    public
    def st *args
      puts "\nstatus for #{path}:"
      Dir.chdir path do
        puts `git #{scm_opts_st} status`
      end
    end

    def self.scm_path? path
      path =~ /^git:/ || path =~ /.git$/
    end

    def self.fill_in_opts opts, main_options, sub_options, options
      opts.on("--git", "-g",
        Integer,
        *"same as '--scm git'  Uses git to
        checkout/export the main project".lines_by_width(options[:summary_width])
      ) {sub_options[:scm] = main_options[:scm] = 'git'}
    end

    def self.detected?
      File.exist?(".git")
    end

    #this is a test helper method
    def self.add_all
      puts `git add .`
      raise unless $? == 0
    end

    def ignore_contains? path
      text = ignore_text(path)
      text.split(/\n/).detect {|r| r.strip == path.strip}
    end

    def ignore_text(path = nil)
      return '' unless File.exist?('.gitignore')
      retval = ''
      open('.gitignore') do |f|
        retval = f.read
      end
      retval
    end

    def ignore_rows(path)
      rows = ignore_text(path) || ''

      rows = rows.split(/\n/)

      rows.delete_if {|row| row =~ /^\s*$/}

      rows
    end

    def append_ignore path
      rows = ignore_rows(path)

      return if rows.index path.strip

      rows << path.strip

      open('.gitignore', 'w') do |f|
        f.write "#{rows.compact.join("\n")}\n"
      end
    end

    def drop_from_ignore path
      ir = ignore_rows(path)
      rows = ir.select {|row| row.strip != path.strip}

      if rows.size == ir.size
        raise "row not found matching #{path} in .gitignore"
      end

      if ir.size - rows.size != 1
        raise "More than one row found matching #{path} in .gitignore"
      end

      open('.gitignore', 'w') do |f|
        f.write "#{rows.compact.join("\n")}\n"
      end
    end

    def current_revision
      Dir.chdir path do
        if `git #{scm_opts} show HEAD` =~ /^\s*commit\s*([0-9a-fA-F]*)\s*$/i
          $1
        end
      end
    end

    def current_branch
      Dir.chdir path do
        if `git #{scm_opts} branch -a` =~ /^\s*\*\s*([^\s]*)\s*$/
          $1
        end
      end
    end

    def extract_name s
      if s =~ /([^\/:]+?)(?:\.git|\.bundle)?$/
        $1
      end
    end

  end
end
