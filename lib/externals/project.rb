require 'externals/extensions/symbol'
require 'fileutils'

module Externals
  OPTS_SUFFIXES = ["co", "up", "st", "ex"]  unless const_defined?('OPTS_SUFFIXES')
  VALID_ATTRIB = ([
      :name, :path, :repository, :branch, :type, :scm, :revision
    ]
  ).map(&:to_s) unless const_defined?('VALID_ATTRIB')

  class Project
    attr_accessor :parent
    include FileUtils
    extend FileUtils

    def self.attr_attr_accessor *names
      names = [names].flatten
      names.each do |name|
        define_method "#{name}=" do |value|
          attributes[name.to_sym] = value
        end
        next if name == "name" || name == "scm"
        define_method name do
          attributes[name.to_sym]
        end
      end
    end


    attr_attr_accessor Externals::VALID_ATTRIB
    def attributes
      @attributes ||= {}
    end
    def name
      attributes[:name] || extract_name(repository)
    end
    def main_project?
      path == '.'
    end

    def self.scm
      if self == Project
        raise "subclass responsibility"
      end
    end

    def scm
      self.class.scm
    end

    def self.default_branch
      raise "subclass responsibility"
    end

    def default_branch
      self.class.default_branch
    end

    def switch branch_name, options = {}
      raise "subclass responsibility"
    end

    def initialize hash
      raise "Abstract class" if self.class == Project
      raise "expected hash" unless hash.is_a? Hash

      hash = hash.keys.inject({}) do |new_hash, key|
        new_hash[key.to_s] = hash[key]
        new_hash
      end

      invalid_attrib = hash.keys - Externals::VALID_ATTRIB

      if !invalid_attrib.empty?
        invalid_attrib.reject! do |attribute|
          attribute =~ /^\w+_opts(_(#{OPTS_SUFFIXES.join("|")}))?/
        end
        if !invalid_attrib.empty?
          raise "invalid attribute(s): #{invalid_attrib.join(', ')}"
        end
      end

      path = hash.delete('path')

      hash.keys.each do |key|
        send("#{key}=", hash[key])
      end

      if path && !path.is_a?(String)
        path = path.default_path(name)
      end
      self.path = path
    end

    [:co, :ex].each do |method_name|
      define_method method_name do |args|
        raise "subclass responsibility"
      end
    end

    def update_ignore path
      if !ignore_contains?(path)
        append_ignore path
      end
    end

    def checkout *args
      co(*args)
    end

    def export *args
      ex(*args)
    end

    def extract_name repository
      if repository =~ /\/([\w-]+)(?:\.git)?$/
        $1
      end
    end

    #test helper method
    def assert_e_dne_i_ni assert, exists, doesnt = [], ignored = exists, notignored = []
      ignored.each do |proj|
        assert.call(ignore_text("vendor/plugins/#{proj}") =~ /#{proj}$/)
      end

      notignored.each do |proj|
        assert.call(ignore_text("vendor/plugins/#{proj}") !~ /#{proj}$/)
      end

      exists.each do |proj|
        assert.call File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
      end

      doesnt.each do |proj|
        assert.call !File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
      end
    end

    def scm_opts
      values = [
        attributes[:scm_opts],
        send("#{scm}_opts")
      ].compact

      if !values.empty?
        values.join(" ")
      end
    end

    def scm_opts= value
      attributes[:scm_opts] = value
    end

    # create the suffixed versions
    OPTS_SUFFIXES.map do |suffix|
      "scm_opts_#{suffix}"
    end.each do |name|
      define_method name do
        values = [
          attributes[name.to_sym],
          attributes[:scm_opts],
          send(name.gsub(/^scm/, scm))
        ].compact

        if !values.empty?
          values.join(" ")
        end
      end

      define_method "#{name}=" do |value|
        attributes[name.to_sym] = value
      end
    end


    def self.inherited child
      child.class_eval do
        def self.scm
          @scm ||= /^([^:]*::)*([^:]+)Project$/.match(name)[2].downcase
        end

        #create the <scm_name>_opts_co/ex/st/up and <scm_opts>_opts setting
        #such as svn_opts and svn_opts_co from the main project (stored
        #in the parrent attribute.)

        raise unless scm && scm != ""

        #first we create global <scm_name>_opts accessors that will apply to all
        #of the suffixed versions (<scm_name>_opts_co) as well as the project
        #specific ones. (scm_opts, scm_opts_co, etc)
        scm_name = scm
        Project.__send__(:define_method, "#{scm_name}_opts_raw") do
          attributes[name.to_sym]
        end
        #global settings are fetched from the parent project.
        Project.__send__(:define_method, "#{scm_name}_opts") do
          if parent
            parent.__send__("#{scm_name}_opts")
          else
            attributes["#{scm_name}_opts".to_sym]
          end
        end
        Project.__send__(:define_method, "#{scm_name}_opts=") do |value|
          attributes["#{scm_name}_opts".to_sym] = value
        end

        #now we create the suffixed version of the global settings.
        OPTS_SUFFIXES.map do |suffix|
          "#{scm_name}_opts_#{suffix}"
        end.each do |name|
          #defer to the parent project for these global settings
          Project.__send__(:define_method, name) do
            if parent
              parent.__send__(name)
            else
              values = [
                attributes[name.to_sym],
                self.send("#{scm_name}_opts")
              ].compact

              if !values.empty?
                values.join(" ")
              end
            end
          end
          Project.__send__(:define_method, "#{name}=") do |value|
            attributes[name.to_sym] = value
          end
        end
      end
    end

    protected
    def trim_quotes value
      if value
        if [value[0].chr, value[-1].chr] == ['"', '"']
          value[1..-2]
        else
          value
        end
      end
    end

    #helper method for converting "co" into "scm_opts_co" and "" into "scm_opts"
    def resolve_opts command = ""
      command = "_#{command}" if command != ""
      send("scm_opts#{command}")
    end
  end
end
