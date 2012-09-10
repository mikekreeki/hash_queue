require 'hash_queue/queue/lockable'

module HashQueue
  class Queue
    include Lockable
    
    def initialize
      @mutex = Mutex.new 
      @queue = []
      @locks = []
      @waiting = []
    end
    
    def queue(obj)
      @mutex.synchronize do
        @queue.push obj
        
        wake_waiting unless @waiting.empty?
      end
    end
    alias_method :enqueue, :queue
    alias_method :push, :queue
    alias_method :<<, :queue
    
    def queue_many(*objs)
      @mutex.synchronize do
        @queue.concat objs
        
        wake_waiting unless @waiting.empty?
      end
    end
    alias_method :enqueue_many, :queue_many
    alias_method :push_many, :queue_many
    
    def pop(options = {}, results = [])
      @mutex.synchronize do
        loop do
          if options[:blocking] and _empty?
            @waiting.push Thread.current
            @mutex.sleep
          else
            return _pop(options,results)
          end
        end
      end
    end
    alias_method :shift, :pop
    
    def size
      @mutex.synchronize do
        @queue.size
      end
    end
    alias_method :count, :size
    alias_method :length, :size
    
    def empty?
      @mutex.synchronize do
        _empty?
      end
    end
    
    def clear
      @mutex.synchronize do
        @queue.clear
      end
    end
    
    private
    
    def _pop(options,results)
      size = options.fetch(:size, 1)
      
      if _locked? and _count_locks >= size
        if options.key? :size
          return [] 
        else
          return nil
        end
      end
            
      (size - _count_locks).times do
        break if _empty?
        results.push @queue.shift
        _lock if options[:lock]
      end
      
      if options.key? :size 
        results
      else
        results[0]
      end
    end 
    
    def _empty?
      @queue.empty?
    end
    
    def wake_waiting
      @waiting.shift.wakeup
    rescue ThreadError
      retry
    end
      
  end
end