## Introduction
A while ago, I made a music review aggregation app I called Aggr. You can find it at https://aggr-music.herokuapp.com/ . The concept is simple: every day, the scraper visits the RSS feeds of a few music review sites, collects the data that I care about, and builds a JSON object containing an array of reviews. Then, when you visit the page, you are served that JSON file formatted into an HTML table for easier browsing.

And it works! I've made moderate changes to it since, and it still has the occasional bug or two, but nothing that I care about since I'm the primary consumer of this data.

But now I've been reading about Haskell. And I've been thinking about how I might eliminate some hidden bugs just by writing in a strongly typed, fully functional language. And I want to make something with it.

So I decided to re-write the part that generates the JSON in Haskell. And because I'm still quite green, I decided to write out my process in a series of articles. Though I'll be putting some massive ignorance on display, I'll also be showing what I'm learning in hopes that it might be helpful to you, Dear Reader.

## Prerequisites

I will assume some familiarity with Haskell and will not explain the very basics. I will try to explain the libraries I use and my thought process for writing the code I do. If you're completely new to Haskell, I recommend [Haskell Programming from First Principles](http://haskellbook.com/). It's a massive book, but you'll be productive long before you finish the book.

## How To Start

Depending on what idioms you've learned, you may start your new projects differently. Some people do the TDD style of just working with the minimal code and only adding libraries as you need them, others create a complete scaffolding of folders so that they stay organized from the start.

I tend to focus on somewhere in the middle, where I don't create a whole lot of files, but I do like to think about which libraries I'll need. That way I'm not as inclined to go shopping for libraries in the middle of my project. And with a project like this, where I'm translating an existing project over, I have a good idea of what I'll need already.

Before doing anything, I'll start a new stack project

	stack new aggr-haskell simple

Because I'm only creating a simple binary to execute, and not a library or an enterprise application, I pass the 'simple' argument. It gives me less surface area to think about.

Once that resolves, I'll open my `.cabal` file and add the libraries I think I'll need. But let's talk that through.

## External libraries

