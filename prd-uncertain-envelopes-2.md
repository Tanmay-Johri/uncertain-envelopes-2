# Uncertain Envelopes v2.0

# Introduction

1. This is a game app
2. The game is called Uncertain Envelopes
3. The objective of the game is to make profit by trading envelopes with other players
4. Every player has infinite envelopes and infinite cash when the game starts (that is why we only talk about the change in cash or the change in number of envelopes and we don’t talk about their actual value)
5. Every envelope has the same amount of cash inside it. This is the monetary value of the envelope but no player knows it. The admin of the game reveals it at the end of the game
6. Even though no player knows the exact monetary value of the envelope, they still must have an approximate idea of what the value is going to be based on the game description and how the other players are valuing it
7. So, if I have a guess that an envelope is worth 100, then I’ll try my best to sell it for 120. If I do manage to sell it at 120, my delta cash would be +120 and my delta envelopes would be -1
8. Buying and selling works just like an actual stock market:
    
    ## Order matching rules
    
    ## General Matching Process
    
    1. **Atomic Processing:**
        - When an order arrives, the order book is “locked” for that matching cycle.
        - Any new orders that come in during the process are queued and handled after the cycle finishes.
    2. **Determine Order Side:**
        - If the incoming order is a buy order (whether limit_buy or market_buy), it is matched against all available resting sell orders.
        - If the order is a sell order (limit_sell or market_sell), it is matched against all available resting buy orders.
    3. **Sort the Resting Orders:**
        - **For Buy Orders Matching Sell Orders:**
            
            Resting sell orders are sorted in ascending order of their `price_per_stock` (lowest price first).
            
        - **For Sell Orders Matching Buy Orders:**
            
            Resting buy orders are sorted in descending order of their `price_per_stock` (highest price first).
            
        - For orders at the same price, the order with the earliest timestamp is given priority. (A secondary tie-breaker such as Order ID may be used if needed.)
    4. **Matching Criteria:**
        - **For Limit Orders:**
            - **Limit Buy:** Can match only with resting sell orders whose price is *less than or equal* to the incoming order’s `price_per_stock`.
            - **Limit Sell:** Can match only with resting buy orders whose price is *greater than or equal* to the incoming order’s `price_per_stock`.
        - **For Market Orders:**
            - There is no price constraint; they will match with any available resting order.
    5. **Execution of a Match:**
        - The trade is executed at the *price of the resting order*.
        - The executed quantity is the minimum of the incoming order’s remaining quantity and the resting order’s current quantity.
        - Reduce both orders’ quantities accordingly.
        - If a resting order is completely filled, it is removed from the resting order book.
        - If a resting order is partially filled, its remaining quantity is updated, but its original timestamp remains unchanged.
    6. **Post-Matching Actions:**
        - **Limit Orders:**
            
            If after matching the incoming limit order there is any remaining quantity, it is added to the resting order book with its updated `quantity_current`.
            
        - **Market Orders:**
            
            If after matching the incoming market order there is any remaining quantity (because there weren’t enough opposing resting orders), the remaining portion is cancelled immediately and is not added to the resting order book.
            
    
    ---
    
    ## Detailed Rules by Order Type
    
    ### 1. `limit_buy`
    
    - **Parameters:**
        - `quantity_initial`
        - `price_per_stock`
    - **Interpretation:**
        
        The player wishes to buy up to `quantity_initial` envelopes at a price per envelope that is *no more than* `price_per_stock`.
        
    - **Matching:**
        - The incoming `limit_buy` order scans for resting sell orders with `price_per_stock` ≤ incoming order’s `price_per_stock`.
        - Each match is executed at the resting order’s price.
        - Partial matches reduce the incoming order’s remaining quantity.
    - **After Matching:**
        - Any unfilled quantity remains in the resting orders with an updated quantity.
    
    ---
    
    ### 2. `limit_sell`
    
    - **Parameters:**
        - `quantity_initial`
        - `price_per_stock`
    - **Interpretation:**
        
        The player wishes to sell up to `quantity_initial` envelopes at a price per envelope that is *no less than* `price_per_stock`.
        
    - **Matching:**
        - The incoming `limit_sell` order scans for resting buy orders with `price_per_stock` ≥ incoming order’s `price_per_stock`.
        - Each match is executed at the resting order’s price.
        - Partial matches reduce the incoming order’s remaining quantity.
    - **After Matching:**
        - Any unfilled quantity remains in the resting orders with an updated quantity.
    
    ---
    
    ### 3. `market_buy`
    
    - **Parameters:**
        - `quantity_initial`
    - **Interpretation:**
        
        The player wishes to buy up to `quantity_initial` envelopes at the market price (i.e. the price of the resting sell orders, regardless of the price).
        
    - **Matching:**
        - The incoming `market_buy` order scans all resting sell orders (sorted from lowest price upward).
        - It is matched regardless of price until either `quantity_initial` is fulfilled or no more resting sell orders exist.
        - Each match is executed at the resting order’s price.
    - **After Matching:**
        - If the order is only partially filled (i.e. not enough envelopes are available in resting sell orders), the remaining unfilled portion is cancelled immediately.
    
    ---
    
    ### 4. `market_sell`
    
    - **Parameters:**
        - `quantity_initial`
    - **Interpretation:**
        
        The player wishes to sell up to `quantity_initial` envelopes at the market price (i.e. the price of the resting buy orders, regardless of the price).
        
    - **Matching:**
        - The incoming `market_sell` order scans all resting buy orders (sorted from highest price downward).
        - It is matched regardless of price until either `quantity_initial` is fulfilled or no more resting buy orders exist.
        - Each match is executed at the resting order’s price.
    - **After Matching:**
        - If the order is only partially filled, the remaining unfilled portion is cancelled immediately.
    
    ---
    
    ## Edge Cases
    
    1. **Concurrent Orders During Matching:**
        - New orders arriving during an active matching cycle are not considered until the current matching process completes.
        - They keep getting queued in the exact order they are received. So if order 1 is being processed, and order 2 is received and order 3 is received while order 1 is being processed, then they are both queued up in that same order. When order 1 is done processing and all values have been updated in that processing process, then order 2 is picked up for processing. Order 3 remains in the queue until order 2 is done processing. Then order 3 is picked.
    2. **Price Gaps:**
        - If a `limit_buy` order’s `price_per_stock` is lower than all resting sell order prices, no match occurs and the order rests.
        - Similarly, if a `limit_sell` order’s `price_per_stock` is higher than all resting buy order prices, no match occurs and the order rests.
    3. **Partial Fills:**
        - If an incoming order is partially filled, update its remaining quantity accordingly.
        - For limit orders, any remaining quantity is added to the resting order book.
        - For market orders, any remaining unfilled quantity is cancelled.
    4. **Matching Execution Price:**
        - All trades are executed at the price of the resting order that is being matched, regardless of whether the incoming order is a market or limit order.
    5. **No Resting Counterpart:**
        - If a market order is submitted and there are no resting orders on the opposite side, the order is cancelled immediately.
