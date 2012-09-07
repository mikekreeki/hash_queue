require 'hash_queue/hash'
require 'hash_queue/queue'

module HashQueue
  extend self
    
  def new
    Hash.new
  end
end
