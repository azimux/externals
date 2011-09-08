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

    def change_to_branch_revision command = ""
      opts = resolve_opts(command)

      if branch
        Dir.chdir path do
          puts `git #{opts} checkout --track -b #{branch} origin/#{branch}`
        end
      end

      if revision
        Dir.chdir path do
          puts `git #{opts} checkout #{revision}`
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
        if revision
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

    def self.fill_in_opts opts, main_options, sub_options
      opts.on("--git", "-g", "same as '--scm git'  Uses git to checkout/export the main project",
        Integer) {sub_options[:scm] = main_options[:scm] = 'git'}
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