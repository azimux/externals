module Externals
  # this regular expression will match a quoted string
  # it will allow for " to be escaped with "" within the string
  quoted = '(?:"(?:(?:[^"]*(?:"")?)*)")'

  # this regular expression will match strings of text that are not quoted.  They must appear at the start of a line or after a ,
  # it will also match empty strings like ,,
  unquoted = '(?:[^"\\s][^\\s$]*)'

  column = "(#{quoted}|#{unquoted})"
  PROJECT_LINE_REGEX = Regexp.new("^\\s*#{column}(?:\\s+#{column})?\\s*$")

  class Project
    attr_accessor :branch, :repository, :path
    attr_writer :is_main, :name
    
    def name
      @name ||= (extract_name(repository) || File.basename(path))
    end
    
    def main?
      @is_main
    end

    def self.scm
      raise "subclass responsibility"
    end
    
        
    def scm
      self.class.scm
    end
    
    
    def initialize row_string, is_main = false
      raise "Abstract class" if self.class == Project
      
      #It's the main project
      self.is_main = is_main
        
      if row_string =~ PROJECT_LINE_REGEX
        repbranch = trim_quotes($1)
        self.path = trim_quotes($2)

        if repbranch =~ /^(.*):(\w+)$/
          self.repository = $1
          self.branch = $2
        else
          self.repository = repbranch
        end
      else
        raise "poorly formatted .externals entry: #{row_string}"
      end
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
    
    def path
      @path || default_path(self)
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