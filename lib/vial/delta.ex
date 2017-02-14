defmodule Vial.Delta do
  alias __MODULE__

  @type key   :: term
  @type value :: term
  @type clock :: pos_integer
  @type actor :: term

  @type addition :: {key, value, {actor, clock}}
  @type removal  :: {actor, clock}

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
  def record_addition(%{end_clock: e}=delta, {_,_,{_,clock}} = addition)
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
end
