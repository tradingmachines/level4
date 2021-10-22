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

  @num_price_levels 100
  @ask_range 1001..2000
  @bid_range 0..999
  @volume_range 1..50

  def rand_sample(n, range) do
    for(_ <- 1..n, do: Enum.random(range))
    |> Enum.uniq
  end

  # not setup_all because by default mix will randomize the order in which tests are executed
  # as such each test will have a fresh set of random sample deltas
  setup do
    {:ok, book} = OrderBook.start_link()

    [
      book: book,
      bids:
        List.zip([
          rand_sample(@num_price_levels, @bid_range),
          rand_sample(@num_price_levels, @volume_range)
        ]),
      asks:
        List.zip([
          rand_sample(@num_price_levels, @ask_range),
          rand_sample(@num_price_levels, @volume_range)
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
    [level | _] = state[:bids]
    OrderBook.apply_delta(state[:book], :bid, level)
    assert OrderBook.best_bid(state[:book]) == level
  end

  test "apply delta to ask side", state do
    [level | _] = state[:asks]
    OrderBook.apply_delta(state[:book], :ask, level)
    assert OrderBook.best_ask(state[:book]) == level
  end

  test "apply snapshot (asks and bids)", state do
    book = state[:book]
    bids = state[:bids]
    asks = state[:asks]
    
    max_bid = Enum.max_by(bids, fn {x, _} -> x end)
    min_ask = Enum.min_by(asks, fn {x, _} -> x end)

    OrderBook.apply_snapshot(book, {bids, asks})
    assert OrderBook.best_ask(book) == min_ask 
       and OrderBook.best_bid(book) == max_bid
  end

  test "get_bids returns bid list in correct order", state do
    book = state[:book]
    bids = Enum.sort_by(state[:bids], fn {x, _} -> -x end)

    OrderBook.apply_snapshot(book, {bids, []})
    assert bids == OrderBook.bids(book)
  end

  test "get_asks returns ask list in correct order", state do
    book = state[:book]
    asks = Enum.sort_by(state[:asks], fn {x, _} -> x end)

    OrderBook.apply_snapshot(book, {[], asks})
    assert asks == OrderBook.asks(book)
  end

  test "book returns bid and ask sides, both correctly ordered", state do
    book = state[:book]
    bids = Enum.sort_by(state[:bids], fn {x, _} -> -x end)
    asks = Enum.sort_by(state[:asks], fn {x, _} -> x end)

    OrderBook.apply_snapshot(book, {bids, asks})
    assert {^bids, ^asks} = OrderBook.book(book)
  end

end
