import os
import psycopg2
from datetime import datetime
from psycopg2 import errors
from flask import Flask, render_template, request, url_for, redirect, jsonify

app = Flask(__name__)

def get_db_connection():
  conn = psycopg2.connect(host='localhost',
        database="padel",
      # user=os.environ['DB_USERNAME'],
  user="usuario",
    #password=os.environ['DB_PASSWORD']
      password="CLAVE")
  return conn


@app.route('/')
def index():
    conn = get_db_connection()
    cur = conn.cursor()
    try:
      cur.execute('SELECT t.tournament_name, t.begining_date, t.ending_date, t.winner, f.f_location FROM tournament t JOIN tournament_facility tf ON t.tournament_id = tf.tournament_id JOIN facility f ON tf.facility_id = f.facility_id;')
    except errors.InFailedSqlTransaction as err:
        # pass exception to function
        print(err)
    tournaments = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('index.html', tournaments=tournaments)

#-----------------------------------------create---------------------------------------------------
#create player 
@app.route('/create/player/', methods=('GET', 'POST'))
def createplayer():
  if request.method == 'POST':
    player_name = request.form['player_name']
    phone_number = int(request.form['phone_number'])
    conn = get_db_connection()
    cur = conn.cursor()
   
    try:
      cur.execute('INSERT INTO player (player_name,phone_number)'
                  'VALUES (%s, %s)',
                  (player_name,phone_number))
      conn.commit()
      cur.close()
      conn.close()
    except psycopg2.errors.InFailedSqlTransaction as err:
      print(err)
      return jsonify ({'ERRORCODE' : err.pgcode})
    except psycopg2.errors.RaiseException as trig_err:
      print(trig_err)
      return jsonify({'Error': trig_err.args, 'Mensaje': 'Vuelva a la pagina e inserte valores que no incumplan este trigger'}), 500
    else:
      if player_name == None:
        return jsonify ({'ERROR' : 'No hay ningun jugador con ese nombre'}), 404
      else:
        return redirect(url_for('showplayer')),200    

  return render_template('create_player.html')
#create team 
@app.route('/create/team/', methods=('GET', 'POST'))
def createteam():
  if request.method == 'POST':
    player_1 = int(request.form['player_1'])  
    player_2 = int(request.form['player_2'])      

    conn = get_db_connection()
    cur = conn.cursor()
    try:
      cur.execute('INSERT INTO team (player_1,player_2)'
                  'VALUES (%s, %s)',
                  (player_1,player_2))
      conn.commit()
      cur.close()
      conn.close()
    except errors.InFailedSqlTransaction as err:   
      print(err)
      return
    except psycopg2.errors.CheckViolation as checkerr:
      print(checkerr)
      return jsonify({'Error': checkerr.args, 'Mensaje': 'Vuelva a la pagina e inserte valores que no incumplan esta restriccion'}), 500
    else:
      return redirect(url_for('showteam')) 
  return render_template('create_team.html')

#create match 
@app.route('/create/match/', methods=('GET', 'POST'))
def creatematch():
  if request.method == 'POST':
    team1_id = int(request.form['team1_id'])
    team2_id = int(request.form['team2_id'])
    team1_score = int(request.form['team1_score'])
    team2_score = int(request.form['team2_score'])
    facility_id = int(request.form['facility_id']) 
    #match_date_str = request.form['match_date']
    #match_date = datetime.strptime(match_date_str, '%Y-%m-%d')
    match_date = (request.form['match_date']) 
    tournament_id = int(request.form['tournament_id'])
    conn = get_db_connection()
    cur = conn.cursor()
    try:
      cur.execute('INSERT INTO match(team1_id,team2_id,team1_score,team2_score,facility_id, match_date, tournament_id)'
                  'VALUES (%s, %s ,%s ,%s ,%s ,%s ,%s)',
                  (team1_id,team2_id,team1_score,team2_score,facility_id, match_date, tournament_id))
    except errors.InFailedSqlTransaction as err:
      print(err)
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('showmatch')) 

  return render_template('create_match.html')

@app.route('/create/tournament/', methods=('GET', 'POST'))
def createtournament():
    if request.method == 'POST':
        tournament_name = request.form['tournament_name']
        begining_date = datetime(request.form['begining_date']) # mismo problema con las fechas alueError: invalid literal for int() with base 10: '2023-01-09'
        ending_date = datetime(request.form['ending_date'])  
        winner = request.form['winner']
        points_to_play = int(request.form['points_to_play'])
        conn = get_db_connection()
        cur = conn.cursor()
        try:
          cur.execute('INSERT INTO tournament(tournament_name, begining_date, ending_date, winner, points_to_play)'
                      'VALUES (%s, %s, %s, %s ,%s)',
                      (tournament_name, begining_date, ending_date, winner,points_to_play))
        except errors.InFailedSqlTransaction as err:
          print(err)
        conn.commit()
        cur.close()
        conn.close()
        return redirect(url_for('index')) 

    return render_template('create_tournament.html')