9. Once the game ends, the admin enters the monetary value of the envelope and everyone’s profit (or loss) is calculated

# Backend Data Structure

## games

1. `game_id`
    1. Unique ID assigned to every game
    2. UUID
    3. Assigned when a game is created
    4. Never changes
    5. No two games should have the same `id`
    6. Primary key
2. `game_name`
    1. Name of the game
    2. String
    3. Required
    4. Max length can be 32 characters
    5. Cannot be edited once the game is created
3. `game_description`
    1. Description of what the envelope value is based on
    2. String
    3. Optional, and can be empty string if desired
    4. Max length can be 256 characters
    5. Cannot be edited once the game is created
4. `game_created_at`
    1. UTC timestamp when the game row was created
    2. Automatically set once
5. `game_security`
    1. Whether the game is public or private
    2. Enum
    3. Allowed values:
        1. `public`
        2. `private`
    4. Cannot be edited once the game is created
6. `is_ranked`
    1. Whether the game is ranked or casual
    2. Enum
    3. Allowed values:
        1. `ranked`
        2. `casual`
    4. Affects whether player performance stats should update
    5. Cannot be edited once the game is created
7. `game_max_players`
    1. Maximum number of players allowed in the game
    2. Integer between 1 and 100
    3. Cannot be edited once the game is created
