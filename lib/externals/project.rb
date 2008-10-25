require 'extensions/symbol'

module Externals
  VALID_ATTRIB = [:name, :path, :repository, :branch, :type, :scm, :revision
  ].map(&:to_s) unless const_defined?('VALID_ATTRIB')

  class Project
    def self.attr_attr_accessor *names
      names = [names].flatten
      names.each do |name|
        define_method name do
          attributes[name.to_sym]
        end
        define_method "#{name}=" do |value|
          attributes[name.to_sym] = value
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

    def freeze_involves_branch?
      true
    end

    def self.scm
      raise "subclass responsibility"
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

    def initialize hash
      raise "Abstract class" if self.class == Project
      raise "expected hash" unless hash.is_a? Hash

      hash = hash.keys.inject({}) do |new_hash, key|
        new_hash[key.to_s] = hash[key]
        new_hash
      end

      inVALID_ATTRIB = hash.keys - Externals::VALID_ATTRIB

      if !inVALID_ATTRIB.empty?
        raise "invalid attribute(s): #{inVALID_ATTRIB.join(', ')}"
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
      if repository =~ /\/([\w_-]+)(?:\.git)?$/
        $1
      end
    end

    def parent_path
      File.dirname path
    end

    def self.project_line? line
      #Make sure it's not a comment
      return false if line =~ /^\s*#/

      line =~ PROJECT_LINE_REGEX
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
  end
end