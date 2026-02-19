# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

require "lhm"

module OnlineMigration
  # Wraps LHM invocation with a simple helper that can be reused in migrations.
  def lhm_change_table(table_name, **options, &block)
    raise "lhm-shopify only supports MySQL adapters" unless mysql_adapter?

    ensure_lhm_eligible_table!(table_name)

    Lhm.change_table(table_name, **options, &block)
  end

  def add_column(table_name, column_name, type, **options)
    return super if reverting?
    return super unless mysql_adapter?

    lhm_change_table(table_name) do |m|
      m.ddl(format("ALTER TABLE %s ADD COLUMN %s", m.name, column_definition_sql(column_name, type, **options)))
    end
  end

  def change_column(table_name, column_name, type, **options)
    return super if reverting?
    return super unless mysql_adapter?

    lhm_change_table(table_name) do |m|
      m.ddl(format("ALTER TABLE %s MODIFY COLUMN %s", m.name, column_definition_sql(column_name, type, **options)))
    end
  end

  private

    def mysql_adapter?
      connection.adapter_name.match?(/mysql|trilogy/i)
    end

    def ensure_lhm_eligible_table!(table_name)
      primary_key = connection.primary_key(table_name)
      raise "LHM requires primary key 'id' on #{table_name} (found #{primary_key.inspect})" unless primary_key == "id"

      id_column = connection.columns(table_name).find { |column| column.name == "id" }
      return if id_column&.type == :integer

        raise "LHM requires #{table_name}.id to be integer-like (found #{id_column&.sql_type || 'missing'})"
    end

    def column_definition_sql(column_name, type, **options)
      sql_type = connection.type_to_sql(type, **type_sql_options(options))

      parts = [ connection.quote_column_name(column_name), sql_type ]
      parts << default_sql(options) if options.key?(:default)
      parts << null_sql(options)

      parts.compact.join(" ")
    end

    def type_sql_options(options)
      allowed = %i[limit precision scale unsigned]
      options.each_with_object({}) do |(key, value), hash|
        hash[key] = value if allowed.include?(key)
      end
    end

    def default_sql(options)
      "DEFAULT #{connection.quote(options[:default])}"
    end

    def null_sql(options)
      return nil unless options.key?(:null)

      options[:null] == false ? "NOT NULL" : "NULL"
    end
end
