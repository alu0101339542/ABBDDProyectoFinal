/*
hAY QUE PROBAR LOS ON DELETE 
trigger para no poderte entrar a equipos_torneo si no has clasificado
trigger para no poder clasificar si no tienes suficientes puntos los jugagadores en el ranking
Añadir la restriccion de inclusividad para clasificacion de torneo

*/

-----------------------------------------------------------------------------------Calculated attributes----------------------------------------------------------------


--Calculate number of courts
CREATE OR REPLACE FUNCTION update_number_courts()
RETURNS TRIGGER AS $ncourts$
BEGIN
    UPDATE facility
    SET number_courts = (SELECT COUNT(*) FROM court WHERE facility_id = NEW.facility_id)
    WHERE facility_id = NEW.facility_id;
    RETURN NULL;
END;
$ncourts$ LANGUAGE plpgsql;

CREATE TRIGGER update_number_courts_trigger
AFTER INSERT OR UPDATE OR DELETE
ON court
FOR EACH ROW
EXECUTE PROCEDURE update_number_courts();

--function to assure the same player is not in two different teams
/*CREATE OR REPLACE FUNCTION set_team_points()
RETURNS TRIGGER AS $tp$
BEGIN
  WITH 
    A AS (
      SELECT player_id, points, team_id
      FROM ranking r
      JOIN team t ON t.player_1 = r.player_id
    ), 
    B AS (
      SELECT player_id, points, team_id
      FROM ranking r
      JOIN team t ON t.player_2 = r.player_id
    ), 
    Poin AS (
      SELECT a.points + b.points as points, A.team_id
      FROM A a JOIN B b ON a.team_id = b.team_id
  )
  UPDATE teams_qualified
  SET teampoints = (SELECT points FROM Poin p WHERE team_id = NEW.team_id)
  WHERE team_id = NEW.team_id;
  RETURN NULL;
END;
$tp$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_team_points()
RETURNS TRIGGER AS $tp$
BEGIN
 UPDATE teams_qualified
 SET teampoints = (SELECT SUM(points)
      FROM ranking r
      JOIN team t ON t.player_1 = r.player_id
      WHERE t.team_id = NEW.team_id
      GROUP BY t.team_id) + (SELECT SUM(points)
      FROM ranking r
      JOIN team t ON t.player_2 = r.player_id
      WHERE t.team_id = NEW.team_id
      GROUP BY t.team_id);

  RETURN NULL;
END;
$tp$ LANGUAGE plpgsql;

CREATE TRIGGER set_team_points_trigger
AFTER INSERT OR UPDATE OR DELETE
ON teams_qualified
FOR EACH ROW
EXECUTE PROCEDURE set_team_points();*/


