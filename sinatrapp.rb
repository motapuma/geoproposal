require 'rubygems'
require 'sinatra'

require_relative './geoproposal.rb'

set :bind, '0.0.0.0'
set :server, 'webrick'

get '/' do
  'Hello world!'
end

get '/whoami' do
	puts system "whoami"
end

get '/pdf' do

	url      = request.referer
	puts url
	#url      = 'http://cliki.geometrica.com/ClinkerGuaymas/Home'
	proposal = Geoproposal.new(url) #aqui entra cliki.geometrica.com/X/Home

	file = proposal.generate_pdf(params[:language])

	if file
		send_file file 
	else
		'Error Con el PDF'
	end

	#send_file 'result2.pdf'

end

get '/pdf/:language' do

	url      = request.referer
	puts url
	#url      = 'http://cliki.geometrica.com/ClinkerGuaymas/Home'
	proposal = Geoproposal.new(url) #aqui entra cliki.geometrica.com/X/Home

	file = proposal.generate_pdf(params[:language])

	if file
		send_file file 
	else
		'Error Con el PDF'
	end

end
