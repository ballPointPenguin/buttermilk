defmodule Buttermilk do
  @moduledoc """
  Documentation for `Buttermilk`.
  butTERMilk. Get it?
  Example borrowed from https://github.com/ndreynolds/ex_termbox/blob/master/examples/hello_world.exs
  """

  def start(name) do
    {:ok, pid} = Buttermilk.Server.start_link(%{name: name})

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end
  end
end
