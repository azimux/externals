require File.join(File.dirname(__FILE__), '..', 'project')

module Externals
  class GitProject < Project
    def default_branch
      'master'
    end

    private
    def co_or_up command
      opts = resolve_opts(command)

      puts "path is #{path} repository is #{repository}"
      if path != '.'
        (rmdircmd = "rmdir #{path}")
        `#{rmdircmd}` if File.exists?(path)
      end

      dest = path
      dest = '' if dest == '.'
      dest = "\"#{dest}\"" if dest && !dest.empty?

      puts(gitclonecmd = "git #{opts} clone \"#{repository}\" #{dest}")
      puts `#{gitclonecmd}`

      change_to_branch_revision(command)
    end

    public
    def co *args
      co_or_up "co"
    end

    private
    # make sure you have already entered Dir.chdir(path) in your calling code!
    def branch_exists branch_name
      opts = resolve_opts
      `git #{opts} branch -a` =~ /^\s*#{branch_name}\s*$/
    end

    public
    def change_to_branch_revision command = ""
      opts = resolve_opts(command)

      if branch
        cb = current_branch

        # This allows the main project to be checked out to a directory
        # that doesn't match it's name.
        project_path = if path == "."
          name
        else
          path
        end

        Dir.chdir project_path do
          if cb != branch
            # let's see if the branch exists in the remote repository
            # and if not, fetch it.
            if !branch_exists("origin/#{branch}")
              puts `git #{opts} fetch`
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
      end

      if revision
        Dir.chdir path do
          puts `git #{opts} fetch`
          puts `git #{opts} pull`
          puts `git #{opts} checkout #{revision}`
          unless $? == 0
            raise "Could not checkout #{revision}"
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
      if path != '.'
        (rmdircmd = "rmdir #{path}")
        `#{rmdircmd}` if File.exists? path
      end

      dest = path

      dest = '' if dest == '.'

      dest = "\"#{dest}\"" if dest && !dest.empty?

      puts(gitclonecmd = "git #{scm_opts_ex} clone --depth 1 \"#{repository}\" #{dest}")

      puts `#{gitclonecmd}`

      change_to_branch_revision "ex"
    end

    def up *args
      if File.exists? path
        puts "updating #{path}:"
        if revision || branch
          change_to_branch_revision "up"
        else
          Dir.chdir path do
            puts `git #{scm_opts_up} pull`
          end
        end
      else
        co_or_up "up"
      end
    end

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
      File.exists? ".git"
    end

    #this is a test helper method
    def self.add_all
      puts `git add .`
    end

    def ignore_contains? path
      text = ignore_text(path)
      text.split(/\n/).detect {|r| r.strip == path.strip}
    end

    def ignore_text(path)
      return '' unless File.exists? '.gitignore'
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