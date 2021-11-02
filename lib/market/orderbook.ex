defmodule Orderbook do
  @moduledoc """
  Orderbook implements a limit orderbook.

  Bid and ask sides are represented in memory using general balanced trees
  via [Erlang's gb_trees](https://erlang.org/doc/man/gb_trees.html). An
  orderbook is a tuple {bids side, asks side} maintained by an agent
  process.

  Orderbook supports the following operations:
  - bids(): list of bids in the book;
  - asks(): list of asks in the book;
  - book(): both sides of the book;
  - best_bid(): top of the bids side;
  - best_ask(): top of the asks side;
  - apply_delta(): update/remove a price level;
  - apply_snapshot(): reset the book.
  """

  use Agent

  # A price level is a tuple (price, liquidity). Both numbers must be floats.
  @type price_level :: {float(), float()}

  # A list of price level tuples.
  @type price_levels :: [price_level]

  # A snapshot is tuple (bid price levels, ask price levels).
  @type snapshot :: {price_levels, price_levels}

  @doc """
  Starts and links a new agent with an initial state {bids side, asks side}
  where a side is a general balanced tree mapping prices to their liquidity.
  """
  @spec start_link() :: pid()
  def start_link() do
    Agent.start_link(fn -> {:gb_trees.empty(), :gb_trees.empty()} end)
  end

  @doc """
  Returns the list of bid limit orders currently in the orderbook. The list
  is ordered in descending order (highest bid price -> lowest bid price).
  Evaluates to an empty list if the book contains zero bid levels.

  e.g. [{P_1, L_1}, {P_2, L_2}, ..., {P_h, L_h}] where P is a bid price,
  L is the total liquidity at that price, and h is the height of the
  bids side. P1 is the highest price somebody is willing to pay.
  """
  @spec bids(Orderbook) :: price_levels
  def bids(book) do
    Agent.get(book, fn {bids, _} ->
      :gb_trees.to_list(bids)
      |> Enum.sort(fn {price1, _}, {price2, _} ->
        price1 > price2
      end)
    end)
  end

  @doc """
  Returns the list of ask limit orders currently in the orderbook. The list
  is ordered in ascending order (lowest ask price -> highest ask price).
  Evaluates to an empty list if the book contains zero ask levels.

  e.g. [{P_1, L_1}, {P_2, L_2}, ..., {P_h, L_h}] where P is an ask price,
  L is the total liquidity at that price, and h is the height of the
  asks side. P1 is the lowest somebody is willing to sell.
  """
  @spec asks(Orderbook) :: price_levels
  def asks(book) do
    Agent.get(book, fn {_, asks} ->
      :gb_trees.to_list(asks)
      |> Enum.sort(fn {price1, _}, {price2, _} ->
        price1 < price2
      end)
    end)
  end

  @doc """
  Returns a snapshot of both sides of the book. Simply a tuple using bids()
  and asks() defined above, therefore the ordering of both sides is the same.
  """
  @spec book(Orderbook) :: snapshot
  def book(book) do
    {Orderbook.bids(book), Orderbook.asks(book)}
  end

  @doc """
  Returns the best (highest) bid price in the book and its liquidity.
  Evaluates to {price, liquidity} if the bids side is not empty,
  otherwise :side_empty.
  """
  @spec best_bid(Orderbook) :: price_level
  @spec best_bid(Orderbook) :: :side_empty
  def best_bid(book) do
    bids = Agent.get(book, fn {bids, _} -> bids end)

    # as long as the bids side is not empty,
    # find the highest somebody is willing to pay.
    if :gb_trees.is_empty(bids) do
      :side_empty
    else
      :gb_trees.largest(bids)
    end
  end

  @doc """
  Returns the best (lowest) ask price in the book and its liquidity.
  Evaluates to {price, liquidity} if the asks side is not empty,
  otherwise :side_empty.
  """
  @spec best_ask(Orderbook) :: price_level
  @spec best_ask(Orderbook) :: :side_empty
  def best_ask(book) do
    asks = Agent.get(book, fn {_, asks} -> asks end)

    # as long as the asks side is not empty,
    # find the lowest somebody is willing to sell.
    if :gb_trees.is_empty(asks) do
      :side_empty
    else
      :gb_trees.smallest(asks)
    end
  end

  @doc """
  Sets a price level on the bids side or the asks side to a specific
  liquidity level. Creates that level if it does not already exist or
  overwrites the price's liquidity if it does. If liquidity <= 0 the price
  level is removed from the book.
  """
  @spec apply_delta(Orderbook, :bid, price_level) :: :ok
  def apply_delta(book, :bid, {price, liquidity}) do
    if liquidity <= 0 do
      # remove price level from bids side if liquidity <= 0.
      Agent.update(book, fn {bids, asks} ->
        {:gb_trees.delete(price, bids), asks}
      end)
    else
      # otherwise insert/update bid price level's liquidity.
      Agent.update(book, fn {bids, asks} ->
        {:gb_trees.enter(price, liquidity, bids), asks}
      end)
    end
  end

  @spec apply_delta(Orderbook, :ask, price_level) :: :ok
  def apply_delta(book, :ask, {price, liquidity}) do
    if liquidity <= 0 do
      # remove price level from asks side if liquidity <= 0.
      Agent.update(book, fn {bids, asks} ->
        {bids, :gb_trees.delete(price, asks)}
      end)
    else
      # otherwise insert/update ask price level's liquidity.
      Agent.update(book, fn {bids, asks} ->
        {bids, :gb_trees.enter(price, liquidity, asks)}
      end)
    end
  end

  @doc """
  Replaces both side of the orderbook with new bids and new asks.
  Both bid and ask trees are reinitialised from lists of price levels
  ordered by price. This function does not assume new bids and asks are
  already ordered, and will prevent price levels that have no liquidity
  from being added to the book.
  """
  @spec apply_snapshot(Orderbook, snapshot) :: :ok
  def apply_snapshot(book, {bids, asks}) do
    Agent.update(book, fn _ ->
      {
        # price levels with liquidity <= 0 should never be added to the
        # book so filter them out before sorting.
        # from_ordict constructs a new tree for both sides but expects
        # the list of {key, value} tuples to be sorted (by price in
        # this context).
        :gb_trees.from_orddict(
          bids
          |> Enum.reject(fn {_, liquidity} -> liquidity <= 0 end)
          |> Enum.sort_by(fn {price, _} -> price end)
        ),
        :gb_trees.from_orddict(
          asks
          |> Enum.reject(fn {_, liquidity} -> liquidity <= 0 end)
          |> Enum.sort_by(fn {price, _} -> price end)
        )
      }
    end)
  end
end
