require 'externals/project'
require 'externals/configuration/configuration'
require 'optparse'
require 'externals/command'
require 'fileutils'

require_relative "../../version"

Dir.entries(File.join(File.dirname(__FILE__), 'extensions')).each do |extension|
  require "externals/extensions/#{extension}" if extension =~ /.rb$/
end

module Externals
  # Full commands operate on the main project as well as the externals
  # short commands only operate on the externals
  # Main commands only operate on the main project
  FULL_COMMANDS_HASH = [
    [:checkout, "ext checkout <repository>",
     %{Checks out <repository>, and checks out any subprojects
      registered in <repository>'s .externals file.}],
    [:export, "ext export <repository>",
     %{Like checkout except this command fetches as little
      history as possible.}],
    [:status, "ext status",
     %{Prints out the status of the main project, followed by
      the status of each subproject.}],
    [:update, "ext update",
     %{Brings the main project, and all subprojects, up to the
      latest version.}]
  ].freeze
  SHORT_COMMANDS_HASH = [
    [:co, "Like checkout, but skips the main project and
          only checks out subprojects."],
    [:ex, "Like export, but skips the main project."],
    [:st, "Like status, but skips the main project."],
    [:up, "Like update, but skips the main project."]
  ].freeze
  MAIN_COMMANDS_HASH = [
    [:freeze, "ext freeze <subproject> [REVISION]",
     %{Locks a subproject into a specific revision/branch.  If no
      revision is supplied, the current revision/branch of the
      project will be used.  You can specify the subproject by name
      or path.}],
    [:help, "You probably just ran this command just now."],
    [:init, "Creates a .externals file containing only [main]
      It will try to determine the SCM used by the main project."],
    [:install, "ext install <repository> [-b <branch>] <path>",
     "Registers <repository> in .externals under the appropriate
      SCM.  Checks out the subproject at given path,
      and also adds it to the ignore
      feature offered by the SCM of the main project.  If the SCM
      type is not obvious from the repository URL, use the --scm,
      --git, or --svn flags."],
    [:switch, "ext switch <branch_name>",
     "Changes to the named branch <branch_name> and updates any
      subprojects and applies any changes that have been made to the
      .externals file."],
    [:touch_emptydirs, "Recurses through all directories from the
      top and adds a .emptydir file to any empty directories it
      comes across.  Useful for dealing with SCMs that refuse to
      track empty directories (such as git, for example)"],
    [:unfreeze, "ext unfreeze <subproject>",
     %{Unfreezes a previously frozen subproject.  You can specify
      the subproject by name or path.}],
    [:uninstall, "ext uninstall [-f|--force_removal] <project>",
     "Removes a subproject from being tracked by ext.  If you
      want the files associated with this subproject deleted as well
      (if, for example, you wish to reinstall it from a different
      repository) then you can use the -f option to remove the files."],
    [:update_ignore, "Adds all paths to subprojects that are
      registered in .externals to the ignore feature of the
      main project.  This is automatically performed by install,
      and so you probably only will run this if you are manually
      maintaining .externals"],
    [:version, "Displays the version number of externals and exits."],
  ].freeze

  FULL_COMMANDS = FULL_COMMANDS_HASH.map(&:first)
  SHORT_COMMANDS = SHORT_COMMANDS_HASH.map(&:first)
  MAIN_COMMANDS = MAIN_COMMANDS_HASH.map(&:first)

  COMMANDS = FULL_COMMANDS + SHORT_COMMANDS + MAIN_COMMANDS

  COULD_NOT_DETERMINE_SCM = 1
  NO_EXTERNALS_FILE = 2

  Dir.entries(File.join(File.dirname(__FILE__), '..', 'externals', 'scms')).each do |project|
    require "externals/scms/#{project}" if project =~ /_project.rb$/
  end

  class Ext
    include FileUtils
    extend FileUtils

    def self.new_opts main_options, sub_options
      opts = OptionParser.new(
        "ext [OPTIONS] <command> [repository] [-b <branch>] [path]"
      )
      opts.summary_indent = '  '
      opts.summary_width = 24
      summary_width = 53

      project_classes.each do |project_class|
        project_class.fill_in_opts(opts, main_options, sub_options,
                                   :summary_width => summary_width)
      end

      opts.on("--scm SCM", "-s SCM",
              String,
              *"The SCM used to manage the main project.  For example, '--scm svn'.".lines_by_width(summary_width)
      ) {|scm| sub_options[:scm] = main_options[:scm] = scm}
      opts.on("--branch BRANCH", "-b BRANCH",
              String,
              *"The branch you want the
        subproject to checkout when doing 'ext install'".lines_by_width(summary_width)
      ) {|branch| sub_options[:branch] = main_options[:branch] = branch}
      opts.on("--revision REVISION", "-r REVISION",
              String,
              *"The revision you want the
        subproject to checkout when doing 'ext install'".lines_by_width(summary_width)
      ) {|revision| sub_options[:revision] = main_options[:revision] = revision}
      opts.on("--force_removal", "-f",
              String,
              *"When doing an uninstall of a subproject,
        remove it's files and subfolders, too.".lines_by_width(summary_width)
      ) { sub_options[:force_removal] = true }
      opts.on(
        "--workdir DIR", "-w DIR", String,
        *"The working directory to execute commands from.  Use this if for some reason you
        cannot execute ext from the main project's directory (or if it's just inconvenient, such as in a script
        or in a Capistrano task)".lines_by_width(summary_width)) {|dir|
        raise "No such directory: #{dir}" unless File.exist?(dir) && File.directory?(dir)

        main_options[:workdir] = dir
      }
      opts.on(
        "--help", *"does the same as 'ext help'  If you use this with a command
        it will ignore the command and run help instead.".lines_by_width(summary_width)
      ) {main_options[:help] = true}
      opts.on("--version", *"Displays the version number of externals and then exits.
        Same as 'ext version'".lines_by_width(summary_width)) {
        main_options[:version] = true
      }
      opts
    end

    def self.run *arguments
      main_options = {}
      sub_options = {}

      opts = new_opts main_options, sub_options

      args = opts.parse(arguments)

      unless args.nil? || args.empty?
        command = args[0]
        args = args[1..] || []
      end

      command &&= command.to_sym

      command = :help if main_options[:help]
      command = :version if main_options[:version]

      if !command || command.to_s == ''
        # :nocov:
        puts "hey... you didn't tell me what you want to do."
        puts "Try 'ext help' for a list of commands"
        exit 1
        # :nocov:
      end

      unless COMMANDS.index command
        # :nocov:
        puts "unknown command: #{command}"
        puts "for a list of commands try 'ext help'"
        exit 1
        # :nocov:
      end

      Dir.chdir(main_options[:workdir] || ".") do
        new(main_options).send(command, args, sub_options)
      end
    end

    def print_commands(commands)
      commands.each do |command|
        puts Command.new(*command)
      end
      puts
    end

    def help(_args, _options)
      puts "There's a tutorial available at http://nopugs.com/ext-tutorial\n\n"
      puts "#{self.class.new_opts({}, {})}\n\n"

      puts "\nCommands that apply to the main project or the .externals file:"
      puts "#{MAIN_COMMANDS.join(', ')}\n\n"
      print_commands(MAIN_COMMANDS_HASH)

      puts "\nCommands that apply to the main project and all subprojects:"
      puts "#{FULL_COMMANDS.join(', ')}\n\n"
      print_commands(FULL_COMMANDS_HASH)

      puts "\nCommands that only apply to the subprojects:"
      puts "#{SHORT_COMMANDS.join(', ')}\n\n"
      print_commands(SHORT_COMMANDS_HASH)
    end

    @registered_scms = nil
    def self.registered_scms
      return @registered_scms if @registered_scms

      @registered_scms ||= []

      scmdir = File.join(File.dirname(__FILE__), 'scms')

      Dir.entries(scmdir).each do |file|
        if file =~ /^(.*)_project\.rb$/
          @registered_scms << $1
        end
      end

      @registered_scms
    end

    def projects
      return @projects if @projects

      @projects = []
      configuration.sections.each do |section|
        @projects << Ext.project_class(section[:scm] || infer_scm(section[:repository])).new(
          section.attributes.merge(:path => section.title))
      end
      #let's set the parents of these projects
      main = main_project
      subprojects.each {|subproject| subproject.parent = main}
      @projects
    end

    def subproject_by_name_or_path name
      name = name.strip
      project = subprojects.detect {|p| p.path.strip == name}
      project ||= subprojects.detect do |p|
        File.split(p.path).last.strip == name
      end
      project || subprojects.detect do |p|
        p.name == name
      end
    end
    alias subproject subproject_by_name_or_path

    def subprojects
      s = []
      projects.each do |project|
        s << project unless project.main_project?
      end
      s
    end

    def main_project
      projects.detect(&:main_project?)
    end

    def configuration
      return @configuration if @configuration

      file_string = ''
      if File.exist?('.externals')
        open('.externals', 'r') do |f|
          file_string = f.read
        end
      end
      @configuration = Configuration::Configuration.new(file_string)
    end

    def reload_configuration
      @configuration = nil
      @projects = nil
      configuration
    end

    def initialize options = {}
      super()

      @configuration = nil
      @projects = nil

      scm = configuration['.']
      scm = scm['scm'] if scm
      scm || options[:scm]
    end

    def self.project_class(scm)
      Externals.const_get("#{scm.to_s.cap_first}Project")
    end

    def self.project_classes
      registered_scms.map do |scm|
        project_class(scm)
      end
    end

    SHORT_COMMANDS.each do |command_name|
      define_method command_name do |args, options|
        project_name_or_path = nil

        if args && !args.empty?
          project_name_or_path = args.first
        end

        if project_name_or_path
          project = subprojects.detect do |p|
            p.name == project_name_or_path || p.path == project_name_or_path
          end

          # :nocov:
          raise "no such project" unless project
          # :nocov:

          project.send command_name, args, options
        else
          subprojects.each {|p| p.send(*[command_name, args, options].flatten)}
        end
      end
    end

    def freeze args, _options
      project = subproject_by_name_or_path(args[0])

      raise "No such project named #{args[0]}" unless project

      revision = args[1] || project.current_revision

      section = configuration[project.path]

      if section[:branch]
        branch = project.current_branch
        if branch
          section[:branch] = branch
        else
          section.rm_setting :branch
        end
      end
      section[:revision] = revision
      configuration.write '.externals'
      reload_configuration

      subproject_by_name_or_path(args[0]).up
    end

    def unfreeze args, _options
      project = subproject_by_name_or_path(args[0])

      raise "No such project named #{args[0]}" unless project

      section = configuration[project.path]

      unless section[:revision]
        # :nocov:
        puts "Uhh... #{project.name} wasn't frozen, so I can't unfreeze it."
        exit 1
        # :nocov:
      end

      section.rm_setting :revision
      configuration.write '.externals'
      reload_configuration

      subproject_by_name_or_path(args[0]).up
    end

    def install args, options
      if !File.exist?('.externals')
        # :nocov:
        warn "This project does not appear to be managed by externals.  Try 'ext init' first"
        exit NO_EXTERNALS_FILE
        # :nocov:
      end
      repository = args[0]
      path = args[1]

      orig_options = options.dup

      scm = options[:scm]

      scm ||= infer_scm(repository)

      unless scm
        # :nocov:
        warn "Unable to determine SCM from the repository name.
You need to either specify the scm used to manage the subproject
that you are installing. Use an option to specify it
(such as --git or --svn)"
        exit COULD_NOT_DETERMINE_SCM
        # :nocov:
      end

      project = self.class.project_class(scm).new(:repository => repository,
                                                  :path => path, :scm => scm)
      path = project.path

      raise "no path" unless path

      raise "already exists" if configuration[path]

      project.branch = options[:branch] if options[:branch]
      project.revision = options[:revision] if options[:revision]

      attributes = project.attributes.dup
      attributes.delete(:path)
      configuration[path] = project.attributes
      configuration.write '.externals'
      reload_configuration

      project.co

      update_ignore args, orig_options
    end

    def uninstall args, options
      unless File.exist?('.externals')
        # :nocov:
        raise "Hmm... there's no .externals file in this directory."
        # :nocov:
      end

      project = subproject_by_name_or_path(args[0])

      raise "No such project named #{args[0]}" unless project

      main_project.drop_from_ignore project.path

      configuration.remove_section(project.path)
      configuration.write '.externals'
      reload_configuration

      if options[:force_removal]
        Dir.chdir File.dirname(project.path) do
          rm_rf File.basename(project.path)
        end
      end
    end

    def update_ignore _args, options
      scm = configuration['.']
      scm = scm['scm'] if scm

      scm ||= options[:scm]

      unless scm
        # :nocov:
        raise "You need to either specify the scm as the first line in .externals (for example, scm = git), " \
                "or use an option to specify it
          (such as --git or --svn)"
        # :nocov:
      end

      project = self.class.project_class(scm).new(:path => ".")

      raise "only makes sense for main project" unless project.main_project?

      subprojects.each do |subproject|
        project.update_ignore subproject.path
      end
    end

    def touch_emptydirs _args, _options
      require 'find'

      excludes = ['.', '..', '.svn', '.git']

      excludes.dup.each do |exclude|
        excludes << "./#{exclude}"
      end

      paths = []

      Find.find('.') do |f|
        if File.directory?(f)
          excluded = false
          File.split(f).each do |part|
            excluded ||= excludes.index(part)
          end

          if !excluded && (Dir.entries(f) - excludes).empty?
            paths << f
          end
        end
      end

      paths.each do |p|
        # TODO: is there not an easier way to touch a file??
        # rubocop:disable Style/FileOpen
        f = File.open(File.join(p, ".emptydir"), "w")
        # rubocop:enable Style/FileOpen
      ensure
        f.close
      end
    end

    def status _args, options
      options ||= {}
      scm = options[:scm]

      if !scm
        scm ||= configuration['.']
        scm &&= scm['scm']
      end

      if !scm
        possible_project_classes = self.class.project_classes.select(&:detected?)

        raise "Could not determine this projects scm" if possible_project_classes.empty?
        if possible_project_classes.size > 1
          raise "This project appears to be managed by multiple SCMs: #{
          possible_project_classes.join(',')}
Please explicitly declare the SCM (by using --git or --svn, or,
by creating the .externals file manually"
        end

        scm = possible_project_classes.first.scm
      end

      unless scm
        # :nocov:
        raise "You need to either specify the scm as the first line in .externals, or use an option to specify it
          (such as --git or --svn)"
        # :nocov:
      end

      project = main_project
      project.scm ||= scm
      project.st

      self.class.new({}).st [], {} #args, options
    end

    def switch args, options
      branch = args[0]

      options ||= {}
      scm = options[:scm]

      if !scm
        scm ||= configuration['.']
        scm &&= scm['scm']
      end

      if !scm
        possible_project_classes = self.class.project_classes.select(&:detected?)

        raise "Could not determine this projects scm" if possible_project_classes.empty?
        if possible_project_classes.size > 1
          raise "This project appears to be managed by multiple SCMs: #{
          possible_project_classes.join(',')}
Please explicitly declare the SCM (by using --git or --svn, or,
by creating the .externals file manually"
        end

        scm = possible_project_classes.first.scm
      end

      unless scm
        # :nocov:
        raise "You need to either specify the scm as the first line in .externals, or use an option to specify it
          (such as --git or --svn)"
        # :nocov:
      end

      old_config = configuration
      project = main_project
      project.scm ||= scm

      if project.current_branch == branch
        puts "Already on branch #{branch}"
      else
        project.switch branch, options
        project.up

        reload_configuration

        #update subprojects
        self.class.new({}).up [], {} #args, options

        removed_project_paths = old_config.removed_project_paths(
          configuration
        ).select{|path| File.exist?(path)}

        if !removed_project_paths.empty?
          puts "WARNING: The following subprojects are no longer being maintained in the
.externals file.  You might want to remove them.  You can copy and paste the
commands below if you actually wish to delete them."
          removed_project_paths.each do |path|
            if File.exist?(path)
              puts "  rm -r #{path}"
            end
          end
        end
      end
    end

    def update _args, options
      options ||= {}
      scm = options[:scm]

      if !scm
        scm ||= configuration['.']
        scm &&= scm['scm']
      end

      unless scm
        # :nocov:
        raise "You need to either specify the scm as the first line in .externals, or use an option to specify it
          (such as --git or --svn)"
        # :nocov:
      end

      project = main_project
      project.scm ||= scm
      project.up

      self.class.new({}).up [], {} #args, options
    end

    def checkout args, options
      options ||= {}

      repository = args[0]
      path = args[1] || "."

      main_project = do_checkout_or_export repository, path, options, :checkout

      if path == "."
        path = main_project.name
      end

      Dir.chdir path do
        self.class.new({}).co [], {}
      end
    end

    def export args, options
      options ||= {}

      repository = args[0]
      path = args[1] || "."

      main_project = do_checkout_or_export repository, path, options, :export

      if path == "."
        path = main_project.name
      end

      Dir.chdir path do
        self.class.new({}).ex [], {} #args, options
      end
    end

    def init args, options = {}
      # :nocov:
      raise ".externals already exists" if File.exist?('.externals')
      # :nocov:

      scm = options[:scm]

      if !scm
        possible_project_classes = self.class.project_classes.select(&:detected?)

        raise "Could not determine this project's scm" if possible_project_classes.empty?
        if possible_project_classes.size > 1
          # :nocov:
          raise "This project appears to be managed by multiple SCMs: #{
          possible_project_classes.join(',')}
Please explicitly declare the SCM (using --git or --svn, or, by creating .externals manually"
          # :nocov:
        end

        scm = possible_project_classes.first.scm
      end

      config = Configuration::Configuration.new_empty
      raise ".externals already exists" if File.exist?('.externals')

      config.add_empty_section '.'

      # TODO: If we are using subversion, we should warn about not setting a branch
      if scm == "svn"
        if options[:branch]
          config['.'][:repository] = SvnProject.extract_repository(
            SvnProject.info_url,
            options[:branch]
          )
        elsif args[0]
          config['.'][:repository] = args[0].strip
        end
      end

      config['.'][:scm] = scm

      config.write '.externals'
      reload_configuration
    end

    def version(_args, _options)
      puts Externals::VERSION
    end

    protected

    def do_checkout_or_export repository, path, options, sym
      if File.exist?('.externals')
        # :nocov:
        raise "seems main project is already checked out here?"
        # :nocov:
      else
        #We appear to be attempting to checkout/export a main project
        scm = options[:scm]

        scm ||= infer_scm(repository)

        if !scm
          scm ||= configuration['main']
          scm &&= scm['scm']
        end

        unless scm
          # :nocov:
          raise "You need to either specify the scm as the first line in .externals, or use an option to specify it
          (such as --git or --svn)"
          # :nocov:
        end

        main_project = self.class.project_class(scm).new(
          :repository => repository,
          :path => path,
          :branch => options[:branch]
        )

        main_project.send(sym)
        main_project
      end
    end

    def infer_scm(path)
      registered_scms.find do |scm|
        project_class(scm).scm_path?(path)
      end
    end

    private

    def registered_scms
      self.class.registered_scms
    end

    def project_class(scm)
      self.class.project_class(scm)
    end
  end
end
