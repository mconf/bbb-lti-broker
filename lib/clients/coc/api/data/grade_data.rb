# frozen_string_literal: true

module Clients::Coc
  module Api
    module Data
      class GradeData
        attr_reader :id, :name, :classes

        def initialize(id, name)
          @id = id
          @name = name
          @classes = ContainerData.new
        end
      end
    end
  end
end
