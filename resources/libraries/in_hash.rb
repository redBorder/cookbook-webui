class Chef
  class Recipe

    def in_hash?(hash, *keys)                                                                                            
      if hash[keys.first] && keys.size == 1
        return true
      elsif hash[keys.first] && hash[keys.first].is_a?(Hash)
        in_hash? hash[keys.first], *keys[1..keys.size-1]
      else
        return false
      end
    end

  end
end
