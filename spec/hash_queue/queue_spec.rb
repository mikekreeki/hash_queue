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
  end
  
  describe 'when popping with blocking option' do
    it 'should wait until some results are available' do
      Thread.new {
        sleep 0.5
        @queue.queue 1
      }   
           
      @queue.pop(blocking: true, size: 1).wont_be_empty
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