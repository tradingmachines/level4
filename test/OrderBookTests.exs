#- Unit tests for:
#    -- best_bid :: float # return best (highest) bid
#    -- best_ask :: float # return best (lowest) ask
#    -- apply_delta :: 3tuple (Delta) -> None # apply a delta (:side, :price, :size) to the book
#    -- apply_snapshot :: [Delta] -> None # clear books and apply a snapshot (list of deltas)
#    -- get_bids :: [2tuple] # gets the bids as a list
#    -- get_asks :: [2tuple] # gets the asks as a list
#    -- get_book :: [[2tuple], [2tuple]] # gets both the bid and ask lists
    
# - all test functions will return :empty if the respective book side is empty
# - all test functions behave in respect to an orderbook Agent (require first arg to be agent pid)


defmodule OrderBookTests do
  use ExUnit.Case
  doctest OrderBook

  test "greets the world" do
    assert is_number(OrderBook.best_ask())
  end
end


