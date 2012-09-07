module HashQueue
  class Queue
    
    def initialize
      @mutex = Mutex.new 
      @queue = []
    end
    
    def queue(obj)
      @mutex.synchronize do
        @queue.push obj
      end
    end
    
    def pop(options = {})
      @mutex.synchronize do
        @queue.shift
      end
    end
    
    def size
      @mutex.synchronize do
        @queue.size
      end
    end
    
    def empty?
      @mutex.synchronize do
        @queue.empty?
      end
    end
    
  end
end