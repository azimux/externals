require 'externals/project'
require 'externals/old_project'
require 'externals/configuration/configuration'
require 'externals/configuration/old_configuration'
require 'optparse'
require 'externals/command'
require 'externals/extensions/symbol'

module Externals
  #exit status
  OBSOLETE_EXTERNALS_FILE = 15

  VERSION = '0.1.8'
  PROJECT_TYPES_DIRECTORY = File.join(File.dirname(__FILE__), '..', 'externals','project_types')

  # Full commands operate on the main project as well as the externals
  # short commands only operate on the externals
  # Main commands only operate on the main project
  FULL_COMMANDS_HASH = [
    [:checkout, "ext checkout <repository>", %{
      Checks out <repository>, and checks out any subprojects
      registered in <repository>'s .externals file.}],
    [:export, "ext export <repository>", %{
      Like checkout except this command fetches as little
      history as possible.}],
    [:status, "ext status", %{
      Prints out the status of the main project, followed by
      the status of each subproject.}],
    [:update, "ext update", %{
      Brings the main project, and all subprojects, up to the
      latest version.}]
  ]
  SHORT_COMMANDS_HASH = [
    [:co, "Like checkout, but skips the main project and
          only checks out subprojects."],
    [:ex, "Like export, but skips the main project."],
    [:st, "Like status, but skips the main project."],
    [:up, "Like update, but skips the main project."]
  ]
  MAIN_COMMANDS_HASH = [
    [:freeze, "ext freeze project [REVISION]", %{
      Locks a subproject into a specific revision/branch.  If no
      revision is supplied, the current revision/branch of the
      project will be used.  You can specify the project by name
      or path.}],
    [:help, "You probably just ran this command just now."],
    [:init, "Creates a .externals file containing only [main]
      It will try to determine the SCM used by the main project,
      as well as the project type.  You don't have to specify
      a project type if you don't want to or if your project type
      isn't supported.  It just means that when using 'install'
      that you'll want to specify the path."],
    [:install, "ext install <repository> [-b <branch>] [path]",
      "Registers <repository> in .externals under the appropriate
      SCM.  Checks out the project, and also adds it to the ignore
      feature offered by the SCM of the main project.  If the SCM
      type is not obvious from the repository URL, use the --scm,
      --git, or --svn flags."],
    [:touch_emptydirs, "Recurses through all directories from the
      top and adds a .emptydir file to any empty directories it
      comes across.  Useful for dealing with SCMs that refuse to
      track empty directories (such as git, for example)"],
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
    [:upgrade_externals_file, "Converts the old format that stored
      as [main][svn][git] to [<path1>][<path2>]..."],
    [:version, "Displays the version number of externals and exits."],
  ]


  FULL_COMMANDS = FULL_COMMANDS_HASH.map(&:first)
  SHORT_COMMANDS =  SHORT_COMMANDS_HASH.map(&:first)
  MAIN_COMMANDS = MAIN_COMMANDS_HASH.map(&:first)

  COMMANDS = FULL_COMMANDS + SHORT_COMMANDS + MAIN_COMMANDS


  class Ext
    Dir.entries(File.join(File.dirname(__FILE__), 'extensions')).each do |extension|
      require "externals/extensions/#{extension}" if extension =~ /.rb$/
    end

    Dir.entries(File.join(File.dirname(__FILE__), '..', 'externals','scms')).each do |project|
      require "externals/scms/#{project}" if project =~ /_project.rb$/
    end

    Dir.entries(File.join(File.dirname(__FILE__), '..', 'externals','old_scms')).each do |project|
      require "externals/old_scms/#{project}" if project =~ /_project.rb$/
    end

    Dir.entries(PROJECT_TYPES_DIRECTORY).each do |type|
      require File.join(PROJECT_TYPES_DIRECTORY, type) if type =~ /\.rb$/
    end

    attr_accessor :path_calculator

    def self.project_types
      types = Dir.entries(PROJECT_TYPES_DIRECTORY).select do |file|
        file =~ /\.rb$/
      end

      types.map do |type|
        /^(.*)\.rb$/.match(type)[1]
      end
    end

    #puts "Project types available: #{project_types.join(' ')}"

    def self.project_type_files
      project_types.map do |project_type|
        "#{File.join(PROJECT_TYPES_DIRECTORY, project_type)}.rb"
      end
    end

    project_type_files.each do |file|
      require file
    end

    def self.new_opts main_options, sub_options
      opts = OptionParser.new

      opts.banner = "ext [OPTIONS] <command> [repository] [-b <branch>] [path]"

      project_classes.each do |project_class|
        project_class.fill_in_opts(opts, main_options, sub_options)
      end

      opts.on("--type TYPE", "-t TYPE", "The type of project the main project is.  For example, 'rails'.",
        String) {|type| sub_options[:scm] = main_options[:type] = type}
      opts.on("--scm SCM", "-s SCM", "The SCM used to manage the main project.  For example, '--scm svn'.",
        String) {|scm| sub_options[:scm] = main_options[:scm] = scm}
      opts.on("--branch BRANCH", "-b BRANCH", "The branch you want the subproject to checkout when doing 'ext install'",
        String) {|branch| sub_options[:branch] = main_options[:branch] = branch}
      opts.on("--force_removal", "-f", "When doing an uninstall of a subproject, remove it's files and subfolders, too.",
        String) {|branch| sub_options[:force_removal] = true}
      opts.on("--workdir DIR", "-w DIR", "The working directory to execute commands from.  Use this if for some reason you
        cannot execute ext from the main project's directory (or if it's just inconvenient, such as in a script
        or in a Capistrano task)",
        String) {|dir|
        raise "No such directory: #{dir}" unless File.exists?(dir) && File.directory?(dir)
        main_options[:workdir] = dir
      }
      opts.on("--help", "does the same as 'ext help'  If you use this with a command
        it will ignore the command and run help instead.") {main_options[:help] = true}
      opts.on("--version", "Displays the version number of externals and then exits.
        Same as 'ext version'") {
        main_options[:version] = true
      }
    end

    def self.run *arguments
      main_options = {}
      sub_options = {}

      opts = new_opts main_options, sub_options

      args = opts.parse(arguments)

      unless args.nil? || args.empty?
        command = args[0]
        args = args[1..(args.size - 1)] || []
      end

      command &&= command.to_sym

      command = :help if main_options[:help]
      command = :version if main_options[:version]

      if !command || command.to_s == ''
        puts "hey... you didn't tell me what you want to do."
        puts "Try 'ext help' for a list of commands"
        exit
      end

      unless COMMANDS.index command
        puts "unknown command: #{command}"
        puts "for a list of commands try 'ext help'"
        exit
      end


      Dir.chdir(main_options[:workdir] || ".") do
        if command == :upgrade_externals_file
          main_options[:upgrade_externals_file] = true
        elsif command != :help && command != :version
          if externals_file_obsolete?
            puts "your .externals file Appears to be in an obsolete format"
            puts "Please run 'ext upgrade_externals_file' to migrate it to the new format"
            exit OBSOLETE_EXTERNALS_FILE
          end
        end

        self.new(main_options).send(command, args, sub_options)
      end
    end

    def self.externals_file_obsolete?
      return false if !File.exists?('.externals')

      open('.externals', 'r') do |f|
        f.read =~ /^\s*\[git\]\s*$|^\s*\[main\]\s*$|^\s*\[svn\]\s*$/
      end
    end

    def print_commands(commands)
      commands.each do |command|
        puts Command.new(*command)
      end
      puts
    end

    def help(args, options)
      puts "There's a tutorial available at http://nopugs.com/ext-tutorial\n\n"
      puts "#{self.class.new_opts({},{}).to_s}\n\n"

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
        @projects << Ext.project_class(section[:scm]||infer_scm(section[:repository])).new(
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
      project ||= subprojects.detect do |p|
        p.name == name
      end
    end

    def subprojects
      s = []
      projects.each do |project|
        s << project unless project.main_project?
      end
      s
    end

    def main_project
      projects.detect {|p| p.main_project?}
    end

    def configuration
      return @configuration if @configuration

      file_string = ''
      if File.exists? '.externals'
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

      if options[:upgrade_externals_file]
        type ||= options[:type]


        if type
          install_project_type type
        else

          possible_project_types = self.class.project_types.select do |project_type|
            self.class.project_type_detector(project_type).detected?
          end

          if possible_project_types.size > 1
            raise "We found multiple project types that this could be: #{possible_project_types.join(',')}
Please use
 the --type option to tell ext which to use."
          elsif possible_project_types.empty?
            install_project_type OldConfiguration::Configuration.new[:main][:type]
          else
            install_project_type possible_project_types.first
          end
        end
        return
      end

      scm = configuration['.']
      scm = scm['scm'] if scm
      scm ||= options[:scm]
      #scm ||= infer_scm(repository)

      type = configuration['.']
      type = type['type'] if type

      type ||= options[:type]

      if type
        install_project_type type
      else
        possible_project_types = self.class.project_types.select do |project_type|
          self.class.project_type_detector(project_type).detected?
        end

        if possible_project_types.size > 1
          raise "We found multiple project types that this could be: #{possible_project_types.join(',')}
Please use
 the --type option to tell ext which to use."
        else
          possible_project_types.each do |project_type|
            install_project_type project_type
          end
        end
      end
    end

    def self.project_class(scm)
      Externals.module_eval("#{scm.to_s.cap_first}Project", __FILE__, __LINE__)
    end

    def self.project_classes
      retval = []
      registered_scms.each do |scm|
        retval << project_class(scm)
      end

      retval
    end
    def self.project_class(scm)
      Externals.module_eval("#{scm.to_s.cap_first}Project", __FILE__, __LINE__)
    end

    def self.old_project_class(scm)
      Externals.module_eval("Old#{scm.to_s.cap_first}Project", __FILE__, __LINE__)
    end

    def self.project_classes
      retval = []
      registered_scms.each do |scm|
        retval << project_class(scm)
      end

      retval
    end

    SHORT_COMMANDS.each do |command_name|
      define_method command_name do |args, options|
        project_name_or_path = nil

        if args && !args.empty?
          project_name_or_path = args.first
        end

        if project_name_or_path
          project = subprojects.detect do |project|
            project.name == project_name_or_path || project.path == project_name_or_path
          end

          raise "no such project" unless project

          project.send command_name, args, options
        else
          subprojects.each {|p| p.send(*([command_name, args, options].flatten))}
        end
      end
    end

    def freeze args, options
      project = subproject_by_name_or_path(args[0])

      raise "No such project named #{args[0]}" unless project

      revision = args[1] || project.current_revision

      branch = if project.freeze_involves_branch?
        project.current_branch
      end

      section = configuration[project.path]
      if section[:branch]
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

    def install args, options
      init args, options unless File.exists? '.externals'
      repository = args[0]
      path = args[1]

      orig_options = options.dup

      scm = options[:scm]

      scm ||= infer_scm(repository)

      unless scm
        raise "Unable to determine SCM from the repository name.
You need to either specify the scm used to manage the subproject
that you are installing. Use an option to specify it
(such as --git or --svn)"
      end

      project = self.class.project_class(scm).new(:repository => repository,
        :path => path || path_calculator.new, :scm => scm)
      path = project.path

      raise "no path" unless path

      raise "already exists" if configuration[path]

      project.branch = options[:branch] if options[:branch]

      attributes = project.attributes.dup
      attributes.delete(:path)
      configuration[path] = project.attributes
      configuration.write '.externals'
      reload_configuration

      project.co

      update_ignore args, orig_options
    end

    def uninstall args, options
      #init args, options unless File.exists? '.externals'
      raise "Hmm... there's no .externals file in this directory." if !File.exists? '.externals'

      project = subproject_by_name_or_path(args[0])

      raise "No such project named #{args[0]}" unless project

      main_project.drop_from_ignore project.path


      configuration.remove_section(project.path)
      configuration.write '.externals'
      reload_configuration

      if options[:force_removal]
        Dir.chdir File.dirname(project.path) do
          `rm -rf #{File.basename(project.path)}`
        end
      end
    end

    def update_ignore args, options
      #path = args[0]


      scm = configuration['.']
      scm = scm['scm'] if scm

      scm ||= options[:scm]

      unless scm
        raise "You need to either specify the scm as the first line in .externals (for example, scm = git), or use an option to specify it
          (such as --git or --svn)"
      end

      project = self.class.project_class(scm).new(:path => ".")

      raise "only makes sense for main project" unless project.main_project?

      subprojects.each do |subproject|
        #puts "about to add #{subproject.path} to ignore"
        project.update_ignore subproject.path
        #puts "finished adding #{subproject.path}"
      end
    end

    def touch_emptydirs args, options
      require 'find'

      excludes = ['.','..','.svn', '.git']

      excludes.dup.each do |exclude|
        excludes << "./#{exclude}"
      end

      paths = []

      Find.find('.') do |f|
        if File.directory?(f)
          excluded = false
          File.split(f).each do |part|
            exclude ||= excludes.index(part)
          end

          if !excluded && ((Dir.entries(f) - excludes).size == 0)
            paths << f
          end
        end
      end

      paths.each do |p|
        open(File.join(p,".emptydir"), "w").close
      end

    end


    def status args, options
      options ||= {}
      #repository = "."
      #path = "."
      #main_project = nil
      scm = options[:scm]
      #scm ||= infer_scm(repository)

      if !scm
        scm ||= configuration['.']
        scm &&= scm['scm']
      end

      if !scm
        possible_project_classes = self.class.project_classes.select do |project_class|
          project_class.detected?
        end

        raise "Could not determine this projects scm" if  possible_project_classes.empty?
        if possible_project_classes.size > 1
          raise "This project appears to be managed by multiple SCMs: #{
          possible_project_classes.map(&:to_s).join(',')}
Please explicitly declare the SCM (by using --git or --svn, or,
by creating the .externals file manually"
        end

        scm = possible_project_classes.first.scm
      end

      unless scm
        raise "You need to either specify the scm as the first line in .externals, or use an option to specify it
          (such as --git or --svn)"
      end

      #main_project = self.class.project_class(scm).new("#{repository} #{path}", :is_main)
      project = main_project
      project.scm ||= scm
      project.st

      self.class.new({}).st [], {} #args, options
    end

    def update args, options
      options ||= {}
      #repository = args[0]
      scm = options[:scm]
      #scm ||= infer_scm(repository)

      if !scm
        scm ||= configuration['.']
        scm &&= scm['scm']
      end

      unless scm
        raise "You need to either specify the scm as the first line in .externals, or use an option to specify it
          (such as --git or --svn)"
      end

      #main_project = self.class.project_class(scm).new("#{repository} #{path}", :is_main)
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
        self.class.new({}).co [], {} #args, options
      end
    end

    def export args, options
      options ||= {}

      repository = args[0]
      path = args[1] || "."

      main_project = do_checkout_or_export repository, path, options, :checkout

      if path == "."
        path = main_project.name
      end

      Dir.chdir path do
        self.class.new({}).ex [], {} #args, options
      end
    end

    def init args, options = {}
      raise ".externals already exists" if File.exists? '.externals'

      scm = options[:scm]
      type = options[:type]

      if !scm
        possible_project_classes = self.class.project_classes.select do |project_class|
          project_class.detected?
        end

        raise "Could not determine this projects scm" if  possible_project_classes.empty?
        if possible_project_classes.size > 1
          raise "This project appears to be managed by multiple SCMs: #{
          possible_project_classes.map(&:to_s).join(',')}
Please explicitly declare the SCM (using --git or --svn, or, by creating .externals manually"
        end

        scm = possible_project_classes.first.scm
      end

      if !type
        possible_project_types = self.class.project_types.select do |project_type|
          self.class.project_type_detector(project_type).detected?
        end

        if possible_project_types.size > 1
          raise "We found multiple project types that this could be: #{possible_project_types.join(',')}
Please use the --type option to tell ext which to use."
        elsif possible_project_types.size == 0
          puts "WARNING: We could not automatically determine the project type.
          Be sure to specify paths when adding subprojects to your .externals file"
        else
          type = possible_project_types.first
        end
      end

      config = Configuration::Configuration.new_empty

      raise ".externals already exists" if File.exists?('.externals')

      config.add_empty_section '.'

      config['.'][:scm] = scm
      config['.'][:type] = type if type

      config.write '.externals'
      reload_configuration
    end

    def upgrade_externals_file args, options = {}
      old = OldConfiguration::Configuration.new

      config = Configuration::Configuration.new_empty

      main = old['main']
      config.add_empty_section '.'

      config['.'][:scm] = main[:scm]
      config['.'][:type] = main[:type]

      old.subprojects.each do |subproject|
        path = subproject.path
        config.add_empty_section path
        config[path][:repository] = subproject.repository
        config[path][:scm] = subproject.scm
        config[path][:branch] = subproject.branch if subproject.branch
      end

      config.write('.externals')
      reload_configuration
    end

    def version(args, options)
      puts Externals::VERSION
    end

    def self.project_type_detector name
      Externals.module_eval("#{name.classify}Detector", __FILE__, __LINE__)
    end

    def install_project_type name
      Externals.module_eval("#{name.classify}ProjectType", __FILE__, __LINE__).install
      self.path_calculator = Externals.module_eval("#{name.classify}ProjectType::DefaultPathCalculator", __FILE__, __LINE__)
    end
    #
    #
    #    def self.determine_project_type path = "."
    #      Dir.chdir path do
    #        raise "not done"
    #      end
    #    end

    protected
    def do_checkout_or_export repository, path, options, sym
      if File.exists?('.externals')
        raise "seems main project is already checked out here?"
      else
        #We appear to be attempting to checkout/export a main project
        scm = options[:scm]

        scm ||= infer_scm(repository)

        if !scm
          scm ||= configuration['main']
          scm &&= scm['scm']
        end

        unless scm
          raise "You need to either specify the scm as the first line in .externals, or use an option to specify it
          (such as --git or --svn)"
        end

        main_project = self.class.project_class(scm).new(:repository => repository,
          :path => path)

        main_project.send(sym)
        main_project
      end
    end

    def infer_scm(path)
      self.class.registered_scms.each do |scm|
        return scm if self.class.project_class(scm).scm_path?(path)
      end
      nil
    end
  end
end
