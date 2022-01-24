module Clients::Coc
  module Api
    module Data
      class ClassData
        attr_reader :id, :name

        def initialize(id, name)
          @id = id
          @name = name
        end
      end
    end
  end
end
