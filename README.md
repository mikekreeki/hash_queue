# HashQueue

Simple namespaced queueing system for highly concurrent environments. Maintains separate queues for different keys accessible from numerous threads without a trouble. Think of it as an extension to stdlib's Queue class. Features nice locking capabilities, read on.

## Installation

Add this line to your application's Gemfile:

    gem 'hash_queue', '~> 0.1'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hash_queue
    
For those living on the edge:

    gem 'hash_queue', git: 'git@github.com:mikekreeki/hash_queue.git'
    
..with Bundler 1.1 or newer:

    gem 'mimi', github: 'mikekreeki/hash_queue'

## Usage

To initialize new HashQueue just simply do:

```ruby
require 'hash_queue'

hash_queue = HashQueue.new
```

### Queueing

To queue stuff it's just as easy as:

```ruby
hash_queue[:my_queue].queue Stuff.new

# or

hash_queue.queue :my_queue, Stuff.new
```

Keys (or namespaces if you prefer) can be anything you want. Usually those will be symbols or strings but don't need to be. Objects, classes, numbers or even `true` or `nil` will work. Same applies for queued items.

`#queue` is aliased as `#enqueue` and `#push` for convenience on both hash_queue and individual queues.

### Working with hash_queue as a whole

HashQueue instances offer some handy methods.

##### size 

Returns combined sizes of all queues managed

```ruby
hash_queue = HashQueue.new
hash_queue.queue :animals, "tenderlove's cat"
hash_queue.queue :favourite_rubies, 'rubinius'
hash_queue.size  # => 2
```

##### empty?

Returns `true` or `false` whether hash_queue is empty or not.

```ruby
hash_queue = HashQueue.new
hash_queue.empty? # => true
hash_queue.queue :animals, "tenderlove's cat"
hash_queue.empty? # => false
```

##### clear

Removes all managed queues.

```ruby
hash_queue = HashQueue.new
hash_queue.queue :animals, "tenderlove's cat"
hash_queue.empty? # => false
hash_queue.clear
hash_queue.empty? # => true
```

##### clean

When using lots of different keys (e.g. hostnames) your hash_queue will eventually grow in size. `#clean` removes empty queues to save precious RAM. It's just a maintenance method, it won't break anything, you can use individual queues later the same way you're doing now, they will be automatically redeclared when you touch them.

##### keys 

Returns maintained keys.

```ruby
hash_queue = HashQueue.new
hash_queue.queue :foo, 'Now or never.' 
hash_queue.keys # => [:foo]
```

Not very interesting but comes handy, for interesting stuff check Popping and Locking section down below.

### Working with individual queues

To get a specific queue you want to put your hands on, just do:

```ruby
hash_queue[:my_queue]
```

It also features some not that fancy methods like `#size`, `#empty?` and `#clear`. 

### Popping stuff out of the queues

There are two way to pop stuff from hash_queue. One way is to pop from all the queues at once. When you call `pop` on hash_queue instance it will pop one item from each individual queue it manages (unless it's locked). Always returns an Array.

```ruby
hash_queue = HashQueue.new
hash_queue.queue :animals, :cat
hash_queue.queue :animals, :dog
hash_queue.queue :rubyists, :tenderlove
hash_queue.queue :rubyists, :yehuda
hash_queue.queue :rubyists, :matz


hash_queue.pop # => [:cat, :tenderlove]
hash_queue.pop # => [:dog, :yehuda]
hash_queue.pop # => [:matz]
```

`#pop` method takes optional `:size` option with which you can specify how much items you want to pop out of each queue.

```ruby
hash_queue = HashQueue.new

10.times { |i| hash_queue.queue :queue_1, i }
10.times { |i| hash_queue.queue :queue_2, i + 100 }

hash_queue.pop(size: 2) # => [0, 1, 100, 101]
```

Or you can provide `:blocking` option. When called with `blocking: true` it won't return until there's something to return. When there's nothing to be returned (either all individual queues are empty, locked or there aren't any) the call holds until something is queued from a background thread or some queue is unlocked. 

