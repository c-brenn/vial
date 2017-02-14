defmodule Vial.SetTest do
  use ExUnit.Case, async: true
  doctest Vial.Set
  alias Vial.{Set, Delta}

  describe "new/1" do
    test "returns a new, usable set" do
      set = Set.new(:foo)

      assert set.actor == :foo

      table_info = :ets.info(set.table)

      assert table_info
      assert Keyword.get(table_info, :size) == 0

      assert set.delta.start_clock == 0
      assert set.delta.end_clock == 0
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

    test "it records additions in the delta" do
      set = Set.new(:foo)
      assert set.delta.additions |> Enum.empty?()
      set =
        set
        |> Set.add(:key, :value)

      refute set.delta.additions |> Enum.empty?()
    end
  end

  describe "lookup" do
    test "it returns the value for a given key" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :value)

      assert Set.lookup(set, :key) == {:ok, :value}
    end

    test  "it returns an error tuple for non-members" do
      assert Set.new(:foo) |> Set.lookup(:key) ==
        {:error, :no_such_element}
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

    test "it records removals in the delta" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :value)
      assert set.delta.removals |> Enum.empty?()

      set =
        set |> Set.remove(:key)

      refute set.delta.removals |> Enum.empty?()
    end
  end

  describe "merge" do
    test "it correctly adds and removes items" do
      replica1 =
        Set.new(:replica1)
        |> Set.add(:removed_element, :value)
        |> Set.add(:remote_element, :value2)
        |> Set.remove(:removed_element)

      replica2 =
        Set.new(:replica2)
        |> Set.add(:local_element, :value3)
        |> Set.merge(replica1.delta)

      assert Set.member?(replica2, :local_element)
      assert Set.member?(replica2, :remote_element)
      refute Set.member?(replica2, :removed_element)
    end

    test "it does not merge deltas that have already been merged" do
        replica1 =
        Set.new(:replica1)
        |> Set.add(:removed_element, :value)
        |> Set.add(:remote_element, :value2)
        |> Set.remove(:removed_element)

      replica2 =
        Set.new(:replica2)
        |> Set.add(:local_element, :value3)
        |> Set.merge(replica1.delta)

      assert replica2 == Set.merge(replica2, replica1.delta)
    end

    test "it does not merge non-contiguous deltas" do
      replica1 =
        Set.new(:replica1)
        |> Set.add(:remoted_element1, :value)
      replica1 =
        %{replica1| delta: Delta.new(:replica1, 1)}
        |> Set.add(:remote_element, :value2)

      replica2 =
        Set.new(:replica2)
        |> Set.add(:local_element, :value3)
        |> Set.merge(replica1.delta)

      assert Set.member?(replica2, :local_element)
      refute Set.member?(replica2, :remote_element)
      refute Set.member?(replica2, :removed_element1)
    end
  end
end
