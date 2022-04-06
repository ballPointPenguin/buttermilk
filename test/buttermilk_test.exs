defmodule ButtermilkTest do
  use ExUnit.Case
  doctest Buttermilk

  test "greets the world" do
    assert Buttermilk.hello() == :world
  end
end
