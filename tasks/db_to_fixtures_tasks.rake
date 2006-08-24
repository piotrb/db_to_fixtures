namespace :db do
	namespace :fixtures do

# 		desc "an improved version of db:fixtures:load, supports multiple databases"
# 		task :load2 => :environment do
# 			require 'active_record/fixtures'
#
# 			class Fixture
# 				def key_list
# 					kls = @class_name.constantize
# 				  columns = @fixture.keys.collect{ |column_name| kls.connection.quote_column_name(column_name) }
# 				  columns.join(", ")
# 				end
# 			end
#
# 			(ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'test', 'fixtures', '*.{yml,csv}'))).each do |fixture_file|
#
# 				puts File.basename(fixture_file)
# 				class_name = File.basename(fixture_file, '.*').pluralize.classify
# 				kls = nil
# 				begin
# 					kls = class_name.constantize
# 				rescue NameError => e
# 					
# 				end
#
# 				connection = kls ? kls.connection : ActiveRecord::Base.connection
#
# 				fixture_name = File.basename(fixture_file, '.*')
#
# 				table_name = kls ? kls.table_name : fixture_name
#
# 				f = Fixtures.new(connection, table_name, class_name, File.join('test/fixtures', fixture_name))
# 				f.delete_existing_fixtures
# 				f.insert_fixtures
#
# 				if connection.respond_to?(:reset_pk_sequence!)
# 					connection.reset_pk_sequence!(table_name)
# 				end
#
# 			end
# 		end

		def model_to_fixtures(klass, order = true, table = nil)
			table ||= klass.table_name
			fn = "test/fixtures/%s.yml" % [table]
			id_field = klass.primary_key
			puts "%11s	%s" % ["update", fn]
			File.open(fn, "w") { |fh|
				fh.puts "# automatically generated fixtures from database data"
				fh.puts "# generated: #{Time.now.to_s}"
				fh.puts
				ord = order ? "#{id_field} asc" : nil
				n = 0 # fallback counter incase o.id is nil
				klass.find(:all, :order => ord).each { |o|
					n += 1
					fh.puts "%s_%d:" % [klass.to_s, o.id.nil? ? n : o.id]
					# remove the --- line from the yaml and indent the yaml 2 characters
					o.attributes.each { |k,v|
						o.attributes[k] = v.to_s if v.kind_of? Bignum
					}
					fh.puts o.attributes.to_yaml.split(/[\r\n]+/).reject { |l| l =~ /---/ }.collect { |l| "  #{l}" }.join("\n")
					fh.puts
				}
			}
		end

		# a hack that on the fly creates an active record class for this table
		# assuming this table is really a table
		def table_to_fixtures(table)
			klass = table.classify
			eval("class #{klass} < ActiveRecord::Base; end")
			klasso = Class.const_get(table.classify)
			model_to_fixtures(klasso, false)
		end

		desc "convert the current database into fixtures"
		task :dump do
			require 'config/environment'
			tables = Dir.glob("test/fixtures/*.yml").collect { |f| File.basename(f).gsub(/\.yml$/, '') }
			tables.each { |tbl|
				begin
					# try getting the active record class for the table
					klass = Class.const_get(tbl.classify)
					model_to_fixtures(klass, true, tbl)
				rescue NameError => e
					# class not found, dump it the hard way
					table_to_fixtures(tbl)
				end
			}
		end
	end
end