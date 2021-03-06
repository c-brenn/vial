defmodule Mix.Tasks.Vial.Set.Bench do
  @moduledoc """
  Runs simple benchmarks for merge operations. Based on Phoenix's benchmarks
  for its CRDT.

  ## Examples

  mix vial.set.bench --size 25000 --delta-size 1000
  """
  use Mix.Task
  alias Vial.{Delta, Set, Vector}

  def run(opts) do
    {opts, [], []} = OptionParser.parse(opts, strict: [size: :integer,
                                                       delta_size: :integer])
    size       = opts[:size] || 100_000
    delta_size = opts[:delta_size] || 10000
    topic_size = trunc(size / 10)

    {s1, s2} = time "Creating 2 #{size} element sets", fn ->
      s1 = Enum.reduce(1..size, Set.new(:s1), fn i, acc ->

        Set.add(acc, "topic#{:erlang.phash2(i, topic_size)}", make_ref(), %{name: i})
      end)

      s2 = Enum.reduce(1..size, Set.new(:s2), fn i, acc ->
        Set.add(acc, "topic#{i}", make_ref(), %{name: i})
      end)

      {s1, s2}
    end
    user = make_ref()
    s1 = Set.add(s1, "topic100", user, %{name: 100})

    delta = time "extracting #{size} element set", fn ->
      Delta.extract(s2)
    end

    s1 = time "merging 2 #{size} element sets", fn ->
      Set.merge(s1, delta)
    end

    s1 = time "merging again #{size} element sets", fn ->
      Set.merge(s1, delta)
    end

    s = time "get_by_topic for 1000 members of #{size * 2} element set", fn ->
      Set.list(s1, "topic10")
    end


    # [{{topic, pid, key}, _meta, _tag} | _] = time "get_by_pid/2 for #{size * 2} element set", fn ->
    #   State.get_by_pid(s1, user)
    # end

    # time "get_by_pid/4 for #{size * 2} element set", fn ->
    #   State.get_by_pid(s1, pid, topic, key) || raise("none")
    # end

    # s1 = State.compact(s1)
    # s2 = State.compact(s2)
    # s2 = State.reset_delta(s2)

    additions = Enum.with_index(delta.additions) |> Enum.take(delta_size)

    s2 = %{s2| delta: Delta.new(s2.actor, Vector.clock(s2.vector, s2.actor) - 1)}

    s2 = time "Creating delta with #{delta_size} joins and leaves", fn ->
      additions
        |> Enum.reduce(s2, fn {addition, i}, acc ->
        {key, pid, _, _} = addition

        acc
        |> Set.add(make_ref(), "delta#{i}:user#{i}", %{name: i})
        |> Set.remove(key, pid)
      end)
    end

    time "Merging delta with #{delta_size} joins and leaves into #{size * 2} element set", fn ->
      Set.merge(s1, s2.delta)
    end

    # {s1, _, _} = time "replica_down from #{size *2} replica with downed holding #{size} elements", fn ->
    #   State.replica_down(s1, s2.replica)
    # end

    # _s1 = time "remove_down_replicas from #{size *2} replica with downed holding #{size} elements", fn ->
    #   State.remove_down_replicas(s1, s2.replica)
    # end
  end

  defp time(log, func) do
    IO.puts "\n>> #{log}..."
    {micro, result} = :timer.tc(func)
    ms = Float.round(micro / 1000, 2)
    sec = Float.round(ms / 1000, 2)
    IO.puts "   = #{ms}ms    #{sec}s    #{micro}us"

    result
  end
end
