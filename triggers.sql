/*
hAY QUE PROBAR LOS ON DELETE 
trigger para no poderte entrar a equipos_torneo si no has clasificado
trigger para no poder clasificar si no tienes suficientes puntos los jugagadores en el ranking


*/

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

