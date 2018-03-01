require 'dry-struct'

module Shokunin
  module Addons
    class Struct < Dry::Struct
      constructor_type :schema

      attribute :enabled, Types::Strict::Bool
    end
  end
end