8. `joining_code`
    1. Code that other players can use to join the game
    2. String
    3. Must be unique across all active games
    4. Recommended format: 5 alphanumeric uppercase characters
    5. Should be treated case-insensitively
    6. Automatically assigned when game is created
    7. Never changes
9. `end_condition`
    1. Defines how the game trading period ends
    2. Enum
    3. Allowed values:
        1. `timed`
        2. `endless`
    4. If `timed`, then the game ends when timer hits zero or admin manually ends it
    5. If `endless`, game ends only when admin manually ends it
    6. Cannot be edited once the game is created
10. `total_decided_duration_seconds`
    1. Total duration of the game in seconds
    2. Integer
    3. Used only when `end_condition = timed`
    4. Should be `null` when `end_condition = endless`
    5. If admin adds more time during the game, this field will be updated to reflect the new total decided duration
11. `end_time_decided`
    1. UTC timestamp representing when trading is supposed to end
    2. Used only when `end_condition = time`
    3. Initially becomes `start_time + duration_seconds` when the game starts
    4. If admin adds more time, this gets updated
    5. `null` for endless games unless you later decide to temporarily compute one
12. `start_time`
    1. Actual UTC timestamp when trading starts
    2. `null` until the admin starts the game
    3. Set exactly once when state moves from `created` to `trading_started`
13. `end_time_actual`
    1. Actual UTC timestamp when trading ends
    2. Set when state moves from `trading_started` to `trading_ended`
    3. Remains unchanged afterwards
14. `game_state`
    1. Current lifecycle state of the game
    2. Enum
    3. Allowed values:
        1. `created`
            1. This is the state after the game has been created by the admin and before the game has started
            2. People can join or exit the lobby and mark themselves as ready when the game is in this state
            3. Admin can also kick people out if he wants at this stage
            4. From here, the game can go to either ‘trading_started’ or ‘discarded’ state
        2. `trading_started`
            1. Admin can start the game if all the players are in the ‘ready’ state
            2. Once admin starts the game, the game enters the ‘trading_started’ state
            3. All the trading and order placing etc. can happen in this state of the game
            4. Players cannot exit a game once it enters the ‘trading_started’ stage. They can merely navigate to some other part of the app, but they will forever be part of this game now
            5. From here, the game can only go to the ‘trading_ended’ state
        3. `trading_ended`
            1. When the `end_condition` is satisfied (either the timer hits 0 or the admin manually ends the game), the game goes from ‘trading_started’ to ‘trading_ended’
            2. Once this state is reached, no more orders can be placed or cancelled or matched
            3. All the players can do in this state is wait for the admin to enter the price of the envelope and see their PnLs
            4. The admin can, in this state, enter the value of the envelope which will get stored in the `envelope_price` variable. He can edit this multiple times in this state of the game
            5. From here, the game can either go to the ‘game_finalised’ state or the ‘discarded’ state
            6. If the admin presses the ‘End game’ button without entering a value for `envelope_price`, the game goes to the ‘discarded’ state
            7. If instead, the admin presses the ‘End game’ button after entering a value for `envelope_price`, the game goes to the ‘game_finalised’ state
        4. `game_finalised`
            1. This state can only be reached from the ‘trading_ended’ state if the admin presses the ‘End game’ button after entering a value for `envelope_price`
            2. Obviously no more orders can be placed or cancelled or matched
            3. Even the price of the envelope cannot be changed by the admin once the game reaches this state
        5. `discarded`
            1. This state can be reached either from the ‘trading_ended’ state or from the ‘created’ state
            2. This state can be reached from the ‘trading_ended’ state if the admin presses the ‘End game’ button without entering a value for `envelope_price`
            3. Obviously no more orders can be placed or cancelled or matched
            4. Even the price of the envelope cannot be changed by the admin once the game reaches this state
15. `admin_player_id`
    1. `profiles.id` of the player who created the game
    2. Required
    3. This player has admin privileges for the game
    4. Should also have a corresponding `game_players` row with `is_admin = true`
