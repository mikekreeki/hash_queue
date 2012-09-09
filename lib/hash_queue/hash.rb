module HashQueue
  class Hash
    
    def initialize
      @hash_queue = {}
      @mutex = Mutex.new
    end
    
    def [](key)
      QueueProxy.new(self, key)
    end
    
    def queue(key, obj)
      get_queue(key).queue obj      
    end
    alias_method :enqueue, :queue
    alias_method :push, :queue
    
    def pop(options = {})
      loop do
        results = pop_from_queues(options)
        
        if options[:blocking] 
          return results unless results.empty?
          sleep 0.01
        else
          return results
        end
      end
    end
    
    def size
      @mutex.synchronize do
        @hash_queue.each_value.inject(0) do |sum, queue|
          sum += queue.size
        end 
      end
    end
    alias_method :count, :size
    
    def empty?
      size.zero?
    end
    
    def keys
      @mutex.synchronize do 
        @hash_queue.keys
      end
    end
    
    def clean
      @mutex.synchronize do 
        @hash_queue.reject! do |key, queue|
          queue.empty?
        end
      end
    end
    
    def clear
      @mutex.synchronize do 
        @hash_queue.clear
      end
    end
    
    def get_queue(key)
      @mutex.synchronize do 
        @hash_queue.fetch(key) do
          @hash_queue[key] = Queue.new
        end
      end
    end
    
    private
    
    def pop_from_queues(options)
      options = options.dup
      options.delete(:blocking)
      
      @mutex.synchronize do
        @hash_queue.each_value.each_with_object([]) do |queue, results|
          queue.pop(options,results)
        end
      end
    end
       
  end
  
  class QueueProxy
    
    [ :queue, :enqueue, :push, :pop, :size, :count, :empty?, :clear, :lock, :unlock, 
     :locked?, :unlock_all, :count_locks, :locks_count].each do |m|
      define_method m do |*args|
        subject.send m, *args
      end
    end

    def initialize(parent, key)
      @parent = parent
      @key = key
    end
    
    def subject
      @parent.get_queue(@key)
    end

  end
end