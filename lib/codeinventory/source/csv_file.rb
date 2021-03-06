require "csv"

module CodeInventory
  module Source
    class CSVFile
      attr_reader :csv

      def initialize(csv_file)
        @csv = CSV.read(csv_file, { headers: true, converters: [ :integer ] })
        validate_headers
      end

      def projects
        @csv.collect do |row|
          csv_data = row.to_hash
          csv_data.inject({}) do |memo, pair|
            csv_header, csv_value = pair
            case
            when csv_header == "tags"
              new_pair = { "tags" => csv_value.split(",").collect { |tag| tag.strip } }
            when csv_header.include?(".")
              new_pair = dotted_to_nested(csv_header, csv_value)
            else
              new_pair = { csv_header => csv_value }
            end
            memo.merge(new_pair)
          end
        end
      end

      private

      def dotted_to_nested(path, value)
        path.split(".").reverse.inject(value) do |hash, element|
          { element => hash }
        end
      end

      def validate_headers
        required_headers = [ "name", "description", "license", "openSourceProject", "governmentWideReuseProject", "tags", "contact.email" ]
        required_headers.each do |required|
          raise FileFormatError unless @csv.headers.include? required
        end
      end
    end

    class FileFormatError < StandardError
    end
  end
end
