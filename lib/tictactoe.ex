defmodule TicTacToe do
  use GenServer
  require Logger

  # Client

  @doc """
    Starts the TicTacToe game
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
    Places a token on the board for the current player
  """
  def place_token({x, y}) when x <= 2 and x >= 0 and y <= 2 and x >= 0 do
    GenServer.cast(__MODULE__, {:place_token, x, y})
  end

  @doc """
    Gets the empty tiles remaining on the board
  """
  def get_board do
    GenServer.call(__MODULE__, {:get_board})
  end

  @doc """
    Resets the board
  """
  def clear_board do
    GenServer.cast(__MODULE__, {:clear_board})
  end

  @doc """
    Returns 1 if it is player 1's turn and 2 if it is player 2's turn
  """
  def get_turn do
    GenServer.call(__MODULE__, {:get_turn})
  end

  @doc """
    Returns the tiles controlled by the given player
  """
  def get_player(n) when n == 1 or n == 2 do
    GenServer.call(__MODULE__, {:get_player, n})
  end

  @doc """
    Returns the winning 3-tile line if the player has won, otherwise false
  """
  def has_won?(n) when n == 1 or n == 2 do
    GenServer.call(__MODULE__, {:has_won, n})
  end

  # Server

  def init(:ok) do
    Logger.debug("TicTacToe server started")
    {:ok, {[8, 1, 6, 3, 5, 7, 4, 9, 2], [], []}}
  end

  def handle_call({:get_board}, _from, state) do
    {board, _, _} = state
    {:reply, board |> Enum.map(&isomorphismToCoords/1), state}
  end

  def handle_call({:get_turn}, _from, state) do
    {board, _, _} = state
    {:reply, get_turn_from_board(board), state}
  end

  def handle_call({:get_player, n}, _from, state) do
    {_, p1, p2} = state
    case n do
      1 -> {:reply, p1 |> Enum.map(&isomorphismToCoords/1), state}
      2 -> {:reply, p2 |> Enum.map(&isomorphismToCoords/1), state}
    end
  end

  def handle_call({:has_won, n}, _from, state) do
    {_, p1, p2} = state

    candidate = case n do
      1 -> p1
      2 -> p2
    end

    index = combinations(3, candidate)
      |> Enum.map(fn(x) -> sum(x) end)
      |> Enum.find_index(fn(x) -> x == 15 end)

    if(index) do
      {:reply, Enum.at(candidate, index) |> Enum.map(&isomorphismToCoords/1), state}
    else
      {:reply, false, state}
    end
  end

  def handle_cast({:place_token, x, y}, state) do
    iso = coordsToIsomorphism({x, y})
    {board, p1, p2} = state

    updated_board = board |> List.delete(iso)

    unless(length(board) == length(updated_board)) do
      case get_turn_from_board(board) do
        1 -> {:noreply, {updated_board, p1 ++ [iso], p2}}
        2 -> {:noreply, {updated_board, p1, p2 ++ [iso]}}
      end
    else
      {:noreply, state}
    end
  end

  def handle_cast({:clear_board}, state) do
    {:noreply, {[8, 1, 6, 3, 5, 7, 4, 9, 2], [], []}}
  end

  # Helpers

  defp coordsToIsomorphism({x, y}) do
    [8, 1, 6, 3, 5, 7, 4, 9, 2]
      |> Enum.at(3 * y + x)
  end

  defp isomorphismToCoords(iso) do
    index = [8, 1, 6, 3, 5, 7, 4, 9, 2]
      |> Enum.find_index(fn(x) -> x == iso end)

    {rem(index, 3), trunc(index/3)}
  end

  defp get_turn_from_board(board) do
    rem(length(board) + 1, 2) + 1
  end

  defp combinations(0, _), do: [[]]
  defp combinations(_, []), do: []
  defp combinations(m, [h|t]) do
    (for l <- combinations(m-1, t), do: [h|l]) ++ combinations(m, t)
  end

  defp sum(l) do
    l |> Enum.reduce(&+/2)
  end
end
