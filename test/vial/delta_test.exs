defmodule Vial.DeltaTest do
  use ExUnit.Case, async: true
  alias Vial.{Delta, Set}

  describe "new" do
    test "it creates a valid Delta" do
      delta = Delta.new(:actor, 5)

      assert delta.actor == :actor
      assert delta.start_clock == 5
      assert delta.end_clock == 5
    end
  end

  describe "record_addition" do
    test "it records additions" do
      addition = {:key, :pid, :bar, {:actor, 12}}
      delta =
        Delta.new(:actor, 10)
        |> Delta.record_addition(addition)

      assert delta.end_clock == 12
      assert delta.additions == [addition]
    end
  end

  describe "record_removal" do
    test "it records removals" do
      removal = {:key, {:actor, 8}}
      delta =
        Delta.new(:actor, 10)
        |> Delta.record_removal(12, removal)

      assert delta.end_clock == 12
      assert delta.removals == [removal]
    end
  end

  describe "extract" do
    test "it only extracts elements that have not been removed" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :pid, :value)
        |> Set.add(:key1, :pid1, :value)
        |> Set.add(:removed, :removed_pid, :value1)
        |> Set.remove(:removed, :removed_pid)

      delta = set
        |> Delta.extract()

      keys =
        delta.additions
        |> Enum.map(fn {key, _, _, _} -> key end)
        |> Enum.sort

      assert keys == [:key, :key1]
    end

    test "it sets the clocks correctly" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :pid, :value)       # 0
        |> Set.add(:key1, :pid1, :value)     # 1
        |> Set.add(:removed, :pid3, :value1) # 2
        |> Set.remove(:removed, :pid3)       # 3

      delta = set |> Delta.extract()

      assert delta.start_clock == 0
      assert delta.end_clock == 3
    end
  end
end
