class Project < ActiveRecord::Base
  attr_accessible :name, :description, :access, :rules, :prizes, :start, :end
  
  def self.inherited(child)
  		child.instance_eval do
  			def model_name
  				Project.model_name
  			end
  		end
  		super
  end
  
  def came_from
  	  self.name
  end
end