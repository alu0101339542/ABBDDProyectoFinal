INSERT INTO player(player_name, phone_number)
VALUES
('Pablo Pastor',633424899),
('Juan Lebron',633424898),

('Alejandro Galan',677342576),
('Paquito navarro',633424688),

('Fernando Belasteguín',632494979),
('Juan Martín Díaz',677345576),

('Sanyo Gutierrez',674269378),
('Pablo Lima',674269358),

('chingoto',674269372),
('El lobo',674223358),

('Matias díaz',674765372),
('juan Tello',674221181),

('Tapia',674765222),
('Coello',674221333),

('Momo',674755555),
('Dineno',674224444);

INSERT INTO team(player_1, player_2)
VALUES
(1, 2),
(3, 4),
(5, 6),
(7,8),
(9,10),
(11,12),
(13,14),
(15,16); 

INSERT INTO tournament(tournament_name, begining_date, ending_date, winner)
VALUES 
('Mutua open', '2020-08-24','2020-09-21', 1),
('open Malmo', '2021-07-02','2021-08-24', 3),
('Master merida', '2022-10-02','2022-12-24', 4);

INSERT INTO tournament_teams(tournament_id, team_id)
VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(1, 5),
(1, 6),
(1, 7),
(1, 8),

(2, 3),
(2, 2),

(3, 4),
(3, 1),
(3, 8),
(3, 7);

INSERT INTO facility(f_location)
VALUES
('La Cuesta'),
('Malmo Centrum'),
('Polideportivo de merida');

INSERT INTO tournament_facility(tournament_id, facility_id)
VALUES
(1,1),
(2,2),
(3,3);

INSERT INTO court(facility_id, price)
VALUES
(1,25.75),
(1,12.3),
(2, 15.6),
(2, 24.7),
(3, 4.3);

INSERT INTO ranking(player_id, wins, defeats)
VALUES
(1, 4, 3),
(2, 3, 4),
(3, 5, 2),
(4, 2, 5),
(5, 5, 0);

INSERT INTO match(team1_id, team2_id, team1_score, team2_score, facility_id, match_date, tournament_id)
VALUES
(1, 2, 6, 3, 1,'2022-04-01',1), 
(2, 3, 5, 7, 1,'2022-04-01', 2),
(4, 1, 7, 6, 2, '2022-07-15', 3),
(8, 7, 6, 2, 3,'2022-07-15', 3),
(3, 4, 6, 4, 2, '2022-10-20',2),
(3, 4, 6, 4, 2, '2022-10-20',2),
(5, 6, 5, 7, 1, '2022-01-20',2),
(7, 8, 1, 6, 3, '2022-02-16',2),
(3, 2, 7, 6, 2, '2022-07-13',2);


INSERT INTO teams_qualified(team_id, tournament_id)
VALUES
(1, 1),
(2, 3);
 
INSERT INTO captain(player_id, captain_bonus)
VALUES
(1, 400),
(3, 400),
(5, 500);


 
INSERT INTO team_mate(player_id, best_season)
VALUES
(2, 2020-2021),
(4, 2020-2021),
(6, 2019-2020);
 
INSERT INTO employee(employee_name, match_id, organizer, referee)
VALUES
('Pepe', 1, true, false),
('Monica', 2, false, true),
('Pablo', 2, false, true);