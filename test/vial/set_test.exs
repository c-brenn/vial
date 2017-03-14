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

      assert Set.member?(set, :foo, :pid) == false
    end
  end

  describe "add" do
    test "it adds elements" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :pid, :value)

      assert Set.member?(set, :key, :pid)
    end

    test "it does not re-add elements" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :pid, :value)

      s1 = Set.add(set, :key, :pid, :value2)

      assert set == s1 # the version vector is the same
    end

    test "it records additions in the delta" do
      set = Set.new(:foo)
      assert set.delta.additions |> Enum.empty?()
      set =
        set
        |> Set.add(:key, :pid, :value)

      refute set.delta.additions |> Enum.empty?()
    end
  end

  describe "remove" do
    test "it does nothing for non-existent elements" do
      set = Set.new(:foo)
      s1  =  Set.remove(set, :key, :pid)

      assert set == s1
    end

    test "it removes elements" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :pid, :value)
        |> Set.remove(:key, :pid)

      refute Set.member?(set, :key, :pid)
    end

    test "it records removals in the delta" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :pid, :value)
      assert set.delta.removals |> Enum.empty?()

      set =
        set |> Set.remove(:key, :pid)

      refute set.delta.removals |> Enum.empty?()
    end

    test "it does not remove elements with the same key" do
      set =
        Set.new(:foo)
        |> Set.add(:key, :removed, :value)
        |> Set.add(:key, :kept, :value)
        |> Set.remove(:key, :removed)

      assert Set.member?(set, :key, :kept)
      refute Set.member?(set, :key, :removed)
    end
  end

  describe "merge" do
    test "it correctly adds and removes items" do
      replica1 =
        Set.new(:replica1)
        |> Set.add(:removed_element, :removed_pid, :value)
        |> Set.add(:remote_element, :remote_pid, :value)
        |> Set.remove(:removed_element, :removed_pid)

      replica2 =
        Set.new(:replica2)
        |> Set.add(:local_element, :local_pid, :value)
        |> Set.merge(replica1.delta)

      assert Set.member?(replica2, :local_element, :local_pid)
      assert Set.member?(replica2, :remote_element, :remote_pid)
      refute Set.member?(replica2, :removed_element, :removed_pid)
    end

    test "it does not merge deltas that have already been merged" do
        replica1 =
        Set.new(:replica1)
        |> Set.add(:removed_element, :pid, :value)
        |> Set.add(:remote_element, :value2, :pid)
        |> Set.remove(:removed_element, :pid)

      replica2 =
        Set.new(:replica2)
        |> Set.add(:local_element, :value3, :pid)
        |> Set.merge(replica1.delta)

      assert replica2 == Set.merge(replica2, replica1.delta)
    end

    test "it does not merge non-contiguous deltas" do
      replica1 =
        Set.new(:replica1)
        |> Set.add(:before_delta, :pid, :value)

      replica1 =
        %{replica1| delta: Delta.new(:replica1, 1)}
        |> Set.add(:in_delta, :pid, :value)

      replica2 =
        Set.new(:replica2)
        |> Set.add(:local_element, :pid, :value)
        |> Set.merge(replica1.delta)

      assert Set.member?(replica2, :local_element, :pid)
      refute Set.member?(replica2, :before_delta, :pid)
      refute Set.member?(replica2, :in_delta, :pid)
    end
  end
end
