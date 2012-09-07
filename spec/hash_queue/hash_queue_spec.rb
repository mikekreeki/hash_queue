require 'spec_helper'
require 'timeout'

describe HashQueue do
  it 'should be able to create new HashQueue instance' do
    HashQueue.new.wont_be_nil
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
      @hash_queue[:foo].must_be_instance_of HashQueue::Queue
    end
    
    it 'should be able to queue stuff' do
      @hash_queue.queue :foo, 1
      @hash_queue.size.must_equal 1    
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
        @hash_queue[:foo].queue :foo
        @hash_queue[:bar].queue :bar
      end
      
      it 'should return array of items, one from each queue' do
        @hash_queue.pop.sort.must_equal [:foo, :bar].sort
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
      
    end
  
  end
  

end

