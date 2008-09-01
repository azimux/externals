unless Symbol.respond_to? :to_proc
  class Symbol
    def to_proc
      proc {|obj,*args| obj.send(self, *args)}
    end
  end
end