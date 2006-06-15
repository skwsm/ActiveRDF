# = yars_adapter.rb
#
# ActiveRDF Adapter to Yars storage
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#

require 'net/http'
require 'uri'
require 'cgi'
require 'adapter/abstract_adapter'
require 'adapter/yars/yars_tools.rb'

class YarsAdapter; implements AbstractAdapter
	
	attr_reader :context, :host, :port, :yars, :query_language
	
#----------------------------------------------#
#               PUBLIC METHODS                 #
#----------------------------------------------#

	# Instantiate the connection with the Yars DataBase.
	def initialize(params = {})
		if params.nil?
			raise(YarsError, "In #{__FILE__}:#{__LINE__}, Yars adapter initialisation error. Parameters are nil.")
		end
	 
    @adapter_type = :yars
		@host = params[:host]
		@port = params[:port] || 8080
		@context = params[:context] || ''
		@query_language = 'n3'

		# We don't open the connection yet but let each HTTP method open and close 
		# it individually. It would be more efficient to pipeline methods, and keep 
		# the connection open continuously, but then we would need to close it 
		# manually at some point in time, which I do not want to do.
	
		if proxy=params[:proxy]
			proxy = Net::HTTP.Proxy(proxy) if (proxy.is_a? String and not proxy.empty?)
			raise YarsError, "provided proxy is not a valid Net::HTTP::Proxy" unless (proxy.is_a?(Class) and proxy.ancestors.include?(Net::HTTP))
			@yars = proxy.new(host,port)
		else
			@yars = Net::HTTP.new(host,port)
		end

		$logger.debug("opened YARS connection on http://#{yars.address}:#{yars.port}/#{context}")
	end

	# Add the triple s,p,o in the database.
	#
	# Arguments:
	# * +s+ [<tt>Resource</tt>]: Subject of triples
	# * +p+ [<tt>Resource</tt>]: Predicate of triples
	# * +o+ [<tt>Node</tt>]: Object of triples. Can be a _Literal_ or a _Resource_
	def add(s, p, o)
		# Verification of nil object
		if s.nil? or p.nil? or o.nil?
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : nil received."
			raise(ActiveRdfError, str_error)		
		end
				
		# Verification of type
		if !s.kind_of?(Resource) or !p.kind_of?(Resource) or !o.kind_of?(Node)
			str_error = "In #{__FILE__}:#{__LINE__}, error during addition of statement : wrong type received."
			raise(ActiveRdfError, str_error)		
		end
		
		put("#{wrap(s)} #{wrap(p)} #{wrap(o)} .")
	end

	# queries the RDF database and only counts the results
	def query_count(qs)
		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, query string nil.") if qs.nil?
		$logger.debug "querying count yars in context #@context:\n" + qs
		
		header = { 'Accept' => 'application/rdf+n3' }
		response = yars.get("/#{context}?q=#{CGI.escape(qs)}", header)
		
		# If no content, we return an empty array
		return 0 if response.is_a?(Net::HTTPNoContent)

		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, bad request: " + qs) unless response.is_a?(Net::HTTPOK)
		response = response.body
		
		# returns number of results
		return response.count("\n")
	end

	# query the RDF database
	#
	# qs is an n3 query, e.g. '<> ql:select { ?s ?p ?o . } ; ql:where { ?s ?p ?o . } .'
	def query(qs)
		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, query string nil.") if qs.nil?
		$logger.debug "querying yars in context #@context" 
		
		header = { 'Accept' => 'application/rdf+n3' }
		response = yars.get("/#{context}?q=#{CGI.escape(qs)}", header)
		
		# If no content, we return an empty array
		return Array.new if response.is_a?(Net::HTTPNoContent)

		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, bad request #{response.inspect}: " + qs) unless response.is_a?(Net::HTTPOK)
		response = response.body
		
		$logger.debug "parsing YARS response"
		parse_yars_query_result response
	end

	# Delete a triple. Generate a query and call the delete method of Yars.
	# If an argument is nil, it becomes a wildcard.
	def remove(s, p, o)
		verify_input_type s,p,o
    
		qe = QueryEngine.new
		
		s = s.nil? ? :s : s
		p = p.nil? ? :p : p
		o = o.nil? ? :o : o
		
		# Add binding triple
		qe.add_binding_triple(s, p, o)
		qe.add_condition(s, p, o)
		
		delete(qe.generate)
	end

	# Synchronise the model. For Yars, it isn't necessary. Just return true.
	def save
		true
	end

#----------------------------------------------#
#               PRIVATE METHODS                #
#----------------------------------------------#
	
	private

  # Verification of type
  def verify_input_type(s,p,o)
    if (!s.nil? and !s.kind_of?(Resource)) or
       (!p.nil? and !p.kind_of?(Resource)) or
       (!o.nil? and !o.kind_of?(Node))
      raise(ActiveRdfError, 'wrong type received for removal')
    end
  end
	
	# Add data (string of ntriples) to database
	#
	# Arguments:
	# * +data+ [<tt>String</tt>]: NTriples to add
	def put(data)
		header = { 'Content-Type' => 'application/rdf+n3' }
		
		$logger.debug 'Yars intance = ' + yars.to_s
		
		$logger.debug "putting data to yars (in context #{'/'+context}): #{data}"
		response = yars.put('/'+context, data, header)
		
		$logger.debug 'PUT - response from yars: ' + response.message
		
		return response.instance_of?(Net::HTTPCreated)
	end

	# Delete results of query string from database
	# qs is an n3 query, e.g. '<> ql:select {?s ?p ?o . }; ql:where {?s ?p ?o . } .'
	def delete(qs)
		raise(QueryYarsError, "In #{__FILE__}:#{__LINE__}, query string nil.") if qs.nil?
		$logger.debug 'DELETE - query: ' + qs
		response = yars.delete(@context + '?q=' + CGI.escape(qs))
		$logger.debug 'DELETE - response from yars: ' + URI.decode(response.message)
		return response.instance_of?(Net::HTTPOK)
	end

end

