---
layout: post
title: "A Beginning Haskeller Builds a Web Scraper (Part 3)"
excerpt: "A journey into Haskell, and my failings along the way"
category: programming
---

### Previously On

[Nearly a month ago]({% post_url 2018-11-20-aggr-haskell-part-2 %}) (sorry about that) we added the concept of a score to our Album datatype, and pulled in a second data source for building up our collection of albums.

For this article, we're going to finish up and focus on the following objectives:

- Convert `date` field in `Album` to use an honest-to-god date
- Filter albums based on the previously-added `score` and `date`.
- Run score fetches and album building concurrently.

### Date field

In [the first post]({% post_url 2018-11-12-aggr-haskell-part-1 %}) we pulled in the `time` library, which we used to parse the date as a `Maybe UTCTime`, which we then formatted as a `Text` to store in our `Album` datatype.

We did this because we didn't want to think about dates yet, so we took the path of least resistance. But now we want to use the `date` field for filtering and for sorting our data.

We could still use `UTCTime` if we wanted. But the problem is that it concerns itself with the date AND the time. We only really care about the day, month, and year that it came out, because we will:

- Filter our results to only have albums that came out this month
- Sort our results first by day of the month, then by artist name.

#### Day

Because of this, we are going to utilize the `Day` datatype within `Data.Time`. Technically, the type represents days since November 17, 1858 (the start of the Modified Juilan Calendar). BUT, it can easily be parsed to a Gregorian representation containing the year, month, and day, both via parsing methods within `Data.Time`, and by `aeson`. So we're still taking a path of less resistance, but it achieves our purposes.

To get started, let's update our `Album` definition:

    data Album
    = Album
    { artist :: Text
    , title  :: Text
    , date   :: Day
    , score  :: Maybe Double
    } deriving (Generic, Eq, Show)

All we've done is change the `date` field from `Text` to `Day`. This should cascade some errors for us to address.

First, we'll update the type signatures for `toPartialAlbums` and `toPartialAlbum` to the following:

    toPartialAlbums :: Text -> [Text] -> [Day -> Maybe Double -> Album]
    toPartialAlbum :: Text -> [Text] -> (Day -> Maybe Double -> Album)

Once again, all we've done is change `Text` to `Day` in describing the partial function that these functions return.

Next, we see that `getPitchforkAlbums` and `getStereogumAlbums` are not happy receiving a list of `Text` to complete the albums. If we dig down to where this occurs, we find that we must change how we work with `toDate`.

Currently, `toDate` passes the `Text` date we pulled from the XML to `toUTCTime` to try and convert to `Maybe UTCTime`. We don't want a `UTCTime` though, we want a `Day`. So, how can we go about getting what we want?

Because of Haskell's amazing polymorphism, all we NEED to do is change our type signature:

    toUTCTime :: String -> Maybe Day

However, for the sake of sanity, we should rename the function to... let's say, `toDay`:

    toDay :: String -> Maybe Day
    toDay = parseTimeM True defaultTimeLocale "%a, %d %b %Y %X %z"

Sweet! Next, we need to update `toDate` to use our new function:

    toDate :: Text -> Text
    toDate d = case toDay (T.unpack d) of
      Nothing -> ""
      Just d' -> T.pack $
        formatTime defaultTimeLocale "%b %d %Y" d'

But this still returns `Text`, which we don't want. If we fall into the `Just` case, we have our `Day` and just want it back:

    Just d' -> d'

But what about our `Nothing` case? We have a couple of options, one more complex than the other. We can:

- Just return a `ModifiedJulianDay` of 0, assuming we'll never hit this case.
- Fetch the current date and parse it as a `Day`, so we'd assume it came out today, keeping the date within range for sorting.

While the latter is the most robust solution, we are going to defer to the simpler one for now. Therefore, our `toDate` function can be updated to the following:

    toDate :: Text -> Day
    toDate d = case toDay (T.unpack d) of
      Nothing -> ModifiedJulianDay 0
      Just d' -> d'

If you remember, this pattern occurs often, of getting either the value from the `Maybe` or a fallback value in the case of `Nothing`. This code can be simplified with the use of `fromMaybe`:

    toDate :: Text -> Day
    toDate d = fromMaybe (ModifiedJulianDay 0)
      (toDay (T.unpack d))

