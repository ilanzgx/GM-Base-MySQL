#include <a_samp>
#include <a_mysql>
#include <zcmd>

#define host      "localhost"
#define usuario   "root"
#define database  "db"
#define senha     "" // No caso estou usando wamp e não precisa de senha :P

#define DIALOG_REGISTRO 1
#define DIALOG_LOGIN 2

#define KickZ(%0) SetTimerEx("KickP", 500, false, "i", %0)

forward KickP(playerid);
forward KickP2(playerid);

enum PlayerD
{
	ID,
	Senha,
	Dinheiro,
	Nivel,
	Logado
}
new Player[MAX_PLAYERS][PlayerD];

main()
{
	print("\n----------------------------------");
	print(" Blank Gamemode by your name here");
	print("----------------------------------\n");
}

new MySQL:Conexao;
new query[250];

public OnGameModeInit()
{
	Conexao = mysql_connect(host, usuario, senha, database);
	if(mysql_errno() != 0) print("Nao foi possivel conectar na database MySQL"), SendRconCommand("exit");
	else print("Conectado com sucesso na database MySQL");
	query[0] = EOS;
	strcat(query, "CREATE TABLE IF NOT EXISTS usuarios(ID int AUTO_INCREMENT PRIMARY KEY, Nick varchar(20) NOT NULL,Senha int(20) NOT NULL,Dinheiro int NOT NULL DEFAULT 5000, Nivel int NOT NULL DEFAULT 1)");
	mysql_query(Conexao, query, false);
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	new row;
    format(query, sizeof(query), "SELECT * FROM usuarios WHERE Nick='%s' LIMIT 1", PlayerName(playerid));
    mysql_query(Conexao, query, true);
    cache_get_row_count(row);
    cache_get_value_name_int(0, "Senha", Player[playerid][Senha]);
    if(row > 0)
    {
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login no servidor", "Você é registrado, digite sua senha abaixo", "Logar", "Sair");
    }
    else
    {
    	ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, "Registro no servidor", "Você não é registrado, digite uma senha abaixo", "Registrar", "Sair");
 	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(Player[playerid][Logado]) SalvarConta(playerid);
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_REGISTRO:
	    {
	        if(!response)
	        {
				KickZ(playerid);
	        }
	        if(strlen(inputtext) < 4 || strlen(inputtext) > 20)
	        {
	            SendClientMessage(playerid, -1, "Digite uma senha de mais de 4 caracteres e menos de 20");
                ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, "Registro no servidor", "Você não é registrado, digite uma senha abaixo", "Registrar", "Sair");
                return 1;
	        }
	        if(!strval(inputtext))
			{ 
				ShowPlayerDialog(playerid, DIALOG_REGISTRO, DIALOG_STYLE_PASSWORD, "Registro no servidor", "Você não é registrado, digite uma senha abaixo", "Registrar", "Sair");
				SendClientMessage(playerid, -1, "Digite apenas numeros");
				return 1;
			}
	        CriarConta(playerid, inputtext);
        	SetSpawnInfo( playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 26, 36, 28, 150, 0, 0 );
 			SpawnPlayer(playerid);
	    }
	    case DIALOG_LOGIN:
	    {
	        if(!response)
	        {
				KickZ(playerid);
	        }
	        if(strlen(inputtext) < 4 || strlen(inputtext) > 20)
	        {
	            SendClientMessage(playerid, -1, "Digite uma senha de mais de 4 caracteres e menos de 20");
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login no servidor", "Você é registrado, digite sua senha abaixo", "Logar", "Sair");
                return 1;
	        }
	        if(strval(inputtext) == Player[playerid][Senha])
	        {
                SendClientMessage(playerid, -1, "Logado com sucesso");
         		CarregarConta(playerid);
         		SetSpawnInfo(playerid, 0, 0, 1958.33, 1343.12, 15.36, 269.15, 26, 36, 28, 150, 0, 0 );
         		SpawnPlayer(playerid);
	        }
	        else
	        {
                SendClientMessage(playerid, -1, "Senha incorreta");
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_INPUT, "Login no servidor", "Você é registrado, digite sua senha abaixo", "Logar", "Sair");
                return 1;
	        }
	    }
	}
	return 1;
}

CMD:akkk(playerid)
{
	CallLocalFunction("OnPlayerSpawn", "i", playerid);
	return 1;
}

PlayerName(playerid)
{
	new nome[24];
	GetPlayerName(playerid, nome, 24);
	return nome;
}

CriarConta(playerid, senhaz[])
{
	query[0] = EOS;
	format(query, sizeof(query), "INSERT INTO usuarios(Nick, Senha) VALUES ('%s', '%s')", PlayerName(playerid), senhaz);
	mysql_query(Conexao, query, true);
	SendClientMessage(playerid, -1, "Conta criada com sucesso na database MySQL");
	CarregarConta(playerid);
	return 1;
}

SalvarConta(playerid)
{
	if(Player[playerid][Logado] == 0) return 0;
	format(query, sizeof(query), "SELECT * FROM usuarios WHERE Nick='%s'", PlayerName(playerid));
    mysql_query(Conexao,query,true);
	format(query, sizeof(query), "UPDATE usuarios SET Nick='%s', Nivel=%d, Dinheiro=%d WHERE ID=%d", PlayerName(playerid), GetPlayerScore(playerid), GetPlayerMoney(playerid), Player[playerid][ID]);
	mysql_query(Conexao, query, false);
	return 1;
}

CarregarConta(playerid)
{
	format(query, sizeof(query), "SELECT * FROM usuarios WHERE Nick='%s'", PlayerName(playerid));
    mysql_query(Conexao,query,true);
    
	cache_get_value_name_int(0, "ID", Player[playerid][ID]);
	cache_get_value_name_int(0, "Dinheiro", Player[playerid][Dinheiro]);
	cache_get_value_name_int(0, "Nivel", Player[playerid][Nivel]);
	
	SetPlayerScore(playerid, Player[playerid][Nivel]);
	GivePlayerMoney(playerid, Player[playerid][Dinheiro]);
	Player[playerid][Logado] = 1;
	SendClientMessage(playerid, -1, "Dados da conta foram carregados na database MySQL carregado");
	return 1;
}

public KickP(playerid)
{
	SetTimerEx("KickP2", 1, false, "i", playerid);
	return 1;
}

public KickP2(playerid)
{
	Kick(playerid);
	return 1;
}
