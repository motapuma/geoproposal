class Geoproposal
	require 'rubygems'
	require 'pdfkit'
	require 'mechanize'
	require 'markaby'

	PDFKit.configure do |config|

		config.default_options = {
		    :print_media_type => true,
		    :margin_right =>"2.34cm",
		    :margin_left =>"2.34cm"

		  }

	end
	PATH_ROOT = "/Library/WebServer/Documents/prop/GeoProposal/Sinatra"

	HUB_PATH    =  PATH_ROOT + "/images/hub.png"
	LOGO_BLUE   =  PATH_ROOT + "/images/logo_geometrica_blue.png"
	LOGO_SILVER =  PATH_ROOT + "/images/logo_geometrica_silver.png"

	PROPOSAL_FP_PDF =  PATH_ROOT + "/tmp/proposalFP.pdf"
	PROPOSAL_AP_PDF =  PATH_ROOT + "/tmp/proposalAP.pdf"
	tmpPath         =  PATH_ROOT + "/tmp/"

	RESULT_PDF  = PATH_ROOT  + "/result.pdf"
	RESULT2_PDF  = PATH_ROOT + "/result2.pdf"

	FULL_HEADER_PDF   = PATH_ROOT + "/tmp/fh.pdf"
	HEAD_AND_FOOT_PDF = PATH_ROOT + "/tmp/haf.pdf"
	MERGED_PDF        = PATH_ROOT + "/tmp/m.pdf"
	TMP_PDF           = PATH_ROOT + "/tmp/tmp.pdf"
	APENDIX_PDF       = PATH_ROOT + "/tmp/appendix.pdf"
	IMAGES_PDF  	  = PATH_ROOT + "/tmp/images.pdf"

	RESULT_HTML   = PATH_ROOT + "/html/result.html"
	HEADER_HTML   = PATH_ROOT + "/html/header.html"
	FOOTER_HTML   = PATH_ROOT + "/html/footer.html"
	E_FOOTER_HTML = PATH_ROOT + "/html/footerEnglish.html"
	PDF_CSS       = PATH_ROOT + "/html/geopdf.css" 

	SIMPLE_HEADER_HTML = PATH_ROOT + "/html/simpleHeader.html"

	MARG_BOTTOM = "3.5cm"
	FOOT_SPAC   = "3"
	MARG_TOP 	= "4cm"
	HEAD_SPAC   = "10"


	def initialize(iniData)
		@home_url =	iniData #siempre supongo obtengo aqui un cliki.geometrica.com/XXXXXX/Home
		@home_url = @home_url[0, @home_url.rindex('/') + 1] + 'HOME'
		puts "HOME 2 #{@home_url}"
		if !File.exist?(SIMPLE_HEADER_HTML) || !File.exist?(FOOTER_HTML)
			raise "Falta #{SIMPLE_HEADER_HTML} o #{FOOTER_HTML}"
		end
	end

	def getPageHandle(url)
	  agent = Mechanize.new()
	  page = agent.get url
	  form = page.forms.first

	  if form
		  form.userid = 'durand.j@geometrica.com'
		  form.passwd = '893494'
		  page = agent.submit form
	  end	  
	  # @pageRealUrl = page.uri
	  return page
	end

	def findItemInLinkCollByParam(coll, param1, param2)
		  tmp = Hash.new
		  
		  coll.each do |c|
		    if ((c.to_s() =~ /^#{param1}$|^#{param1}\sRev\.\s*\d\d$/i) || (c.to_s() =~ /^#{param2}$|^#{param2}\sRev\.\s*\d\d$/i))
		      tmp[c.to_s()] = c.href
		    end
		  end

		  tmp = tmp.to_a().sort() { |a,b| b <=> a }
		  return tmp[0][1]
	end

	def get_proposal_for(homeUrl)

		homePage = getPageHandle(homeUrl)
		linkHash = homePage.links
		findLink = findItemInLinkCollByParam(linkHash, 'propuesta', 'proposal')
		propPage = formProposalLink(findLink)
		return propPage

	end

	def getProposalHandler()
		puts "HOME 1 #{@home_url}"
		proposal        = get_proposal_for(@home_url)
		proposalHandler = getPageHandle(proposal)
		return proposalHandler
	end

	def formProposalLink(href)
		return href if href.start_with?("http") || href.start_with?("www.")
		
    	propPage = @home_url[0, @home_url.rindex('/') + 1] + href
   		 return propPage
  	end

	def generate_header(company,project,date,language="esp")

		mab = Markaby::Builder.new

		mab.html do 

			mab.head do
				# http-equiv="Content-Type" content="text/html; charset=utf-8"
				mab.link :rel =>"stylesheet",:type=>"text/css",:href=> PDF_CSS
				mab.meta   :content => "text/html; charset=utf-8"
				mab.script :src => "./app.js"
			end

			mab.body do
				br
				br
				mab.div :align =>"center" do
					img :src => HUB_PATH
				end

				mab.div :align =>"left", :class => "geolittle" do
					
					div company, :class => "geolittle"
					
					div project, :class => "geolittle"
					
					div date, :class => "geolittle"
					
					font "Página " if language == "esp"
					font "Page " if language == "eng"


					font "", :class =>"page",:color =>"#7F7F7F",:size=>"1" 
				end
			end

		end


		htmlFile = File.new(HEADER_HTML,"w")
		htmlFile.write(mab.to_s)
		htmlFile.close

	end

	def generate_begining(date,company,companInfo,intro,project)

		mab = Markaby::Builder.new

		mab.div :align =>"left" do

			mab.p {date}
			mab.p{ company + "<br />" + companInfo  }
			mab.p { project}
			mab.div { intro }	

		end

		return mab.to_s

	end

	def generate_links(links)

		st = ""
		links.search("a").each do |ele |
			
			link = formProposalLink(ele.values[0])
			linkHandler = getPageHandle(link)
			#puts "linksss" + ele.values[0].to_s 

			content = linkHandler.search("//div[@id='bodycontent']")
			
			st += content_correct_images(content)
			#st += content.to_s

		end

		return st

	end

	def get_tempfile_name(prefix, ext)
	#    file_name_final = File.join(PATH_R, "tmp/#{prefix}_#{rand(10000)}_#{Time.now.to_f}_#{rand(10000)}.#{ext}")
	#    file_name_final[file_name_final.index('.')] = '_'
	  #file_name_final = File.join(".", "tmp/#{prefix}-#{rand(10000)}-#{Time.now.to_f}-#{rand(10000)}.#{ext}"
	  	file_name_final = PATH_ROOT + "/tmp/#{prefix}-#{rand(10000)}-#{Time.now.to_f}-#{rand(10000)}.#{ext}"
	   file_name_final[file_name_final.index('.')] = '-'
	 
	   file_name_final
	end

	def getPageAgent(url)
	  agent = Mechanize.new()
	  page = agent.get url
	  form = page.forms.first
	  if form
		  form.userid = 'durand.j@geometrica.com'
		  form.passwd = '893494'
		  page = agent.submit form
	  end
	  # @pageRealUrl = page.uri
	  return agent
	end

	def local_file(img,ext,link = nil )

		tmpNameFile = get_tempfile_name('pic',ext )
		urlImage = img.attr("src")
		puts urlImage
		is_external = link.start_with?("http") || link.start_with?("www.") if link
		#puts link.to_s + "no es nil"
		urlImage = "/" + urlImage if (urlImage[0] != "/" && link[-1] != "/" ) if link
		urlImage = link + urlImage  if is_external if link # Para los external links 
		#puts "Final #{urlImage}"
		#puts "Antes #{urlImage}"	

		urlImage = formProposalLink(urlImage)
		#puts urlImage
		pageAgent = getPageAgent(@home_url)
		temporal=pageAgent.get(urlImage)
		temporal.save( tmpNameFile )
		return tmpNameFile
	end

	def generate_pend(pend)
		return pend
	end

	def content_correct_images(content,link = nil)

		#is_external = link.start_with?("http") || link.start_with?("www.")
	
		content.search("div#bodycontent img").each do |img|
			#puts "IMG" + img.to_s + "Link " + link.to_s
			img['src'] = local_file(img,'png',link)
		end
	

		content.search("div#pagecontent img").each do |img|
			#puts "IMG" + img.to_s + "Link " + link.to_s
			img['src'] = local_file(img,'png',link)
		end

		return content.to_s
	end

	def generate_html(date,project,company,companInfo,links,intro,pend,docLinks)

	 	begining  = generate_begining(date,company,companInfo,intro,project)
	 	body      = generate_links(links)
	 	pend  	  = generate_pend(pend)
	 	#images    = generate_images(docLinks)

	 	mab = Markaby::Builder.new
		mab.html do
			mab.head do
				#mab.meta :name => "pdfkit-header-center", :content =>"\<img src='/Users/albertomota/Desktop/AlbertoMota/GeoJale/Cotizaciones/GeoPropuestas/images/hub.png'\>"
				mab.link :rel =>"stylesheet",:type=>"text/css",:href=> PDF_CSS
				mab.meta :name => "pdfkit-header_html",    :content => HEADER_HTML
	            mab.meta :name => 'pdfkit-margin_bottom',  :content => MARG_BOTTOM
				mab.meta :name => 'pdfkit-footer_spacing', :content => FOOT_SPAC
				mab.meta :name => 'pdfkit-margin_top',     :content => MARG_TOP
				mab.meta :name => 'pdfkit-header_spacing', :content => HEAD_SPAC
				#mab.meta :name => 'pdfkit-footer-center',  :content => "[page]"
			end

			mab.body{ 
				div{ begining }
				div{ body }  
				div{ pend } 
			}
		
		end

	 	return mab.to_s
	end

	def generate_htmlforFirst(date,project,company,companInfo,links,intro,language="esp")

	 	begining  = generate_begining(date,company,companInfo,intro,project)
	 	body      = generate_links(links)
	
	 	mab = Markaby::Builder.new

		mab.html do
			mab.head do
				#mab.meta :name => "pdfkit-header-center", :content =>"\<img src='/Users/albertomota/Desktop/AlbertoMota/GeoJale/Cotizaciones/GeoPropuestas/images/hub.png'\>"
				mab.link :rel =>"stylesheet",:type=>"text/css",:href=> PDF_CSS
				mab.meta :name => "pdfkit-footer_html",    :content => FOOTER_HTML if language == "esp"
				mab.meta :name => "pdfkit-footer_html",    :content => E_FOOTER_HTML if language == "eng"
				mab.meta :name => "pdfkit-header_html",    :content => SIMPLE_HEADER_HTML
				mab.meta :name => 'pdfkit-margin_bottom',  :content => MARG_BOTTOM
				mab.meta :name => 'pdfkit-footer_spacing', :content => FOOT_SPAC
				mab.meta :name => 'pdfkit-margin_top',     :content => MARG_TOP
				mab.meta :name => 'pdfkit-header_spacing', :content => HEAD_SPAC
			end

			mab.body{ 
				div{ begining }
				div{ body }  
			}

		end
	 	return mab.to_s
	end

	 def generate_html_with_body(body)

	 	mab = Markaby::Builder.new
		mab.html do
			mab.head do
				#mab.meta :name => "pdfkit-header-center", :content =>"\<img src='/Users/albertomota/Desktop/AlbertoMota/GeoJale/Cotizaciones/GeoPropuestas/images/hub.png'\>"
				mab.link :rel =>"stylesheet",:type=>"text/css",:href=> PDF_CSS
				mab.meta :content => "text/html; charset=utf-8"
				mab.meta :name => "pdfkit-header_html",    :content => SIMPLE_HEADER_HTML
	            mab.meta :name => 'pdfkit-margin_bottom',  :content => MARG_BOTTOM
				mab.meta :name => 'pdfkit-footer_spacing', :content => FOOT_SPAC
				mab.meta :name => 'pdfkit-margin_top',     :content => MARG_TOP
				mab.meta :name => 'pdfkit-header_spacing', :content => HEAD_SPAC
				#mab.meta :name => "pdfkit-footer_html",    :content => FOOTER_HTML
				#mab.meta :name => 'pdfkit-footer-center',  :content => "[page]"
			end

			mab.body{ 

				div{ body }  
				
			}
		
		end
	 	return mab.to_s
	end

	def existingPDF(docLinks)
		tmpNameFile = get_tempfile_name('result','pdf')

		content = docLinks.search("a")
		urlPDF = content.attr("href")
		#puts urlPDF.to_s + " el url es "
		urlPDF = formProposalLink(urlPDF.to_s)
		pageAgent = getPageAgent(@home_url)

		temporal = pageAgent.get(urlPDF)
		temporal.save( tmpNameFile )
		return tmpNameFile
	end

	def generate_imagesPDF(docLinks)
		options = "-q -dNOPAUSE -dQUIET -dBATCH -sDEVICE=pdfwrite"

		docLinks.search("a").each do |ele |

			link       = formProposalLink(ele.values[0])
			linkHandler = getPageHandle(link)

			content = linkHandler.search("//div[@id='bodycontent']/p/a")

			pdfFile =File.new(IMAGES_PDF,"w")
			pdfFile.write("")
			pdfFile.close

			#puts "sontent " + content.size().to_s
			i = 0

			content.each do |pdf|
				tmpNameFile = get_tempfile_name('imgpdf','pdf')
		
				urlPDF = pdf.attr("href")
				#puts urlPDF
				urlPDF = formProposalLink(urlPDF)
				#puts urlPDF
				pageAgent = getPageAgent(@home_url)

				temporal=pageAgent.get(urlPDF)
				temporal.save( tmpNameFile )

				j = i == 0 ? 0 : i - 1
				
				#puts i.to_s

				system "gs #{options} -sOutputFile=./tmp/pdf#{i}.pdf ./tmp/pdf#{j}.pdf #{tmpNameFile}"

				i = i + 1
				
			end

			system "mv ./tmp/pdf#{i-1}.pdf #{IMAGES_PDF}"
		end
	end

	def generate_appendix(anexLinks)

		st = ""
		options = "-q -dNOPAUSE -dBATCH -dQUIET -sDEVICE=pdfwrite"
		
		i = j = 0
		
		st = ""

		anexLinks.search("a").each do |ele |
			
			#puts "ele " + ele.values[0] + " values"
			link = formProposalLink(ele.values[0])
			#puts "LINKKKKK" + ele + "no soy nada"
			linkHandler = getPageHandle(link)
			#puts linkHandler.class.to_s 

			content = linkHandler.search("//div[@id='bodycontent']")
			content = linkHandler.search("//div[@id='pagecontent']") if content.length == 0
			
			next if content.length == 0

			#puts content
			
			st   = content_correct_images(content,link[0, link.rindex('/') + 1])
			st   = generate_html_with_body(st)
			#puts "empie" + st + "Termina" 
			kit  = PDFKit.new(st, :page_size => 'Letter')
			kit.stylesheets << PDF_CSS
			pdf  = kit.to_pdf
			file = kit.to_file( TMP_PDF )

			#htmlFile =File.new("app.html","w")
			#htmlFile.write(st)
			#htmlFile.close

			j = i == 0 ? 0 : i - 1

			st = "./tmp/anexpdf#{i}.pdf"
			system "gs #{options} -sOutputFile=#{st} ./tmp/anexpdf#{j}.pdf #{TMP_PDF}"

			i = i + 1

		end

		return  st 
	end

	def generate_pdf(language="esp")

		start = Time.now

		handler    = getProposalHandler()

		pdf = handler.search("//div[@id='ppdf']").at(0)
		if pdf.to_s.length > 0
			seudoPDF = existingPDF(pdf)
			return seudoPDF if File.exist?(seudoPDF)#aqui ya obtuve el pdf de result2
		end

		companInfo = handler.search("//span[@id='pcompinfo']").at(0).to_s
		links      = handler.search("//span[@id='plinks']").at(0)
		intro 	   = handler.search("//div[@id='pintro']").at(0).to_s
		pend 	   = handler.search("//div[@id='pend']").at(0).to_s
		docLinks   = handler.search("//span[@id='plinkdoc']").at(0) 
		appLinks   = handler.search("//div[@id='pappendix']").at(0)
		date       = handler.search("//span[@id='pdate']")
		project    = handler.search("//span[@id='pproj']")
		company    = handler.search("//span[@id='pcompany']")
		
		sGH = Time.now

		generate_header(company.at(0).content().to_s,project.at(0).content().to_s,date.at(0).content().to_s,language)

		puts "Generate HEADER " + (Time.now - sGH ).to_s

		date       = date.at(0).to_s
		project    = project.at(0).to_s
		company    = company.at(0).to_s
	 


			sGH = Time.now
			html = generate_html(date,project,company,companInfo,links,intro,pend,docLinks)
			puts "Generate HTML1 " + (Time.now - sGH ).to_s

			sGH = Time.now
			htmlforFirst   = generate_htmlforFirst(date,project,company,companInfo,links,intro,language)
			puts "Generate HTML2 " + (Time.now - sGH ).to_s

			#sGH = Time.now
			#images = generate_images(docLinks)
			#puts "Generate IMAGES " + (Time.now - sGH ).to_s

			sGH = Time.now
			kit  = PDFKit.new(html, :page_size => 'Letter')
			kit.stylesheets << PDF_CSS
			pdf  = kit.to_pdf
			file = kit.to_file( FULL_HEADER_PDF )
			puts "Generate PDF1 " + (Time.now - sGH ).to_s

			sGH = Time.now
			kit  = PDFKit.new(htmlforFirst, :page_size => 'Letter')
			kit.stylesheets << PDF_CSS
			pdf  = kit.to_pdf
			file = kit.to_file( HEAD_AND_FOOT_PDF )
			puts "Generate PDF2 " + (Time.now - sGH ).to_s
	
			options = "-q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dQUIET"
			sGH = Time.now
			system "gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET \-dFirstPage=1 -dLastPage=1 \-sOutputFile=#{PROPOSAL_FP_PDF} #{HEAD_AND_FOOT_PDF}"
			system "gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET \-dFirstPage=2 \-sOutputFile=#{PROPOSAL_AP_PDF} #{FULL_HEADER_PDF}"
			puts "Generate MERGE1 " + (Time.now - sGH ).to_s
	
			#sGH = Time.now
			#kit2 = PDFKit.new(images, :page_size => 'Letter', :orientation => 'Landscape')
			#pdf2 = kit2.to_pdf
			#file2 = kit2.to_file(IMAGES_PDF)
			#puts "Generate IMAGES " + (Time.now - sGH ).to_s

			generate_imagesPDF(docLinks) if docLinks
			name_append = generate_appendix(appLinks)  if appLinks
#=begin
			htmlFile =File.new(RESULT_HTML,"w")
			htmlFile.write(html)
			htmlFile.close
#=end
			sGH = Time.now
	#=begin		
	 		system "gs #{options} -sOutputFile=#{MERGED_PDF } #{PROPOSAL_FP_PDF} #{PROPOSAL_AP_PDF}"
	 		system "gs #{options} -sOutputFile=#{RESULT_PDF} #{MERGED_PDF } #{IMAGES_PDF}"
	 		system "gs #{options} -sOutputFile=#{RESULT2_PDF} #{RESULT_PDF } #{name_append}"
	 		puts "Last Merge " + (Time.now - sGH ).to_s
	#=end
	 		finish = Time.now

	 		puts "TOTAL TIME: " + (finish - start).to_s

	 		return RESULT2_PDF

	end

end

=begin
url = ARGV.first
proposal = Geoproposal.new(url) #aqui entra cliki.geometrica.com/X/Home
proposal.generate_pdf()
=end


