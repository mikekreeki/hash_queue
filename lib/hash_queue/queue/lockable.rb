module HashQueue
  module Lockable
    
    def lock(n = 1)
      @mutex.synchronize do
        _lock(n)
      end
    end
    
    def unlock(n = 1)
      @mutex.synchronize do
        @locks.shift(n)
      end
    end
    
    def locked?
      @mutex.synchronize do
        _locked?
      end
    end
    
    def unlock_all
      @mutex.synchronize do
        @locks.clear
      end
    end
    
    def count_locks
      @mutex.synchronize do
        _count_locks
      end
    end
    alias_method :locks_count, :count_locks
    
    private
    
    def _lock(n = 1)
      n.times { @locks.push true }
    end
    
    def _locked?
      not @locks.empty?
    end
    
    def _count_locks
      @locks.count
    end 
    
  end
end