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
    alias_method :push, :queue
    alias_method :<<, :queue
    
    def queue_many(*objs)
      @mutex.synchronize do
        @queue.concat objs
      end
    end
    alias_method :enqueue_many, :queue_many
    alias_method :push_many, :queue_many
    
    def pop(options = {}, results = [])
      if options[:blocking] 
        loop do 
          result = _pop(options, results)
          
          return result unless result.nil? or result == [] 
          sleep 0.01
        end
      else
        _pop(options,results)
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
      @mutex.synchronize do
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
    end 
    
    def _empty?
      @queue.empty?
    end
      
  end
end