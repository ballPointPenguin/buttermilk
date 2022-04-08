defmodule Buttermilk do
  @moduledoc """
  Documentation for `Buttermilk`.
  butTERMilk. Get it?
  Example borrowed from https://github.com/ndreynolds/ex_termbox/blob/master/examples/hello_world.exs
  """

  def start(name) do
    {:ok, _pid} = Buttermilk.Server.start_link(%{name: name})
  end
end
