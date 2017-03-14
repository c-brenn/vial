defmodule Vial.Delta do
  alias __MODULE__
  alias Vial.{Set, Vector}

  @type key   :: term
  @type value :: term
  @type clock :: pos_integer
  @type actor :: term

  @type addition :: {key, value, {actor, clock}}
  @type removal  :: {key, {actor, clock}}

  defstruct [
    :actor,
    :additions,
    :removals,
    :start_clock,
    :end_clock
  ]

  @opaque t :: %Delta {
    actor:       actor,
    additions:   [addition],
    removals:    [removal],
    start_clock: clock,
    end_clock:   clock
  }

  @doc """
  Creates a new delta for the given actor with the given starting clock.
  """
  @spec new(actor, clock) :: t
  def new(actor, clock) do
    %Delta{
      actor: actor,
      additions: [],
      removals: [],
      start_clock: clock,
      end_clock: clock
    }
  end

  @doc """
  Records the addition in the list of additions.
  """
  @spec record_addition(t, addition) :: t
  def record_addition(%{end_clock: e}=delta, {_,_,_,{_,clock}} = addition)
    when e <= clock do

    %{delta|
      additions: [addition|delta.additions],
      end_clock: clock
    }
  end

  @doc """
  Records the removal in the list of removals.
  """
  @spec record_removal(t, clock, removal) :: t
  def record_removal(%{end_clock: e}=delta, removal_clock, removal)
    when e <= removal_clock do

    %{delta|
      removals: [removal|delta.removals],
      end_clock: removal_clock
    }
  end

  @doc """
  Extracts all of the elements of the Set added by the given
  actor into a Delta
  """
  @spec extract(Set.t) :: t
  def extract(set) do
    match_pattern = {:_, :_, :_, {set.actor, :_}}

    %Delta{
      actor:       set.actor,
      start_clock: 0,
      end_clock:   Vector.clock(set.vector, set.actor) - 1,
      additions:   :ets.match_object(set.table, match_pattern),
      removals:    []
    }
  end
end
