# Possible scopes:
# cfstack/<stack name>/outputs
#  - key corresponds to output name in this case
# cfstack/<stack name>/resources/<logical resource id>
#  - key is read from JSON-formatted resource metadata
class Hiera
	module Backend
		class Cloudformation_backend
			TIMEOUT = 60  # 1 minute timeout for AWS API response caching

			def initialize
				begin
					require 'aws'
					require 'timedcache'
					require 'json'
				rescue LoadError
					require 'rubygems'
					require 'aws'
					require 'timedcache'
					require 'json'
				end

				@cf = AWS::CloudFormation.new
				@output_cache = TimedCache.new
				@resource_cache = TimedCache.new

				Hiera.debug("Hiera cloudformation backend loaded")
			end

			def lookup(key, scope, order_override, resolution_type)
				Hiera.debug("We are meant to lookup '#{key}' with scope '#{scope}', order_override '#{order_override}' and resolution_type '#{resolution_type}'")

				answer = nil

				Backend.datasources(scope, order_override) do |elem|
					case elem
					when /cfstack\/([^\/]+)\/outputs/
						Hiera.debug("Looking up #{key} as an output of stack #{$1}")
						raw_answer = stack_output_query($1, key)
					when /cfstack\/([^\/]+)\/resources\/([^\/]+)/
						Hiera.debug("Looking up #{key} in metadata of stack #{$1} resource #{$2}")
						raw_answer = stack_resource_query($1, $2, key)
					else
						Hiera.debug("#{elem} doesn't seem to be a CloudFormation hierarchy element")
						next
					end

					Hiera.debug("raw_answer is #{raw_answer}")
					next if raw_answer.nil?

					new_answer = Backend.parse_answer(raw_answer, scope)
					Hiera.debug("new_answer is #{new_answer}")

					case resolution_type
					when :array
						raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
						answer ||= []
						answer << new_answer
					when :hash
						raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
						answer ||= {}
						answer = Backend.merge_answer(new_answer,answer)
					else
						answer = new_answer
						break
					end
				end

				return answer
			end

			def stack_output_query(stack_name, key)
				outputs = @output_cache.get(stack_name)

				if outputs.nil? then
					begin
						outputs = @cf.stacks[stack_name].outputs
					rescue AWS::CloudFormation::Errors::ValidationError
						Hiera.debug("Stack #{stack_name} outputs can't be retrieved")
						outputs = []  # this is just a non-nil value to serve as marker in cache
					end
					@output_cache.put(stack_name, outputs, TIMEOUT)
				end

				output = outputs.select { |item| item.key == key }
				Hiera.debug("Retrieved #{output} as stack output for #{key}")

				return output.empty? ? nil : output.shift.value
			end

			def stack_resource_query(stack_name, resource_id, key)
				metadata = @resource_cache.get({:stack => stack_name, :resource => resource_id})

				if metadata.nil? then
					begin
						metadata = @cf.stacks[stack_name].resources[resource_id].metadata
					rescue AWS::CloudFormation::Errors::ValidationError
						# Stack or resource doesn't exist
						Hiera.debug("Stack #{stack_name} resource #{resource_id} can't be retrieved")
						metadata = "{}" # This is just a non-nil value to serve as marker in cache
					end
					@resource_cache.put({:stack => stack_name, :resource => resource_id}, metadata, TIMEOUT)
				end

				Hiera.debug("Metadata for resource #{resource_id} of stack #{stack_name} is #{metadata}")

				if metadata.respond_to?(:to_str) then
					data = JSON.parse(metadata)

					return data[key] if data.include?(key)
				end

				return nil
			end
		end
	end
end
