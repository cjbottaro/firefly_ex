# Firefly

Image/asset management for Elixir and Phoenix, heavily influenced by Ruby's
Dragonfly gem.

Primary use case is handling the cropping and thumbnailing of image uploads.

## How it works

The idea is that you store the unaltered image and do the cropping and
thumbnailing on the fly when the image link is requested. Performance is
handled by request caching or a CDN.

Firefly handles the storing of the image (or asset) in customizable storage
backends. It comes with an ETS based storage backend out of the box and there
will be an S3 based one as a separate package.

A plug is provided to serve the images.

## Example

You probably want to see code. Imagine you have a web app that let's people
submit a url of an image and the app fetches that url and displays a thumbnail
of it.

Configure a Firefly "app". Note you can have more than one per project.
```elixir
use Mix.Config
config :firefly, MyFireflyApp,
  storage: Firefly.Storage.Ets,
  plugins: [Firefly.Plugin.ImageMagick],
  url_prefix: "images"

defmodule MyFireflyApp do
  use Firefly.App
end
```

In your controller that receives the url to be fetched.
```elixir
def create(conn, params) do
  uid = MyFireflyApp.new_job
    |> MyFireflyApp.fetch_url(params["url"])
    |> MyFireflyApp.store

  # Use Ecto or something to store the uid.

  redirect conn, to: "/show"
end

def show(conn, params) do
  # Use Ecto or something to retrieve the uid.

  url = MyFireflyApp.new_job
    |> MyFireflyApp.thumb("200x200#")
    |> MyFireflyApp.url

  render conn, "show.html", url: url
end
```

Then in your view...
```elixir
<%= img_tag(@url) %>
```

Finally, setup the plug to serve up the thumbnail.
```elixir
# In router.ex
forward "/images", Firefly.Plug, app: MyFireflyApp
```
