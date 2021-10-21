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


defmodule OrderBookTest do
  use ExUnit.Case
  doctest OrderBook

  def brew_data(items) do
    price_range = 1000..1500
    volume_range = 1..50
    
    prices = for _ <- 1..items, do: Enum.random(price_range)
    vols = for _ <- 1..items, do: Enum.random(volume_range)
    List.zip([prices, vols])
  end

  setup_all do
    {_, book} = OrderBook.start_link()
    data = brew_data(200)
    [book: book, data: data]
  end

  test "test_empty_asks", state do
    assert OrderBook.best_ask(state[:book]) == :side_empty
  end

  test "test_empty_bids", state do
    assert OrderBook.best_ask(state[:book]) == :side_empty
  end

  test "apply_ask_delta", state do
    [price|_] = state[:data]
    OrderBook.apply_delta(state[:book], :ask, price)
    assert OrderBook.best_ask(state[:book]) == price
  end

  test "apply_bid_delta", state do
    [price|_] = state[:data]
    OrderBook.apply_delta(state[:book], :bid, price)
    assert OrderBook.best_bid(state[:book]) == price
  end
end


