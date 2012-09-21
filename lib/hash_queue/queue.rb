require 'hash_queue/queue/lockable'
require 'ostruct'

module HashQueue
  class Queue
    include Lockable
    
    def initialize
      @mutex = Mutex.new 
      @queue = []
      @locks = []
      @waiting = []
    end
    
    def queue(*objs)
      @mutex.synchronize do
        @queue.concat objs
        
        wake_waiting
      end
    end
    alias_method :enqueue, :queue
    alias_method :push, :queue
    alias_method :<<, :queue
    alias_method :queue_many, :queue
    alias_method :enqueue_many, :queue
    alias_method :push_many, :queue
    
    def pop(options = {}, results = [])
      @mutex.synchronize do
        loop do
          if options[:blocking] and not can_pop?(options[:size] || 1)
            @waiting.push OpenStruct.new(thread: Thread.current, pop_size: options[:size] || 1) 
            @mutex.sleep
          else
            if block_given?
              should_pop = yield _peek(options)
              
              if should_pop
                return _pop(options,results)
              else
                return 
              end
            else
              return _pop(options,results)
            end
          end
        end
      end
    end
    alias_method :shift, :pop
    
    def peek(options = {})
      @mutex.synchronize do
        _peek(options)
      end
    end
    
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
      
      unless can_pop?(size)
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
    
    def _peek(options)
      if options.has_key? :size
        @queue[0..options[:size]]
      else
        @queue[0]
      end
    end
    
    def _empty?
      @queue.empty?
    end
    
    def wake_waiting
      unless @waiting.empty?
        while @waiting[0] and can_pop? @waiting[0].pop_size
          begin
            @waiting.shift.thread.wakeup
          rescue ThreadError
            retry
          end
        end
      end
    end
    
    def can_pop?(size)   
      size = @queue.size if size > @queue.size

      (not _empty?) and (size > _count_locks)
    end
      
  end
end