# Helper method to recursively convert a hash to ActionController::Parameters
def parameters(hash)
  to_value = ->(v) do
    case v
    when Array
      v.map { |e| to_value.call(e) }
    when Hash
      parameters(v)
    else
      v
    end
  end

  hash.each do |k, v|
    hash[k] = to_value.call(v)
  end

  ActionController::Parameters.new(hash)
end