#create tournament teams 
@app.route('/create/tournamenteams/', methods=('GET', 'POST'))
def createtournamentteams():
    if request.method == 'POST':
        team_id = int(request.form['team_id'])
        tournament_id = int(request.form['tournament_id'])
        conn = get_db_connection()
        cur = conn.cursor()
        try:
          cur.execute('INSERT INTO tournament_teams (tournament_id,team_id)'
                      'VALUES (%s,%s)',
                      (tournament_id,team_id))
          conn.commit()
          cur.close()
          conn.close()
        except errors.InFailedSqlTransaction as err: # me salta problema con name 'errors' is not defined
          print(err)
        except psycopg2.errors.UniqueViolation as error:
          return jsonify({'Error': error.args, 'Mensaje': 'Vuelva a la pagina e inserte valores que no estén duplicados'}), 500
        except psycopg2.errors.RaiseException as trig_err:
          print(trig_err)
          return jsonify({'Error': trig_err.args, 'Mensaje': 'Vuelva a la pagina e inserte valores que no incumplan este trigger'}), 500
        else:
          return redirect(url_for('index')) 

    return render_template('create_tournament_team.html')

#------------------------------------------delete-----------------------------------------------------
# en los deletes hay problemas cuando le introduces id que no existen 
#delete player
@app.route('/delete/player/', methods=('GET','POST'))
def deleteplayer():
  rows_deleted = 0
  try:
    if request.method == 'POST':
      player_name = (request.form['player_name'])
      conn = get_db_connection()
      cur = conn.cursor()
      cur.execute('DELETE FROM player WHERE player_name = %s',(player_name,))
      rows_deleted = cur.rowcount
      #print(type(id))
      conn.commit()
      conn.close()
      cur.close()
      return redirect(url_for('showplayer'))
  except (Exception, psycopg2.DatabaseError) as error:
        print(error)  
        return jsonify({'Error': error.args}), 500
  
  print(rows_deleted)
  return render_template('delete_player.html')	

#delete match
@app.route('/delete/match/', methods=('GET','POST'))
def deletematch():
  rows_deleted = 0
  try:
    if request.method == 'POST':
      match_id = int(request.form['match_id'])
      conn = get_db_connection()
      cur = conn.cursor()
      cur.execute('DELETE FROM match WHERE match_id = %s',(match_id,))
      rows_deleted = cur.rowcount
      #print(type(id))
      conn.commit()
      conn.close()
      cur.close()
      return redirect(url_for('index'))
  except (Exception, psycopg2.DatabaseError) as error:
        print(error)  
        return jsonify({'Error': error.args}), 500
  print(rows_deleted)
  return render_template('delete_match.html')	

#delete tournament 
#update or delete on table "tournament" violates foreign key constraint "fk_teams_tournament" on table "tournament_teams"DETAIL:  Key (tournament_id)=(1) is still referenced from table "tournament_teams"
@app.route('/delete/tournament', methods=('GET','POST'))
def deletetournament():
  rows_deleted = 0
  try:
    if request.method == 'POST':
      tournament_id= int(request.form['tournament_id'])
      conn = get_db_connection()
      cur = conn.cursor()
      cur.execute("DELETE FROM tournament WHERE tournament_id = %s",(tournament_id,))
      rows_deleted = cur.rowcount
      #print(type(id))
      conn.commit()
      conn.close()
      cur.close()
      return redirect(url_for('showtournament'))
  except (Exception, psycopg2.DatabaseError) as error:
        print(error) 
        return jsonify({'Error': error.args}), 500
  print(rows_deleted)
  return render_template('delete_tour.html')

#delete team
#update or delete on table "team" violates foreign key constraint "match_team1_id_fkey" on table "match"
@app.route('/delete/team/', methods=('GET','POST'))
def deleteteam():
  rows_deleted = 0
  try:
    if request.method == 'POST':
      team_id= int(request.form['team_id'])
      conn = get_db_connection()
      cur = conn.cursor()
      cur.execute("DELETE FROM team WHERE team_id = %s",(team_id,))
      rows_deleted = cur.rowcount
      #print(type(id))
      conn.commit()
      conn.close()
      cur.close()
      return redirect(url_for('showteam'))
  except (Exception, psycopg2.DatabaseError) as error:
        print(error) 
        return jsonify({'Error': error.args}), 500 
  print(rows_deleted)
  return render_template('delete_team.html')

