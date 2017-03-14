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
      table:  :ets.new(actor, [:bag, :protected]),
      vector: Vector.new(),
      delta:  Delta.new(actor, 0)
    }
  end

  @doc """
  Adds an element to the set.
  """
  @spec add(t, key, pid, value) :: t
  def add(set, key, pid, value) do
    if member?(set, key, pid) do
      set
    else
      clock = Vector.clock(set.vector, set.actor)
      addition = {key, pid, value, {set.actor, clock}}
      :ets.insert(set.table, addition)

      %{set|
        vector: Vector.increment(set.vector, set.actor),
        delta:  Delta.record_addition(set.delta, addition)
      }
    end
  end

  @doc """
  Removes an element from the set.
  """
  @spec remove(t, key, pid) :: t
  def remove(%Set{actor: actor}=set, key, pid) do
    clock = Vector.clock(set.vector, actor)

    case :ets.match_object(set.table, {key, pid, :_, :_}) do
      [] ->
        set

      [{^key, ^pid, _, {^actor, clock_to_remove}} = object] ->

        removal = {key, pid, {actor, clock_to_remove}}
        :ets.delete_object(set.table, object)
        %{set|
          vector: Vector.increment(set.vector, set.actor),
          delta:  Delta.record_removal(set.delta, clock, removal)
        }
    end
  end

  @doc """
  Checks if an element is in the set
  """
  @spec member?(t, key, pid) :: boolean
  def member?(set, key, pid) do
    case :ets.match(set.table, {key, pid, :_, :_}) do
      [] -> false
      [_] -> true
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
    for {key, pid, dot} <- delta.removals do
      :ets.match_delete(set.table, {key, pid, :_, dot})
    end

    %{set| vector: Vector.set(set.vector, delta.actor, delta.end_clock)}
  end
end
