defmodule Firefly.Plugin.ImageMagick do
  use Firefly.Plugin

  alias Firefly.{Job, Utils}

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
    args = thumb_spec_to_args(spec)
    %{job | content: magick(:convert, args, job.content)}
  end

  @doc """
  (processor) Convert image to different format.

  Ex:
  ```
  encode(job, "tiff")
  ```
  """
  @spec encode(Job.t, String.t) :: Job.t
  processor encode(job, format) do
    %{job | content: magick(:convert, "", job.content, format: format)}
  end

  @doc ~S"""
  (processor) Put identifying information in metadata.

  Ex:
  ```
  job = MyApp.fetch_file("~/puppy.png") |> MyApp.identify
  job.metadata.identify # => %{height: 640, size: 582556, type: "PNG", width: 428}
  ```
  """
  @spec identify(Job.t) :: Job.t
  processor identify(job) do
    {size, type, width, height} = :identify
      |> magick(["-format", "%b %m %w %h"], job.content)
      |> String.split
      |> List.to_tuple
    size = String.trim_trailing(size, "B") |> String.to_integer
    width = String.to_integer(width)
    height = String.to_integer(height)
    info = %{size: size, type: type, width: width, height: height}
    metadata = Map.put(job.metadata, :identify, info)
    %{job | metadata: metadata}
  end

  @doc ~S"""
  (processor) Rotate an image.

  Ex:
  ```
  MyApp.fetch_file("~/puppy.png") |> MyApp.rotate(90)
  """
  @spec rotate(Job.t, String.t | integer) :: Job.t
  processor rotate(job, degrees) do
    %{job | content: magick(:convert, "-rotate #{degrees}", job.content)}
  end

  @resize_spec ~r/\A(\d+[%@x]|x\d+|\d+x\d+[\^!><%]?)\z/
  @resize_crop_spec ~r/\A\d+x\d+#(\w{1,2})?\z/
  @crop_offset_spec ~r/\A\d+x\d+[+-]\d+[+-]\d+\z/
  @crop_gravity_spec ~r/\A\d+x\d+\*(\w{1,2})?\z/

  @doc false
  def thumb_spec_to_args(spec) do
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

  defp magick(:identify, args, data) do
    args = normalize_magick_args(args)

    Utils.with_tmpfile(fn file ->
      File.write!(file, data)
      args = ["identify"] ++ args ++ [file]
      err_args = Enum.join(args, " ")
      case System.cmd("magick", args) do
        {output, 0} -> output
        _ -> raise "Command failed: magick #{err_args}"
      end
    end)
  end

  # This is gross and inefficient, but it works for now.
  defp magick(:convert, args, data, options \\ []) do
    args = normalize_magick_args(args)

    Utils.with_tmpfile(2, fn {i_file, o_file} ->
      File.write!(i_file, data)

      # https://stackoverflow.com/a/16689602/788380
      o_file_with_format = if options[:format] do
        options[:format] <> ":#{o_file}"
      else
        o_file
      end
      
      args = ["convert"] ++ args ++ [i_file, o_file_with_format]
      err_args = Enum.join(args, " ")
      case System.cmd("magick", args) do
        {_, 0} -> File.read!(o_file)
        _ -> raise "Command failed: magick #{err_args}"
      end
    end)
  end

  defp normalize_magick_args(args) when is_binary(args), do: String.split(args)
  defp normalize_magick_args(args) when is_list(args), do: args

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
