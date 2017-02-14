defmodule Vial.Set do
  alias Vial.{
    Delta,
    Set,
    Vector
  }

  defstruct [:actor, :table, :vector, :delta]

  @type actor   :: term
  @type key     :: term
  @type value   :: term

  @opaque t :: %Set {
    actor: actor,
    table:  term,
    vector: Vector.t,
    delta:  Delta.t
  }

  @doc """
  Creates a new set with the given actor id.
  """
  @spec new(actor) :: t
  def new(actor) do
    %Set {
      actor:  actor,
      table:  :ets.new(actor, [:set, :protected]),
      vector: Vector.new(),
      delta:  Delta.new(actor, 0)
    }
  end

  @doc """
  Adds an element to the set.
  """
  @spec add(t, key, value) :: t
  def add(set, key, value) do
    clock = Vector.clock(set.vector, set.actor)
    addition = {key, value, {set.actor, clock}}

    if :ets.insert_new(set.table, {key, value, {set.actor, clock}}) do
      %{set|
        vector: Vector.increment(set.vector, set.actor),
        delta:  Delta.record_addition(set.delta, addition)
      }
    else
      set
    end
  end

  @doc """
  Removes an element from the set.
  """
  @spec remove(t, key) :: t
  def remove(%Set{actor: actor}=set, key) do
    clock = Vector.clock(set.vector, actor)

    case :ets.lookup(set.table, key) do
      [] ->
        set

      [{^key, _, {^actor, clock_to_remove}}] ->

        removal = {key, {actor, clock_to_remove}}
        :ets.delete(set.table, key)
        %{set|
          vector: Vector.increment(set.vector, set.actor),
          delta:  Delta.record_removal(set.delta, clock, removal)
        }
    end
  end

  @doc """
  Checks if an element is in the set
  """
  @spec member?(t, key) :: boolean
  def member?(set, key) do
    case :ets.lookup(set.table, key) do
      [] -> false
      [_] -> true
    end
  end

  @doc """
  Retrieves the value stored for the given element
  """
  @spec lookup(t, key) :: {:ok, value} | {:error, :no_such_element}
  def lookup(set, key) do
    case :ets.lookup(set.table, key) do
      [] ->
        {:error, :no_such_element}
      [{_, value, _}] ->
        {:ok, value}
    end
  end

  @doc """
  Merges a Delta into the Set
  """
  @spec merge(t, Delta.t) :: t
  def merge(set, delta) do
    expected_clock = Vector.clock(set.vector, delta.actor)

    if delta.start_clock == expected_clock do
      do_merge(set, delta)
    else
      set
    end
  end

  defp do_merge(set, delta) do
    :ets.insert(set.table, delta.additions)
    for {key, dot} <- delta.removals do
      :ets.match_delete(set.table, {key, :_, dot})
    end

    %{set| vector: Vector.set(set.vector, delta.actor, delta.end_clock)}
  end
end
