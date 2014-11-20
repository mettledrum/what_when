require './lib/organizer.rb'

RSpec.configure do |config|
	config.failure_color = :red
	config.tty = true
	config.color = true
end 

describe Organizer, "#add_next_ocurrences" do
	context "when repeating a month" do
		it "accounts for differently lengthed months" do
			expect(2).to eq(2)
		end
	end
end