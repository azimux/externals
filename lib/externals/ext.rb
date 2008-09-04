require 'externals/project'
require 'externals/configuration/configuration'
require 'optparse'
require 'externals/command'
require 'ext/symbol'

module Externals
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
    [:update_ignore, "Adds all paths to subprojects that are
      registered in .externals to the ignore feature of the
      main project.  This is automatically performed by install,
      and so you probably only will run this if you are manually
      maintaining .externals"],
    [:install, "ext install <repository[:branch]> [path]",
      "Registers <repository> in .externals under the appropriate
      SCM.  Checks out the project, and also adds it to the ignore
      feature offered by the SCM of the main project.  If the SCM 
      type is not obvious from the repository URL, use the --scm, 
      --git, or --svn flags."],
    [:init, "Creates a .externals file containing only [main]
      It will try to determine the SCM used by the main project,
      as well as the project type.  You don't have to specify
      a project type if you don't want to or if your project type
      isn't supported.  It just means that when using 'install'
      that you'll want to specify the path."],
    [:touch_emptydirs, "Recurses through all directories from the
      top and adds a .emptydir file to any empty directories it
      comes across.  Useful for dealing with SCMs that refuse to
      track empty directories (such as git, for example)"],
    [:help, "You probably just ran this command just now."]
  ]


  FULL_COMMANDS = FULL_COMMANDS_HASH.map(&:first)
  SHORT_COMMANDS =  SHORT_COMMANDS_HASH.map(&:first)
  MAIN_COMMANDS = MAIN_COMMANDS_HASH.map(&:first)

  COMMANDS = FULL_COMMANDS + SHORT_COMMANDS + MAIN_COMMANDS


  class Ext
    Dir.entries(File.join(File.dirname(__FILE__), '..', 'ext')).each do |extension|
      require "ext/#{extension}" if extension =~ /.rb$/
    end

    Dir.entries(File.join(File.dirname(__FILE__), '..', 'externals','scms')).each do |project|
      require "externals/scms/#{project}" if project =~ /_project.rb$/
    end


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

      opts.banner = "ext [OPTIONS] <command> [repository[:branch]] [path]"

      project_classes.each do |project_class|
        project_class.fill_in_opts(opts, main_options, sub_options)
      end

      opts.on("--type TYPE", "-t TYPE", "The type of project the main project is.  For example, 'rails'.",
        Integer) {|type| sub_options[:scm] = main_options[:type] = type}
      opts.on("--scm SCM", "-s SCM", "The SCM used to manage the main project.  For example, '--scm svn'.",
        Integer) {|scm| sub_options[:scm] = main_options[:scm] = scm}
      opts.on("--workdir DIR", "-w DIR", "The working directory to execute commands from.  Use this if for some reason you
        cannot execute ext from the main project's directory (or if it's just inconvenient, such as in a script
        or in a Capistrano task)",
        String) {|dir|
        raise "No such directory: #{dir}" unless File.exists?(dir) && File.directory?(dir)
        main_options[:workdir] = dir
      }
      opts.on("--help", "does the same as 'ext help'  If you use this with a command
        it will ignore the command and run help instead.") {main_options[:help] = true}
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
        new(main_options).send(command, args, sub_options)
      end
    end

    def print_commands(commands)
      commands.each do |command|
        puts Command.new(*command)
      end
      puts
    end

    def help(args, options)
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
      configuration.projects
    end

    def subprojects
      configuration.subprojects
    end

    def configuration
      return @configuration if @configuration

      @configuration = Configuration::Configuration.new
    end

    def reload_configuration
      @configuration = nil
      configuration
    end

    def initialize options
      super()

      scm = configuration['main']
      scm = scm['scm'] if scm
      scm ||= options[:scm]
      #scm ||= infer_scm(repository)

      type = configuration['main']
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

    def install args, options
      init args, options unless File.exists? '.externals'
      row = args.join " "

      orig_options = options.dup

      scm = options[:scm]

      scm ||= infer_scm(row)

      if !configuration[scm]
        configuration.add_empty_section(scm)
      end
      configuration[scm].add_row(row)
      configuration.write
      reload_configuration

      project = self.class.project_class(scm).new(row)

      project.co

      update_ignore args, orig_options
    end

    def update_ignore args, options
      #path = args[0]


      scm = configuration['main']
      scm = scm['scm'] if scm

      scm ||= options[:scm]

      unless scm
        raise "You need to either specify the scm as the first line in .externals (for example, scm = git), or use an option to specify it
          (such as --git or --svn)"
      end

      project = self.class.project_class(scm).new(".")

      raise "only makes sense for main project" unless project.main?

      subprojects.each do |subproject|
        puts "about to add #{subproject.path} to ignore"
        project.update_ignore subproject.path
        puts "finished adding #{subproject.path}"
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
      repository = "."
      path = "."
      main_project = nil
      scm = options[:scm]
      scm ||= infer_scm(repository)

      if !scm
        scm ||= configuration['main']
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

      main_project = self.class.project_class(scm).new("#{repository} #{path}", :is_main)
      main_project.st

      self.class.new({}).st [], {} #args, options
    end

    def update args, options
      options ||= {}
      repository = args[0]
      main_project = nil
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

      main_project = self.class.project_class(scm).new("#{repository} #{path}", :is_main)
      main_project.up

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

      config.sections << Configuration::Section.new("[main]\n",
        "scm = #{scm}\n" +
          "#{'type = ' + type if type}\n")

      config.write
      reload_configuration
    end

    def self.project_type_detector name
      Externals.module_eval("#{name.classify}Detector", __FILE__, __LINE__)
    end

    def install_project_type name
      Externals.module_eval("#{name.classify}ProjectType", __FILE__, __LINE__).install
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

        main_project = self.class.project_class(scm).new("#{repository} #{path}", :is_main)

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


