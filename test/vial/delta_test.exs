defmodule Vial.DeltaTest do
  use ExUnit.Case, async: true
  alias Vial.Delta

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
      addition = {:foo, :bar, {:actor, 12}}
      delta =
        Delta.new(:actor, 10)
        |> Delta.record_addition(addition)

      assert delta.end_clock == 12
      assert delta.additions == [addition]
    end
  end

  describe "record_removal" do
    test "it records removals" do
      removal = {:actor, 8}
      delta =
        Delta.new(:actor, 10)
        |> Delta.record_removal(12, removal)

      assert delta.end_clock == 12
      assert delta.removals == [removal]
    end
  end
end
