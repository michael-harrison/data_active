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
    def many_from_xml(xml, options = [])
      if xml.is_a?(String)
        doc = Nokogiri::XML(xml)
        current_node = doc.children.first
      else
        current_node = xml
      end

      records = []
      if self.name.pluralize.underscore.eql? current_node.name.underscore
        ids = []

        if current_node.attributes['type'].try(:value) == "array"
          current_node.element_children.each do |node|
            record = self.one_from_xml(node, options)
            if record
              ids[ids.length] = record[primary_key.to_sym]
              records[records.length] = record
            end
          end
        else
          records[records.length] = self.one_from_xml current_node
        end


        if options.include?(:sync)
          if ids.length > 0
            self.destroy_all [self.primary_key.to_s + " not in (?)", ids.collect]
          end
        elsif options.include?(:destroy)
          if ids.length > 0
            self.destroy_all [self.primary_key.to_s + " not in (?)", ids.collect]
          else
            self.destroy_all
          end
        end

      elsif self.name.underscore.eq? current_node.name.underscore
        raise "The supplied XML (#{current_node.name}) is a single instance of '#{self.name}'. Please use one_from_xml"
      else
        raise "The supplied XML (#{current_node.name}) cannot be mapped to this class (#{self.name})"
      end

      records
    end

    def one_from_xml(xml, options = [])
      if xml.is_a? String
        doc = Nokogiri::XML xml
        current_node = doc.children.first
      else
        current_node = xml
      end

      if xml_node_matches_class(current_node)
        # Load or create a new record
        pk_value = 0
        pk_node = current_node.xpath self.primary_key.to_s
        if pk_node
          begin
            ar = find pk_node.text
            pk_value = pk_node.text
          rescue
            # No record exists, create a new one
            if options.include?(:sync) or options.include?(:create)
              ar = self.new
            else
              # must have only have :destroy and/or :update so exit
              return nil
            end
          end
        else
          # No primary key value, must be a new record
          if options.include?(:sync) or options.include?(:create)
            ar = self.new
          else
            # must have only have :destroy and/or :update so exit
            return nil
          end
        end

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
              if pk_value == 0
                containers = current_node.xpath("//#{self.name.underscore}[#{self.primary_key}=#{pk_node.text}]/#{association.name}")
              else
                containers = current_node.xpath("//#{self.name.underscore}[#{self.primary_key}=#{pk_value}]/#{association.name}")
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
                    ar.__send__(container.name.underscore.to_sym) << new_record
                  end
                end

                if pk_value != 0
                  if options.include?(:sync)
                    if child_ids.length > 0
                      klass.destroy_all [klass.primary_key.to_s + " not in (?) and #{foreign_key} = ?", child_ids.collect, pk_value]
                    end
                  elsif options.include?(:destroy)
                    if child_ids.length > 0
                      klass.destroy_all [klass.primary_key.to_s + " not in (?) and #{foreign_key} = ?", child_ids.collect, pk_value]
                    else
                      klass.destroy_all
                    end
                  end
                end
              end

            when association.macro == :has_one
              single_objects = current_node.xpath("//#{self.name.underscore}[#{self.primary_key}=#{pk_value}]/#{association.name}")
              klass = association.klass
              record = klass.where(foreign_key => pk_value).all
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
                    new_record[foreign_key.to_sym] = ar[self.primary_key]
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
                  klass.destroy_all("#{foreign_key} = #{pk_value}")
                end
              end

            when association.macro == :belongs_to

            else
              raise "unsupported association #{association.macro} for #{association.name  } on #{self.name}"
          end
        end

        if options.include? :update or options.include? :sync or options.include? :create
          # Process the attributes
          current_node.element_children.each do |node|
            node_name = node.name.underscore.to_sym
            association = self.reflect_on_association node_name

            if association.nil?
              if node.attributes['nil'].try(:value)
                node_value = nil
              else
                node_value = node.text
              end

              if ar.attributes.keys.include? node_name.to_s
                ar[node_name] = node_value
              end
            end
          end
        end

        if options.include? :sync
          # Doing complete synchronisation with XML
          ar.save
        elsif options.include?(:create) and ar.new_record?
          ar.save
        elsif options.include?(:update) and not ar.new_record?
          ar.save
        end

        ar
      else
        raise "The supplied XML (#{current_node.name}) cannot be mapped to this class (#{self.name})"
      end
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