16. `last_traded_price`
    1. Price of the most recent execution in this game
    2. Number
    3. Updated every time a trade occurs
    4. `null` until first trade happens
17. `envelope_price`
    1. Final revealed true value of the envelope
    2. Number
    3. Can only be entered by admin
    4. Can only be edited during `trading_ended`
    5. Must become immutable once game reaches `game_finalised`
    6. If left `null` and admin ends the game, game should go to `discarded`
18. `state_version`
    1. Monotonically increasing integer version of game state
    2. Starts at 1
    3. Incremented whenever any gameplay-relevant change happens
19. `updated_at`
    1. UTC timestamp of latest update to the game row
    2. Automatically updated whenever game data changes

## players

1. `player_id`
    1. Unique ID assigned to every player
    2. String or UUID
    3. Assigned when a player signs up and never changes
    4. No two players should have the same `player_id`
    5. Primary key
2. `username`
    1. Username chosen by the player
    2. String
    3. Must be unique across all players
    4. Should be required
    5. Can have length limits such as 3 to 32 characters
    6. Should ideally be case-insensitive for uniqueness
    7. Always store it as lowercase
    8. Can be editable with uniqueness checks
3. `created_at`
    1. Timestamp of when the profile was created
    2. UTC timestamp
    3. Automatically set when the player signs up
    4. Never changes afterwards
4. `email`
    1. Email that the player uses for registration
    2. String that are a valid mail ID
    3. The players can only add it when they sign up and it never gets deleted
    4. No two players should have the same `email`

## orders

1. `order_id`
    1. Unique ID assigned to every order
    2. UUID
    3. Assigned when order is created
    4. Never changes
    5. Primary key
2. `created_by_player_id`
    1. Foreign key to `players.player_id`
    2. Required
    3. Player who created the order
3. `game_id`
    1. Foreign key to `games.game_id`
    2. Required
    3. Indicates which game this order belongs to
4. `type`:
    1. ‘limit_buy’
        1. Player must specify `quantity_initial`
        2. Player must specify `price_per_stock`
        3. This means that the player wishes to buy at most `quantity_initial` number of envelopes where the price of each envelope is `price_per_stock` or less. If the order cannot be matched instantly, the remaining order stays in the `resting_orders` list of the game with updated `quantity_current`
    2. ‘limit_sell’
        1. Player must specify `quantity_initial`
        2. Player must specify `price_per_stock`
        3. This means that the player wishes to sell at most `quantity_initial` number of envelopes where the price of each envelope is `price_per_stock` or more. If the order cannot be matched instantly, the remaining order stays in the `resting_orders` list of the game with updated `quantity_current`
    3. ‘market_buy’
        1. Player must specify `quantity_initial`
        2. This means that the player wishes to buy at most `quantity_initial` number of envelopes where the price will be decided as per the market and can be anything required to make this deal possible. If the order cannot be matched instantly, the remaining order is closed and does not go to the `resting_orders` list of the game
    4. ‘market_sell’
        1. Player must specify `quantity_initial`
        2. This means that the player wishes to buy at most `quantity_initial` number of envelopes where the price will be decided as per the market and can be anything required to make this deal possible. If the order cannot be matched instantly, the remaining order is closed and does not go to the `resting_orders` list of the game
5. `quantity_initial`
    1. Original quantity specified by the player
    2. Positive integer
    3. Never changes
6. `quantity_current`
    1. Remaining unmatched quantity
    2. Positive integer or zero
    3. Initially same as `quantity_initial`
    4. Decreases as executions occur
    5. Becomes zero when the order is done
7. `price_per_stock`
    1. Limit price for limit orders
    2. Floating number
    3. Required when `execution_type = limit`
    4. Must be `null` when `execution_type = market`
