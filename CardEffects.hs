module CardEffects where

import UnoDataModels
import Utils
import Control.Monad.Trans
import Control.Monad.Trans.State
-- Every time when player drops a card, set the GameState.currCard to the droped card, then apply the card effect


runEffect :: CardType -> Game ()
runEffect _cardType = case _cardType of
                          Regular       -> get >>= regular
                          Skip          -> get >>= skip 
                          Reverse       -> get >>= reverseD
                          DrawTwo       -> get >>= drawTwo
                          Wild          -> get >>= wild
                          WildDrawFour  -> get >>= wildDrawFour


-- Card effect - update GameState, including 
    -- current card
    -- each player state
    -- Deck state
    -- direction
-- #######################################################
--Next player in sequence misses a turn
-- #######################################################
-- skip :: Game ()
-- skip = do
--   state <- get
--   lift $ putStrLn "Player played Skip"
--   let game@GameState{whoseTurn=_whoseTurn,players=_players,dir=_dir} = state
--   put game{whoseTurn=_nextTurn}
--    where _nextTurn = getNextTurn (getNextTurn _whoseTurn _players _dir) _players _dir

skip :: GameState -> Game ()
skip game@GameState{whoseTurn=_whoseTurn,players=_players,dir=_dir} = do
  liftIO $ putStrLn "Player played Skip"
  put game{whoseTurn=_nextTurn}
   where _nextTurn = getNextTurn (getNextTurn _whoseTurn _players _dir) _players _dir

-- skip' :: GameState -> GameState
-- skip' (GameState _dir _whoseTurn _currCard _players _deck) = GameState _dir (getNextTurn (getNextTurn _whoseTurn _players _dir) _players _dir ) _currCard _players _deck

-- @Int next ith turn
-- @Int playerID of next turn 
nextTurn :: Int -> GameState -> Int
nextTurn 0 game@GameState{whoseTurn=_whoseTurn}= _whoseTurn
nextTurn i game@GameState{whoseTurn=_whoseTurn,players=_players,dir=_dir} = nextTurn (i-1) game{whoseTurn = getNextTurn _whoseTurn _players _dir}

-- @int Current turn
-- @[PlayerState]
-- @Direction
-- @Int NextTurn
getNextTurn :: Int -> [PlayerState]-> Direction -> Int
getNextTurn _whoseTurn _players _dir = varifyTurnNum (_whoseTurn + dirt _dir) (length _players)
-- varify the index of current player, making sure it goes in a manner of cycle
-- @Int CurrentTurn
-- @Int number of players
-- @Int Final decision of current turn
varifyTurnNum :: Int -> Int-> Int
varifyTurnNum _whoseTurn num_p 
                       | _whoseTurn == num_p = 0
                       | _whoseTurn < 0    = num_p
                       | otherwise          = _whoseTurn 

-- turn direction into operation                            
dirt :: Direction -> Int
dirt Clockwise        = 1
dirt CounterClockwise = -1
-- #######################################################
-- drawTwo effect - Next player in sequence draws two cards and misses a turn
-- #######################################################
-- need to update whoseTurn
drawTwo ::GameState -> Game ()
drawTwo  game@GameState{whoseTurn=_whoseTurn,players=_players,dir=_dir} = do 
    lift $ putStrLn "Player played drawTwo"
    let game' = drawCards 2 game _nextTurn
    put game'{whoseTurn=nextTurn 1 game'}
  where
    _nextTurn = nextTurn 1 game   
 
--draw one card from deck
-- Type: GameState -> Player ID -> IO GameState 
  
-- drawTwo (GameState _dir _whoseTurn _currCard _players _deck) = GameState _dir (getNextTurn _nextTurn _players _dir) _currCard (updatePlayers _players _nextTurn _deck) (updateDeck _deck 2) where _nextTurn = getNextTurn _whoseTurn _players _dir

-- type PlayerID = Int
-- updatePlayers :: [PlayerState] -> PlayerID -> Deck -> [PlayerState]
-- updatePlayers  []            _  _                = []
-- updatePlayers  _playerState  _  []               = _playerState
-- updatePlayers (p:ps) _playerId _deck 
--                     | getPlayerId p /= _playerId = updatePlayers ps _playerId _deck
--                     | getPlayerId p == _playerId = playerStateUpdateDrawCard p _deck 2:ps

-- playerStateUpdateDrawCard :: PlayerState -> Deck -> Int ->PlayerState
-- playerStateUpdateDrawCard  (PlayerState _id _name _score  _cards) _deck i = PlayerState _id _name _score (getCards _deck i ++_cards)

-- getCards :: Deck -> Int -> [Card]
-- getCards _ 0          = []
-- getCards [] _         = []
-- getCards (c:_cards) i = c : getCards _cards (i-1)

-- updateDeck :: Deck -> Int -> Deck
-- updateDeck [] _         = []
-- updateDeck d  0         = d
-- updateDeck (_:_cards) i = updateDeck _cards (i-1)

-- #######################################################
-- reverse effect - Order of play switches directions (clockwise to counterclockwise, and vice versa)
-- #######################################################
reverseD :: GameState -> Game()
reverseD game@GameState{whoseTurn=_whoseTurn,players=_players, dir=_dir} = do 
    lift $ putStrLn "Player played reverse"
    put game{whoseTurn=_nextTurn, dir=_newDir}
  where
    _newDir   = reverseDir _dir
    _nextTurn = getNextTurn _whoseTurn _players _newDir

-- reverse' :: GameState -> GameState
-- reverse' (GameState _dir _whoseTurn _currCard _players _deck) = 
--         let _nextTurn  = getNextTurn  _whoseTurn _players (reverseDir _dir)
--         in GameState (reverseDir _dir) _nextTurn _currCard _players _deck 
                                                                    
reverseDir :: Direction -> Direction
reverseDir Clockwise        = CounterClockwise
reverseDir CounterClockwise = Clockwise

-- #######################################################
-- wild effect - Player declares next color to be matched (may be used on any turn even if the player has matching color)
-- #######################################################
wild :: GameState -> Game ()
wild game = if robotPlayer game 
     then 
       put game{whoseTurn=nextTurn 1 game,currClr =  colors !! genRanInt 3}
     else do
        lift $ putStrLn "Please pick a color to continue: 1-Yellow, 2-Red, 3-Blue, 4-Green"
        _numStr <- lift getLine
        let clrInt = read _numStr :: Int
        put game{whoseTurn=nextTurn 1 game, currClr = colors !! (clrInt-1)}

robotPlayer :: GameState -> Bool
robotPlayer  game@GameState{whoseTurn=_whoseTurn, realPlayer=_realPlayer} = _whoseTurn /= _realPlayer

-- #######################################################
-- wildDrawFour effect:
--Player declares next color to be matched; next player in sequence draws four cards and loses a turn. May be legally played only if the player has no cards of the current color; Wild cards and cards with the same number or symbol in a different color do not count.
-- #######################################################
wildDrawFour :: GameState -> Game ()
wildDrawFour = undefined

-- #######################################################
-- regular card effect - Move to next player
-- #######################################################
regular :: GameState -> Game ()
regular game@GameState{whoseTurn=_whoseTurn,players=_players, dir=_dir} = do 
    lift $putStrLn "Player played regular"
    put  game{whoseTurn=_nextTurn}
  where
    _nextTurn = getNextTurn _whoseTurn _players _dir

-- regular :: GameState -> GameState
-- regular (GameState _dir _whoseTurn _currCard _players _deck) =
--     GameState _dir _nextTurn _currCard _players _deck
--      where _nextTurn = getNextTurn _whoseTurn _players _dir
