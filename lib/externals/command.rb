module Externals
  class Command
    attr_reader :name, :usage, :summary
    def initialize name, usage, summary = nil
      @name = name
      @usage = usage
      @summary = summary
      
      if !@summary
        @summary, @usage = @usage, @summary
      end
    end
    
    def to_s
      retval = "  #{name}"
      retval += "     Usage: #{usage}\n" if usage
      summary.split(/\n/).each do |line|
        retval += "       #{line}\n"
      end
      
      retval
    end
  end
end
