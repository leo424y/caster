defmodule Caster.Feed.VimCastFeed do
  alias Caster.Repo

  @moduledoc """
  This feed parses the RSS feed for vimcasts and then
  creates records in the database
  """
  def fetch!(client \\ Caster.Feed.VimCastFeed.ProdClient) do
    FeederEx.parse!(client.fetch!)
     |> Map.get(:entries)
     |> Enum.filter(&(Map.get(&1, :enclosure)))
     |> Enum.each(&insert_record_unless_existing/1)
  end

  defp insert_record_unless_existing(%FeederEx.Entry{title: title, enclosure: %{ url: url }, updated: published_date } = _record) do
    case Repo.get_by(Caster.VimCast, url: url) do
      %{id: _id} -> nil
      nil -> insert(title, url)
    end
  end

  defp insert(title, url) do
    %Caster.VimCast{}
      |> Caster.VimCast.changeset(title: title, url: url)
      |> Repo.insert!()
  end

  defmodule ProdClient do
    @behaviour Caster.FeedClient
    @feed_url "http://vimcasts.org/feeds/ogg.rss"

    def fetch! do
      %HTTPoison.Response{body: body} = HTTPoison.get!(@feed_url)
      body
    end

  end

  defmodule TestClient do
    @behaviour Caster.FeedClient
    def fetch! do
      ~s|<?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
          <item>
            <title>Using selected text in UltiSnips snippets</title>
            <description>&lt;p&gt;When UltiSnips is triggered from Visual mode it captures the selection and makes it available to our snippets. We can then insert the selection unchanged with the &lt;code&gt;$VISUAL&lt;/code&gt; placeholder, or we can use UltiSnips Python interpolation to transform the text before inserting it back into the document.&lt;/p&gt;

      </description>
            <enclosure url="http://media.vimcasts.org/videos/68/ultisnips-selections.ogv" length="9878749" type="video/ogg"/>
            <pubDate>Wed, 23 Jul 2014 00:00:00 GMT</pubDate>
            <guid>http://vimcasts.org/episodes/ultisnips-visual-placeholder/</guid>
            <link>http://vimcasts.org/episodes/ultisnips-visual-placeholder/</link>
          </item>
        </channel>
      </rss>
      |
    end
  end
end