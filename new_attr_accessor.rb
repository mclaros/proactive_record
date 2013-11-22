class Object

	def new_attr_accessor(*args)
		p args
		vars = args.map { |arg| arg.to_s }
		p vars
		vars.each do |var|
			self.send(:define_method, var) do
				instance_variable_get("@#{var}".to_sym)
			end

			self.send(:define_method, "#{var}=") do |obj|
				instance_variable_set("@#{var}", obj)
			end
		end
		nil
	end

end