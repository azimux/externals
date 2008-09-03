module Externals
  class GitProject < Project
    def co *args
      puts "path is #{path} repository is #{repository}"
      if path != '.'
        (rmdircmd = "rmdir #{path}")
        `#{rmdircmd}` if File.exists?(path)
      end

      dest = path
      dest = '' if dest == '.'
      dest = "\"#{dest}\"" if dest && !dest.empty?

      puts(gitclonecmd = "git clone \"#{repository}\" #{dest}")
      puts `#{gitclonecmd}`
      if branch
        puts `cd #{path}; git checkout --track -b #{branch} origin/#{branch}`
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

      puts(gitclonecmd = "git clone --depth 1 \"#{repository}\" #{dest}")

      puts `#{gitclonecmd}`
      if branch
        puts `cd #{path}; git checkout --track -b #{branch} origin/#{branch}`
      end
    end

    def up *args
      puts "updating #{path}:"
      Dir.chdir path do
        puts `git pull`
      end
    end

    def st *args
      puts "status for #{path}:"
      Dir.chdir path do
        puts `git status`
      end
    end

    def self.scm_path? path
      path =~ /^git:/ || path =~ /.git$/
    end

    def self.fill_in_opts opts, main_options, sub_options
      opts.on("--git", "-g", "Use git to checkout/export the main project",
        Integer) {sub_options[:scm] = main_options[:scm] = 'git'}
    end


    def self.scm
      "git"
    end

    def self.detected?
      File.exists? ".git"
    end

    def self.add_all
      puts `git add .`
    end


    protected
    def ignore_contains? path
      text = ignore_text
      text.split(/\n/).detect {|r| r.strip == path.strip}
    end

    def ignore_text
      return '' unless File.exists? '.gitignore'
      retval = ''
      open('.gitignore') do |f|
        retval = f.read
      end
      retval
    end

    def append_ignore path
      rows = ignore_text || ''
      return if rows.index path.strip
      
      rows = rows.split(/\n/)
      rows << path.strip

      rows.delete_if {|row| row =~ /^\s*$/}


      open('.gitignore', 'w') do |f|
        f.write "#{rows.compact.join("\n")}\n"
      end
    end

    def extract_name s
      if s =~ /\/([\w_-]+)(?:\.git)?$/
        $1
      end
    end
  end
end