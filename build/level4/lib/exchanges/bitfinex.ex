defmodule Exchanges.Bitfinex do
  @moduledoc """
  Translation scheme for the Bitfinex websocket API.
  """

  defmacro __using__(_opts) do
    quote do
      @impl TranslationScheme
      def synchronised?(current_state) do
        # TODO
        true
      end

      @impl TranslationScheme
      def translate(json, current_state) do
        {instructions, next_state} =
          case json do
            [_, "hb"] ->
              {[:noop], current_state}

            %{"event" => "info"} ->
              {[:noop], current_state}

            %{"event" => "conf"} ->
              {[:noop], current_state}

            %{"event" => "pong"} ->
              {[:noop], current_state}

            %{
              "event" => "subscribed",
              "channel" => "book",
              "chanId" => chan_id
            } ->
              {[:noop], %{current_state | "book_cid" => chan_id}}

            %{
              "event" => "subscribed",
              "channel" => "trades",
              "chanId" => chan_id
            } ->
              {[:noop], %{current_state | "trades_cid" => chan_id}}

            [chan_id, data] ->
              cond do
                chan_id == current_state["book_cid"] ->
                  case data do
                    [price_int, count, amount_int] ->
                      price = price_int / 1
                      amount = amount_int / 1

                      delta =
                        cond do
                          amount > 0 ->
                            if count == 0 do
                              {:bid, price, 0}
                            else
                              {:bid, price, amount}
                            end

                          amount <= 0 ->
                            if count == 0 do
                              {:ask, price, 0}
                            else
                              {:ask, price, -amount}
                            end
                        end

                      {[{:deltas, [delta]}], current_state}

                    levels ->
                      bids =
                        levels
                        |> Enum.filter(fn [_, _, amount] -> amount > 0 end)
                        |> Enum.map(fn [price_int, _, amount_int] ->
                          price = price_int / 1
                          amount = amount_int / 1
                          {price, amount}
                        end)

                      asks =
                        levels
                        |> Enum.filter(fn [_, _, amount] -> amount <= 0 end)
                        |> Enum.map(fn [price_int, _, amount_int] ->
                          price = price_int / 1
                          amount = amount_int / 1
                          {price, -amount}
                        end)

                      {[{:snapshot, bids, asks}], current_state}
                  end

                chan_id == current_state["trades_cid"] ->
                  {[:noop], current_state}
              end

            [chan_id, type, data] ->
              case type do
                "te" ->
                  cond do
                    chan_id == current_state["trades_cid"] ->
                      [_, _, amount_int, price_int] = data

                      price = price_int / 1
                      amount = amount_int / 1

                      if amount > 0 do
                        {
                          [{:buys, [{price, amount}]}],
                          current_state
                        }
                      else
                        {
                          [{:sells, [{price, -amount}]}],
                          current_state
                        }
                      end
                  end

                "tu" ->
                  {[:noop], current_state}
              end
          end

        {:ok, instructions, next_state}
      end

      @impl TranslationScheme
      def initial_state(base_symbol, quote_symbol) do
        %{"book_cid" => nil, "trades_cid" => nil}
      end

      @impl TranslationScheme
      def ping_msg(current_state) do
        book =
          if current_state["book_cid"] != nil do
            {:ok, json_str_book} =
              Jason.encode(%{
                "event" => "ping",
                "cid" => current_state["book_cid"]
              })

            [json_str_book]
          else
            []
          end

        trade =
          if current_state["trades_cid"] != nil do
            {:ok, json_str_trade} =
              Jason.encode(%{
                "event" => "ping",
                "cid" => current_state["trades_cid"]
              })

            [json_str_trade]
          else
            []
          end

        {:ok, book ++ trade}
      end
    end
  end
end

defmodule Exchanges.Bitfinex.Spot do
  @moduledoc """
  Spot markets.

  Relevant documentation:
  - https://docs.bitfinex.com/docs/changelog
  - https://docs.bitfinex.com/docs/ws-general
  """

  @behaviour TranslationScheme

  use Exchanges.Bitfinex

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    {internal_base, internal_quote} =
      case {base_symbol, quote_symbol} do
        {any_b, "USDT"} -> {any_b, "UST"}
        {any_b, any_q} -> {any_b, any_q}
      end

    symbol =
      cond do
        String.length(internal_base) > 3 or
            String.length(internal_quote) > 3 ->
          # delimit with :
          "t#{internal_base}:#{internal_quote}"

        String.length(internal_base) <= 3 and
            String.length(internal_quote) <= 3 ->
          # no : needed
          "t#{internal_base}#{internal_quote}"
      end

    {:ok, json_str_book} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "book",
        "symbol" => symbol
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "trades",
        "symbol" => symbol
      })

    {:ok, [json_str_book, json_str_trade]}
  end
end

defmodule Exchanges.Bitfinex.Futures do
  @moduledoc """
  Futures markets.

  Relevant documentation:
  - https://docs.bitfinex.com/docs/changelog
  - https://docs.bitfinex.com/docs/ws-general
  """

  @behaviour TranslationScheme

  use Exchanges.Bitfinex

  @impl TranslationScheme
  def subscribe_msg(base_symbol, quote_symbol) do
    symbol =
      case {base_symbol, quote_symbol} do
        {any_b, "USDT"} -> "t#{any_b}F0:USTF0"
        {any_b, any_q} -> "t#{any_b}F0:#{any_q}F0"
      end

    {:ok, json_str_book} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "book",
        "symbol" => symbol
      })

    {:ok, json_str_trade} =
      Jason.encode(%{
        "event" => "subscribe",
        "channel" => "trades",
        "symbol" => symbol
      })

    {:ok, [json_str_book, json_str_trade]}
  end
end
