defmodule Vial.Set do
  alias Vial.{Set, Vector}

  defstruct [:actor, :table, :vector]

  @type actor   :: term
  @type key     :: term
  @type value   :: term

  @opaque t :: %Set {
    actor: actor,
    table: term,
    vector: Vector.t
  }

  @doc """
  Creates a new set with the given actor id.
  """
  @spec new(actor) :: t
  def new(actor) do
    %Set {
      actor: actor,
      table: :ets.new(actor, [:set, :protected]),
      vector: Vector.new()
    }
  end

  @doc """
  Adds an element to the set.
  """
  @spec add(t, key, value) :: t
  def add(set, key, value) do
    clock = Vector.clock(set.vector, set.actor)

    if :ets.insert_new(set.table, {key, value, {set.actor, clock}}) do
      # todo: store addition in delta
      %{set|
        vector:  Vector.increment(set.vector, set.actor)
      }
    else
      set
    end
  end

  @doc """
  Removes an element from the set.
  """
  @spec remove(t, key) :: t
  def remove(set, key) do
    case :ets.lookup(set.table, key) do
      [] ->
        set
      [_] ->
        # todo: store removal in delta
        :ets.delete(set.table, key)
        %{set|
          vector: Vector.increment(set.vector, set.actor)
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
end
