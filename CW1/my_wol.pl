:- use_module(library(system)).
:- use_module(library(lists)).
% :- include(war_of_life).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Strategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

test_strategy(N, First_player_strategy, Second_player_strategy) :-
	write('Player 1: '), write(First_player_strategy), write('\n'),
	write('Player 2: '), write(Second_player_strategy), write('\n'),
	test_strategy(N, First_player_strategy, Second_player_strategy, Winner_list, Move_list, Time_list),
	count_item(First_player_wins, 'b', Winner_list),
	count_item(Second_player_wins, 'r', Winner_list),
	count_item(Draws, 'draw', Winner_list),
	count_item(Stalemates, 'stalemate', Winner_list),
	count_item(Exhausts, 'exhaust', Winner_list),
	TotalDraws is Draws + Stalemates + Exhausts,
	min_member(Minimum_moves, Move_list),
	average(Average_game_length, Move_list),
	average(Average_game_time, Time_list),
	max_non_exhaustive(Maximum_moves, Move_list),
	write('Number of draws: '), write(TotalDraws), write('\n'),
	write('Number of wins for player 1 (blue): '), write(First_player_wins), write('\n'),
	write('Number of wins for player 2 (red): '), write(Second_player_wins), write('\n'),
	write('Longest (non-exhaustive) game: '), write(Maximum_moves), write('\n'),
	write('Shortest game: '), write(Minimum_moves), write('\n'),
	write('Average game length (including exhaustives): '), write(Average_game_length), write('\n'),
	write('Average game time: '), write(Average_game_time), write('\n').

% test_strategy(+N, +First_player_Strategy, +Second_player_Strategy, -Winner_list, -Move_list, -Time_list)
%
% test_strategy/6 plays N number of games with player1 using FIRST_PLAYER_STRATEGY and player2 using SECOND_PLAYER_STRATEGY
% and records the winner of each game in WINNER_LIST,
% the number of moves in each game in MOVE_LIST,
% and the time used in each game in TIME_LIST.
test_strategy(0, _, _, [], [], []).

test_strategy(N, First_player_strategy, Second_player_strategy, [Winner|Winners], [Move|Moves], [Time|Times]) :-
	now(Start_time),
	play(quiet, First_player_strategy, Second_player_strategy, Move, Winner),
	now(End_time),
	Time is integer(End_time) - integer(Start_time),
        N_decrement is N - 1,
	test_strategy(N_decrement, First_player_strategy, Second_player_strategy, Winners, Moves, Times).

% count_item(-Count, +Item, +List)
%
% count_item/3 holds when there are COUNT number of ITEMs in LIST.
count_item(Count, Item, List) :-
	findall(Item, member(Item, List), Result),
	length(Result, Count).

% average(-Average, +List)
%
% average/2 calculates the average of LIST.
average(Average, List) :-
	sumlist(List, Sum),
	length(List, Number_of_elements),
	Average is Sum / Number_of_elements.

% max_non_exhaustive(-Maximum, +List)
%
% max_non_exhaustive/2 finds the largest number less than 250 in LIST,
% A game with 250 moves is declared as exhausted.
max_non_exhaustive(Maximum, List) :-
	delete(List, 250, Residue),
	max_member(Maximum, Residue).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Strategy Implementation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

bloodlust(Player_color, Current_board_state, New_board_state, Move) :-
	possible_move(Player_color, Current_board_state, Possible_moves),
	best_move(bloodlust, Player_color, Current_board_state, Possible_moves, Move),
	update_move(Player_color, Move, Current_board_state, New_board_state).

self_preservation(Player_color, Current_board_state, New_board_state, Move) :-
	possible_move(Player_color, Current_board_state, Possible_moves),
	best_move(self_preservation, Player_color, Current_board_state, Possible_moves, Move),
	update_move(Player_color, Move, Current_board_state, New_board_state).

land_grab(Player_color, Current_board_state, New_board_state, Move) :-
	possible_move(Player_color, Current_board_state, Possible_moves),
	best_move(land_grab, Player_color, Current_board_state, Possible_moves, Move),
	update_move(Player_color, Move, Current_board_state, New_board_state).

minimax(Player_color, Current_board_state, New_board_state, Move) :-
	possible_move(Player_color, Current_board_state, Possible_moves),
	best_move(minimax, Player_color, Current_board_state, Possible_moves, Move),
	update_move(Player_color, Move, Current_board_state, New_board_state).

% possible_move(+Player_color, +Current_board_state, -Possible_moves)
%
% possible_move/3 all possible moves of PLAYER_COLOR in CURRENT_BOARD_STATE.
possible_move(Player_color, [Blue, Red], Possible_moves) :-
	(Player_color == 'b' -> Color = Blue; Color = Red),
	findall([Row, Col, New_row, New_col],
		(member([Row, Col], Color),
		neighbour_position(Row , Col, [New_row, New_col]),
		\+ member([New_row, New_col], Blue),
		\+ member([New_row, New_col], Red)),
		Possible_moves).

% update_move(+Player_color, +Move, +Current_board_State, -Next_generation_board_state)
%
% update_move/4 makes the move MOVE and generate next board state using Conways Crank.
update_move('r', Move, [Blue, Red], Next_generation_board_state) :-
	alter_board(Move, Red, New_red),
	next_generation([Blue, New_red], Next_generation_board_state).

update_move('b', Move, [Blue, Red], Next_generation_board_state) :-
	alter_board(Move, Blue, New_blue),
	next_generation([New_blue, Red], Next_generation_board_state).


