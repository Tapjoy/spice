require 'cgi'

module Spice
  class Connection
    module Search
      # @option options [String] :q The Solr search query string
      # @option options [String] :sort Order by which to sort the results
      # @option options [Numeric] :start The number by which to offset the results
      # @option options [Numeric] :rows The maximum number of rows to return
      def search(index, options=Mash.new)
        index = index.to_s
        options = {:q => options} if options.is_a? String
        options.symbolize_keys!

        options[:q] ||= '*:*'
        options[:sort] ||= "X_CHEF_id_CHEF_X asc"
        options[:start] ||= 0
        options[:rows] ||= 1000

        # clean up options hash
        options.delete_if{|k,v| !%w(q sort start rows).include?(k.to_s)}

        params = options.collect{ |k, v| "#{k}=#{CGI::escape(v.to_s)}"}.join("&")
        # chef sometimes returns null elements in returned json.
        # get_or_new returns nil in these cases so compact the map to remove them
        case index
        when 'node'
          get("/search/#{CGI::escape(index.to_s)}?#{params}")['rows'].map do |node|
            Spice::Node.get_or_new(node)
          end.compact
        when 'role'
          get("/search/#{CGI::escape(index.to_s)}?#{params}")['rows'].map do |role|
            Spice::Role.get_or_new(role)
          end.compact
        when 'client'
          get("/search/#{CGI::escape(index.to_s)}?#{params}")['rows'].map do |client|
            Spice::Client.get_or_new(client)
          end.compact
        when 'environment'
          get("/search/#{CGI::escape(index.to_s)}?#{params}")['rows'].map do |env|
            env['attrs'] = env.delete('attributes')
            Spice::Environment.get_or_new(env)
          end.compact
        else
          # assume it's a data bag
          get("/search/#{CGI::escape(index.to_s)}?#{params}")['rows'].map do |db|
            data = db['raw_data']
            Spice::DataBagItem.get_or_new(data)
          end.compact
        end
      end # def search
      
    end # module Search
  end # class Connection
end # module Spice