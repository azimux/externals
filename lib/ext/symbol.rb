unless Symbol.respond_to? :to_proc
  class Symbol
    def to_proc
      proc { |*args| args[0].send(self, *args[1...args.size]) }
    end
  end
end