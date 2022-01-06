module Clients::Coc
  module Api
    module Data
      class SchoolData
        attr_reader :id, :segments
        attr_accessor :name

        def initialize(id)
          @id = id
          @name = ''
          @segments = ContainerData.new
        end

        def extract_data_from(raw_schools_data)
          raw_school_data = raw_schools_data.find { |rsd| @id == rsd['escola_id'] }
          return unless raw_school_data

          @name = raw_school_data['escola_nome']
        end

        def parse_structures(structures, classes_ids)
          structures.each do |raw_segment|
            raw_segment['series'].each do |raw_grade|
              raw_grade['turmas'].each do |raw_class|
                next unless raw_class['id'].in?(classes_ids)

                current_segment = @segments.find_by(raw_segment['id'])
                unless current_segment
                  current_segment = SegmentData.new(raw_segment['id'],
                                                    raw_segment['nome'])
                  @segments.push(current_segment)
                end

                current_grade = current_segment.grades.find_by(raw_grade['id'])
                unless current_grade
                  current_grade = GradeData.new(raw_grade['id'], raw_grade['nome'])
                  current_segment.grades.push(current_grade)
                end

                klass = ClassData.new(raw_class['id'], raw_class['nome'])
                current_grade.classes.push(klass)
              end
            end
          end
        end
      end
    end
  end
end
