# Struct to encapsulate the result of the data fetching process.
#
# @param [Object, NilClass] data The actual data fetched, or nil if an error occurred. The data type
#                                depends on the service and can vary based on the service’s needs.
# @param [Boolean] cache_hit Indicates whether the data was fetched from the cache (`true`) or fetched fresh (`false`).
# @param [Integer, NilClass] cache_age The age of the cached data in seconds. Relevant only if `cache_hit` is true.
#                                      If the data is fetched fresh (cache miss), this will be nil.
# @param [String, NilClass] error An error message if something went wrong during the fetch process.
#                                 If no error occurred, this will be nil.
BaseResult = Struct.new(:data, :cache_hit, :cache_age, :error, keyword_init: true) do
  def initialize(data: nil, cache_hit: false, cache_age: nil, error: nil)
    super
  end
end
