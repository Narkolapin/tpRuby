# coding: utf-8
require 'sinatra'
require 'mongo'
require 'cgi'
include Mongo

# On se connecte à la base et on récupère la collection
@@mongo_client = MongoClient.from_uri('mongodb://admin:admin@ds043971.mongolab.com:43971/chat') 
@@collection = @@mongo_client.db("chat").collection("message")  

# En arrivant sur l'application
get '/' do 
	# Si aucun nom n'a été choisi, on va à @login
	halt erb(:login) unless params[:user]
	# Sinon on va à @chat
	erb :chat, locals: { user: params[:user].gsub(/\W/, '') }
end
 
# Utilisé pour récupèrer les messages à intervales régulier
get '/refresh' do
	#On regarde combien il y a de messages dans la collection
	count = @@collection.count
	
	if count > 20 # S'il y en a plus de 20, on récupère seulement les 20 derniers
		messages = @@collection.find().sort(:date => :asc).skip(count - 20)
	else # Sinon on les récupère tous
		messages = @@collection.find().sort(:date => :asc)
	end

	# Pour chaque messages on va créer du html qui sera retourner dans "reponse"
	reponse = ""
	messages.each{ |doc| 
		msg = CGI.escapeHTML("#{ doc['msg'] }") # Pour éviter les failles XSS
		user = CGI.escapeHTML("#{ doc['user'] }") 
		reponse = reponse + 
		"<span id=\"date\">[#{ doc['date'] }]</span> " +
		"<span id=\"user\">#{ user }:</span> " + 
		"<span id=\"msg\">#{ msg }</span><br/><br/>" 
	}

	reponse # Retourne les messages
end

# Utilisé lorsque l'on envoi un message
post '/' do
	date = Time.now.strftime("%d/%m/%Y %H:%M:%S") # On récupère la date et l'heure actuelle
	doc = {"msg" => "#{params[:msgfield]}", 'user' => "#{params[:userfield]}",'date' => date} # On crée un document
	@@collection.insert(doc) # Puis on insert le document
end
 
__END__
 
@@ layout
<html>
	<head>
		<title>Sinatra Chat</title>
		<meta charset="utf-8" />
		<link type="text/css" rel="stylesheet" href="/style.css"/>
	</head>
	<body>
		<center>
		<pre id="banner">
  ██████  ██▓ ███▄    █  ▄▄▄     ▄▄▄█████▓ ██▀███   ▄▄▄          ▄████▄   ██░ ██  ▄▄▄     ▄▄▄█████▓
▒██    ▒ ▓██▒ ██ ▀█   █ ▒████▄   ▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄       ▒██▀ ▀█  ▓██░ ██▒▒████▄   ▓  ██▒ ▓▒
░ ▓██▄   ▒██▒▓██  ▀█ ██▒▒██  ▀█▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄     ▒▓█    ▄ ▒██▀▀██░▒██  ▀█▄ ▒ ▓██░ ▒░
  ▒   ██▒░██░▓██▒  ▐▌██▒░██▄▄▄▄██░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██    ▒▓▓▄ ▄██▒░▓█ ░██ ░██▄▄▄▄██░ ▓██▓ ░ 
▒██████▒▒░██░▒██░   ▓██░ ▓█   ▓██▒ ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒   ▒ ▓███▀ ░░▓█▒░██▓ ▓█   ▓██▒ ▒██▒ ░ 
▒ ▒▓▒ ▒ ░░▓  ░ ▒░   ▒ ▒  ▒▒   ▓▒█░ ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░   ░ ░▒ ▒  ░ ▒ ░░▒░▒ ▒▒   ▓▒█░ ▒ ░░   
░ ░▒  ░ ░ ▒ ░░ ░░   ░ ▒░  ▒   ▒▒ ░   ░      ░▒ ░ ▒░  ▒   ▒▒ ░     ░  ▒    ▒ ░▒░ ░  ▒   ▒▒ ░   ░    
░  ░  ░   ▒ ░   ░   ░ ░   ░   ▒    ░        ░░   ░   ░   ▒      ░         ░  ░░ ░  ░   ▒    ░      
      ░   ░           ░       ░  ░           ░           ░  ░   ░ ░       ░  ░  ░      ░  ░        
                                                                ░                                  


		</pre>
		</center>
		<%= yield %>
	</body>
</html>
 
@@ login
<center>
	<form action='/'>
		<span for='user'>Choisissez un pseudo:</span>
		<input name='user' id='pseudofield' maxlength="30" value='' />
		<input type='submit' value="Entrer" />
	</form>
</center>

@@ chat
<div id='chat'></div>
<br/>
<center>
	<form id="form">
		<input type="hidden" id="userfield" value="<%= user %>" />
		<input id='msgfield' placeholder='Tapez votre message ici...' />
		<input type="submit" value="OK" />
	</form> 
</center>

<script src="jquery.js"></script>
<script>

$( document ).ready(function() {

	var scroll = true;

	setInterval(function() {
	      
	      $.get('/refresh').done(function(data){
	      	$('#chat').html(data);
			if(scroll){
				var chat = document.getElementById('chat');
				chat.scrollTop = chat.scrollHeight;
			}
	      });

	}, 500);

	$("#form").submit(function(e) {
		e.preventDefault();
		$.post('/', {msgfield: $('#msgfield').val(), userfield: $("#userfield").val()});
		$('#msgfield').val(''); 
		$('#msgfield').focus();

	});
	
	$('#chat').mouseover(function(){
		scroll = false;
	});

	$('#chat').mouseout(function(){
		scroll = true;
	});
});

</script>