defmodule OrderBookTest do
  @moduledoc """
  Unit tests for the OrderBook module

  All test functions will return :empty if the respective book side is empty.
  Also, all test functions behave in respect to an orderbook Agent (require
  first arg to be agent pid).

  ## Testing
  - best_bid       :: float                  # return best (highest) bid
  - best_ask       :: float                  # return best (lowest) ask
  - apply_delta    :: 3tuple (Delta) -> None # apply a delta (:side, price, size)
                                               to the book
  - apply_snapshot :: [Delta] -> None        # clear books and apply a snapshot
                                               (list of deltas)
  - get_bids       :: [2tuple]               # gets the bids as a list
  - get_asks       :: [2tuple]               # gets the asks as a list
  - get_book       :: [[2tuple], [2tuple]]   # gets both the bid and ask lists
  """

  use ExUnit.Case
  doctest OrderBook

  @num_price_levels 200
  @price_range 1000..1500
  @volume_range 1..50

  # not setup_all because by default mix will randomize the order in which tests
  # are executed. sharing and modifying the state of the book in this way is
  # confusing and might cause some tests to fail intermittently?
  setup do
    {:ok, book} = OrderBook.start_link()

    [
      book: book,
      data:
        List.zip([
          for(_ <- 1..@num_price_levels, do: Enum.random(@price_range)),
          for(_ <- 1..@num_price_levels, do: Enum.random(@volume_range))
        ])
    ]
  end

  test "bids side is empty to begin with", state do
    assert OrderBook.bids(state[:book]) == []
    assert OrderBook.best_bid(state[:book]) == :side_empty
  end

  test "asks side is empty to begin with", state do
    assert OrderBook.asks(state[:book]) == []
    assert OrderBook.best_ask(state[:book]) == :side_empty
  end

  # maybe: have separate "data"s for bids and asks, such that bid prices are
  # in 0..999 and ask prices are in 1001..2000 (a £2 spread). the volume can
  # stay the same. more representative. the intersection of the bid prices and
  # the ask prices is always empty.
  test "apply delta to bids side", state do
    [level | _] = state[:data]
    OrderBook.apply_delta(state[:book], :bid, level)
    assert OrderBook.best_bid(state[:book]) == level
  end

  test "apply delta to ask side", state do
    [level | _] = state[:data]
    OrderBook.apply_delta(state[:book], :ask, level)
    assert OrderBook.best_ask(state[:book]) == level
  end
end
