defmodule Mix.Tasks.Vial.SequentialSet.Bench do
  @moduledoc """
  Runs simple benchmarks for merge operations. Based on Phoenix's benchmarks
  for its CRDT.

  ## Examples

  mix vial.set.bench --size 25000 --delta-size 1000
  """
  use Mix.Task
  alias MapSet, as: Set

  def run(opts) do
    {opts, [], []} = OptionParser.parse(opts, strict: [size: :integer,
                                                       delta_size: :integer])
    size       = opts[:size] || 100_000
    topic_size = trunc(size / 10)

    time "Creating 2 #{size} element sets", fn ->
      Enum.reduce(1..size, Set.new(), fn i, acc ->

        Set.put(acc, {"topic#{:erlang.phash2(i, topic_size)}", make_ref()})
      end)

      Enum.reduce(1..size, Set.new(), fn i, acc ->
        Set.put(acc, {"topic#{i}", make_ref()})
      end)
    end
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
