require 'hash_queue/queue/lockable'

module HashQueue
  class Queue
    include Lockable
    
    def initialize
      @mutex = Mutex.new 
      @queue = []
      @locks = []
    end
    
    def queue(obj)
      @mutex.synchronize do
        @queue.push obj
      end
    end
    alias_method :enqueue, :queue
    
    def pop(options = {})
      if options[:blocking] 
        loop do 
          result = _pop(options)
          
          return result unless result.nil? or result == [] 
          sleep 0.1
        end
      else
        _pop(options)
      end
    end
    
    def size
      @mutex.synchronize do
        @queue.size
      end
    end
    alias_method :count, :size
    
    def empty?
      @mutex.synchronize do
        @queue.empty?
      end
    end
    
    def clear
      @mutex.synchronize do
        @queue.clear
      end
    end
    
    private
    
    def _pop(options)
      @mutex.synchronize do
        size = options.fetch(:size, 1)
        
        if _locked? and _count_locks >= size
          if options.key? :size
            return [] 
          else
            return nil
          end
        end
        
        result = if options.key? :size
          @queue.shift(size - _count_locks)
        else
          @queue.shift
        end
        
        _lock(Array(result).size) if options[:lock]
        result
      end      
    end 
      
  end
end