The first thing I know I'll need is some way to read in data from a URL. For this, I've opted to use `http-conduit` and [`http-client`](https://haskell-lang.org/library/http-client). Full disclosure, I don't know if I need both, but I pulled them in, just in case. I can always remove one if I find out I don't use it later.

Next, I need some way of interpreting that incoming data as XML. And so I pulled in [`xml-conduit`](https://www.yesodweb.com/book/xml), mostly because I found the tutorial to be thorough enough to address what I'll be trying to do. You'll notice that it links to the Yesod Web Framework, to whose family I'm guessing this library belongs, but we're not going to use a full framework, mostly because we don't need it.

Skipping some details, I know that after some parsing and checking that I will want my outgoing data to be JSON. While I could totally just write back my data as XML, the original project used JSON because JavaScript and JSON play nicely together. Plus, it's just much easier to work with in a Node environment. I'm already familiar with how simple and amazing (`aeson`)[http://hackage.haskell.org/package/aeson-1.4.1.0/docs/Data-Aeson.html) is. Plus, I found [a thorough tutorial on `aeson`](https://artyom.me/aeson) that seemed able to help if I hit any sticky situations.

For everything else:

* To work with parsing and formatting dates: [`time`](http://hackage.haskell.org/package/time-1.9.2/docs/Data-Time.html)
* Because several libraries prefer Text over Strings for performance reasons: ['text'](http://hackage.haskell.org/package/text-1.2.3.1/docs/Data-Text.html)
* When trying to figure out how to glue `http-client` and `xml-conduit` together, I noticed they both talked in bytestrings (another way of representing textual data): ['bytestring'](http://hackage.haskell.org/package/bytestring-0.10.8.2/docs/Data-ByteString.html)
** If the difference between Text, Strings, and Bytestrings is lost on you, I recommend [this tutorial on Haskell's string types](https://mmhaskell.com/blog/2017/5/15/untangling-haskells-strings)

With that said, this is what my `build-depends` looks like in my .cabal file:

	  build-depends: base >= 4.7 && < 5
            	 , aeson
                     , bytestring
                     , http-client
                     , http-conduit
                     , text
                     , time
                     , xml-conduit

## Reading data over HTTP

To keep matters simple, we'll start with one of the sites I read in, [Pitchfork](https://pitchfork.com/). [People have opinions about Pitchfork](https://entertainment.theonion.com/pitchfork-gives-music-6-8-1819569318), but we'll set those aside here. What works for our purposes is that [Pitchfork provides an XML RSS feed](https://pitchfork.com/rss/reviews/albums/) that we can consume.

In our main method, we can remove the boilerplate "hello world" and try to read in the feed. Like I said earlier, I had a hard time figuring out how to get `http-client` and `xml-conduit` to talk to one another, so I started with byestrings:

	{-# LANGUAGE OverloadedStrings #-}
	module Main where

	import Network.HTTP.Simple

	main :: IO ()
	main = do
	  response <- httpLBS "https://pitchfork.com/rss/reviews/albums/"
	  print $ getResponseBody response

Running this, I was able to see the XML from the site in a string representation. Good first step! To run the code:

* I build the code: `stack build`
* I run the executable: `stack exec aggr-haskell`

The reason we added the OverloadedStrings language extension is that `httpLBS` expects a `Request` type. And while we could pass the URL string to `parseRequest`, OverloadedStrings takes care of string literal conversions for types that can handle it, like Request. If that feels like magic to you, please feel free to utilize `parseRequest`, although I'll be making good use of OverloadedStrings throughout so it may be worth starting with [a basic introduction to OverloadedStrings](https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/guide-to-ghc-extensions/basic-syntax-extensions#overloadedstrings) and working from there.

For the curious, with `parseRequest` it would look like:


	module Main where

	import Network.HTTP.Simple

	main :: IO ()
	main = do
	  request <- parseRequest "https://pitchfork.com/rss/reviews/albums/"
	  response <- httpLBS request
	  print $ getResponseBody response

## Treating data as XML

While we have the XML as a string, we'd like to be able to treat it as XML. What do I mean by that? What I'd like to do is traverse over the XML structure and find the bits of data that are important to me and pull them out. Right now, with the data as it is, I don't have any easy way to do it.

`xml-conduit` provides two datatypes that will be important to us: `Document` and `Cursor`. There are others within the library like `Axis` that we will be using but not on the surface, so they're not as important to our current understanding.

A `Document` is a full representation of the XML Document, complete with types representing all of the data and metadata. If we were staying within the XML space (that is, our output would also be XML or HTML), then we could probably make use of the Document and it's subtypes and get a lot of mileage. But we're not interested in the XML as much as the data therein.

That's where `Cursor` comes in. A `Cursor` is a node that knows its own location in the XML tree. That means that we can move around from this starting point to get to specific nodes or text within the XML document.

To get there, we'll need to make some conversions:

	{-#LANGUAGE OverloadedStrings #-}
	module Main where

	import Network.HTTP.Simple
	import Text.XML
	import Text.XML.Cursor

	main :: IO ()
	main = do
	  response <- httpLBS "https://pitchfork.com/rss/reviews/albums/"
	  let document = parseLBS_ def (getResponsebody response)
	  let cursor = fromDocument document
	  print cursor

Building and executing, we can see our same XML data but built up as Haskell data types. Don't worry about understanding everything going on. You don't have to think about the data in this format. We can still reason about the structure by looking at the XML data.

## XML to JSON

So, what we have right now is XML represented by Haskell datatypes. What we would like is to write some of that into JSON. But we don't want to think about the data we're writing to JSON as XML nodes and elements, we'd like to think about it in terms of the types the JSON is representing. And what is the JSON representing? A list of albums.

You may be thinking, "yeah, we know what the data represents, but in the ends, it's just strings, arrays, and objects, so why get bogged down by types we're just going to lose in the JSON anyways?" Or maybe not. One aspect of the JavaScript version of this project was that there was no such thing as an "Album with a capital A". We just read in the XML, parsed it into JavaScript objects, and then let JSON.parse() take care of the rest. We did that because we didn't want to have to think about how to translate something like a class into JSON because it added additional complexity that wasn't needed.

That isn't the case with Haskell, and especially with `aeson`. What makes `aeson` such a breeze to work with is that it has the ability to define JSON conversions for Haskell datatypes with very little work on our part. And it does so with the notion of a `Generic`. But we'll set that aside for now and think about our data.

## What is an Album?

Let's think about what we want the data to look like. An album for our purposes has three attributes: an artist, a title, and a release date. The artist and title are obvious enough, but the reason we care about the release date is that our JSON at the end should only contain albums released this month. If you look at [the aggr website](https://aggr-music.herokuapp.com/), you'll see that each page is broken out into months. I did that because 1) I only wanted to focus on a small chunk of albums at a time, and 2) the RSS feeds we consume don't keep all old data so we need some way of preserving historical data.

In Haskell, that would look like this:

	data Album
	  = Album
	  { artist :: Text
	  , title    :: Text
	  , date  :: Text
	  } deriving (Eq, Show)

We derive Show because we want to be able to print out the album representations and make sure we're on the right path. We derive Eq because we're going to want to remove duplicate representations when we have multiple sites pulled in and they both have the same album. This is definitely a far-future concern, but one we can address right now with little thought.

You might be wondering why we're treating the date as Text and not a Date type. Initially, this was because I wanted to output the JSON representation in a particular format. Also, I didn't know much about the datatypes that the `time` library gave me and I was scared to commit to one. Later in the series, we'll look at how to better represent a date.

## Album to JSON

Next, we'd like to know how to translate this representation to JSON. After all, I said it would be easy, right? I'll give you the updated file and then we'll work from there:

	{-# LANGUAGE DeriveGeneric #-}
	{-# LANGUAGE OverloadedStrings #-}
	module Main where

	import Data.Aeson
	import Data.Text (Text)
	import GHC.Generics
	import Network.HTTP.Simple
	import Text.XML
	import Text.XML.Cursor

	data Album
	  = Album
	  { artist :: Text
	  , title   :: Text
	  , date  :: Text
	  } deriving (Generic, Eq, Show)

	instance ToJSON Album where
	  toEncoding = genericToEncoding defaultOptions

	-- main is the same as above

The first change you'll notice is the language extension for `DeriveGeneric`. I will not pretend to understand how Generics work. What I do know is that `aeson` takes advantage of Haskell's Generics for simple JSON translation.

We imported Data.Aeson so that we could make use of its magic, Data.Text (Text) so that we could label our Text fields, and GHC.Generics so that we could make use of Generics.

To our Album datatype, in the deriving section, we added `Generic`. This was why we added `DeriveGeneric` so that we do that here without having to write out boilerplate for the conversion.

Finally, our Album instance of the ToJSON typeclass makes use of some defaults given to use by `aeson`. The `genericToEncoding` takes a Generic representation and converts it to JSON. The `defaultOptions` are, well, the default options you can pass to it because we don't need any configuration.

And that's it. The addition of Generics might hurt your head a little bit, and you might be worried if you don't fully understand them. I'm saying, for our purposes, you don't need to understand all that's going on under the hood. You just need to know that we pulled in these things that `aeson` could do the heavy lifting for us.

### What if I need configuration?

While `aeson` provides some nice defaults, there are plenty of ways you can customize the ToJSON conversion, and whatever you'll need. The tutorial I mentioned above for `aeson` is very helpful in that regard.

## XML -> Album

So now that we have a way to get from an HTTP request to XML, and a way to get from an Album to JSON, we just need to glue those together. I saved this for last because, unlike everything up to this point, this will require writing out and reasoning about code. We'll still make use of the libraries we've pulled in, but we've got to figure out how to make them work in harmony. Or at least to the best of my ability.

### XML -> Text

The more appropriate title would be "Cursor -> Text", but you get the idea. We have this cursor for traversing the structure of an XML document. But what do we want to pull out?

If we look at the XML for the feed, we see that we have a top-level "rss" element containing a "channel" element that contains all of the RSS data. Then, after some initial data, we see a recurring "item" element. In each item element, we have two nodes we care about: "title" and "pubDate". Looking at the title, we see that it contains both the artist and the album title, so we'll have to figure out how to split those apart, but we'll start with fetching them.

Looking at [the xml-conduit tutorial](https://www.yesodweb.com/book/xml), under the "Cursor" section, we see how we can use a series of custom operators to get from a cursor to an element's text. So, for our title and artist, we could do:

	let albumArtist = cursor $// element "item" &/ element "title" &// content

Let's try to break down what each operator is doing for us:

* The `$//` operator takes a `Cursor` and an `Axis` to then move the cursor to that position in the XML.
* `element "item"` defines an `Axis` for us to find: the "item" elements. So as this point, we are working with a list of all the item element in the XML document
* The `&/` operator takes the Axis and another Axis to move to the first instance of that element.
* `element "title" defines an `Axis` for the title element. We have essentially mapped over our "item" elements list to make it a list of their titles.
* The `&//` operator "applies the Axis to all the descendants". Wait, wait, I'll explain!
* `content` gets all of the content from our current point downward. So, combined with &//, what it means is that we are stopping our digging, and just converting everything from within this node inward into Text.

Phew! That's a lot of information. And believe me, I did not understand that when I first used these operators. I just looked a the tutorial, saw they worked and applied them to my situation. When first working with a library, I believe that's perfectly valid way of approaching it. It's only when you need more than what the base cases show that you'll need to dig in and learn enough to progress.

We can use a similar operator to get to the pubDates, which is what we're considering the release date.

	let date = cursor $// element "item" &/ element "pubDate" &// content

The only differences here are the name of our variable and the "pubDate" element.

You may be wondering if we could store an intermediate value for the section from the cursor to element "item" since those are repeated in both. I believe that you can! I just haven't figured out how to do it. If any reader wishes to tell me how I'd be happy to hear you out. I'll provide contact details at the end of the tutorial.

### Splitting text

Now that we have each of the titles, we would like to split those out into a separate artist and title. There are so many ways to do this, and the way I'm about to do it may not be the best way, but it was the way I did it at the time (optimizations will be left for future articles).

Those familiar with Haskell will know that Text has a `splitOn` method, which takes a sample of Text that we want to use for where to split:

	let albumArtist = cursor $// element "item" &/ element "title" &// content
	let albumArtistSplit = map T.splitOn ": " albumArtist

This leaves us with a list of list of Text. We could probably work with this, but I'm going to make my life a little easier and create another function for us to map with:

	toAlbumAwaitingDate :: [Text] -> (Text -> Album)
	toAlbumAwaitingDate [a, t]        = Album a t
	toAlbumAwaitingDate [a]           = Album a ""
	toAlbumAwaitingDate [a, t1, t2] = Album a (t1 <> ": " <> t2)
	toAlbumAwaitingDate _             = error "Unknown format"

As you can see, this is meant to take a list of text and return a function that awaits more text. That text it's awaiting is our date. The first two cases probably make sense: if we get a list with two elements, that's the artist and title. If we get a list with one element, that's the artist (maybe, I didn't run into this case yet).

The third one is if we have three elements in the list. Since we split on ": ", this probably means that we accidentally cut a title containing a colon in half, so we're appending it back together. Rather than try to use some internal Text-specific operator, we can take advantage of the fact that Text has a Monoid instance and use it's `mappend` (aliased to the `<>` operator internally). It's similar to the `++` operator for lists, but much more powerful. If Monoid is a new or scary word, [the Typeclassopedia entry on Monoids](https://wiki.haskell.org/Typeclassopedia#Monoid) may be helpful.

 Finally, we provide a bottom case that throws an error. We don't want to ignore other formats, we want to support new ones as they come. There may be a more generalized and intelligent approach, but this one works for us in the here and now and isn't too complicated.

 To make use of this function, we'll compose it with our `splitOn` in the map:

 	let albumArtist = cursor $// element "item" &/ element "title" &// content
 	let albumsAwaitingDate = map (toAlbumAwaitingDate . T.splitOn ": ") albumArtist

Along with datatypes, the ability elegantly compose functions together like this is one of the main reasons I fell for Haskell. You can bring in libraries like [Ramda](https://ramdajs.com/) in your JavaScript, but Ramda seeks to operate more like Clojure, which can add a lot of additional friction if you're not comfortable with Lisps. I tried bringing Ramda into the JavaScript version of aggr, but I found the resulting code less clear in some places.

### Formatting dates

The same way we mapped over our artist and titles to get them in the format we wanted, we can do the same with our collection of dates. In order to help, we'll pull in the `time` library:

	-- Add to our list of imports
	import Data.Time
	import Data.Time.Format

Data.Time will give us the method `parseTimeM`, which we will use to get out a date object of some kind. At this junction, I decided on `UTCTime`, which also comes from Data.Time. `parseTimeM` is not like some flexible date time parsers that will accept almost any format and convert it for us automatically. We need to tell it the exact format of what we're expecting in, and what type we'd like to convert it to. For the dates we get from the Pitchfork RSS feed:

	toUTCTime :: String -> Maybe UTCTime
	toUTCTime = parseTimeM True defaultTimeLocale "%a, %d %b %Y %X %z"

The True is just telling the parser that we'll accept leading and trailing whitespace. The defaultTimeLocale is for American usage, which works for our case. Those familiar with date formats in C-like languages will recognize the format string passed as the last argument. This tells the parser the exact shape of the incoming dates.

You'll notice that instead of just giving us a UTCTime, it gives us a Maybe UTCTime. This means that, if the parser does not recognize the input, it will return `Nothing`, and it it does, it will return `Just d`, where d is our UTCTime object. This is a nice alternative to errors because it allows us to continue executing code even if the parser doesn't understand what came in.

We'll make use of `toUTCTime` in our formatting function:

	toDate :: Text -> Text
	toDate d = case toUTCTime (T.unpack d) of
	  Nothing -> ""
	  Just d' -> T.pack $ formatTime defaultTimeLocale "%b %d"

In order to pass the Text variable into toUTCTime, we needed to `unpack` it, which converts it to a String. If we had passed a string literal, we would not have needed to do that. In the case of Nothing, we're just going to return an empty string for now. When we actually get something back, we're going to use `formatTime` from Data.Time.Format, which operates similarly to `parseTimeM`, except we define the shape of our outputted date in the format string.

Converting Text to UTCTime to Text may feel silly on the surface. And in some ways it is. We should leave things like date formatting to the consuming code, not our JSON. But this is the choice I made at the time, so we'll live with it for now.

So to use our `toDate`, we can do:

	let date = map toDate $ cursor $// element "item" &/ element "pubDate" &// content

Notice we just passed the results of the XML traversal to our mapper. We could have done it in our artist and title example too, but I felt like it was too much going on for one line.

### Building our Albums

We now have two lists: one of the Albums awaiting dates, and one of the dates. Because they were all pulled from the same ordered source, we know that each element matches at their respective indexes. Because of this, we can make use of a core library function, `zipWith`. `zipWith` expects a function that knows how to combine elements from each list and two lists. The arguments to the `zipWith` lambda will be in the same order as which lists you pass to the rest of the function:

	let albums = zipWith (\album date -> album date) albumsAwaitingDate date

This is why we wrote our `toAlbumsAwaitingDate` function the way we did so that zipping in the dates will leave us with the complete albums we want. In the lambda, `album` is a function and `date` is the last Text we are passing to it if that's not clear.

### Exporting the JSON

We covered that we can easily convert Albums to JSON. But now comes a matter of HOW.

In the original JS project, we just wrote it out to a file called `album.json`, so we're just going to do that. `aeson` provides a convenient method for encoding to a file called `encodeFile`:

	let albums = zipWith (\album date -> album date) albumsAwaitingDate date
	encodeFile "albums.json" albums

That's it! If we build and run the executable, we won't see any output in the terminal, but we should see a new `albums.json` file, containing our JSON-formatted album data.

## Conclusion
For the first part, we covered a lot of ground! We covered small parts of a number of helpful libraries, wrote our own basic datatype and ToJSON instance. In terms of projects, we have gone from zero to something functionally complete!

In future articles, we will add additional feeds to our data, look at filtering our data based on various criteria, and other refactors as I think of them. This is still a work in progress, so this won't be the most organized series, but I'll try to explain how I got to where I am at each stage, why I make the choices and changes I'll make. It should be a learning process for both of us!

If you see any obvious flaws in the code, please feel free to submit a pull request or file a bug on [the git repo](https://github.com/blrobin2/aggr-haskell/).

## Full Code (for now)

You can also [view the current code on GitHub](https://github.com/blrobin2/aggr-haskell/commit/5e162321673498bbec3a8832b70b20d481ba7075). Note: it will look slightly different than what I've presented here due to choices I made in the process of writing the article.

	{-# LANGUAGE DeriveGeneric #-}
	{-# LANGUAGE OverloadedStrings #-}
	module Main where

	import           Data.Aeson
	import           Data.Text (Text)
	import qualified Data.Text as T
	import           Data.Time
	import           Data.Time.Format
	import           GHC.Generics
	import           Network.HTTP.Simple
	import           Text.XML
	import           Text.XML.Cursor

	data Album
	  = Album
	  { artist :: Text
	  , title  :: Text
	  , date   :: Text
	  } deriving (Generic, Eq, Show)

	instance ToJSON Album where
	  toEncoding = genericToEncoding defaultOptions

	toAlbumAwaitingDate :: [Text] -> (Text -> Album)
	toAlbumAwaitingDate [a, t]       = Album a t
	toAlbumAwaitingDate [a]          = Album a ""
	toAlbumAwaitingDate (a:t1:t2:[]) = Album a (t1 <> ": " <> t2)
	toAlbumAwaitingDate _            = error "Unknown format"

	toUTCTime :: String -> Maybe UTCTime
	toUTCTime = parseTimeM True defaultTimeLocale "%a, %d %b %Y %X %z"

	toDate :: Text -> Text
	toDate d = case toUCTTime (T.unpack d) of
	  Nothing -> ""
	  Just d'  -> T.pack $ formatTime defaultTimeLocale "%b %d %Y" d'

	main :: IO ()
	main = do
	  response <- httpLBS "https://pitchfork.com/rss/reviews/albums/"
	  let document = parseLBS_ def (getResponseBody response)
	  let cursor   = fromDocument document
	  let albumArtist = cursor $// element "item" &/ element "title" &// content
	  let date = map toDate $ cursor $// element "item" &/ element "pubDate" &// content
	  let albumsAwaitingDate = map (toAlbum . T.splitOn ": ") albumArtist

	  let albums = zipWith (\a d -> a d) albumsAwaitingDate date
	  encodeFile "albums.json" albums
