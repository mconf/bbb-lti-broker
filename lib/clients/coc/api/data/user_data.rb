module Clients::Coc
  module Api
    module Data
      class UserData
        attr_reader :id, :name, :email, :schools, :economic_group, :roles

        def initialize(raw_data, schools_data)
          @id = raw_data['id'].to_s
          @name = raw_data['nome']
          @email = raw_data['login']
          @schools = schools_data
          @economic_group = {
            id: raw_data['grupoEconomico']['id'].to_s,
            name: raw_data['grupoEconomico']['nome'],
          }
          @roles = raw_data['tipo_perfil_nome']
        end
      end
    end
  end
end
