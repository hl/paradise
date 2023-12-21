defmodule Paradise.Entity do
  @type entity() :: any()
  @callback new(entity(), Keyword.t()) :: entity()
end