Or if you prefer pointfree:

    toDate :: Text -> Day
    toDate = fromMaybe (ModifiedJulianDay 0)
           . toDay
           . T.unpack

Once we've updated this function, we have one more place to change: `getReleaseDates`. We change it from:

    getReleaseDates :: Cursor -> [Text]

to:

    getReleaseDates :: Cursor -> [Day]

Once again, refactoring is so simple! Run `stack build` and `stack exec aggr-haskell`, and we can see a change in our JSON output. We're no longer storing the dates in the "Dec 18" format, but in "2018-12-18" format.

In the end, this is more flexible and allows the consuming code to format the date as it pleases instead of being forced into our formatting choice (or more painfully, to re-parse and format the date themselves).

### Sorting

Now that we have the date in the types we need, we can begin our sorting and filtering.

If you've done sorting in other languages, you know that you often have to write object-specific sorting code for each thing that you intend to sort. Those specifics almost never have to deal with the sorting algorithm itself, but with how to tell the algorithm the ordering of the items.

In Haskell, we don't do this at the function level. Instead, we define an `Ord` instance for the data type we want sorted. `Ord`, short for Order, defines a function `compare` that when given two objects of the same type, returns the ordering relationship to each other.

Before we write the code, let's write out how we want to order `Album`s:

- We want to sort firstly by `date` DESCENDING (that is, the most recent albums will be first)
- If the `date` is equal, then we want to sort secondly by `artist` ASCENDING (that is, the albums for a given day will be listed in alphabetical order)

How do we express that in Haskell?

First, like we did with our `ToJSON` instance, we initiate an `Ord` instance:

    instance Ord Album where

Next, we must provide a definition of `compare`. We can think of type definition for `compare` in our instance being:

    compare :: Album -> Album -> Ordering

That is, it takes two Albums, and returns how they are ordered. In more C-like languages, that ordering is usually expressed as:

- -1 for 'the first album comes before the second album', or Less Than
- 0 for 'the first album and the second album are the same', or EQual
- 1 for 'the first album comes after the second album', or Greater Than

Haskell has the `Ordering` data type, which you can think of as being defined as:

    data Ordering = LT | EQ | GT deriving (Ord)

- LT is for 'Less Than'
- EQ is for 'EQual'
- 'GT is for 'Greater Than'

So our `compare` function will return one of these, which the `sort` function will use to determine how to sort them.

We only want to deal with the artist and the date, so in our function definition, let's destructure each `Album` so that we can access just those fields:

    compare (Album a1 _ d1 _) (Album a2 _ d2 _) = ...

If you find the single-letter names confusing, please feel free to do:

    compare (Album artist1 _ date1 _) (Album artist2 _ date2 _ ) =...

Now, how do we use this data to get back an `Ordering`? Well, it just so happens that for both `Day` and `Text`, an `Ord` instance has been defined by their libraries. Which means that we can use `compare` on THEM in order to get our ordering!

So we start with the date DESCENDING:

    compare (Album a1 _ d1 _) (Album a2 _ d2 _) = compare d2 d1

Do you see what we've done? By passing the second date as the first argument, we are saying that we want dates that are later (or higher in their ordering) to come before dates that are earlier.

From this, you can probably figure out that for artists ASCENDING, we can do:

    compare a1 a2

But where do we put it? You wouldn't be blamed for thinking that we'll first need to do the compare on the date, and then in the case where the result is EQ, do the next compare, otherwise return the results. I will spare you the sample code of what that will look like and reveal something else about `Ordering`: it has `Semigroup` instance!

A `Semigroup` defines the way in which a data type should be combined with itself. We've already used part of it when using `(<>)` for combining `Text`.

I think it's easier to just look at the `Semigroup` instance for `Ordering` instead of trying to describe it:

    instance Semigroup Ordering where
      LT <> _ = LT
      EQ <> y = y
      GT <> _ = GT

So as you can see, when combining two Orderings, if the first is EQ, we go with the second one. Otherwise, we go with the Ordering from the first one. So then, all we need to do in our case is:

    instance Ord Album where
      compare (Album a1 _ d1 _) (Album a2 _ d2 _) =
        compare d2 d1 <> compare a1 a2

