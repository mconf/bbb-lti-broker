module Clients::Coc
  module Api
    module Data
  class SegmentData
    attr_reader :id, :name, :grades

    def initialize(id, name)
      @id = id
      @name = name
      @grades = ContainerData.new
    end
  end
end
end
end