require 'sinatra'
require 'mysql2'
require 'aws-sdk'
require 'bcrypt'
enable :sessions
load 'local_ENV.rb' if File.exist?('local_ENV.rb')
client = Mysql2::Client.new(:username => ENV['RDS_USERNAME'], :password => ENV['RDS_PASSWORD'], :host => ENV['RDS_HOSTNAME'], :port => ENV['RDS_PORT'], :database => ENV['RDS_DB_NAME'], :socket => '/tmp/mysql.sock')

get '/' do
	erb :index, locals:{error: "", error2: ""}
end

post '/index' do	
	loginname = params[:loginname]
	loginname = client.escape(loginname)
	results2 = client.query("SELECT * FROM useraccounts WHERE `username` = '#{loginname}'")
	password = params[:password]
	session[:loginname] = loginname
	logininfo = []
	results2.each do |row|
		logininfo << [[row['username']], [row['password']]]
	end
	logininfo.each do |accounts|
		salt = accounts[1][0].split('')
		salt = salt[0..28].join
		encrypt = BCrypt::Engine.hash_secret(password, salt)
		if accounts[0][0] == loginname && accounts[1][0] == encrypt
			redirect '/contacts_page'
		end	
	end	
	erb :index, locals:{logininfo: logininfo, error: "Incorrect Username/Password", error2: ""}
end

