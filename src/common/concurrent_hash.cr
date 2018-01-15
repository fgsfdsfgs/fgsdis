require "hash"
require "mutex"

class ConcurrentHash(K, V)
  @lock : Mutex
  @hash : Hash(K, V)

  def initialize
    @hash = Hash(K, V).new
    @lock = Mutex.new
  end

  def []=(key : K, value : V)
    @lock.synchronize { @hash[key] = value }
  end

  def [](key : K) : V
    @lock.synchronize { @hash[key] }
  end

  def []?(key : K) : V?
    @lock.synchronize { @hash[key]? }
  end

  def each(&block : (K, V) -> _)
    cb = block
    @lock.synchronize { @hash.each(&cb) }
  end

  def delete(key : K) : V?
    @lock.synchronize { @hash.delete(key) }
  end

  def delete_all(keys : Array(K))
    @lock.synchronize { keys.each { |k| @hash.delete(k) } }
  end
end
