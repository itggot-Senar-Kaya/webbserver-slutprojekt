require 'sinatra'	
require 'erb'
require 'slim'
require 'sqlite3'
require 'bcrypt'

class App < Sinatra::Base
	enable :sessions

	get '/' do
		slim(:index)
	end

	post ('/login') do
		db = SQLite3::Database.new("db/database.sqlite") 
		username = params["username"] 
		password = params["password"]
		kryptera_password = db.execute("SELECT password FROM accounts WHERE username=?", username)
		if kryptera_password == []
			password_verify = nil
		else
			kryptera_password = kryptera_password[0][0] 
			password_verify = BCrypt::Password.new(kryptera_password) 
		end
		if password_verify == password
			result = db.execute("SELECT id FROM accounts WHERE username=?", [username])
			session[:id] = result[0][0]
			session[:login] = true 
		else
			session[:login] = false 
		end
		redirect('/notes')
	end

	
	get '/create' do
		slim(:create)
	end

	
	get '/notes' do
		db = SQLite3::Database.new("db/database.sqlite") 
		if session[:login] == true
			note = db.execute("SELECT * FROM notes WHERE account_id=?", session[:id].to_i)
			slim(:notes, locals:{notes:note}) 
		else
			session[:message] = "Fel användarnamn eller lösenord"
			redirect("/error")
		end
	end

	get '/register' do
		slim(:register)
	end

	post('/register') do
		db = SQLite3::Database.new("db/database.sqlite")
		username = params["username"]  
		password = params["password"]
		confirm = params["password2"]
		if confirm == password
			begin
				password_verify = BCrypt::Password.create(password)
				db.execute("INSERT INTO accounts(username, password) VALUES(?,?) ", [username, password_verify])
				redirect('/') #a href="/"
			rescue SQLite3::ConstraintException 
				session[:message] = "Username is not available"
				redirect("/error")
			end
		else
			session[:message] = "Password does not match"
			redirect("/error")
		end
	end

	post ('/create') do
		db = SQLite3::Database.new("db/database.sqlite")
		content = params["content"]
		begin
			db.execute("INSERT INTO notes(account_id,msg) VALUES(?,?)", [session[:id],content])
		rescue SQLite3::ConstraintException 
			session[:message] = "You are not logged in"
			redirect("/error")
		end
		redirect('/notes')
	end

	post ('/delete/:id') do
		db = SQLite3::Database.new("db/database.sqlite")
		id = params[:id]
		p id.to_s + "-----------------------------------------------------------"
		executestring = "DELETE FROM notes WHERE id = " + id.to_s
		p executestring
		db.execute(executestring)
		redirect('/notes')
	end
		
	post('/logout') do
		log_error = ""
		session[:logged] = false
		session[:username] = "guest"
		redirect('/')
	end

	get ('/error') do
		slim(:error, locals:{msg:session[:message]})
	end
end
