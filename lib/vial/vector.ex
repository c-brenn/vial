defmodule Vial.Vector do
  @moduledoc """
  Provides functions for working with version vectors.
  """

  @type actor :: term
  @type clock :: pos_integer
  @opaque t   :: %{ actor => clock }

  @spec new() :: t
  def new(), do: %{}

  @doc """
  Increments the clock for a given actor.
  If the actor is not yet in the vector, the clock is set to 1.
  """
  @spec increment(t, actor) :: t
  def increment(vector, actor) do
    Map.update(vector, actor, 1, &(&1 + 1))
  end

  @doc """
  Returns the current clock for a given actor.
  If the actor is not present, it returns 0.
  """
  @spec clock(t, actor) :: clock
  def clock(vector, actor) do
    Map.get(vector, actor, 0)
  end

  @doc """
  Sets the clock for the given actor to the given clock value.
  """
  @spec set(t, actor, clock) :: t
  def set(vector, actor, clock) do
    Map.put(vector, actor, clock)
  end
end