post '/login_page_new' do
	results2 = client.query("SELECT * FROM useraccounts")
	loginname = params[:loginname]
	password = params[:password]
	confirmpass = params[:confirmpass]
	session[:loginname] = loginname
	password = client.escape(password)
	encryption = BCrypt::Password.create(password)
	loginname1 = loginname.split('')
	counter = 0
	loginname1.each do |elements|
		if elements == " "
			counter += 1
		end
	end
	username_arr = []
	results2.each do |row|
		username_arr << row['username']
	end
	if counter >= 2
		erb :index, locals:{error: "", error2: "Invalid Username Format"}
	elsif username_arr.include?(loginname)
		erb :index, locals:{error: "", error2: "Username Already Exists"}	 
	elsif password != confirmpass
		erb :index, locals:{error: "", error2: "Check Passwords"}
	else
		loginname = client.escape(loginname)
		client.query("INSERT INTO useraccounts(username, password)
  		VALUES('#{loginname}', '#{encryption}')")
   		redirect '/contacts_page'
   	end
end

get '/contacts_page' do
	loginname = session[:loginname]
	loginname = client.escape(loginname)
	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{loginname}'")
	info = []
  	results.each do |row|
    	info << [[row['Index']], [row['FName']], [row['LName']], [row['Address']], [row['City']], [row['State']], [row['ZipCode']], [row['PNumber']],[row['Notes']], [row['Owner']], [row['Number']]]
 	end
	erb :contacts_page, locals:{info: info, loginname: session[:loginname]}
end

post '/contacts_page_add' do
	number = params[:number]
	FName = params[:FName]
	LName = params[:LName]
	Address = params[:Address]
	City = params[:City]
	State = params[:State]
	ZipCode = params[:ZipCode]
	PNumber = params[:PNumber]
	Notes = params[:Notes]
	loginname = session[:loginname]
	number = client.escape(number)
	FName = client.escape(FName)
	LName = client.escape(LName)
	Address = client.escape(Address)
	City = client.escape(City)
	State = client.escape(State)
	ZipCode = client.escape(ZipCode)
	PNumber = client.escape(PNumber)
	Notes = client.escape(Notes)
	loginname = client.escape(loginname)
	client.query("INSERT INTO usertable(number, FName, LName, Address, City, State, ZipCode, PNumber, Notes, owner)
  	VALUES('#{number}', '#{FName}', '#{LName}', '#{Address}', '#{City}', '#{State}', '#{ZipCode}', '#{PNumber}', '#{Notes}', '#{loginname}')")
  	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{loginname}'")
	info = []
  	results.each do |row|
    	info << [[row['Index']], [row['FName']], [row['LName']], [row['Address']], [row['City']], [row['State']], [row['ZipCode']], [row['PNumber']],[row['Notes']], [row['Owner']], [row['Number']]]
 	end
	erb :contacts_page, locals:{info: info, loginname: session[:loginname]}
end

post '/contacts_page_update' do
	index_arr = params[:index_arr]
	number_arr = params[:number_arr]
	FName_arr = params[:FName_arr]
	LName_arr = params[:LName_arr]
	Address_arr = params[:Address_arr]
	City_arr = params[:City_arr]
	State_arr = params[:State_arr]
	ZipCode_arr = params[:ZipCode_arr]
	PNumber_arr = params[:PNumber_arr]
	Notes_arr = params[:Notes_arr]
	loginname = session[:loginname]
	loginname = client.escape(loginname)
	counter = 0
	unless index_arr == nil
		index_arr.each do |ind|
			ind = client.escape(ind)
			number_arr[counter] = client.escape(number_arr[counter])
			client.query("UPDATE `usertable` SET `Number`='#{number_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			FName_arr[counter] = client.escape(FName_arr[counter])
			client.query("UPDATE `usertable` SET `FName`='#{FName_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			LName_arr[counter] = client.escape(LName_arr[counter])
			client.query("UPDATE `usertable` SET `LName`='#{LName_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			Address_arr[counter] = client.escape(Address_arr[counter])
			client.query("UPDATE `usertable` SET `Address`='#{Address_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			City_arr[counter] = client.escape(City_arr[counter])
			client.query("UPDATE `usertable` SET `City`='#{City_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			State_arr[counter] = client.escape(State_arr[counter])
			client.query("UPDATE `usertable` SET `State`='#{State_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			ZipCode_arr[counter] = client.escape(ZipCode_arr[counter])
			client.query("UPDATE `usertable` SET `ZipCode`='#{ZipCode_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			PNumber_arr[counter] = client.escape(PNumber_arr[counter])
			client.query("UPDATE `usertable` SET `PNumber`='#{PNumber_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			Notes_arr[counter] = client.escape(Notes_arr[counter])
			client.query("UPDATE `usertable` SET `Notes`='#{Notes_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			counter += 1
		end
	end
	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{loginname}'")
	info = []
  	results.each do |row|
		info << [[row['Index']], [row['FName']], [row['LName']], [row['Address']], [row['City']], [row['State']], [row['ZipCode']], [row['PNumber']],[row['Notes']], [row['Owner']], [row['Number']]]
 	end
	erb :contacts_page, locals:{info: info, loginname: session[:loginname]}
end

post '/contacts_page_delete' do
	number = params[:number]
	index_arr = params[:index_arr]
	number_arr = params[:number_arr]
	FName_arr = params[:FName_arr]
	LName_arr = params[:LName_arr]
	Address_arr = params[:Address_arr]
	City_arr = params[:City_arr]
	State_arr = params[:State_arr]
	ZipCode_arr = params[:ZipCode_arr]
	PNumber_arr = params[:PNumber_arr]
	Notes_arr = params[:Notes_arr]
	loginname = session[:loginname]
	loginname = client.escape(loginname)
	counter = 0
	unless index_arr == nil
		index_arr.each do |ind|
			ind = client.escape(ind)
			number_arr[counter] = client.escape(number_arr[counter])
			client.query("UPDATE `usertable` SET `Number`='#{number_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			FName_arr[counter] = client.escape(FName_arr[counter])
			client.query("UPDATE `usertable` SET `FName`='#{FName_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			LName_arr[counter] = client.escape(LName_arr[counter])
			client.query("UPDATE `usertable` SET `LName`='#{LName_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			Address_arr[counter] = client.escape(Address_arr[counter])
			client.query("UPDATE `usertable` SET `Address`='#{Address_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			City_arr[counter] = client.escape(City_arr[counter])
			client.query("UPDATE `usertable` SET `City`='#{City_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			State_arr[counter] = client.escape(State_arr[counter])
			client.query("UPDATE `usertable` SET `State`='#{State_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			ZipCode_arr[counter] = client.escape(ZipCode_arr[counter])
			client.query("UPDATE `usertable` SET `ZipCode`='#{ZipCode_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			PNumber_arr[counter] = client.escape(PNumber_arr[counter])
			client.query("UPDATE `usertable` SET `PNumber`='#{PNumber_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			Notes_arr[counter] = client.escape(Notes_arr[counter])
			client.query("UPDATE `usertable` SET `Notes`='#{Notes_arr[counter]}' WHERE `Index`='#{ind}' AND `Owner`='#{loginname}'")
			counter += 1
		end
	end
	number = client.escape(number)
	client.query("DELETE FROM `usertable` WHERE `Number`='#{number}' AND `Owner`='#{loginname}'")
	results = client.query("SELECT * FROM usertable WHERE `Owner`='#{loginname}'")
	info = []
  	results.each do |row|
    	info << [[row['Index']], [row['FName']], [row['LName']], [row['Address']], [row['City']], [row['State']], [row['ZipCode']], [row['PNumber']],[row['Notes']], [row['Owner']], [row['Number']]]
 	end
	erb :contacts_page, locals:{info: info, loginname: session[:loginname]}
end