% best_move(+Strategy, +Player_color, +Current_board_state, +Possible_moves, -Best_move)
%
% best_move/5 calculates the BEST_MOVE from all POSSIBLE_MOVES using the sepcified STRATEGY
best_move(_, _, _, [Move], Move).
best_move(Strategy, Player_color, Current_board_state, [Move1, Move2|Moves], Best_move) :-
	update_move(Player_color, Move1, Current_board_state, Next_board_state1),
	update_move(Player_color, Move2, Current_board_state, Next_board_state2),
	(Strategy == 'bloodlust' -> bloodlust_strategy(Player_color, Move1, Next_board_state1, Move2, Next_board_state2, Better_move)
	;Strategy == 'self_preservation' -> self_preservation_strategy(Player_color, Move1, Next_board_state1, Move2, Next_board_state2, Better_move)
	;Strategy == 'land_grab' -> land_grab_strategy(Player_color, Move1, Next_board_state1, Move2, Next_board_state2, Better_move)
	;Strategy == 'minimax' -> minimax_strategy(Player_color, Move1, Next_board_state1, Move2, Next_board_state2, Better_move)
	;fail),
	best_move(Strategy, Player_color, Current_board_state, [Better_move | Moves], Best_move).


% list_empty(+List)
%
% list_empty/1 holds if the given list is empty.
list_empty([]).



% bloodlust_strategy(Player_color, Move1, Move1_board_state, Move2, Move2_board_state, Better_move)
%
% bloodlust_strategy/6 compares the next generation of applying MOVE1 (MOVE1_BOARD_STATE)
% and the next generation of applying MOVE2 (MOVE2_BOARD_STATE),
% then determines the better move by choosing the board with fewer opponent pieces.
bloodlust_strategy('b', Move1, [_, Red1], Move2, [_, Red2], Better_move) :-
	length(Red1, Result1),
	length(Red2, Result2),
	(Result1 < Result2 -> Better_move = Move1; Better_move = Move2).

bloodlust_strategy('r', Move1, [Blue1, _], Move2, [Blue2, _], Better_move) :-
	length(Blue1, Result1),
	length(Blue2, Result2),
	(Result1 < Result2 -> Better_move = Move1; Better_move = Move2).

% self_preservation_strategy(Player_color, Move1, Move1_board_state, Move2, Move2_board_state, Better_move)
%
% self_preservation_strategy/6 compares the next generation of applying MOVE1 (MOVE1_BOARD_STATE)
% and the next generation of applying MOVE2 (MOVE2_BOARD_STATE),
% then determines the better move by choosing the board with more player pieces.
self_preservation_strategy('r', Move1, [_, Red1], Move2, [_, Red2], Better_move) :-
	length(Red1, Result1),
	length(Red2, Result2),
	(Result1 > Result2 -> Better_move = Move1; Better_move = Move2).

self_preservation_strategy('b', Move1, [Blue1, _], Move2, [Blue2, _], Better_move) :-
	length(Blue1, Result1),
	length(Blue2, Result2),
	(Result1 > Result2 -> Better_move = Move1; Better_move = Move2).

% land_grab_strategy(Player_color, Move1, Move1_board_state, Move2, Move2_board_state, Better_move)
%
% land_grab_strategy/6 compares the next generation of applying MOVE1 (MOVE1_BOARD_STATE)
% and the next generation of applying MOVE2 (MOVE2_BOARD_STATE),
% then determines the better move by choosing the board that maximises Player piece - Opponent piece.
land_grab_strategy('r', Move1, [Blue1, Red1], Move2, [Blue2, Red2], Better_move) :-
	length(Red1, Red1_length),
	length(Blue1, Blue1_length),
	Result1 is Red1_length - Blue1_length,
	length(Red2, Red2_length),
	length(Blue2, Blue2_length),
	Result2 is Red2_length - Blue2_length,
	(Result1 > Result2 -> Better_move = Move1; Better_move = Move2).

land_grab_strategy('b', Move1, [Blue1, Red1], Move2, [Blue2, Red2], Better_move) :-
	length(Red1, Red1_length),
	length(Blue1, Blue1_length),
	Result1 is Blue1_length - Red1_length,
	length(Red2, Red2_length),
	length(Blue2, Blue2_length),
	Result2 is Blue2_length - Red2_length,
	(Result1 > Result2 -> Better_move = Move1; Better_move = Move2).

% minimax_strategy(Player_color, Move1, Move1_board_state, Move2, Move2_board_state, Better_move)
%
% minimax_strategy/6 assumes the opponent uses land grab strategy and apply opponents move to
% MOVE1_BOARD_STATE and MOVE2_BOARD_STATE. It then compares the two new board states and
% determines the better move using land grab strategy.
minimax_strategy('r', Move1, [New_blue1, New_red1], Move2, [New_blue2, New_red2], Better_move) :-
	((list_empty(New_blue1), \+ list_empty(New_red1)) -> Better_move = Move1
	;(list_empty(New_blue2), \+ list_empty(New_red2)) -> Better_move = Move2
	;land_grab('b', [New_blue1, New_red1], Deeper_board_state1, _),
	land_grab('b', [New_blue2, New_red2], Deeper_board_state2, _),
	land_grab_strategy('r', Move1, Deeper_board_state1, Move2, Deeper_board_state2, Better_move)).

minimax_strategy('b', Move1, [New_blue1, New_red1], Move2, [New_blue2, New_red2], Better_move) :-
	((list_empty(New_red1), \+ list_empty(New_blue1)) -> Better_move = Move1
	;(list_empty(New_red2), \+ list_empty(New_blue1)) -> Better_move = Move2
	;land_grab('r', [New_blue1, New_red1], Deeper_board_state1, _),
	land_grab('r', [New_blue2, New_red2], Deeper_board_state2, _),
	land_grab_strategy('b', Move1, Deeper_board_state1, Move2, Deeper_board_state2, Better_move)).