```ruby
hash_queue = HashQueue.new

Thread.new {
  sleep 1
  @hash_queue[:foo].queue :bar
}   
     
@hash_queue.pop(blocking: true) # waits until a background thread queues something and then returns, [:bar] in this case
```

You can also pop items from individual queues:

```ruby
hash_queue = HashQueue.new
3.times { hash_queue[:foo].queue Object.new }

hash_queue[:foo].pop # => #<Object:0x000001008d4658>
hash_queue[:foo].pop(size: 2) # => [#<Object:0x000001008ae228>, #<Object:0x000001008ae200>]
```

You can use same options as mentioned above.

### Locking capabilities

HashQueue was designed for a specific use case and for that it provides a flexible locking facility.

You can lock a specific queue so you won't be able to pop until you unlock it.

```ruby
hash_queue = HashQueue.new
hash_queue[:foo].queue Object.new
hash_queue[:foo].lock
hash_queue[:foo].pop # => nil
hash_queue[:foo].unlock
hash_queue[:foo].pop # => #<Object:0x000001008a5bf0>
```

And you can place multiple locks on a queue and then you'll need to unlock them all to be able to pop stuff out again.

```ruby
hash_queue = HashQueue.new
hash_queue[:foo].queue Object.new
hash_queue[:foo].lock(3)
hash_queue[:foo].pop # => nil
hash_queue[:foo].unlock
hash_queue[:foo].pop # => nil
hash_queue[:foo].unlock
hash_queue[:foo].unlock
hash_queue[:foo].pop # => #<Object:0x000001008a5bf0>
```

Both `#lock` and `#unlock` take as an argument number of locks you want to put or remove from the queue. Defaults to `1`. There's even a convenient `#unlock_all` method and `#count_locks` that returns current number of locks placed on the queue. You can always check whether the queue is locked with `#locked?`.

```ruby
hash_queue[:foo].lock
hash_queue[:foo].locked? # => true
hash_queue[:foo].unlock
hash_queue[:foo].locked? # => false
```

Here it gets a little bit tricky. When popping stuff out of a queue you can specify `lock: true` option. That means while popping it will place the same number of locks on the queue as the number of items it pops out. 

```ruby
hash_queue[:foo].locked? # => false
hash_queue[:foo].pop(size: 2, lock: true)
hash_queue[:foo].locked? # => true
hash_queue[:foo].count_locks # => 2
```

While it seems complicated the use case is fairly simple. Locking facility ensures that only a certain number of items could be out of a specific queue at one time. Imagine a crawler, you have opened 200 parallel connections but want to make sure you won't open more than 10 connections to one server at the time. You can use HashQueue as a local queue for URLs to be crawled, hostnames using as a key to keep separate queues for each hostname. You pop out 10 URLs placing 10 locks on a hostname, when a page is processed then unlock one lock. 

You may see a flaw in this schema, because I lied a little. The issue with this example is that you can't pop new URLs to process until all previous 10 have been processed, right? You would have to wait until all locks have been unlocked. Well, HashQueue got this covered - You can pop from a queue while the queue is locked! 

Imagine a queue with a lot of items in it. When you tell a queue to pop X items but the queue has Y locks on it, it just pops `X-Y` items. When you look in specs you'll find something like this:

```ruby
it 'should allow you to pop items even if locked when you want more items then there are locks but taking existing locks into account' do        
  @hash_queue[:foo].lock(2)
  @hash_queue[:foo].pop(size: 10).size.must_equal 8
end
```

## Acknowledgements

Requires Ruby 1.9. Tested under MRI 1.9.3 and JRuby.

## TODO

+ Someone please check and correct my grammar in readme. English is not my native language. I will send you my love and hug over Twitter.

## Specs

To run the specs just run:

    rake

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This library is released under the MIT license.

```
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
‘Software’), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
