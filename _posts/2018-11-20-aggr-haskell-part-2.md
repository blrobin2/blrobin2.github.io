---
layout: post
title: "A Beginning Haskeller Builds a Web Scraper (Part 2)"
excerpt: "A journey into Haskell, and my failings along the way"
category: programming
---
### Previously On...

In the [previous article]({% post_url 2018-11-12-aggr-haskell-part-1 %}), we built a web scraper that reads in an RSS Feed, translates it to an XML DSL in order to traverse it and collect relevant data, and translated that data into a custom Album datatype that we can use to export the data as JSON.

That's a lot!

In this article, we're going to tackle the following objectives:

* Clean up our code
* Pull in a second RSS feed
* Introduce an optional score field to our Album datatype

Let's get started!

### Clean Up Our Code

For convenience sake, let's look at how we left our code last article:

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

    data Album = Album
      { artist :: Text
      , title  :: Text
      , date   :: Text
      } deriving (Generic, Eq, Show)

    instance ToJSON Album where
      toEncoding = genericToEncoding defaultOptions

    toAlbumAwaitingDate :: [Text] -> (Text -> Album)
    toAlbumAwaitingDate [a, t]      = Album a t
    toAlbumAwaitingDate [a]         = Album a ""
    toAlbumAwaitingDate [a, t1, t2] = Album a (t1 <> ": " <> t2)
    toAlbumAwaitingDate _           = error "Unknown format"

    toUTCTime :: String -> Maybe UTCTime
    toUTCTime = parseTimeM True defaultTimeLocale "%a, %d %b %Y %X %z"

    toDate :: Text -> Text
    toDate d = case toUCTTime (T.unpack d) of
      Nothing -> ""
      Just d' -> T.pack $ formatTime defaultTimeLocale "%b %d %Y" d'

    main :: IO ()
    main = do
      response <- httpLBS "https://pitchfork.com/rss/reviews/albums/"
      let document = parseLBS_ def (getResponseBody response)
      let cursor   = fromDocument document
      let albumArtist = cursor
                $// element "item"
                &/  element "title"
                &// content
      let date = map toDate $ cursor
                $// element "item"
                &/  element "pubDate"
                &// content
      let albumsAwaitingDate = map ( toAlbumAwaitingDate
                                . T.splitOn ": "
                                ) albumArtist

      let albums = zipWith (\album date -> album date) albumsAwaitingDate date
      encodeFile "albums.json" albums

Even if we weren't going to do anything else with our code, we'd still probably want to pull all that code out of the `main` function. Why? The biggest reason is, if we ever wanted to test this code, we would have a hard time getting to it without having to kick off this modules `main` method. There are other motivations, but they're a bit beyond my ability to explain them...

#### Clean out `main`

First, let's pull out everything up to the encode into its own function, called `getPitchforkAlbums`

    getPitchforkAlbums :: IO [Album]
    getPitchforkAlbums = do
      response <- httpLBS "https://pitchfork.com/rss/reviews/albums/"
      let document = parseLBS_ def (getResponseBody response)
      let cursor   = fromDocument document
      let albumArtist = cursor
                $// element "item"
                &/  element "title"
                &// content
      let date = map toDate $ cursor
                $// element "item"
                &/  element "pubDate"
                &// content
      let albumsAwaitingDate = map ( toAlbumAwaitingDate
                                . T.splitOn ": "
                                ) albumArtist
      pure $ zipWith (\album date -> album date) albumsAwaitingDate date

Because we are in the `IO` space, we can't just return `[Album]`, our list of albums. But if we leave the results of the `zipWith` as our return from the function, we'll get an error, because that results in `[Album]`, not `IO [Album]`. This is why we utilize `pure`, to lift the `[Album]` into the `IO` context.

##### `pure` vs `return`

Depending on what you've read, you may be familiar with `return` or `pure` but maybe not either. The short explanation is that `pure` is defined with the `Applicative` and `return` in the `Monad`. Both of them perform the same functionality in our case because `IO` has both an `Applicative` and `Monad` instance. In future versions of Haskell, it will be impossible to have a `Monad` without also having an `Applicative`, meaning that `return` will be even less useful. Also, I find the name `return` very confusing for people who come from other programming languages like JavaScript where that is how you return from a function or method.

