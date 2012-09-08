require 'spec_helper'

describe HashQueue::QueueProxy do
  before do
    hash_queue = HashQueue.new
    @proxy = HashQueue::QueueProxy.new(hash_queue, :foo)
  end
  
  it 'should proxy public methods of Queue and modules included to Queue object itself in sane matter' do
    methods = [HashQueue::Queue, HashQueue::Lockable].map{ |k| k.instance_methods(false) }.flatten
    methods.each do |m|
      @proxy.must_respond_to m
    end
  end
  
  it 'should return the subject, Queue object itself (but really never use it directly, misbehaves in edge cases)' do
    @proxy.subject.must_be_instance_of HashQueue::Queue
  end
end

