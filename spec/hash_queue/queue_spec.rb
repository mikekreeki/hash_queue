require 'spec_helper'

describe HashQueue::Queue do
  before do
    @queue = HashQueue::Queue.new
  end
  
  describe 'when initialized' do
    
    it 'should be empty' do
      @queue.empty?.must_equal true
      @queue.size.must_equal 0
    end
    
    it 'should be able to queue stuff' do
      @queue.queue :foo
      @queue.size.must_equal 1
    end
    
    it 'should be to queue stuff in batches' do
      @queue.queue_many :foo, :bar, :xyz
      @queue.size.must_equal 3
    end
    
  end
  
  describe 'when queued stuff' do
    before do
      @queue.queue 1
      @queue.queue 2
    end
    
    it 'shouldnt be empty' do
      @queue.empty?.must_equal false
      @queue.size.must_equal 2
    end
    
    it 'should be able to clear itself' do
      @queue.clear
      @queue.empty?.must_equal true
    end
    
    it 'should be able to pop the stuff in right order' do
      @queue.pop.must_equal 1
      @queue.pop.must_equal 2
    end
    
    it 'should be empty when you pop all the stuff' do
      @queue.pop
      @queue.empty?.must_equal false
      @queue.pop
      @queue.empty?.must_equal true
    end
    
    it 'should be able to pop more stuff if you tell it how much stuff do you want' do
      @queue.pop(size: 2).must_equal [1, 2]
    end
    
    it 'should return an array every time when size option specified' do
     @queue.pop(size: 1).must_equal [1]
     
     @queue.clear
     @queue.pop(size: 1).must_equal []
    end
    
    it 'should yeild items in the block passed to #pop' do
      @queue.pop { |item| item.must_equal 1 }
      @queue.pop(size: 1) { |items| items.must_equal [2] }
    end
    
    it 'should pop when block passed to #pop evaluates to truthy value' do
      item = @queue.pop do
        true
      end
      
      item.must_equal 1
    end
    
    it 'shouldnt pop when block passed to #pop evaluates to falsy value' do
      item = @queue.pop {}
      
      item.must_be_nil
    end
    
    it 'should be able to peek in the queue' do
      @queue.peek.must_equal 1
      @queue.size.must_equal 2
    end
    
    it 'should be able to peek on batch of items' do
      @queue.peek(size: 2).must_equal [1,2]
      @queue.size.must_equal 2
    end
  end
  
  describe 'when we queue weird stuff' do
     describe 'like nil' do
       before do
         3.times { @queue.queue nil }
       end

       it 'should return nil when popping' do
         @queue.pop.must_equal nil
         @queue.pop(size: 2).must_equal [nil, nil]
       end
     end

     describe 'like an empty array' do
       before do
         3.times { @queue.queue [] }
       end

       it 'should return an empty array when popping' do
         @queue.pop.must_equal []
         @queue.pop(size: 2).must_equal [[], []]
       end
     end

   end
  
  describe 'when popping with blocking option' do
    it 'should wait until some results are available' do
      Thread.new {
        sleep 0.5
        @queue.queue 1
      }   
           
      @queue.pop(blocking: true, size: 1).wont_be_empty
    end
    
    it 'should return appropriate number of items when locked and size is specified' do
      @queue.lock 1
      
      Thread.new {
        sleep 0.5       
        @queue.queue :foo
        @queue.queue :bar
      }
      
      Timeout::timeout(0.7) { @queue.pop(blocking: true, size: 2).must_equal [:foo] }
    end 
    
    it 'should wait until queue is unlocked' do
      @queue.push :foo, :bar, :xyz
      @queue.lock 3
      
      Thread.new {
        sleep 0.5
        @queue.unlock
        sleep 0.5
        @queue.unlock_all
      }

      Timeout::timeout(0.7) { @queue.pop(blocking: true, size: 3).must_equal [:foo] }
      Timeout::timeout(0.7) { @queue.pop(blocking: true, size: 3).must_equal [:bar, :xyz] }
    end
    
    it 'should wake multiple threads if necessary' do
      threads = []
      threads << Thread.new { sleep 0.1; @queue.pop(blocking: true).must_equal :foo }
      threads << Thread.new { sleep 0.2; @queue.pop(blocking: true).must_equal :bar }
      
      sleep 0.1
      @queue.push :foo, :bar
      Timeout::timeout(0.7) { threads.map(&:join) }
    end
    
    it 'should handle nil in queue' do
      Thread.new {
        sleep 0.5
        @queue.queue_many nil, nil
      }   
      
      Timeout::timeout(0.7) { @queue.pop(blocking: true).must_equal nil }
      Timeout::timeout(0.7) { @queue.pop(blocking: true, size: 1).must_equal [nil] }
    end
    
    it 'should handle empty array in queue' do
      Thread.new {
        sleep 0.5
        @queue.queue_many [], []
      }   
      
      Timeout::timeout(0.7) { @queue.pop(blocking: true).must_equal [] }
      Timeout::timeout(0.7) { @queue.pop(blocking: true, size: 1).must_equal [[]] }
    end
    
  end
  
  describe 'locking' do
    
    it 'should be unlocked when initialized' do
      @queue.locked?.must_equal false
    end
    
    it 'should be able to be locked' do
      @queue.lock
      @queue.locked?.must_equal true
      @queue.count_locks.must_equal 1
    end
    
    it 'should be able to be unloacked when locked' do
      @queue.lock
      @queue.unlock
      @queue.locked?.must_equal false
      @queue.count_locks.must_equal 0
    end
    
    
    it 'should be able to specify how much locks you want to apply' do
      @queue.lock(2)
      @queue.count_locks.must_equal 2
      @queue.unlock(2)
      @queue.count_locks.must_equal 0
    end
    
    it 'should be able to unlock all locks' do
      @queue.lock(2)
      @queue.unlock_all
      @queue.locked?.must_equal false
      @queue.count_locks.must_equal 0
    end
    
    describe 'when popping with lock option' do
      before do
        10.times { @queue.queue :foo }
      end
      
      it 'should place lock on the queue' do
        @queue.pop(lock: true)
        @queue.locked?.must_equal true
        @queue.count_locks.must_equal 1
      end
      
      it 'should put appropriate amount of locks on the queue when custom pop size is specified' do
        @queue.pop(size: 2, lock: true)
        @queue.locked?.must_equal true
        @queue.count_locks.must_equal 2 
      end
      
      it 'should allow you to pop items even if locked when you want more items then there are locks but taking existing locks into account' do        
        @queue.lock(2)
        @queue.pop(size: 10).size.must_equal 8
      end
    end
    
  end
end