#----------------------------------------------update--------------------------------------------------
#update player
@app.route('/update/player', methods=('GET','POST'))
def updateplayer():
  try:
    if request.method == 'POST':
      player_id = int(request.form['player_id'])
      player_name = request.form['player_name']
      phone_number = int(request.form['phone_number'])
      conn = get_db_connection()
      cur = conn.cursor()
      cur.execute("UPDATE player SET  player_name = %s, phone_number = %s WHERE player_id = %s",(player_name, phone_number,player_id,))
      conn.commit()
      conn.close()
      cur.close()
      return redirect(url_for('showplayer'))
  except (Exception, psycopg2.DatabaseError) as error:
        print(error) 
        return jsonify({'Error': error.args}), 500  
  return render_template('update_player.html')

#update match
@app.route('/update/match/', methods=('GET','POST'))
def updatematch():
  try:
    if request.method == 'POST':
      match_id = int(request.form['match_id'])
      team1_id = int(request.form['team1_id']) 
      team2_id = int(request.form['team2_id'])
      team1_score = int(request.form['team1_score'])
      team2_score = int(request.form['team2_score'])
      facility_id = int(request.form['facility_id'])
      match_date = request.form['match_date']
      tournament_id = int(request.form['tournament_id'])
      conn = get_db_connection()
      cur = conn.cursor()
      cur.execute("UPDATE match SET  team1_id = %s, team2_id = %s,team1_score = %s, team2_score = %s, facility_id= %s ,match_date= %s,tournament_id= %s WHERE match_id = %s",(team1_id , team2_id ,team1_score , team2_score, facility_id,match_date,tournament_id ,match_id ))
      conn.commit()
      conn.close()
      cur.close()
      return redirect(url_for('showmatch'))
  except (Exception, psycopg2.DatabaseError) as error:
        print(error)  
  return render_template('update_match.html')	

#update tournament 
@app.route('/update/tournament/', methods=('GET','POST'))
def updatetournament():
  try:
    if request.method == 'POST':
      tournament_id = int(request.form['tournament_id'])
      tournament_name = request.form['tournament_name'] 
      begining_date = request.form['begining_date']
      ending_date = request.form['ending_date']
      winner = int(request.form['winner'])
      points_to_play = int(request.form['points_to_play'])
      conn = get_db_connection()
      cur = conn.cursor()
      cur.execute("UPDATE tournament SET tournament_name = %s, begining_date = %s, ending_date = %s, winner = %s, points_to_play = %s WHERE tournament_id = %s",(tournament_name, begining_date, ending_date, winner, points_to_play, tournament_id))
      conn.commit()
      conn.close()
      cur.close()
      return redirect(url_for('showtournament'))
  except (Exception, psycopg2.DatabaseError) as error:
        print(error)  
  return render_template('update_tournament.html')	

#------------------------------------ display ------------------------------------------------------------
#mostrar jugadores 
@app.route('/mostar/jugador')
def showplayer():
  conn = get_db_connection()
  cur = conn.cursor()
  try:
    cur.execute('SELECT * FROM player;')
  except errors.InFailedSqlTransaction as err:
    # pass exception to function
      print(err)
  player = cur.fetchall()
  cur.close()
  conn.close()
  return render_template('mostar_jugador.html', player=player)

#mostar torneos
@app.route('/mostar/torneo')
def showtournament():
  conn = get_db_connection()
  cur = conn.cursor()
  try:
    cur.execute('SELECT * FROM tournament;')
  except errors.InFailedSqlTransaction as err:
    # pass exception to function
      print(err)
  tournaments = cur.fetchall()
  cur.close()
  conn.close()
  return render_template('mostar_torneo.html', tournaments=tournaments)
#mostar eqipos 
@app.route('/mostar/equipo')
def showteam():
  conn = get_db_connection()
  cur = conn.cursor()
  try:
    cur.execute('SELECT * FROM team;')
  except errors.InFailedSqlTransaction as err:
    # pass exception to function
      print(err)
  team= cur.fetchall()
  cur.close()
  conn.close()
  return render_template('mostar_equipo.html', team=team)

#mostar ranking 
@app.route('/mostar/ranking')
def showranking():
  conn = get_db_connection()
  cur = conn.cursor()
  try:
    cur.execute('SELECT p.player_name, r.wins, r.defeats, r.points FROM RANKING r JOIN PLAYER p ON r.player_id=p.player_id  order by r.points DESC;')
  except errors.InFailedSqlTransaction as err:
    # pass exception to function
      print(err)
  ranking= cur.fetchall()
  cur.close()
  conn.close()
  return render_template('mostar_ranking.html', ranking=ranking)

#mostar partido 
@app.route('/mostar/partido')
def showmatch():
  conn = get_db_connection()
  cur = conn.cursor()
  try:
    cur.execute('SELECT * FROM match order BY match_id ASC;')
  except errors.InFailedSqlTransaction as err:
    # pass exception to function
      print(err)
  match= cur.fetchall()
  cur.close()
  conn.close()
  return render_template('mostar_partido.html', match=match)
