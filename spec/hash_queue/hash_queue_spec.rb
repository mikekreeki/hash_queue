require 'spec_helper'

describe HashQueue do
  it 'should be able to create new HashQueue instance' do
    HashQueue.new.must_be_instance_of HashQueue::Hash
  end
end

describe HashQueue::Hash do
  
  describe 'when initialized' do 
    before do
      @hash_queue = HashQueue::Hash.new
    end
    
    it 'should be empty' do
      @hash_queue.empty?.must_equal true
    end
    
    it 'should return correct size' do
      @hash_queue.size.must_equal 0
    end
  
    it 'should create Queues on the fly' do
      @hash_queue[:foo].queue 1
      @hash_queue.keys.size.must_equal 1
    end
    
    it 'should be able to queue stuff' do
      @hash_queue.queue :foo, 1
      @hash_queue.size.must_equal 1    
    end
    
    it 'should be able to get Queue object when asked with a key' do
      @hash_queue.get_queue(:foo).must_be_instance_of HashQueue::Queue
      @hash_queue.get_queue(:non_existent).must_be_instance_of HashQueue::Queue
    end
  end
  
  
  describe 'when we queue stuff' do
    before do
      @hash_queue = HashQueue::Hash.new
      @hash_queue.queue :foo, true
      @hash_queue.queue :bar, false
    end
    
    it 'shouldnt be empty' do
      @hash_queue.empty?.must_equal false
    end
  
    it 'should return correct size' do
      @hash_queue.size.must_equal 2
    end
    
    it 'should return maintained keys' do
      @hash_queue.keys.sort.must_equal [:foo, :bar].sort
    end
    
    it 'should be able to clear itself' do
      @hash_queue.clear
      @hash_queue.size.must_equal 0
      @hash_queue.keys.must_equal []
    end
    
    it 'should be able to clean itself' do
      @hash_queue[:foo].pop
      @hash_queue.clean
      @hash_queue.size.must_equal 1
      @hash_queue.keys.must_equal [:bar]
    end
  end
  
  
  describe 'when we queue an array' do
    before do
      @hash_queue = HashQueue::Hash.new
      @hash_queue.queue :foo, [1]
      @hash_queue.queue :bar, [2]
    end
    
    it 'should return array values' do
      @hash_queue.pop.sort.must_equal [[1],[2]].sort
    end
  end
  
  describe 'when we queue weird stuff' do
    before do
      @hash_queue = HashQueue::Hash.new
    end
    
    describe 'like nil' do
      before do
        @hash_queue.queue :foo, nil
      end
      
      it 'should return nil when popping' do
        @hash_queue.pop.must_equal [nil]
      end
    end
    
    describe 'like an empty array' do
      before do
        @hash_queue.queue :foo, []
      end
      
      it 'should return an empty array when popping' do
        @hash_queue.pop.must_equal [[]]
      end
    end
  
  end
  
  describe 'when popping' do
    
    describe 'from empty HashQueue instance' do
      before do
        @hash_queue = HashQueue::Hash.new
      end
      
      it 'should return empty array' do
        @hash_queue.pop.must_equal []
      end
    end
  
  
    describe 'from non-empty HashQueue instance' do
      before do
        @hash_queue = HashQueue::Hash.new
        @hash_queue[:foo].queue 1
        @hash_queue[:foo].queue 2
        @hash_queue[:bar].queue 3
        @hash_queue[:bar].queue 4
      end
      
      it 'should return array of items, one from each queue' do
        @hash_queue.pop.sort.must_equal [1,3].sort
      end
      
      it 'should return appropriate number of items from each queue when size option specified' do
        @hash_queue.pop(size: 2).sort.must_equal [1,2,3,4]
      end
      
    end
  
    
    describe 'with blocking option' do
      before do
        @hash_queue = HashQueue::Hash.new
      end
      
      it 'should wait until some results are available' do
        Thread.new {
          sleep 0.5
          @hash_queue[:foo].queue :bar
        }   
             
        @hash_queue.pop(blocking: true).wont_be_empty
      end
      
      it 'should work as expected when an empty array is queued' do
        Thread.new {
          sleep 0.5
          @hash_queue[:foo].queue []
        }   
        
        Timeout::timeout(0.7) { @hash_queue.pop(blocking: true).must_equal [[]] }
      end
      
    end
  
  end
  
end

