defmodule Buttermilk.Server do
  use GenServer

  import ExTermbox.Constants, only: [key: 1]

  alias ExTermbox.Bindings, as: Termbox
  alias ExTermbox.Cell
  alias ExTermbox.EventManager
  alias ExTermbox.Event
  alias ExTermbox.Position

  require Logger

  @spacebar key(:space)
  @enter key(:enter)

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]

  @initial_state %{response: "", line_buffer: ""}

  def start_link(%{name: name} = state) do
    init_state = Map.merge(@initial_state, state)
    GenServer.start_link(__MODULE__, init_state, name: name)
  end

  def say(to, msg) do
    GenServer.call(to, {:rcv, msg})
  end

  @impl GenServer
  def init(%{name: name} = state) do
    :ok = Termbox.init()
    {:ok, em_pid} = EventManager.start_link(name: :"#{name}_event_mgr")
    :ok = EventManager.subscribe(em_pid, name)

    {:ok, state, {:continue, :draw_screen}}
  end

  @impl GenServer
  def handle_call({:rcv, msg}, _from, state) do
    {:reply, :ok, %{state | response: msg}, {:continue, :draw_screen}}
  end

  @impl GenServer
  def handle_continue(:draw_screen, state) do
    draw_screen(state)
    {:noreply, state}
  end

  def handle_info({:event, %Event{key: key}}, %{line_buffer: line_buffer} = state)
      when key in @delete_keys do
    {:noreply, %{state | line_buffer: String.slice(line_buffer, 0..-2)},
     {:continue, :draw_screen}}
  end

  @impl GenServer
  def handle_info({:event, %Event{key: @enter}}, %{line_buffer: "exit"} = state) do
    {:stop, :normal, state}
  end

  def handle_info({:event, %Event{key: @enter}}, %{line_buffer: line_buffer} = state) do
    # TODO Process commands here
    {:noreply, %{state | response: "Received " <> line_buffer, line_buffer: ""},
     {:continue, :draw_screen}}
  end

  def handle_info({:event, %Event{key: @spacebar}}, %{line_buffer: line_buffer} = state) do
    {:noreply, %{state | line_buffer: line_buffer <> " "}, {:continue, :draw_screen}}
  end

  def handle_info({:event, %Event{ch: char}}, %{line_buffer: line_buffer} = state)
      when char > 0 do
    {:noreply, %{state | line_buffer: line_buffer <> <<char::utf8>>}, {:continue, :draw_screen}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_, %{name: name}) do
    :ok = EventManager.stop(:"#{name}_event_mgr")
    :ok = Termbox.shutdown()
    :ok
  end

  defp draw_screen(%{response: response, line_buffer: line_buffer}) do
    Termbox.clear()

    response
    |> String.to_charlist()
    |> Enum.with_index()
    |> Enum.each(fn {ch, x} ->
      :ok = Termbox.put_cell(%Cell{position: %Position{x: x, y: 0}, ch: ch})
    end)

    "<type a comand or type 'exit' to quit>"
    |> String.to_charlist()
    |> Enum.with_index()
    |> Enum.each(fn {ch, x} ->
      :ok = Termbox.put_cell(%Cell{position: %Position{x: x, y: 2}, ch: ch})
    end)

    ("> " <> line_buffer <> "█")
    |> String.to_charlist()
    |> Enum.with_index()
    |> Enum.each(fn {ch, x} ->
      :ok = Termbox.put_cell(%Cell{position: %Position{x: x, y: 3}, ch: ch})
    end)

    Termbox.present()
  end
end