--Ranking
CREATE OR REPLACE FUNCTION update_ranking()
RETURNS TRIGGER AS $$
BEGIN
  -- update the wins column for the winning team's players
  UPDATE ranking
  SET wins = wins + 1
  WHERE player_id IN (
    SELECT player_1 FROM team WHERE team_id = NEW.winner
    UNION
    SELECT player_2 FROM team WHERE team_id = NEW.winner
  );

  -- update the defeats column for the losing team's players
  UPDATE ranking
  SET defeats = defeats + 1
  WHERE player_id IN (
    SELECT player_1 FROM team WHERE team_id = NEW.team1_id OR team_id = NEW.team2_id
    UNION
    SELECT player_2 FROM team WHERE team_id = NEW.team1_id OR team_id = NEW.team2_id
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ranking
AFTER INSERT ON match
FOR EACH ROW
EXECUTE PROCEDURE update_ranking();
*/
----------------------------------------------------------------------- triggers-------------------------------------------------------------------------------------------------

--This function will get the number of distinct teams registered for the current tournament, and check if that number is a power of 2. If it is not, it will raise an exception.
CREATE OR REPLACE FUNCTION NumberofParticipants() 
RETURNS trigger AS $numberofparticipants$
  DECLARE
    num_teams INT;
  BEGIN 
    -- Get the number of teams registered for the current tournament
    SELECT COUNT(DISTINCT team_id) INTO num_teams FROM tournament_teams
    WHERE tournament_id = NEW.tournament_id;

    -- Check if the number of teams is a power of 2
    IF (num_teams & (num_teams - 1)) != 0 THEN
      RAISE EXCEPTION 'El numero de participantes registrados a un torneo tiene que ser potencia de 2';
    END IF;

    RETURN NEW;
  END;
$numberofparticipants$ LANGUAGE plpgsql;

CREATE TRIGGER check_Numberofparticipants_after_ins_updt
AFTER INSERT OR UPDATE ON tournament_teams
FOR EACH ROW
EXECUTE PROCEDURE Numberofparticipants();


--This functions assure that a player cannot be a captain and a team mate at the same time
CREATE OR REPLACE FUNCTION player_captain_or_mate() RETURNS TRIGGER AS $player_captain_team_mate$
  BEGIN
      IF (SELECT player_id FROM captain WHERE player_id IN (SELECT player_id FROM team_mate))  THEN
        RAISE EXCEPTION 'Un jugador no puede ser capitán y compañero al mismo tiempo';
      END IF;
      RETURN NEW;
  END;
$player_captain_team_mate$ LANGUAGE plpgsql;

CREATE TRIGGER check_player_captain_on_mate_after_ins_updt
AFTER INSERT OR UPDATE ON captain --wE HAVE TO PUT AFTER INSERT, SINCE IT WILL ONLY CHECK ALL THE VALUES THAT WERE ALREADY IN THE TABLE IF WE PUT BEFORE
FOR EACH ROW
EXECUTE PROCEDURE player_captain_or_mate();

CREATE TRIGGER check_player_mate_on_captain_after_ins_updt
AFTER INSERT OR UPDATE ON team_mate
FOR EACH ROW
EXECUTE PROCEDURE player_captain_or_mate();



--function to assure the same player is not in two different teams
CREATE OR REPLACE FUNCTION player_in_one_team() RETURNS TRIGGER AS $player_in_one_team$
 BEGIN
      IF (SELECT player_1 FROM team WHERE player_1 IN (SELECT player_2 FROM team))  THEN
        RAISE EXCEPTION 'Un jugador no puede jugar en dos equipos al mismo tiempo';
      END IF;
      RETURN NEW;
  END;
$player_in_one_team$ LANGUAGE plpgsql;

CREATE TRIGGER check_player_in_one_team_after_ins_updt
AFTER INSERT OR UPDATE ON team
FOR EACH ROW
EXECUTE PROCEDURE player_in_one_team();

--trigger that ensures that the phone_number attribute has a length of 9
CREATE OR REPLACE FUNCTION check_phone_number_length()
RETURNS TRIGGER AS $number_length$
BEGIN
    IF LENGTH(NEW.phone_number::text) <> 9 THEN
        RAISE EXCEPTION 'Phone number must be exactly 9 digits';
    END IF;
    RETURN NEW;
END;
$number_length$ LANGUAGE plpgsql;

CREATE TRIGGER check_phone_number_length_before_ins_updt
BEFORE INSERT OR UPDATE ON player
FOR EACH ROW
EXECUTE PROCEDURE check_phone_number_length();


--trigger that checks if the winner of the turnament played on it
CREATE OR REPLACE FUNCTION winner_played() RETURNS TRIGGER AS $winner_played$
 BEGIN
    IF (SELECT winner FROM tournament WHERE (winner, tournament_id) NOT IN (SELECT t.team_id, tt.tournament_id FROM team t JOIN tournament_teams tt ON t.team_id = tt.team_id GROUP BY t.team_id, tt.tournament_id)limit 1)  THEN
      RAISE EXCEPTION 'El equipo no puede ganar el torneo ya que no lo jugó';
    END IF;
    RETURN NEW;
  END;
$winner_played$ LANGUAGE plpgsql;

CREATE TRIGGER check_winner_played
AFTER INSERT OR UPDATE ON tournament_teams
FOR EACH ROW
EXECUTE PROCEDURE winner_played();


--Function to check wether a qualified tiem has 2 or more players in the ranking
CREATE OR REPLACE FUNCTION player_ranking() RETURNS TRIGGER AS $pla_rank$
  BEGIN
      WITH TeamP AS ( 
      SELECT player_id, team_id
      FROM ranking r
      JOIN team t ON t.player_1 = r.player_id
      union
      SELECT player_id, team_id
      FROM ranking r
      JOIN team t ON t.player_2 = r.player_id)
    IF (SELECT COUNT(tp.player_id) FROM TeamP tp JOIN teams_qualified t ON tp.team_id = t.team_id GROUP BY tp.team_id) < 2 THEN
      RAISE EXCEPTION 'El equipo no puede clasificar al torneo porque no tiene al menos 2 jugadores en el ranking';
    END IF;
    RETURN NEW;
  END;
$pla_rank$ LANGUAGE plpgsql;

CREATE TRIGGER check_player_ranking
AFTER INSERT OR UPDATE ON teams_qualified
FOR EACH ROW
EXECUTE PROCEDURE player_ranking();



--Can a team qualify to the tournament

/*CREATE OR REPLACE FUNCTION check_ranking_points()
RETURNS TRIGGER AS $$
BEGIN
  -- check if the sum of the ranking points of the players on the team
  -- is greater than or equal to the required points to play in the tournament
  IF (SELECT SUM(points) FROM ranking WHERE player_id IN (SELECT player_1, player_2 FROM team WHERE team_id = NEW.team_id)) < (SELECT points_to_play FROM tournament WHERE tournament_id = NEW.tournament_id) THEN
    RAISE EXCEPTION 'Team does not have enough ranking points to participate in the tournament';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;*/
/*CREATE OR REPLACE FUNCTION check_ranking_points()
RETURNS TRIGGER AS $$
BEGIN
  WITH A AS (
    SELECT player_id, points, team_id
    FROM ranking r
    JOIN team t ON t.player_1 = r.player_id
  ), B AS (
    SELECT player_id, points, team_id
    FROM ranking r
    JOIN team t ON t.player_2 = r.player_id
  ), Poin as(SELECT a.points + b.points as points, A.team_id
  FROM A a JOIN B b ON a.team_id = b.team_id;)
  IF (SELECT points FROM Poin < SELECT points FROM tournament) then 
    RAISE EXCEPTION 'El equipo no puede clasificar el torneo ya que no tiene suficientes';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;*/
/*
CREATE TRIGGER check_ranking_points
BEFORE INSERT ON teams_qualified
FOR EACH ROW
EXECUTE PROCEDURE check_ranking_points();*/