Now, to make use of it, we'll go to our `writeAlbumJSON`, where we're collecting our difference sources together. After we `join` the lists together, we'll `sort` them:

    writeAlbumJSON :: FilePath -> IO ()
    writeAlbumJSON fileName = do
      albums <- sort . join <$> sequence [getPitchforkAlbums, getStereogumAlbums]
      encodeFile fileName albums

`sort` is defined in `Data.List` so add the following to your imports at the top:

    import Data.List (sort)

`build` and `exec`, then look at your `albums.json` and you'll see our data is sorted!

### Filtering

Now that we have some sense of order for our data, we can begin working on filtering our data down to that which is most important to us.

#### Duplicates

We have explicitly stated it yet, but have sort of assumed a rule that we are currently not enforcing. For our final list of albums, we do not want any duplicate albums. It may be, up to this point, that we have not had any duplicates between our Pitchfork feed and our Stereogum feed. But that doesn't not preclude this duplication from occurring.

We can address this trivially with the help of a function in `Data.List` called `nub`. It's type signature looks like the following:

    nub :: Eq a => [a] -> [a]

The documentation gives it the following definition: "The `nub` function removes duplicate elements from a list. In particular, it keeps only the first occurrence of each element." ([source](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-List.html#g:20)).

The only requirement it has is that the type being compared have an `Eq` instance, so that it can have some way to determine whether each type is equal. Rather than write one ourselves, we have already derived one in our `Album` definition:

    data Album
      = Album
      { artist :: Text
      , title  :: Text
      , date   :: Day
      , score  :: Maybe Double
      } deriving (Generic, Eq, Show)

By deriving it, Haskell will by default compare each field for equality.

But wait! The `artist` and `title` may be the same between sources, but Stereogum does not have a `score`. And there's nothing that prevents Stereogum from publishing a review on a different day than Pitchfork.

So, we should remove our derived `Eq` and write one ourselves.

    instance Eq Album where
      (Album a1 t1 _ _) == (Album a2 t2 _ _) =
        a1 == a2 && t1 == t2

Again, please feel free to replace the single-letter variables with full names if you find that easier to understand.

To make use of `nub`, we add it to our `Data.List` import, and compose it right along with `join` and `sort`:

    writeAlbumJSON :: FilePath -> IO ()
    writeAlbumJSON fileName = do
      albums <- sort . nub . join <$> sequence [getPitchforkAlbums, getStereogumAlbums]
      encodeFile fileName albums

`build` and `exec`, and depending on whether you had duplicate entries, you should not see them any longer!

#### Filter by score

While we can filter duplicates out at the top level, we must be more specific for each of our sources when it comes to score. First, only one of them has a score at the moment. Second, even if we had multiple sources with scores, they may not be the same scale as each other, nor have the same minimum required score in order to be included.

While we cannot place our filtering function in `writeAlbumJSON`, we can write a function that will work for all of our cases.

We will start with a function called `filterAlbums`. Initially, it will take as its parameters the lowest score we will allow through and the list of albums to filter, and return a filtered list of albums. Or:

    filterAlbums :: Double -> [Album] -> [Album]

If you aren't aware, we have a built-in `filter` function, which takes a function that returns a Boolean that represents whether or not to keep the item, and the initial list of items. For our case, the data is the Album, and the Boolean is whether or not the score is at least our lowest score. We can call this function `scoreIsHighEnough`:

    scoreIsHighEnough :: Album -> Bool

And our top level `filterAlbums` will be:

    filterAlbums lowestScore = filter scoreIsHighEnough
      where
        scoreIsHighEnough :: Album -> Bool
        scoreIsHigEnough album = ...

The `score` field is a `Maybe Double`, so we'll need to handle both when we have a score and when we don't. If you recall from our previous articles, if the album doesn't have a score (that is, if the `score` field is `Nothing`), it gets an automatic pass. Otherwise, if we have a value, it must be greater than or equal to our lowestScore:

    scoreIsHighEnough album = case score album of
      Nothing -> True
      Just s  -> s >= lowestScore

You may think that we can use `fromMaybe` here, but in this case we are not using the value we get from `score`, only further using it for a computation. That isn't to say you couldn't rewrite the logic in some way that still makes use of `fromMaybe`, but the result (in my opinion) would be more convoluted than what we have now.

Let's go ahead and incorporate what we have into `getStereogumAlbums` and `getPitchforkAlbums`. If we look at the functions now, we see that they use `pure` to lift all the albums they get back into the `IO` space. What we'd like to do is lift the filtered album instead.

For Pitchfork, I decided on a minimum of 7.8. This number is largely arbitrary and based on years of reading the site and choosing that number as my minimum. You can choose any number between 0.0 and 10.0 (but if you go higher than 8.4 or 8.5, you'll find your list reduced significantly).

    getPitchforkAlbums :: IO [Album]
    getPitchforkAlbums = do
      cursor <- getXmlCursor "https://pitchfork.com/rss/reviews/albums/"
      let albumArtists = getArtistsAndTitles cursor
      let dates = getReleaseDates cursor
      scores <- getScores cursor
      let partialAlbums = toPartialAlbums ":" albumArtists
      let albums = zipWith3 (\album date score -> album date score)
                partialAlbums dates scores
      pure $ filterAlbums 7.8 albums

We could have composed `zipWith3` and `filterAlbums`, but I thought the line was too long and made the code more difficult to understand. Similarly, with `getStereogumAlbums`:

    getStereogumAlbums :: IO [Album]
    getStereogumAlbums = do
      cursor <- getXmlCursor "https://www.stereogum.com/heavy-rotation/feed/"
      let albumArtist = getArtistsAndTitles cursor
      let date = getReleaseDates cursor
      let partialAlbums = toPartialAlbums "–" albumArtist
      let albums = zipWith (\album date -> album date Nothing) partialAlbums date
      pure $ filterAlbums 0 albums

We could pass literally any number since we're ignoring the field, but 0 is a good indicator that we're letting everything pass.

I will readily admit that this process of handling scores is pretty convoluted and requires a lot more domain knowledge than anything else up to this point. I am open to more intuitive solutions to this problem, and will gladly look at any pull requests on the final repo (see bottom of article).

Regardless, `build` and `exec`, check your results, and we've finally made use of the score!

#### Filter by date

Our final bit of filtering criteria is that the album must have come out this month. But that requires our application knowing what the current month is. This means we will have to do some `IO`-related work to get our month.

Thankfully, `Data.Time` has all the functions we need. We will, for our purposes, need to glue some of them together.

We have worked with `UTCTime`, which represents an exact date and time, and with `Day`, which represents days since modified Julian calendar began. There is a third "type", although it is not named like the other two, but represented as a 3-tuple:

    (Integer, Int, Int)

First, we must find a function that gives us the current day. `Data.Time` provides `getCurrentTime` of type `IO UTCTime`. That `IO` signals that Haskell is going out into the "real" world to get the date, because there is no pure way of deriving the date; it has to ask something else for it. It is in UTCTime, because that is the most expressive of the types in that it has the most information. We can convert that type to suit our purposes.

Unfortunately, there is not a direct path from UTCTime to Gregorian. We must make a stop at `Day` (using `utctDay`), which can be converted to Gregorian (using `toGegorian`). Altogether, it looks like this:

    getCurrentDate :: IO (Integer, Int, Int)
    getCurrentDate = do
      utc <- getCurrentTime
      d <- utctDay utc
      pure $ toGregorian d

Or more simply:

    getCurrentDate :: IO (Integer, Int, Int)
    getCurrentDate = toGregorian . utctDay <$> getCurrentTime

That is, we can compose `toGregorian` and `utctDay` into a single function and `fmap` over the `IO` from `getCurrentTime` to arrive at `IO (Integer, Int, Int)`.

I don't know about you, but `(Integer, Int, Int)` means nothing to me at first glance. I'd like to give the fields more expressive names. So, we'll use type aliases:

    type Year = Integer
    type Month = Int

We don't care about the day, so a type alias for it is optional (but be wary of the name `Day` since it will conflict with our `Day` type). With those, we can change the type signature for `getCurrentDate` to:

    getCurrentDate :: IO (Year, Month, Int)
    getCurrentDate = toGregorian . utctDay <$> getCurrentTime

Much better!

For now, the only value from the date we really need is the month. You might be wondering why we don't need to filter by the year. This is because the XML we get back never holds more than a few months of data, so we never get to a point where filtering by month doesn't give us what we want.

Let's write a helper function for getting the month out of the 3-tuple:

    getMonthFromDate :: (a, Month, b) -> Month
    getMonthFromDate (_, month, _) = month

We could have provided the specific types in our type constructor, but it's not information we make use of, so we just leave them as any types `a` and `b`.

Finally, we'll use that helper function to write a more useful helper, `getMonthFromDay`:

    getMonthFromDay :: Day -> Month
    getMonthFromDay = getMonthFromDate . toGregorian

This will convert the day to the 3-tuple, then pull out the month, which will be helpful for when we're extracting the month from the date in our `Album`s.

With these functions in place, we can work on putting them to use.

Ideally, I'd like to only fetch the date once, and then pass in the month where it's needed. This also prevents us from having to rewrite other functions to account for `IO`. So, for lack of a better place, let's do it in `writeAlbumJSON`:

    writeAlbumJSON :: FilePath -> IO ()
    writeAlbumJSON fileName = do
      (_, currentMonth, _) <- getCurrentDate
      albums <- sort . nub . join <$> sequence
        [ getPitchforkAlbums currentMonth
        , getStereogumAlbums currentMonth
        ]
      encodeFile fileName albums

Using destructuring, we can get at the month directly, then pass it along to `getPitchforkAlbums` and `getStereogumAlbums`. We'll have to rewrite their type signature and arguments to account for the new field:

    getStereogumAlbums :: Month -> IO [Album]
    getStereogumAlbums currentMonth = ...

    getPitchforkAlbums :: Month -> IO [Album]
    getPitchforkAlbums currentMonth = ...

From here, we'd like to pass them down into their respective `filterAlbums`:

    pure $ filterAlbums 0 currentMonth albums
    ...
    pure $ filterAlbums 7.8 currentMonth albums

Which requires us to rewrite the signature and arugments to `filterAlbums`:

    filterAlbums :: Double -> Month -> [Album] -> [Album]
    filterAlbums lowestScore currentMonth = ...

And phew! We have the month where we need it.

There are readers who may be familiar with `Reader` who see an opportunity to make passing the month around less cumbersome. I don't find this too bad, though, so if you want to give that a shot, I'll leave that as an exercise for the reader. For the others who aren't familiar with `Reader`, don't sweat it, let's carry on!

In `filterAlbums`, we have a sub-expression named `scoreIsHighEnough`. Without thinking about it too much, let's go ahead and write another sub-expression called `cameOutThisMonth`.

    cameOutThisMonth :: Album -> Bool
    cameOutThisMonth album = (getMonthFromDay . date $ album) == currentMonth

Like `scoreIsHighEnough`, the function is of type `Album -> Bool`. We get the date from the album, and then pass it to our helper `getMonthFromDay`, which gives us back the month the album came out. We then check if it is equal to the currentMonth we passed in. Easy enough!

To use both of these together, you might think we need to use two `filter`s:

    filter cameOutThisMonth (filter scoreIsHighEnough)

And that would work, but it wouldn't be efficient. What would be nice is if we could compose these methods together. But we can't use `(.)` because they are both `Album -> Bool` and don't compose together.

Perhaps we need another function that can take the results of our functions and combine them together. This would be a function of type `Bool -> Bool -> Bool`. This function should return `True` if and only if the other two `Bool`s are `True`. If you're familiar with logical operators, you'd know that there is a function like this called `(&&)` (you can pronounce this as "logical AND" or "logical conjunction").

We need some way to pull all of this together... and we can do that with the help of Applicatives! If you're not familiar, I recommend [this post on Applicatives](https://mmhaskell.com/blog/2017/2/6/applicatives-one-step-further) as an introduction.

If you are familiar with Applicatives, but did not know that FUNCTIONS have their own Applicative instances, I recommend [this in depth chapter from Learn You a Haskell that covers Applicatives of Functions](http://learnyouahaskell.com/functors-applicative-functors-and-monoids#applicative-functors).

So the short of it is, with the Applicative instance of functions, we can take two functions and pass the results of them to a third function, which then "composes" to one function of type `Album -> Bool`.

Pulling this all together, we can write it out as:

    filterer :: Album -> Bool
    filterer = (&&) <$> cameOutThisMonth <*> scoreIsHighEnough

Or, more cleanly with `liftA2` from `Control.Applicative` (which does the same thing as above):

    filterer :: Album -> Bool
    filterer = liftA2 (&&) cameOutThisMonth scoreIsHighEnough

So now, with our new SUPER filterer, we can write `filterAlbums` as:

    filterAlbums :: Double -> Month -> [Album] -> [Album]
    filterAlbums lowestScore currentMonth = filter filterer
      where
        filterer :: Album -> Bool
        filterer = liftA2 (&&) cameOutThisMonth scoreIsHighEnough

        scoreIsHighEnough :: Album -> Bool
        scoreIsHighEnough album = case score album of
          Nothing -> True
          Just s  -> s >= lowestScore

        cameOutThisMonth :: Album -> Bool
        cameOutThisMonth album = (getMonthFromDay . date $ album) == currentMonth

Seriously, if any of that felt like magic to you, read those articles I linked! This is powerful stuff, and it can be yours to wield with patience!

`build` and `exec`, look at your `albums.json`, and you should see only albums that came out the month you ran it!

### Concurrency

For this final bit, we're not going to learn much. Instead, we're going to hand the heavy lifting over to the amazing `async` library. Add that to your `.cabal` file, run `stack build` to pull it in. At the top of the file, pull in `mapConcurrently` from `Control.Concurrent.Async`.

The first place we'll use this is when fetching scores. So in `getScores`, where we're using `traverse`, replace it with `mapConcurrently`:

    getScores :: Cursor -> IO [Maybe Double]
    getScores = mapConcurrently linkToScore . getReviewLinks

Then, where we're using `sequence` in `writeAlbumJSON`, replace with `mapConcurrently id`

    writeAlbumJSON :: FilePath -> IO ()
    writeAlbumJSON fileName = do
      (_, currentMonth, _) <- getCurrentDate
      albums <- sort . nub . join <$> mapConcurrently id
        [ getPitchforkAlbums currentMonth
        , getStereogumAlbums currentMonth
        ]
      encodeFile fileName albums

This makes sense, since `traverse` can be replaced wholesale, and `sequence` can be defined in terms of `traverse`:

    sequence = traverse id

`build` and `exec`, and your script should finish in a fraction of the speed!

### That's all

We've pulled in XML from multiple sources, formatted, filtered and sorted it according to our own rules, and exported it to JSON. All in just over 150 lines!

I know I had initially promised to pull in a third data source, but looking at what we've accomplished here, we wouldn't be covering any new ground (except for maybe file organization, which feels a bit boring for the focus of an article).

If you'd like the challenge, try and pull in Metacritic into your collection. I used [the Metacritic page with new releases](https://www.metacritic.com/browse/albums/release-date/new-releases/date) since they have a garbage XML feed. You'll have to inspect the source to look at how the HTML is built and make use of the CSS classes to traverse down to where the data is. It won't be easy, but you have all the tools needed.

The repo (linked below) contains the final code, so you can refer to it if you get lost or want to compare your solution to mine.

Thank you for reading! You can file complaints, request improvements, and report bugs in the code through [the git repo for aggr haskell](https://github.com/blrobin2/aggr-haskell)

### The Full Code

    {-# LANGUAGE DeriveGeneric     #-}
    {-# LANGUAGE OverloadedStrings #-}
    {-# LANGUAGE RecordWildCards   #-}
    module Main where

    import           Control.Applicative (liftA2)
    import           Control.Concurrent.Async (mapConcurrently)
    import           Control.Monad ((>=>), join)
    import           Data.Aeson
    import           Data.List (nub, sort)
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
      , date   :: Day
      , score  :: Maybe Double
      } deriving (Generic, Show)

    instance ToJSON Album where
      toJSON Album{..} = object
        [ "artist" .= artist
        , "title"  .= title
        , "date"   .= date
        ]

    instance Eq Album where
      (Album a1 t1 _ _) == (Album a2 t2 _ _) = a1 == a2 && t1 == t2

    instance Ord Album where
      compare (Album a1 _ d1 _) (Album a2 _ d2 _) = compare d2 d1 <> compare a1 a2

    toDay :: String -> Maybe Day
    toDay = parseTimeM True defaultTimeLocale "%a, %d %b %Y %X %z"

    toDate :: Text -> Day
    toDate = fromMaybe (ModifiedJulianDay 0)
          . toDay
          . T.unpack

    type Year = Integer
    type Month = Int

    getCurrentDate :: IO (Year, Month, Int)
    getCurrentDate = toGregorian . utctDay <$> getCurrentTime

    getMonthFromDate :: (a, Month, b) -> Month
    getMonthFromDate (_, month, _) = month

    getMonthFromDay :: Day -> Month
    getMonthFromDay = getMonthFromDate . toGregorian

    getArtistsAndTitles :: Cursor -> [Text]
    getArtistsAndTitles cursor =
      cursor $// element "item" &/ element "title" &// content

    getReleaseDates :: Cursor -> [Day]
    getReleaseDates cursor = map toDate dates
      where dates = cursor $// element "item" &/ element "pubDate" &// content

    toPartialAlbums :: Text -> [Text] -> [Day -> Maybe Double -> Album]
    toPartialAlbums splitter =
      map (toPartialAlbum splitter . map T.strip . T.splitOn splitter)

    toPartialAlbum :: Text -> [Text] -> (Day -> Maybe Double -> Album)
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

    parseScore :: Applicative m => Text -> m Double
    parseScore = pure . fromMaybe 0 . readMaybe . T.unpack

    linkToScore :: Text -> IO (Maybe Double)
    linkToScore link = parseScore . getScore
      <$> (getXmlCursor =<< parseRequest (T.unpack link))

    getScores :: Cursor -> IO [Maybe Double]
    getScores = mapConcurrently linkToScore . getReviewLinks

    filterAlbums :: Double -> Month -> [Album] -> [Album]
    filterAlbums lowestScore currentMonth = filter filterer
      where
        filterer :: Album -> Bool
        filterer = liftA2 (&&)
          cameOutThisMonth
          scoreIsHighEnough

        scoreIsHighEnough :: Album -> Bool
        scoreIsHighEnough album = case score album of
          Nothing -> True
          Just s  -> s >= lowestScore

        cameOutThisMonth :: Album -> Bool
        cameOutThisMonth album =
          (getMonthFromDay . date $ album)
          == currentMonth

    getStereogumAlbums :: Month -> IO [Album]
    getStereogumAlbums currentMonth = do
      cursor <- getXmlCursor "https://www.stereogum.com/heavy-rotation/feed/"
      let albumArtist = getArtistsAndTitles cursor
      let date = getReleaseDates cursor
      let partialAlbums = toPartialAlbums "–" albumArtist
      let albums = zipWith (\album date -> album date Nothing) partialAlbums date
      pure $ filterAlbums 0 currentMonth albums

    getPitchforkAlbums :: Month -> IO [Album]
    getPitchforkAlbums currentMonth = do
      cursor <- getXmlCursor "https://pitchfork.com/rss/reviews/albums/"
      let albumArtists = getArtistsAndTitles cursor
      let dates = getReleaseDates cursor
      scores <- getScores cursor
      let partialAlbums = toPartialAlbums ":" albumArtists
      let albums = zipWith3 (\album date score -> album date score)
                    partialAlbums dates scores
      pure $ filterAlbums 7.8 currentMonth albums

    writeAlbumJSON :: FilePath -> IO ()
    writeAlbumJSON fileName = do
      (_, currentMonth, _) <- getCurrentDate
      albums <- sort . nub . join <$> mapConcurrently id
        [ getPitchforkAlbums currentMonth
        , getStereogumAlbums currentMonth
        ]
      encodeFile fileName albums

    main :: IO ()
    main = writeAlbumJSON "albums.json"
