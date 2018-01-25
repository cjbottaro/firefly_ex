defmodule Firefly.Plugin.ImageMagick do
  use Firefly.Plugin

  alias Firefly.Job

  @doc ~S"""
  (processor) Create a thumbnail by resizing and/or cropping.

  `spec` can be described in the following examples:

  ```txt
  200%        Height and width both scaled by specified percentage.
  200@        Resize image to have specified area in pixels. Aspect ratio is preserved.
  300x        Width given, height automagically selected to preserve aspect ratio.
  x300        Height given, width automagically selected to preserve aspect ratio.

  200x300     Maximum values of height and width given, aspect ratio preserved.
  200x300^    Minimum values of width and height given, aspect ratio preserved.
  200x300!    Width and height emphatically given, original aspect ratio ignored.
  200x300>    Shrinks an image with dimension(s) larger than the corresponding width and/or height argument(s).
  200x300<    Enlarges an image with dimension(s) smaller than the corresponding width and/or height argument(s).
  100x200%    Height and width individually scaled by specified percentages.

  400x300#    Resize, crop if necessary to maintain aspect ratio (center gravity).
  400x300#ne  Same as above, but with northeast gravity.

  400x300*    Crop with center gravity.
  400x300*ne  Crop with northeast gravity.
  ```
  """
  @spec thumb(Job.t, String.t) :: Job.t
  processor thumb(job, spec) do
    content = spec
      |> spec_to_args
      |> convert(job.content)
    %{job | content: content}
  end

  @resize_spec ~r/\A(\d+[%@x]|x\d+|\d+x\d+[\^!><%]?)\z/
  @resize_crop_spec ~r/\A\d+x\d+#(\w{1,2})?\z/
  @crop_offset_spec ~r/\A\d+x\d+[+-]\d+[+-]\d+\z/
  @crop_gravity_spec ~r/\A\d+x\d+\*(\w{1,2})?\z/

  @doc false
  def spec_to_args(spec) do
    cond do
      Regex.match?(@resize_spec, spec) -> "-resize #{spec}"
      Regex.match?(@resize_crop_spec, spec) -> resize_crop_args(spec)
      Regex.match?(@crop_offset_spec, spec) -> "-crop #{spec}"
      Regex.match?(@crop_gravity_spec, spec) -> crop_gravity_args(spec)
    end
  end

  defp resize_crop_args(spec) do
    {geometry, gravity} = String.split(spec, "#") |> List.to_tuple
    gravity = full_gravity(gravity)
    "-resize #{geometry}^ -crop #{geometry}+0+0 -gravity #{gravity}"
  end

  defp crop_gravity_args(spec) do
    {geometry, gravity} = String.split(spec, "*") |> List.to_tuple
    gravity = full_gravity(gravity)
    "-crop #{geometry}+0+0 -gravity #{gravity}"
  end

  # This is gross and inefficient, but it works for now.
  defp convert(args, data) do
    alias Firefly.Utils
    i_file = Utils.tmpfile
    o_file = Utils.tmpfile
    try do
      File.write!(i_file, data)
      args = "convert #{args} #{i_file} #{o_file}" |> String.split
      case System.cmd("magick", args) do
        {_, 0} -> File.read!(o_file)
        _ -> raise "Command failed: magick #{args}"
      end
    after
      File.rm(i_file)
      File.rm(o_file)
    end
  end

  @gravity_map %{
    "nw" => "NorthWest",
    "n"  => "North",
    "ne" => "NorthEast",
    "w"  => "West",
    "c"  => "Center",
    "e"  => "East",
    "sw" => "SouthWest",
    "s"  => "South",
    "se" => "SouthEast"
  }

  defp full_gravity(""), do: full_gravity("c")
  defp full_gravity(gravity) do
    @gravity_map[String.downcase(gravity)]
      || raise("Invalid gravity: #{gravity}")
  end

end
