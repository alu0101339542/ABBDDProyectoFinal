/*START TRANSACTION;*/
/*Remove all tables in 'public' schema*/
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

/*Drop tables if exist */
DROP TABLE IF EXISTS player;
DROP TABLE IF EXISTS team;
DROP TABLE IF EXISTS tournament;
DROP TABLE IF EXISTS tournament_teams;
DROP TABLE IF EXISTS facility;
DROP TABLE IF EXISTS tournament_facility;
DROP TABLE IF EXISTS court;
DROP TABLE IF EXISTS match;
DROP TABLE IF EXISTS teams_qualified;
DROP TABLE IF EXISTS ranking;
DROP TABLE IF EXISTS captain;
DROP TABLE IF EXISTS team_mate;


/*Create tables */
CREATE TABLE player(
  player_id INT GENERATED ALWAYS AS IDENTITY,
  player_name VARCHAR(30),
  phone_number INT UNIQUE, /*quiero que solo pueda tener 9 digitos. Probablemente se haga con un trigger Posiblemente haya que hacer una función*/
  PRIMARY KEY(player_id)
  );

CREATE TABLE captain(
  player_id INT UNIQUE,
  captain_bonus INT,
  PRIMARY KEY(player_id),
  CONSTRAINT fk_player_captain
    FOREIGN KEY (player_id) REFERENCES player(player_id)
    ON DELETE CASCADE /*CASCADE specifies that when a referenced row is deleted, row(s) referencing it should be automatically deleted as well.*/
    ON UPDATE CASCADE
  );

CREATE TABLE team_mate(
  player_id INT UNIQUE,
  best_season VARCHAR(9),
  PRIMARY KEY(player_id),
  CONSTRAINT fk_player_team_mate
    FOREIGN KEY (player_id) REFERENCES player(player_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
  );


CREATE TABLE team(
  team_id INT GENERATED ALWAYS AS IDENTITY,
  player_1 INT NOT NULL UNIQUE,
  player_2 INT NOT NULL UNIQUE,
  CHECK (player_1 != player_2),
  PRIMARY KEY(team_id),
  CONSTRAINT fk_player_id
    FOREIGN KEY (player_1) REFERENCES player (player_id),
    FOREIGN KEY (player_2) REFERENCES player (player_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
  );

CREATE TABLE tournament(
  tournament_id INT GENERATED ALWAYS AS IDENTITY,
  tournament_name VARCHAR(30) UNIQUE,
  begining_date DATE,
  ending_date DATE,
  winner INT,
  points_to_play INT DEFAULT 0,
  CHECK (begining_date <= ending_date),
  PRIMARY KEY(tournament_id),
  CONSTRAINT fk_team_win
    FOREIGN KEY (winner)
      REFERENCES team(team_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE TABLE tournament_teams( /*Hay que hacer qeu sea potencia de 2*/
  tournament_id INT,
  team_id INT,
  --PRIMARY KEY (tournament_id),
  CONSTRAINT fk_teams_tournament
    FOREIGN KEY (tournament_id)REFERENCES tournament(tournament_id),
    FOREIGN KEY (team_id)REFERENCES team(team_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

--This will assure the same team is not twice on the same tournament
CREATE UNIQUE INDEX index_tournament_teams
ON tournament_teams (tournament_id, team_id);

CREATE TABLE facility(
  facility_id INT GENERATED ALWAYS AS IDENTITY,
  number_courts INT DEFAULT 0,
  f_location VARCHAR(30),
  PRIMARY KEY (facility_id)
);

CREATE TABLE court(
  court_id INT GENERATED ALWAYS AS IDENTITY,
  facility_id INT,
  price numeric(4,1),
  PRIMARY KEY (court_id),
  CONSTRAINT fk_court_facility
    FOREIGN KEY (facility_id) REFERENCES facility(facility_id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT
);

CREATE TABLE tournament_facility(
  tournament_id INT,
  facility_id INT,
  PRIMARY KEY (tournament_id),
  CONSTRAINT fk_tournament_location
    FOREIGN KEY (tournament_id) REFERENCES tournament(tournament_id),
    FOREIGN KEY (facility_id) REFERENCES facility(facility_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE TABLE match(
  match_id INT GENERATED ALWAYS AS IDENTITY,
  team1_id INT,
  team2_id INT,
  team1_score INT,/*Numero de juegos ganados*/
  team2_score INT,/*Numero de juegos ganados*/
  facility_id INT,
  winner INT DEFAULT NULL,
  match_date DATE,
  tournament_id INT DEFAULT NULL,
  CHECK (team1_id != team2_id),

  /*Nos aseguramos que solo puede dar resultados posibles para el padel */
  CHECK((team1_score = 7 AND team2_score <=6 AND team2_score >=5) 
    OR (team2_score = 7 AND team1_score <=6 AND team2_score >=5) 
    OR (team1_score = 6 AND team2_score <=4) 
    OR (team2_score = 6 AND team1_score <=4)),
  
  PRIMARY KEY (match_id),
  CONSTRAINT fk_match
    FOREIGN KEY (tournament_id) REFERENCES tournament(tournament_id),
    FOREIGN KEY (facility_id) REFERENCES facility(facility_id),
    FOREIGN KEY (team1_id) REFERENCES team(team_id),
    FOREIGN KEY (team2_id) REFERENCES team(team_id),
    FOREIGN KEY (winner) REFERENCES player(player_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE TABLE teams_qualified(
  team_id INT UNIQUE,
  tournament_id INT,
  teampoints INT DEFAULT 0, /*calculated from the sum of the player's points*/
  PRIMARY KEY (tournament_id),
  CONSTRAINT fk_qualify
    FOREIGN KEY (team_id) REFERENCES team(team_id),
    FOREIGN KEY (tournament_id) REFERENCES tournament(tournament_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

CREATE TABLE ranking(
  player_id INT UNIQUE,
  wins INT DEFAULT 0,
  defeats INT DEFAULT 0,
  points INT DEFAULT 0,
  PRIMARY KEY (player_id),
  CONSTRAINT fk_players_ranking
    FOREIGN KEY (player_id) REFERENCES player(player_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);



/*COMMIT;*/

/*Esto se hará en otro ficchero para que quede mas limpio*/
