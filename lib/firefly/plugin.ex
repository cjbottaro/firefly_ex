defmodule Firefly.Plugin do

  defmacro __using__(_) do
    quote do
      import Firefly.Plugin
      Module.register_attribute(__MODULE__, :generators, accumulate: true)
      Module.register_attribute(__MODULE__, :processors, accumulate: true)
      Module.register_attribute(__MODULE__, :analyzers, accumulate: true)
      @before_compile Firefly.Plugin
    end
  end

  alias Firefly.Job

  defmacro generator(expr, do: block) do
    {name, meta, args} = expr
    expr = {name, meta, List.delete_at(args, 0)}
    apply_expr = {:"apply_#{name}", meta, args}

    quote do

      @generators unquote(name)

      def unquote(expr) do
        Job.new |> Job.add_step(__MODULE__, unquote(name), unquote(elem(expr, 2)))
      end

      def unquote(apply_expr) do
        unquote(block)
      end

      @doc false
      def __firefly_type(unquote(name)), do: :generator

    end
  end

  defmacro processor(expr, do: block) do
    {name, meta, args} = expr
    job_args = List.delete_at(args, 0)
    apply_expr = {:"apply_#{name}", meta, args}

    quote do

      @processors unquote(name)

      def unquote(expr) do
        Job.add_step(var!(job), __MODULE__, unquote(name), unquote(job_args))
      end

      @doc false
      def unquote(apply_expr) do
        unquote(block)
      end

      @doc false
      def __firefly_type(unquote(name)), do: :processor

    end
  end

  defmacro analyzer(expr, do: block) do
    {name, meta, args} = expr
    job_args = List.delete_at(args, 0)
    apply_expr = {:"apply_#{name}", meta, args}

    quote do

      @analyzers unquote(name)

      def unquote(expr) do
        Job.add_step(var!(job), __MODULE__, unquote(name), unquote(job_args))
      end

      @doc false
      def unquote(apply_expr) do
        unquote(block)
      end

      @doc false
      def __firefly_type(unquote(name)), do: :analyzer

    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc false
      def generators, do: @generators
      @doc false
      def processors, do: @processors
      @doc false
      def analyzers, do: @analyzers
    end
  end

end
