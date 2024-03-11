# frozen_string_literal: true

module Clients::Coc
  module Api
    module Data
      class ContainerData < Array
        def find_by(element_id)
          find { |e| e.id == element_id }
        end
      end
    end
  end
end
