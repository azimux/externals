require 'externals/project'
require 'externals/configuration/configuration'
require 'optparse'

module Externals
  PROJECT_TYPES_DIRECTORY = File.join(File.dirname(__FILE__), '..', 'externals','project_types')

  # Full commands operate on the main project as well as the externals
  # short commands only operate on the externals
  # Main commands only operate on the main project
  FULL_COMMANDS_HASH = [[:checkout, ""], [:export, ""], [:status, ""], [:update, ""]]
  SHORT_COMMANDS_HASH = [[:co, ""], [:ex, ""], [:st, ""], [:up, ""]]
  MAIN_COMMANDS_HASH = [[:update_ignore, ""], [:add, ""], [:init, ""], [:touch_emptydirs, ""], [:help, ""]]


  FULL_COMMANDS = [:checkout, :export, :status, :update]
  SHORT_COMMANDS = [:co, :ex, :st, :up]
  MAIN_COMMANDS = [:update_ignore, :add, :init, :touch_emptydirs, :help]

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


    def self.run *arguments
      opts = OptionParser.new

      main_options = {}
      sub_options = {}

      #      opts.on("--only-externals", "-e",
      #        "Do not run the command for the main project, only for the external projects",
      #        Integer) {options[:only_externals] = true}

      project_classes.each do |project_class|
        project_class.fill_in_opts(opts, main_options, sub_options)
      end

      opts.on("--type TYPE", "-t TYPE", "The type of project the main project is.  For example, 'rails'.",
        Integer) {|type| main_options[:type] = type}

      args = opts.parse(arguments)

      unless args.nil? || args.empty?
        command = args[0]
        args = args[1..(args.size - 1)] || []
      end

      command &&= command.to_sym

      puts opts.to_s unless command

      raise "unknown command #{command}" unless COMMANDS.index command

      new(main_options).send(command, args, sub_options)
    end




    #    def register_scm scm_sym
    #      registered_scms << scm_sym
    #    end


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
          project = projects.detect do |project|
            project.name == project_name_or_path || project.path == project_name_or_path
          end

          raise "no such project" unless project

          project.send command_name, args, options
        else
          projects.each {|p| p.send(*([command_name, args, options].flatten))}
        end
      end
    end

    #    LONG_COMMANDS.each do |command_name|
    #      define_method command_name do |project, options|
    #        if project
    #          self.class.project(project).send(command_name, options)
    #        else
    #          unless options[:only_externals] || ONLY_EXTERNALS.index(command_name)
    #            main_project.send(command_name, options)
    #          end
    #          projects.each {|p| p.send(command_name, options)}
    #        end
    #      end
    #    end

    def add args, options
      row = args.join " "

      options = options.dup
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

      
      update_ignore args, options
    end

    def update_ignore args, options
      #path = args[0]

      scm = options[:scm]

      unless scm
        scm = configuration['main']
        scm = scm['scm'] if scm
      end


      unless scm
        raise "You need to either specify the scm as the first line in .externals (for example, scm = git), or use an option to specify it
          (such as --git or --svn)"
      end

      project = self.class.project_class(scm).new(".")

      projects.each do |subproject|
        puts "about to add #{subproject.path} to ignore"
        project.update_ignore subproject.path unless subproject.main?
        puts "finished adding #{subproject.path}"
      end
    end

    def  touch_emptydirs args, options
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


