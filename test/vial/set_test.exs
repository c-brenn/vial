defmodule Vial.SetTest do
  use ExUnit.Case, async: true
  doctest Vial.Set
  alias Vial.Set

  describe "new/1" do
    test "returns a new, usable set" do
      set = Set.new(:foo)

      assert set.actor == :foo

      table_info = :ets.info(set.table)

      assert table_info

      assert Keyword.get(table_info, :size) == 0
    end
  end

  describe "member?/2" do
    test "returns false for non-members" do
      set = Set.new(:actor)

      assert Set.member?(set, :foo) == false
    end
  end

  describe "add" do
    test "it adds elements" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :value)

      assert Set.member?(set, :key)
    end

    test "it does not re-add elements" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :value)

      s1 = Set.add(set, :key, :value2)

      assert set == s1 # the version vector is the same
      assert Set.lookup(set, :key) == {:ok, :value}
    end
  end

  describe "remove" do
    test "it does nothing for non-existent elements" do
      set = Set.new(:foo)
      s1  =  Set.remove(set, :key)

      assert set == s1
    end

    test "it removes elements" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :value)
        |> Set.remove(:key)

      refute Set.member?(set, :key)
    end
  end
end
