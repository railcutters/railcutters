module Railcutters
  module ActionController
    # Rename parameters from a hash of "from => to" expressions.
    # The expressions are dot notation strings, and can be used to rename keys, or to move keys
    # around the parameters hash.
    module ParamsRenamer
      def rename!(spec)
        actions_from_spec(spec).each do |action|
          rename_action(action, params)
        end

        params
      end

      def rename(spec)
        params = self.params.deep_dup

        actions_from_spec(spec).each do |action|
          rename_action(action, params)
        end

        params
      end

      private

      # ===== Internal reference
      # A RAW SPEC is an object containing a "from => to" structure of renaming expressions, in
      # the way they are passed to the `rename` method:
      #   ({"a.b[].c" => "c.d[].e"})
      # A SPEC is intermediate parsed structure that represent a list of actions:
      #   ([ACTION, ACTION, ...])
      # An ACTION is a tuple containing the from and to addresses rename operation:
      #   ({ from: ADDRESS, to: ADDRESS })
      # An ADDRESS is an array containing the keys to access the object:
      #   ([KEY, KEY, ...])

      def parse_dot_expr(expr)
        previous_el = ""

        expr.split(".").map do |el|
          result = {key: el.sub(/\[\]$/, "")}

          # If the previous element is an array, we mark the current one
          result[:start_from_previous_array] = true if previous_el.end_with?("[]")
          previous_el = el

          raise "No key specified for attribute in #{expr}!" if result[:key].empty?
          raise "Invalid key specified for attribute in #{expr}" if result[:key].end_with?("[]")

          result
        end
      end

      # Transform a RAW SPEC expression list into a parsed SPEC, with ACTIONS and ADDRESSES, ready
      # to be processed by `rename_action`
      def actions_from_spec(spec)
        spec.map do |from, to|
          result = {from: parse_dot_expr(from), to: parse_dot_expr(to)}
          origin_count = result[:from].sum { |el| el[:start_from_previous_array] ? 1 : 0 }
          dest_count = result[:to].sum { |el| el[:start_from_previous_array] ? 1 : 0 }

          if origin_count != dest_count
            raise "Incompatible number of arrays in expressions '#{from}' and '#{to}'"
          end

          result
        end.map do |action|
          update_action_list(action)
        end
      end

      # Transforms this:
      #   { from/to: [{ key: "obj" }, { key: "obj2", start_from_previous_array: true }] }
      # Into that:
      #   { from/to: ['obj'], child: { from/to: ['obj2'] } }
      def update_action_list(action)
        new_action = {from: [], to: []}

        last_action = new_action
        action[:from].each do |address|
          last_action = process_address(address, :from, last_action)
        end

        last_action = new_action
        action[:to].each do |address|
          last_action = process_address(address, :to, last_action)
        end

        new_action
      end

      def process_address(address, direction, last_inserted_node)
        if address[:start_from_previous_array]
          last_inserted_node[:child] ||= {from: [], to: []}
          last_inserted_node[:child][direction].push(address[:key])

          # Always return the correct node to be used for adding new elements to - in this case it
          # will be the newer child node
          last_inserted_node[:child]
        else
          last_inserted_node[direction].push(address[:key])

          # Always return the correct node to be used for adding new elements to
          last_inserted_node
        end
      end

      # An action is a structure like this one:
      # {
      #   :from=>["person"],
      #   :to=>["person", "name"],
      #   :child => {
      #     :from => ["nationality"],
      #     :to => ["nationality_id"],
      #     :child => {:from => ["id"], :to => ["identification"]}
      #   }
      # },
      def rename_action(action, starting_object = self)
        if action[:from] == action[:to]
          # If both from and to address are the same, it means a rename is not needed, so instead
          # of renaming the element, we just select it and move on to the next iteration
          element = select_element(action[:from], starting_object)
          return unless element
        else
          element = select_element(action[:from], starting_object, 1)&.delete(action[:from].last)
          return unless element
          inject_element(action[:to], element, starting_object)
        end

        if action[:child]
          # If we're iterating over a Hash, we need to get the values, otherwise .each will return a
          # tuple of [key, value] for each element, and we don't want that
          element = element.values if element.respond_to?(:values)

          element.each do |child_el|
            rename_action(action[:child], child_el)
          end
        end
      end

      def select_element(address, starting_object = self, right_pad = 0)
        current = starting_object

        address.take(address.size - right_pad).each do |elem|
          return nil if current.is_a?(Array) || !current.has_key?(elem)
          current = current[elem]
        end

        current
      end

      def inject_element(address, element, starting_object = self)
        current = starting_object
        addr = address.dup
        new_key = addr.pop

        addr.each do |elem|
          unless current[elem]
            current[elem] = {}
            current[elem].permit!
          end

          current = current[elem]
        end

        current[new_key] = element
      end
    end
  end
end
