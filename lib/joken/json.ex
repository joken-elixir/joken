defmodule Joken.Json do
  alias Poison, as: JSON
  
  def encode(map) do
    JSON.encode!(map)
  end

  def encode!(map) do
    JSON.encode!(map)
  end

  def decode(binary) do
    JSON.decode!(binary, keys: :atoms!)
  end

  def decode!(binary) do
    JSON.decode!(binary, keys: :atoms!)
  end
end