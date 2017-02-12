defmodule Vial.VectorTest do
  use ExUnit.Case, async: true
  doctest Vial.Vector
  alias Vial.Vector

  describe "new/0" do
    test "it returns an empty map" do
      assert Vector.new() == %{}
    end
  end

  describe "clock/2" do
    test "it returns 0 for unknown actors" do
      assert %{} |> Vector.clock(:unkown) == 0
    end

    test "it returns the correct clock for know actors" do
      vector = %{actor: 5}
      assert vector |> Vector.clock(:actor) == 5
    end
  end

  describe "increment/2" do
    test "it sets the clocks of new actors to 1" do
      vector =
        Vector.new()
        |> Vector.increment(:actor)

      assert vector[:actor] == 1
    end

    test "it adds 1 to the clocks of existing actors" do
      vector =
        %{actor: 5}
        |> Vector.increment(:actor)

      assert vector[:actor] == 6
    end
  end

  describe "set/3" do
    test "it sets the clock of unkown actors" do
      vector =
        Vector.new()
        |> Vector.set(:actor, 5)

      assert vector |> Vector.clock(:actor) == 5
    end

    test "it sets the clock of kown actors" do
      vector =
        %{actor: 2}
        |> Vector.set(:actor, 5)

      assert vector |> Vector.clock(:actor) == 5
    end
  end
end