8. `status`
    1. Current status of the order
    2. Enum
    3. Allowed values:
        1. `in_queue`
            1. Order is waiting to be processed
        2. `being_processed`
            1. Order is currently the one being matched
        3. `order_resting`
            1. Only valid for partially or fully unmatched limit orders
            2. Means it sits in book waiting for opposite orders
        4. `order_closed`
            1. Order has completed its lifecycle normally
            2. This includes:
                1. market orders whose unmatched remainder was dropped after attempting match
                2. limit orders that got fully filled
        5. `cancelled`
            1. Order was explicitly cancelled by player while still resting
            2. Only possible if the order is in order_resting state
        6. `game_ended`
            1. Every order that was in in_queue, being_processed or order_resting state when the game ends, will be immediately moved to this state
9. `order_created_at`
    1. UTC timestamp when order row was created
    2. Required
    3. Determines FIFO ordering among queued orders
10. `order_updated_at`
    1. UTC timestamp when order row was last updated
    2. Required

## games_players

1. `games_players_row_id`
    1. Unique ID for this game-player membership row
    2. UUID
    3. Primary key
    4. There should not be any other row with the same game and player
2. `map_game_id`
    1. Foreign key to `games.game_id`
    2. Required
    3. Identifies which game this membership belongs to
3. `map_player_id`
    1. Foreign key to `players.player_id`
    2. Required
    3. Identifies which player this row belongs to
4. `lobby_status`
    1. Current status of this player within the game lifecycle
    2. Enum
    3. Recommended values:
        1. `playing`
        2. `finished`
    4. If the player is kicked or leaves the game on their own, then this row is deleted
5. `joined_at`
    1. UTC timestamp when player joined the game lobby
    2. Required once row exists
6. `is_admin`
    1. Boolean
    2. True only for the row belonging to `games.admin_player_id`
    3. Exactly one row per game should have `is_admin = true`
7. `delta_cash`
    1. Net cash change for this player in this game
    2. Number
    3. Starts at `0`
    4. Updated every time an execution involving this player happens
    5. If player buys, decreases
    6. If player sells, increases
8. `delta_envelopes`
    1. Net envelope position change for this player in this game
    2. Integer or number
    3. Starts at `0`
    4. Updated every time an execution happens
    5. If player buys, increases
    6. If player sells, decreases
9. `pnl`
    1. Final pnl for this player in this game
    2. Number
    3. Starts as `0`
    4. Should be computed when game finalises
    5. Formula:
        1. `delta_cash + envelope_price * delta_envelopes`

## executions

1. `executions_id`
    1. Unique ID for each execution
    2. UUID
    3. Primary key
2. `executions_game_id`
    1. Foreign key to `games.game_id`
    2. Required
    3. Every execution belongs to one game
3. `buy_order_id`
    1. Foreign key to `orders.order_id`
    2. Required
    3. The buy-side order in this execution
4. `sell_order_id`
    1. Foreign key to `orders.id`
    2. Required
    3. The sell-side order in this execution
5. `quantity`
    1. Quantity matched in this execution
    2. Positive integer
    3. Must be greater than 0 and lower than or equal to the minimum of the two current quantities involved
6. `execution_price`
    1. Price at which this trade happened
    2. Number
    3. Must always equal the price of the resting order that got matched
    4. This is extremely important and should follow the matching rules exactly
7. `executed_at`
    1. UTC timestamp when the execution happened
    2. Required

## commands

1. `command_id`
    1. Unique ID for the command row
    2. UUID
    3. Primary key
2. `command_game_id`
    1. Foreign key to `games.game_id`
    2. Required
    3. Every command belongs to one game
3. `command_created_at`
    1. UTC timestamp when command was received
4. `player_id`
    1. Foreign key to `players.player_id`
    2. Player who triggered the command
    3. Can be admin or normal player
    4. Could be `null` for system commands if needed
5. `command_type`
    1. Type of requested action
    2. Enum
    3. Example values:
        1. `join_game`
        2. `leave_game`
        3. `kick_player`
        4. `start_game`
        5. `create_order`
        6. `cancel_order`
        7. `end_trading`
        8. `set_envelope_price`
        9. `finalise_game`
        10. `discard_game`
        11. `add_time`
6. `payload`
    1. JSON object containing command details
    2. Example:
        1. for `place_order`, side/type/quantity/price
        2. for `kick_player`, target player id
        3. for `set_envelope_price`, the price value
