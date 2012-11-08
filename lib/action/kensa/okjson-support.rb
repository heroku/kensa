class Hash
  def stringify_keys
    new_hash = {}
    each do |key, value|
      case value
      when Hash
        value = value.stringify_keys
      when Array
        value = value.map { |v| v.stringify_keys if v.is_a? Hash }
      end

      new_hash[key.to_s] = value
    end
    new_hash
  end
end

module OkJson
  alias encode_without_stringify encode

  def encode(x)
    encode_without_stringify(x.stringify_keys)
  end
end
