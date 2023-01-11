import os
import psycopg2
from flask import Flask, render_template, request, url_for, redirect, abort

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
      cur.execute('SELECT * FROM tournament;')
    except errors.InFailedSqlTranroughsaction as err:
        # pass exception to function
        print_psycopg2_exception(err)
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
    except errors.InFailedSqlTranroughsaction as err:
      print_psycopg2_exception(err)
      abort(404)
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('index')) 

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
      cur.execute('INSERT INTO team(player_1,player_2)'
                  'VALUES (%s, %s)',
                  (player_1,player_2))
    except errors.InFailedSqlTranroughsaction as err:
      print_psycopg2_exception(err)
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('index')) 

  return render_template('create_team.html')