7. `command_status`
    1. Processing status of the command
    2. Enum
    3. Recommended values:
        1. `pending`
            1. Default status when the command comes in and is not yet picked up by a worker
        2. `claimed`
            1. As soon as a worker picks up a command row, it should be moved to the ‘claimed’ status
        3. `processed`
            1. When the worker has successfully completed the command, it should be moved to the 'processed’ status
        4. `failed`
            1. When the worker fails to complete the command, it should be moved to the 'failed’ status
            2. The new worker will come and pick up the command again if the attempt count is less than 3
        5. `rejected`
            1. When the game ends before this command is picked up or when the command cannot logically be picked up (like a non-admin trying to end the game), it is moved to the 'rejected’ status
8. `claim_token`
    1. Unique token used by worker when claiming this command
    2. When the worker later tries to commit its changes to the table, it should check if the claim_token is still the same as the one it picked up
    3. If the claim_token is not the same as the one it picked up, it means that this worker took too long and some other worker has picked up this command. Now this other worker will handle this command and the original worker should not commit its changes
    4. Helps avoid double processing
9. `claimed_at`
    1. UTC timestamp when worker claimed the command
    2. `null` until claimed
10. `attempt_count`
    1. Number of times processing was attempted
    2. Integer
    3. Starts at 0
11. `finished_at`
    1. UTC timestamp when command reached final processed/failed/rejected state

# Implementation Notes

1. **Lobby and player presence**
    1. There is no ready state
    2. Everyone who enters the code of the game or opens it by clicking on its link is sent to the lobby. In the lobby:
        1. If the game hasn’t started yet:
            1. They can join the game
            2. The can leave the game
        2. If the game has started:
            1. They can join the game (if the game hasn’t hit maximum number of players yet)
            2. They can go to the trading screen
    3. A player is considered part of the lobby/game if they have a `games_players` row for that game
2. **Commands**
    1. Everything that the user can do is in the form of commands
    2. The creation of a new game is a command that does not send its game ID as a parameter
        1. All other commands should send their game ID as a parameter
    3. These commands are processed sequentially
3. **create_order command behavior**
    1. `create_order` should be treated exactly like every other command
    2. Do not create an `orders` row immediately when the command is received
    3. The `orders` row should be created only when the command processor actually picks up and processes that command
    4. Until then, the order will be in ‘in_queue’ state
4. **UI data that must stay updated**
    1. We want the UI to always reflect the latest official state for the game
        1. Lobby
            1. Current list of players always accommodating for newly joined and kicked or left players
            2. latest game state changes such as game starting or being discarded which changes the action button 
                1. The action button in the lobby screen becomes ‘Enter’ when the game has started
        2. Trading screen
            1. latest `last_traded_price`
            2. latest full resting order book
            3. latest state of all personal orders of the player
            4. latest graph / trade history
            5. latest game state changes such as trading ending or game finalising
5. Username updates
    1. Live username updates are not required.
    2. If a username changes, it is acceptable to fetch the updated username next time the lobby/game snapshot is loaded.
    3. We do not need to make username edits propagate live into already-open screens.
6. `games.state_version`
    1. We want one single game-level version number for repair and consistency
    2. That version should move forward whenever any visible game-related data changes
    3. This includes any changes (not just insertion of new rows) coming from:
        1. `games`
        2. `games_players`
        3. `orders`
    4. The purpose of this version is:
        1. realtime gives fast updates
        2. periodic polling of `state_version` detects if the phone missed something
        3. if version differs, the phone fetches a fresh snapshot and repairs itself
7. Realtime + repair model
    1. Realtime updates are the fast path
    2. Periodic version polling is the repair path
    3. The app should not rely on realtime alone
    4. If a realtime update is missed, the next version mismatch should force a full refresh of that game screen
8. Redis usage
    1. Redis should be used only to store the **latest cached game state for active games**
    2. Redis is not the source of truth
    3. Postgres / Supabase remains the official source of truth
    4. Redis exists only to make latest-state-version reads faster and easier
    5. If Redis is missing or stale, backend should rebuild from Postgres
