defmodule Firefly.Configuration do
  def init do
    Application.get_all_env(:firefly)
    |> Enum.each(fn {repo, options} ->
      case repo do
        :included_applications -> nil
        _ -> configure(repo, options)
      end
    end)
  end

  defp configure(repo, options) do
  end
end
