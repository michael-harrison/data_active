require "data_active/version"

module DataActive
  def self.included(base)
    base.extend ClassMethods
  end

  def ensure_unique(name)
    begin
      self[name] = yield
    end while self.class.exists?(name => self[name])
  end

  VALID_FROM_XML_OPTIONS = [:sync, :create, :update, :destroy]

  module ClassMethods
    def many_from_xml(source_xml, options = [])
      @data_active_options = options
      many_from root_node_in source_xml
    end

    def many_from(current_node)
      case
        when self.name.pluralize.underscore.eql?(current_node.name.underscore)
          many_from_rails_xml current_node

        when (current_node.name.eql?('dataroot') \
          and current_node.namespace_definitions.map { |ns| ns.href }.include?('urn:schemas-microsoft-com:officedata'))
          # Identified as data generated from Microsoft Access
          many_from_ms_xml current_node

        when self.name.underscore.eql?(current_node.name.underscore)
          raise "The supplied XML (#{current_node.name}) is a single instance of '#{self.name}'. Please use one_from_xml"

        else
          raise "The supplied XML (#{current_node.name}) cannot be mapped to this class (#{self.name})"

      end
    end

    def many_from_ms_xml(current_node)
      records = []
      recorded_ids = []

      current_node.element_children.each do |node|
        if self.name.underscore.eql?(node.name.underscore)
          record = self.one_from_xml(node, @data_active_options)
          if record
            recorded_ids << record[primary_key.to_sym]
            records << record
          end
        end
      end

      remove_records_not_in recorded_ids

      records
    end

    def many_from_rails_xml(current_node)
      records = []
      recorded_ids = []

      current_node.element_children.each do |node|
        record = self.one_from_xml(node, @data_active_options)
        if record
          recorded_ids << record[primary_key.to_sym]
          records << record
        end
      end

      remove_records_not_in recorded_ids

      records
    end

    def remove_records_not_in(recorded_ids)
      if @data_active_options.include?(:sync)
        if recorded_ids.length > 0
          self.destroy_all [self.primary_key.to_s + " not in (?)", recorded_ids.collect]
        end
      elsif @data_active_options.include?(:destroy)
        if recorded_ids.length > 0
          self.destroy_all [self.primary_key.to_s + " not in (?)", recorded_ids.collect]
        else
          self.destroy_all
        end
      end
    end

    def root_node_in(source_xml)
      if source_xml.is_a?(String)
        doc = Nokogiri::XML(source_xml)
        doc.children.first
      else
        source_xml
      end
    end

    def one_from_xml(source_xml, options = [])
      @data_active_options = options

      current_node = root_node_in source_xml

      if current_node.name.eql?(self.class.name.underscore)

      end


      if xml_node_matches_class(current_node)
        # Load or create a new record
        pk_node = current_node.xpath self.primary_key.to_s

        active_record = find_record_based_on(pk_node)


        unless active_record.nil?
          # Check through associations and apply sync appropriately
          self.reflect_on_all_associations.each do |association|
            if ActiveRecord::Reflection::AssociationReflection.method_defined? :foreign_key
              # Support for Rails 3.1 and later
              foreign_key = association.foreign_key
            elsif ActiveRecord::Reflection::AssociationReflection.method_defined? :primary_key_name
              # Support for Rails earlier than 3.1
              foreign_key = association.primary_key_name
            else
              raise "Unsupported version of ActiveRecord. Unable to identify the foreign key."
            end
            case
              when association.macro == :has_many, association.macro == :has_and_belongs_to_many
                # Check to see if xml contains elements for the association
                if active_record.new_record?
                  containers = current_node.xpath("//#{self.name.underscore}[#{self.primary_key}=#{pk_node.text}]/#{association.name}")
                else
                  containers = current_node.xpath("//#{self.name.underscore}[#{self.primary_key}=#{active_record.attributes[self.primary_key.to_s]}]/#{association.name}")
                end
                if containers.count > 0
                  container = containers[0]
                  klass = association.klass
                  child_ids = []
                  container.element_children.each do |single_obj|
                    # TODO: Allow for child node that doesn't have a primary key value
                    child_ids[child_ids.length] = single_obj.xpath(self.primary_key.to_s).text
                    new_record = klass.one_from_xml(single_obj, options)
                    if new_record != nil
                      active_record.__send__(container.name.underscore.to_sym) << new_record
                    end
                  end


                  unless active_record.new_record?
                    if options.include?(:sync)
                      if child_ids.length > 0
                        klass.destroy_all [klass.primary_key.to_s + " not in (?) and #{foreign_key} = ?", child_ids.collect, active_record.attributes[self.primary_key.to_s]]
                      end
                    elsif options.include?(:destroy)
                      if child_ids.length > 0
                        klass.destroy_all [klass.primary_key.to_s + " not in (?) and #{foreign_key} = ?", child_ids.collect, active_record.attributes[self.primary_key.to_s]]
                      else
                        klass.destroy_all
                      end
                    end
                  end
                end

              when association.macro == :has_one
                pk_value = active_record.new_record? ? 0 : active_record.attributes[self.primary_key.to_s]
                single_objects = current_node.xpath("//#{self.name.underscore}[#{self.primary_key}=#{pk_value}]/#{association.name}")
                klass = association.klass
                record = klass.where(foreign_key => active_record.attributes[self.primary_key.to_s]).all
                if single_objects.count == 1
                  # Check to see if the already record exists
                  if record.count == 1
                    db_pk_value = record[0][klass.primary_key]
                    xml_pk_value = Integer(single_objects[0].element_children.xpath("//#{self.name.underscore}/#{klass.primary_key}").text)

                    if db_pk_value != xml_pk_value
                      # Different record in xml
                      if options.include?(:sync) or options.include?(:destroy)
                        # Delete the one in the database
                        klass.destroy(record[0][klass.primary_key])
                      end
                    end
                  elsif record.count > 1
                    raise "Too many records for one to one association in the database. Found #{record.count} records of '#{association.name}' for association with '#{self.name}'"
                  end

                  if options.include?(:create) or options.include?(:update) or options.include?(:sync)
                    new_record = klass.one_from_xml(single_objects[0], options)
                    if new_record != nil
                      new_record[foreign_key.to_sym] = active_record[self.primary_key.to_s]
                      new_record.save!
                    end
                  end
                elsif single_objects.count > 1
                  # There are more than one associations
                  raise "Too many records for one to one association in the provided XML. Found #{single_objects.count} records of '#{association.name}' for association with '#{self.name}'"
                else
                  # There are no records in the XML
                  if record.count > 0 and options.include?(:sync) or options.include?(:destroy)
                    # Found some in the database: destroy then
                    klass.destroy_all("#{foreign_key} = #{active_record.attributes[self.primary_key.to_s]}")
                  end
                end

              when association.macro == :belongs_to

              else
                raise "unsupported association #{association.macro} for #{association.name  } on #{self.name}"
            end
          end

          # Process the attributes
          if options.include? :update or options.include? :sync or options.include? :create
            assign_attributes_from current_node, :to => active_record
          end

          # Save the record
          if options.include? :sync
            # Doing complete synchronisation with XML
            active_record.save
          elsif options.include?(:create) and active_record.new_record?
            active_record.save
          elsif options.include?(:update) and not active_record.new_record?
            active_record.save
          end
        end

        active_record
      else
        raise "The supplied XML (#{current_node.name}) cannot be mapped to this class (#{self.name})"
      end
    end

    def assign_attributes_from(current_node, options)
      record = options[:to]

      record.attributes.each do |name, value|
        attribute_nodes = current_node.xpath name.to_s
        if attribute_nodes.count == 1
          if attribute_nodes[0].attributes['nil'].try(:value)
            record[name] = nil
          else
            record[name] = attribute_nodes[0].text
          end
        elsif attribute_nodes.count > 1
          raise "Found duplicate elements in xml for active record attribute '#{name}'"
        end
      end
    end

    def find_record_based_on(pk_node)
      ar = nil
      if pk_node
        begin
          ar = find pk_node.text
        rescue
          # No record exists, create a new one
          if @data_active_options.include?(:sync) or @data_active_options.include?(:create)
            ar = self.new
          end
        end
      else
        # No primary key value, must be a new record
        if @data_active_options.include?(:sync) or @data_active_options.include?(:create)
          ar = self.new
        end
      end
      ar
    end

    def xml_node_matches_class(xml_node)
      if xml_node.attributes['type'].blank?
        xml_node.name.underscore == self.name.underscore
      else
        xml_node.attributes['type'].value.underscore == self.name.underscore
      end
    end
  end
end

class ActiveRecord::Base
  include DataActive
end