If that sounded like some gobbledygook, then don't worry about it, it's just there for the people that care. If you want to know a bit more, [the Haskell wiki has info on the Functor-Applicative-Monad Proposal](https://wiki.haskell.org/Functor-Applicative-Monad_Proposal).

#### Back to `main`

We left our `main` function looking like this:

    main :: IO ()
    main = do
      albums <- getPitchforkAlbums
      encodeFile "albums.json" albums

Much cleaner, right? But let's go one step further and pull this code into its own function. We'll call it `writeAlbumJSON`:

    writeAlbumJSON :: FilePath -> IO ()
    writeAlbumJSON fileName = do
      albums <- getPitchforkAlbums
      encodeFile fileName albums

Notice we aren't hardcoding the "albums.json" file path, but accepting it as an argument. This will allow us some flexibility in choosing how we can to pass in this file path. For now, we'll hard code the argument, but we may change that in the future:

    main :: IO ()
    main = writeAlbumJSON "albums.json"


And just to make sure things are working, we run:

* `stack build` to build our code
* `stack exec aggr-haskell` to generate our JSON

It works! Let's continue.

### Pull in Second RSS Feed

We knew from the outset that we weren't just going to pull in Pitchfork's RSS feed. Now that we've cleaned up our `main`, we are now free to create a function for our need feed, Stereogum. Specifically, we are going to pull in the RSS XML from [Stereogum's Heavy Rotation RSS feed](https://www.stereogum.com/heavy-rotation/feed/).

#### Stereogum RSS XML

Looking at the RSS feed, we may be surprised to see how much in common this feed has with the Pitchfork feed, especially for our purposes:

* The album artist and album title both live in the `title` tag
* The date lives in the `pubDate` tag

With this in mind, we can write a naive first draft of `getStereogumAlbums` with little work:

    getStereogumAlbums :: IO [Album]
    getStereogumAlbums = do
      response <- httpLBS "https://www.stereogum.com/heavy-rotation/feed/"
      let document = parseLBS_ def (getResponseBody response)
      let cursor   = fromDocument document
      let albumArtist = cursor
                $// element "item"
                &/  element "title"
                &// content
      let date = map toDate $ cursor
                $// element "item"
                &/  element "pubDate"
                &// content
      let albumsAwaitingDate = map ( toAlbumAwaitingDate
                                . T.splitOn "–"
                                ) albumArtist
      pure $ zipWith (\album date -> album date) albumsAwaitingDate date

What's different between this and `getPitchforkAlbums`? It's genuinely hard to tell! The only things I changed was the URL passed to `httpLBS` and the character to split the title and artist on in `T.splitOn`.

Before we refactor, let's pull this in and make sure it works as we expect. We could comment out `getPitchforkAlbums` and put in `getStereogumAlbums` for testing, but let's actually think about how we want to pull these two together.

* We have two functions whose types are `IO [Album]`
* We want to arrive at a value of `IO [Album]`
* We can put each function into a list:
  - `[getPitchforkAlbums, getStereogumAlbums]`
  - which gives us a type of `[IO [Album]]`.
* We want to join the `[Album]` together, so we can pull in `Control.Monad (join)` to help with that:
  - `join [getPitchforkAlbums, getStereogumAlbums]`
  - but that doesn't work. `join` sees us trying to flatten `IO`, not the lists within...
* We look to our friend, the `Traversable` typeclass, and it's function `sequence`, which has the following type:
  - `sequence :: Monad m => t (m a) -> m (t a)`
* Combining our sequence to flip where the IO is, we get:
  - `sequence [getPitchforkAlbums, getStereogumAlbums]`
  - Which gets us a type of `IO [[Album]]`
  - Which we can `fmap` over with `join` to get: `join <$> sequence [getPitchforkAlbums, getStereogumAlbums]`
  - Which gets us a type of `IO [Album]`. Just what we wanted!

If you're not familiar with the `Traversable` typeclass, I recommend [the Haskell Wiki article on Foldable and Traversable](https://wiki.haskell.org/Foldable_and_Traversable).

If that thought process went over your head, don't worry. I just wanted to give a deeper peek at how I think through writing Haskell code. That is, I look at the types and try to match up what fits together. Often, I end up writing part of the code and then write sub-expressions as undefined with the types I want, and play around until the types move the way I want them to. It's something that comes with practice and patience, and I'm not always the greatest at it myself, but I'm trying!

Let's `build` and `exec`. And look! Our output now has more albums than it did before!

#### Refactor `getStereogumAlbums`

You probably noticed that we duplicated a lot of code between `getStereogumAlbums` and `getPitchforkAlbums`. Let's go through both and see if we can find some useful common functions we can use.

The most obvious refactors are the cursor traversals for getting the artist and title and getting the release date. The two lines are identical! So let's create two new functions:

    getArtistsAndTitles :: Cursor -> [Text]
    getArtistsAndTitles cursor =
      cursor $// element "item" &/ element "title" &// content

    getReleaseDates :: Cursor -> [Text]
    getReleaseDates cursor = map toDate dates
      where dates = cursor $// element "item" &/ element "pubDate" &// content

Notice that I'm passing in the `Cursor` instead of trying to fetch it each time. Also, notice that I broke down getting the dates from the `Cursor` and mapping them to the format we wanted into two separate pieces. I primarily did this for line length, but also to convey that we're performing two separate actions within the function.

Next, we can break out the line for translating the albumArtist strings into Album functions:

    toPartialAlbums :: Text -> [Text] -> [Text -> Album]
    toPartialAlbums splitter =
      map (toPartialAlbum splitter . map T.strip . T.splitOn splitter)

Instead of hard-coding which bit of `Text` on which we'll split the `Text`, we'll pass it in with the name `splitter`. Also, notice that I added a mapping of `strip`. This is because some of the strings have leading or trailing whitespace that we should be removing that I missed the first time around.

You'll notice that I also decided to rename `toAlbumAwaitingDate` to `toPartialAlbum` and added the splitter as an argument to it since we re-use it in one of our cases:

    toPartialAlbum :: Text -> [Text] -> (Text -> Album)
    toPartialAlbum _ [a, t] = Album a t
    toPartialAlbum _ [a]    = Album a ""
    toPartialAlbum splitter [a,t1,t2] = Album a (t1 <> splitter <> t2)
    toPartialAlbum splitter xs = error "Invalid pattern!"

Finally, the path from URL to Cursor is identical except for the URL itself, which sounds like a perfect case for a function!

    getXMLCursor :: Request -> IO Cursor
    getXMLCursor url = do
      response <- httpLBS url
      let document = parseLBS_ def (getResponseBody response)
      pure $ fromDocument document

Like our get functions, we need an IO context to reach out into the real world, so we have to lift our `Cursor` into `IO` using `pure` at the end.

This refactor leaves our `getStereogumAlbums` and `getPitchforkAlbums` looking like the following:

    getStereogumAlbums :: IO [Album]
    getStereogumAlbums = do
      cursor <- getXMLCursor "https://www.stereogum.com/heavy-rotation/feed/"
      let albumArtist = getArtistsAndTitles cursor
      let date = getReleaseDates cursor
      let partialAlbums = toPartialAlbums "–" albumArtist
      pure $ zipWith (\album date -> album date) partialAlbums date

    getPitchforkAlbums :: IO [Album]
    getPitchforkAlbums = do
      cursor <- getXMLCursor "https://pitchfork.com/rss/reviews/albums/"
      let albumArtist = getArtistsAndTitles cursor
      let date = getReleaseDates cursor
      let partialAlbums = toPartialAlbums ":" albumArtist
      pure $ zipWith (\album date -> album date) partialAlbums date

#### We could go further

The observant reader will notice that there is still plenty of duplication between `getStereogumAlbums` and `getPitchforkAlbums`. And if this was our final destination, I would probably do further refactoring to some sort of shared `getAlbums` function.

To borrow from Haskell tutorials I've read, I'll leave that as an exercise for the reader.

In the meantime, let's `build` and `exec` to prove our code is working. And it is!

### Extend Album datatype

In the future, I would like to be able to filter which albums end up the JSON by the album's score. But, this does not apply to every site from which we'll pull. Also, I do not want the score to end up in the final JSON; I only want to know that the albums there passed the minimum score criteria, not what score they gave it specifically.

In our current code, Pitchfork reviews contain scores, whereas Stereogum's do not. We could keep the concept of a score outside of our Album datatype (this was how I initially approached the problem). But the code can turn into an unwieldy mess of zipped-up tuples being created and uncreated, making the code more difficult to reason about.

Instead, we're going to treat score as an optional field by making use of `Maybe`:

    data Album
      = Album
      { artist :: Text
      , title  :: Text
      , date   :: Day
      , score  :: Maybe Double
      } deriving (Generic, Eq, Show)

This means that, when an album has a score, it will be stored as `Just 8.5` or whatever the score is. If it doesn't, it will be `Nothing`. For our filtering purposes, then, we'll consider `Nothing` as an automatic pass, and then further investigate the value if we have a `Just`.

We can go ahead and filter the score out of our final JSON by making our `ToJSON` a little more complicated. We'll utilize the `RecordWildCards` language extension to reduce duplication and clutter in the intstance:

    {-# LANGUAGE RecordWildCards   #-}

    instance ToJSON Album where
      toJSON Album{..} = object
        [ "artist" .= artist
        , "title"  .= title
        , "date"   .= date
        ]

While this is more complicated than our previous `ToJSON` instance, I cannot complain that it is too complicated. Our intentions seem clear despite some unfamiliar syntax.

Check out [this tutorial on RecordWildCards and Aeson](https://ocharles.org.uk/posts/2014-12-04-record-wildcards.html) for more info on RecordWildCards.

For the sake of getting our code to compile, we'll need to fix the type signatures for `toPartialAlbum` and `toPartialAlbums`:

    toPartialAlbums :: Text -> [Text] -> [Text -> Maybe Double -> Album]
    toPartialAlbums = ...

    toPartialAlbum :: Text -> [Text] -> (Text -> Maybe Double -> Album)
    toPartialAlbum = ...

And then, in the lamdas we pass to `zipWith` in `getStereogumAlbums` and `getPitchforkAlbums`, we need to provide a `Maybe Double` value to complete the albums. For now, we'll pass `Nothing` in both:

    pure $ zipWith (\album date -> album date Nothing) partialAlbums date

`build` and `exec`, nothing's changed. Good! We're about to change that.

#### HTML Parsing

If you look back at [the Pitchfork RSS XML](https://pitchfork.com/rss/reviews/albums/), you'll see that we don't have a score anywhere. Pitchfork, reasonably, does not include the score in the feed. Otherwise, a large subsection of their readers would not click through to open the article, and their metrics would plummet.

In order to get the score for an album, we need to follow the review link and grab it from there. That means parsing HTML, which our `xml-conduit` library will not handle kindly.

So, in order to avoid some configuration that I'd rather not deal with, we'll pull in the `html-conduit` library. Because of its flexibility, we can use it in place of some of the `xml-conduit` library code we've used (we'll still use the `Cursor`, though), so that we have far less code to manage.

Once added to our `.cabal` file and `build`ing, we can remove `Text.XML` and add `Text.HTML.DOM` to our imports:

    import Text.HTML.DOM

Next, we'll rewrite our `getXMLCursor` to make use of `httpSink`, which can translate a `Response` directly to a `Document` when paired with `sinkDoc`. We probably could've done this with `xml-conduit`, but I didn't realize until now:

    getXMLCursor :: Request -> IO Cursor
    getXMLCursor url = do
      document <- httpSink url (const sinkDoc)
      pure $ fromDocument document

If you'd like, we can simplify this code a little bit. When we create the `IO Document` we pull it out of the `IO` context, pass it to `fromDocument`, then put it right back into the `IO` context with `pure`. Since `IO` is a functor, we can `fmap` the `fromDocument` function over the result of `httpSink` like so:

    getXmlCursor :: Request -> IO Cursor
    getXmlCursor url = fromDocument <$> httpSink url (const sinkDoc)

If this looks like black magic to you, keep the previous code! I'm not saying this is "better", I'm just pointing out a common pattern that you might see in other people's code. Haskellers love to reduce their code to its simplest form when they can, so being aware of how that might happen will be beneficial.

`build` and `exec` to ensure we haven't broken the world. So far, so good!

#### Getting the review links

Before we write some code, let's think about our strategy. We need to grab the `link` from each `item` in the RSS XML. We then need to visit each `link`, look for the score on the page, and return it. So, it SOUNDS like we'll be mapping each link to a score. Then, we can zip up those scores with our partial albums, the same as we do with the dates, and we'll be golden!

So, let's start with what we know. Let's fetch the review links:

    getReviewLinks :: Cursor -> [Text]
    getReviewLinks cursor = cursor $// element "item" &/ element "link" &// content

Rather than continue assuming we're getting what we want, let's test this out. The easiest way would be to incorporate this into our `getPitchforkAlbums` function and print out the results:

    getPitchforkAlbums = do
        -- code...
        let links = getReviewLinks cursor
        print links
        -- remaining code...

If we `build` and `exec`, we see... an empty list? What gives?

I spent so long trying to figure this out. And I'm still not sure what it is about the `link` tag. My guess is that it has something to do with a conflict between the HTML `link` tag and an `XML` link tag, and how the former is self-closing and therefore couldn't contain content. Regardless, we need a workaround.

There's probably a ton of better options than this, but we want results. We know we can fetch all of the items and get their content as a list. We can also tell which elements of the list are links by their leading "http". So...

    getReviewLinks :: Cursor -> [Text]
    getReviewLinks cursor = filter (T.isPrefixOf "http") elems
      where elems = cursor $// element "item" &// content

If you're not familiar with `isPrefixOf`, it takes a `Text` pattern and returns whether or not each element starts with that Text. Dirty, but effective.

Keeping our test `print` in place, we `build` and `exec`... and hey! Look at those links!

#### Getting the scores

Let's skip the middle part for now and look at how to find the score on a review. Grab one of the links we dumped out earlier and go to it in your browser of choice. At the time of writing, Pitchfork has the scores to the right of the album art in a black circle. We can right click, choose "Inspect" (or whatever it's called in your browser), and the Developer Tools will open, highlighting the node we want.

It looks like they put the score text in a span with a class of "score". Not quite as descriptive as a `score` node, like we might find in XML, but we can work with it.

Since we're narrowing down our elements, not by their name, but by one of their attributes, we'll make use of `Control.Monad`'s Kleisli arrow: `(>=>)` . You may or may not have seen this guy floating around (get it, because it looks like a fish? I'll see myself out...). The basic idea behind it is that it allows you to compose two functions whose types look like `a -> m b`, so that you send up with just one `m` at the end, where `m` is a `Monad`. Or more succinctly:

    (>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c

Let's look at how we're using it, and it might help see what's happening:

    getScore :: Cursor -> Text
    getScore cursor = T.concat score
      where score = cursor
              $// element "span" >=> attributeIs "class" "score"
              &// content

You can see that we are looking for all `span` elements, which gives us an `Axis`, but then we're looking for that whose "class" attribute is "score", which gives us another `Axis`. In the end, we only want a subset of the `span`s (that is, a `span` whose "class" is "score"), so the operator combines our selector to return one function that goes from our cursor to our "score" spans. Nifty!

You can also see that I am `concat`ing the result. Unlike our previous selects, we're not fetching a list of data, but only one element. But `content` gives us a list regardless. So `concat` ensures that we end up with only one `Text` item.

#### Parsing the Scores

We can read in the score, but it's of type `Text`. What we want is a `Maybe Double`. We'll need a function for parsing the `Text`. Let's work through this together. We'll start with an `undefined` function:

    parseScore :: Text -> Maybe Double
    parseScore = undefined

What function allows us to convert from a string type to a numeric type? Our good friend `read`. But `read` only accepts the `String` type, so we'll need to `unpack` our passed in `Text`:

    parseScore :: Text -> Maybe Double
    parseScore score = read $ T.unpack score

Believe it or not, that's all we need! By looking at the type signature, `read` knows where we want to end up and puts the score in a `Maybe` for us.

But what happens if `read` can't interpret the incoming score as a `Double` ? It will throw an error, causing the whole script to halt. And you may want that! That is, after all, how we handle `toPartialAlbum`.

But what if you don't want it to halt? What if you wanted to provide a fallback?

We have access to a little-known cousin of `read` called `readMaybe`. Instead of throwing an error when it can't read the value as a `Double`, it just returns a `Nothing`:

    parseScore :: Text -> Maybe Double
    parseScore score = readMaybe $ T.unpack score

Even though we haven't written our filtering code yet, we talked briefly about it. We decided that we would treat `Nothing` as an automatic pass since all of the scores for Stereogum will be `Nothing`. You may decide that's how you want to treat malformed scores.

I don't, though. I have enough to listen to. I don't need some album that is potentially not great getting through. I know, I'm a snob. So, instead of keeping it as is, we're going to treat it as a 0. We'll do that with `fromMaybe` (which lives in `Data.Maybe`:

    parseScore :: Text -> Maybe Double
    parseScore score = pure . fromMaybe 0 . readMaybe $ T.unpack score

Using composition, we read in the `Maybe`, convert it either to the `Double` or to 0, and then `pure` it right back into `Maybe`-land. If this feels convoluted, it is. The idea is not "this is the best approach!". It's showing my thought process, and tinkering with types until I get the behavior I want.

We will make one refactor through. Since we only use score at the end and compose everything else, we can pull out the argument and make our function [pointfree](https://wiki.haskell.org/Pointfree):

    parseScore :: Text -> Maybe Double
    parseScore = pure . fromMaybe 0 . readMaybe . T.unpack

Okay, I've tortured that function enough. Let's move on

#### Review Link -> Score

We can fetch our review links. And given a `Cursor` that points to one of those links, we can fetch a score. But how will we wire them up? You already know the answer, because we've done it already! Let's look at the code, and then we'll talk about what's different:

    linkToScore :: Text -> IO Text
    linkToScore link = do
      request <- parseRequest $ T.unpack link
      cursor <- getXMLCursor request
      let score = getScore cursor
      pure $ parseScore score

Unlike our previous string literals, we can't pretend that the links we're getting back are anything but `Text`. That's what `getScore` returns, so that's what we use. So, we'll need to both `unpack` it and pass it to `parseRequest` in order to get our `Request` to pass to `getXMLCursor`. The rest should look familiar.

You may also notice that we're once again in a pattern where we pull things out of their `IO` context only to throw them back in at the end. For completion's sake, I'll show you how this code could look by utilizing `fmap`:

    linkToScore :: Text -> IO (Maybe Double)
    linkToScore link = parseScore . getScore
      <$> (getXmlCursor =<< parseRequest (T.unpack link))

The reversed `>>=` is only to help the code read right-to-left. Otherwise, we jump in the middle, move right a bit, then move left, and that's not helpful at all. Once again, if this isn't clear to you, don't sweat it! Like I said before, this is more about exposure than complete understanding.

#### Wiring it all together

We have a method for getting a list of links, and for each one, we'd like to replace the link with a score. Like before, this sounds like a job for `map`. But let's give it a shot:

    getScores :: Cursor -> IO [Maybe Double]
    getScores cursor = linkToScore <$> getReviewLinks cursor

If we look at what type `fmap` gives us back, it's not what we thought. It's `[IO (Maybe Double)]`. If you remember earlier, we had a method for flipping our types the way we want: `sequence`. But we'd also like to apply a function to each argument, which `sequence` doesn't allow us to do. Luckily, `Traversable` knows that people want to `map` and `sequence` at the same time, and provides the method `traverse` to do such things:

    getScores :: Cursor -> IO [Maybe Double]
    getScores cursor = traverse linkToScore $ getReviewLinks cursor

Or in a pointfree style:

    getScores :: Cursor -> IO [Maybe Double]
    getScores = traverse linkToScore . getReviewLinks

Finally! We have what we need. Let's utilize it in `getPitchforkAlbums`:

    getPitchforkAlbums :: IO [Album]
    getPitchforkAlbums = do
      cursor <- getXmlCursor "https://pitchfork.com/rss/reviews/albums/"
      let albumArtists = getArtistsAndTitles cursor
      let dates = getReleaseDates cursor
      scores <- getScores cursor
      let partialAlbums = toPartialAlbums ":" albumArtists
      pure $ zipWith3 (\album date score -> album date score) partialAlbums dates scores

Besides renaming a few things, you can see where I pull in `scores`, and in order to zip with one more list, I use `zipWith3` instead of `zipWith`, altering the lambda to accept a score argument and pass it to the album, as well as passing the scores as the last argument.

We `build` and `exec`. And... hey, we get the same albums. BUT that means we haven't broken anything! And you probably noticed that the script is now MUCH slower because we are not visiting two links but several, depending on how many reviews we have to pull in.

### Until next time

Yes, we're going to stop here with a slow script that pulls in scores we don't use. But we learned a lot, and did a lot! It doesn't show in our end results yet, but by testing each step of the way, we've made sure that our code continues to work as expected, which will make our final steps much easier.

Next time, we'll look at:

* Filtering based on the score
* Using an actual Date type for the date in Album
* Pulling in a third (and final) source for albums

We'll try to finish up everything next time, but if not, we'll have one more article after that for clean up and clarification.

Thank you for reading! You can file complaints and report bugs in the code through [the git repo for aggr haskell](https://github.com/blrobin2/aggr-haskell)

### The Full Code (for now):
    {-# LANGUAGE DeriveGeneric     #-}
    {-# LANGUAGE OverloadedStrings #-}
    {-# LANGUAGE RecordWildCards   #-}
    module Main where

    import           Control.Monad ((>=>), join)
    import           Data.Aeson
    import           Data.Maybe (fromMaybe)
    import           Data.Text (Text)
    import qualified Data.Text as T
    import           Data.Time
    import           Data.Time.Format
    import           GHC.Generics
    import           Network.HTTP.Simple
    import           Text.HTML.DOM
    import           Text.Read (readMaybe)
    import           Text.XML.Cursor

    data Album
      = Album
      { artist :: Text
      , title  :: Text
      , date   :: Text
      , score  :: Maybe Double
      } deriving (Generic, Eq, Show)

    instance ToJSON Album where
      toJSON Album{..} = object
        [ "artist" .= artist
        , "title"  .= title
        , "date"   .= date
        ]

    toUTCTime :: String -> Maybe UTCTime
    toUTCTime = parseTimeM True defaultTimeLocale "%a, %d %b %Y %X %z"

    toDate :: Text -> Text
    toDate d = case toUTCTime (T.unpack d) of
      Nothing -> ""
      Just d' -> T.pack $ formatTime defaultTimeLocale "%b %d %Y" d'

    getArtistsAndTitles :: Cursor -> [Text]
    getArtistsAndTitles cursor =
      cursor $// element "item" &/ element "title" &// content

    getReleaseDates :: Cursor -> [Text]
    getReleaseDates cursor = map toDate dates
      where dates = cursor $// element "item" &/ element "pubDate" &// content

    toPartialAlbums :: Text -> [Text] -> [Text -> Maybe Double -> Album]
    toPartialAlbums splitter =
      map (toPartialAlbum splitter . map T.strip . T.splitOn splitter)

    toPartialAlbum :: Text -> [Text] -> (Text -> Maybe Double -> Album)
    toPartialAlbum _ [a, t] = Album a t
    toPartialAlbum _ [a]    = Album a ""
    toPartialAlbum splitter [a,t1,t2] = Album a (t1 <> splitter <> t2)
    toPartialAlbum splitter xs = error $ errorString splitter xs
      where
        errorString :: Text -> [Text] -> String
        errorString s xs = T.unpack $ "Invalid pattern: " <> T.intercalate s xs

    getXmlCursor :: Request -> IO Cursor
    getXmlCursor url = fromDocument <$> httpSink url (const sinkDoc)

    getReviewLinks :: Cursor -> [Text]
    getReviewLinks cursor = filter (T.isPrefixOf "http") elems
      where elems = cursor $// element "item" &// content

    getScore :: Cursor -> Text
    getScore cursor = T.concat score
      where score = cursor
              $// element "span" >=> attributeIs "class" "score"
              &// content

    parseScore :: Text -> Maybe Double
    parseScore = pure . fromMaybe 0 . readMaybe . T.unpack

    linkToScore :: Text -> IO (Maybe Double)
    linkToScore link = parseScore . getScore
      <$> (getXmlCursor =<< parseRequest (T.unpack link))

    getScores :: Cursor -> IO [Maybe Double]
    getScores = traverse linkToScore . getReviewLinks

    getStereogumAlbums :: IO [Album]
    getStereogumAlbums = do
      cursor <- getXmlCursor "https://www.stereogum.com/heavy-rotation/feed/"
      let albumArtist = getArtistsAndTitles cursor
      let date = getReleaseDates cursor
      let partialAlbums = toPartialAlbums "–" albumArtist
      pure $ zipWith (\album date -> album date Nothing) partialAlbums date

    getPitchforkAlbums :: IO [Album]
    getPitchforkAlbums = do
      cursor <- getXmlCursor "https://pitchfork.com/rss/reviews/albums/"
      let albumArtists = getArtistsAndTitles cursor
      let dates = getReleaseDates cursor
      scores <- getScores cursor
      let partialAlbums = toPartialAlbums ":" albumArtists
      pure $ zipWith3 (\album date score -> album date score) partialAlbums dates scores

    writeAlbumJSON :: FilePath -> IO ()
    writeAlbumJSON fileName = do
      albums <- join <$> sequence [getPitchforkAlbums, getStereogumAlbums]
      encodeFile fileName albums

    main :: IO ()
    main = writeAlbumJSON "albums.json"
