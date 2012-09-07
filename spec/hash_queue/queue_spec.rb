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
    end
    
    it 'shouldnt be empty' do
      @queue.empty?.must_equal false
      @queue.size.must_equal 1
    end
    
    it 'should be able to pop the stuff' do
      @queue.pop.must_equal 1
      @queue.empty?.must_equal true
    end
  end
  
  
  
end