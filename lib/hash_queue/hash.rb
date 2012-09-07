module HashQueue
  class Hash
    
    def initialize
      @hash_queue = {}
      @mutex = Mutex.new
    end
    
    def [](key)
      @mutex.synchronize do
        @hash_queue.fetch(key) do
          @hash_queue[key] = Queue.new
        end
      end
    end
    
    def pop(options = {})
      loop do
        results = pop_from_queues(options)
        
        if options[:blocking] 
          return results unless results.empty?
          sleep 0.1
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
    
    def empty?
      size.zero?
    end
    
    private
    
    def pop_from_queues(options)
      @mutex.synchronize do
        @hash_queue.each_value.map do |queue|
          queue.pop(options)
        end.flatten.compact
      end
    end
  
  end
end