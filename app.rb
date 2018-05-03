require 'sinatra'	
require 'erb'
require 'slim'
require 'sqlite3'
require 'bcrypt'


	get('/home') do
		erb(:test)
	end

	get('/') do
		db = SQLite3::Database.new("db/database.sqlite")
		result = db.execute("SELECT * FROM posts")
		slim(:index, locals:{post:result})
	end


	get('/login') do
		slim(:login, locals:{username:nil, error:nil})
	end

	get('/register') do
		slim(:register, locals:{username:nil, error:nil})
	end

	post('/register') do
		db = SQLite3::Database.new("db/database.sqlite")
		reg_username = params["reg-username"]
		reg_password1 = params["reg-password1"]
		reg_password2 = params["reg-password2"]
		if reg_password1 == reg_password2
			reg_password = reg_password1
			usernames = db.execute("SELECT username FROM users").join(" ").split(" ")
			p usernames
			if !usernames.include?(reg_username)
				crypt_password = BCrypt::Password.create(reg_password)
				db.execute("INSERT INTO users('username', 'password') VALUES(?, ?)", [reg_username, crypt_password])
				log_error = ""
			else
				log_error = "That username already exists"
			end
		else
			log_error = "Passwords do not match"
			redirect('/register')
		end
		session[:logged] = true
		session[:username] = reg_username
		log_error = ""
		redirect('/')
	end

	post('/login') do
		db = SQLite3::Database.new("db/database.sqlite")
		log_username = params["log-username"]
		log_password = params["log-password"]
		password = db.execute("SELECT password FROM users WHERE username IS '#{log_username}'")
		if password[0] == nil
			log_error = "Wrong username or password"
			redirect('/')
		else
			password_digest = BCrypt::Password.new(password[0][0])
			if  password_digest == log_password
				session[:logged] = true
				session[:username] = log_username
				log_error = ""
			else
				log_error = "Wrong username or password"
			end
		redirect('/')
		end
	end

	post('/logout') do
		log_error = ""
		session[:logged] = false
		session[:username] = "guest"
		redirect('/')
	end