9. Worker / processor model
    1. We do **not** want to assume a permanent always-on worker
    2. We want short-lived processors that wake up when needed and die when done
    3. Main idea:
        1. a new command row comes in
        2. processor wakes up
        3. it handles that game’s pending commands sequentially
        4. when no more claimable commands remain for that game, it dies
    4. In addition to this, we want a periodic safety-net sweep every 5 to 10 seconds
    5. The sweeper exists only to rescue cases where command processing got missed or stuck
        1. If the sweeper sees that for a game, there exists a command that has been claimed by a processor (less than 30 seconds ago), then it doesn’t process any further commands for that game. This is because, the other processor is probably going to sequentially process all the commands for that game anyway
        2. If the sweeper sees that for a game, there don’t exist any pending commands, then it doesn’t process any further commands for that game
        3. If the sweeper sees that for a game, there exist commands that are not being processed, or the processor is stuck for more than 30 seconds on a particular command, then it takes matters into its own hands and claims the first chronologically available command for that game and starts processing it sequentially. It also immediately changes the claim token for that command so that if the previous processor does return with the output, it will see that someone else has picked it up while he was still processing it. Seeing this, the old processor will die without committing the output.
    6. Workers commit their changes to the database after they have successfully completed all steps of that particular command. For example, if a command comes to create an order, then the worker immediately updates the attempt count and claim token for that command and then it starts the process of creating the order. Let’s say it involves 5 steps. Only after all 5 steps are completed successfully and none of them have failed, the worker commits the changes to the database, otherwise, it does not commit anything and rolls back his change-to-be
10. Mutex / game-level exclusivity
    1. At most one processor should be actively working a given game at a time
    2. Different games may be processed in parallel
    3. Same game must be processed sequentially
    4. Freshly claimed commands should act as the signal that some processor is already handling that game
    5. If a game has a recently claimed command, other processors should avoid picking new commands for that same game
11. Processor intent
    1. When a processor wakes up for a game, the intended behavior is:
        1. if that game is already being actively processed, do nothing
        2. otherwise start processing
        3. continue draining commands for that same game in order
        4. stop only when no more claimable commands remain for that game
12. Safety-net sweeper intent
    1. The sweeper should be global, not one cron job per game
    2. It should look for games that still have commands needing attention
    3. It should then wake processors only for those games
    4. This avoids needing separate periodic workers for every active game
13. Command retry intent
    1. We want commands to be retryable if processing failed but retry limit is not exhausted.
    2. A stale claimed command should be considered rescuable.
    3. Attempt count must survive crashes/retries.
    4. Truly terminal commands are only:
        1. processed
        2. rejected
        3. permanently failed after retry limit
14. Order book intent
    1. Full order book should always represent the current resting orders only
    2. Market orders should never remain in the order book
    3. Book depth should update whenever resting orders are added, partially reduced, fully filled, cancelled, or ended because the game ended
15. Personal orders intent
    1. Personal orders panel should show all official orders of that player for that game.
    2. It should reflect status changes continuously.
    3. It should include both active and finished orders.
16. Graph intent
    1. The graph should represent official executions only
    2. It should update from the latest execution history
    3. `last_traded_price` and the graph should remain consistent with executions
    4. Basically, the phone is maintaining a table of time-elapsed vs execution price and the entire graph is derive-able from this table alone. Every time the game state changes, this table should also be updated with latest values and the graph would automatically update
17. End-of-game consistency
    1. When trading ends, no further trading actions should be allowed
    2. Any still-active orders should transition into their ended state consistently
    3. Finalised/discarded state should become the single official terminal state for that game
    4. The UI should move cleanly from trading view to ended/final view based on official game state
18. Overall system intent
    1. The intended system behavior is:
        1. Postgres stores official truth.
        2. Redis stores latest cached game state for active games.
        3. Commands trigger short-lived processors.
        4. Each processor handles one game sequentially.
        5. Different games may process in parallel.
        6. Realtime updates keep screens fresh quickly.
        7. Version polling repairs missed updates.
        8. The phone UI should always converge back to the latest official state even if a realtime update or processor run was missed.