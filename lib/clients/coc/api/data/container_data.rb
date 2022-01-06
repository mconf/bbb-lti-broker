module Clients::Coc
  module Api
    module Data
      class ContainerData < Array
        def initialize
          super
        end

        def find_by(element_id)
          find { |e| e.id == element_id }
        end
      end
    end
  end
end
