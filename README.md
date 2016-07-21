# The introduction to RxSwift you've been missing

This work is inspired by [The introduction to Reactive Programming you've been missing](https://gist.github.com/staltz/868e7e9bc2a7b8c1f754) 
from [@andrestaltz](https://twitter.com/andrestaltz).
I recreate his RxJS sample code in RxSwift with a step-by-step walkthrough, 
for those struggling with learning RxSwift due to lack of good references (as I did).

<img src="https://i.gyazo.com/60f3a1b7dc9384b7400a6780cd82e727.gif" width="400">

---

So you're finding yourself having trouble with learning this new Swift trend. You are not alone. 

RxSwift is hard, especially with the lack of good references. 
All tutorials out there is either too general or too specific, and ReactiveX document just don't help:

> Rx.Observable.prototype.flatMapLatest(selector, [thisArg])

> Projects each element of an observable sequence into a new sequence of observable sequences 
> by incorporating the element's index and then transforms an observable sequence of observable sequences 
> into an observable sequence producing values only from the most recent observable sequence.

![Imgur](http://i.imgur.com/hLF5F3K.png)

I ended up digging to RxSwift examples and some [open source app](https://github.com/devxoul/RxTodo).
The RxSwift's [very first document](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Why.md) 
bring in RxSwift's `Binding` or `Retry` - things that I haven't got a clue about. 
Reading code is not easy also, since it introduces RxSwift in very detail with `RxDataSources` and `Moya/RxSwift` *at the same time*.

So I decided to code a sample app that present exactly "Who to Follow" pattern with step by step explanation. This is equivalent to Andre's work but is written in Swift instead, and I hope this can help you learning RxSwift easier than me :smile:

# What is Reactive Programming?
Tapping a button, typing one chracter inside a label, etc, every occurrence triggered by user can be considered as a typical asynchronous event.
What if our user repeatedly tap an element, or continuously typing in a search bar? 
This time we have *asynchronous event streams*.

```
--a---b-c---d---X---|->

a, b, c, d are events
X is an error event
| is the 'completed' signal
---> is the timeline
```

You are able to create data streams of anything, not just from tap and typing events. 
Streams are cheap and ubiquitous, anything can be a stream: variables, user inputs, properties, caches, data structures, etc. 
For example, imagine your Twitter feed would be a data stream in the same fashion that tap events are. 
You can listen to that stream and react accordingly.

On top of that, you are given an amazing toolbox of functions to combine, create and filter any of those streams. 
That's where the "functional" magic kicks in. 
A stream can be used as an input to another one. 
Even multiple streams can be used as inputs to another stream. 
You can merge two streams. 
You can filter a stream to get another one that has only those events you are interested in. 
You can map data values from one stream to another new one.

```
buttonTapStream: ---t----t--t----t------t-->
                 vvvvv map(t becomes 1) vvvv
                 ---1----1--1----1------1-->
                 vvvvvvvvv scan(+) vvvvvvvvv
counterStream:   ---1----2--3----4------5-->
```

In Reactive World streams are called **Observables**, represented by a timeline with ongoing event in time order.
Every Observable is **immutable**, which means that each stream composition will create completely new Observable.
 
Reactive Programming(RP) introduce a whole new paradigm in development for reactive applications. 
Mobile apps today are highly interactive with UI events related to data flow in the back. 
No screen transition are made but user can see search result while typing in search bar, or pull down for instant refresh, etc.
 
# Implementing a "Who to follow" suggestions box
Let's dive into real-world example. This is Twitter's UI element that suggests other accounts you may want to follow

![Who To Follow](https://camo.githubusercontent.com/81e5d63c69768e1b04447d2e246f47540dd83fbd/687474703a2f2f692e696d6775722e636f6d2f65416c4e62306a2e706e67)

I am going to implement core features below
* On startup, load accounts data from the API and display 3 suggestions
* On tapping "Refresh", load 3 other account suggestions into the 3 rows
* On tapping 'x' button on an account row, clear only that current account and display another
* Each row displays the account's avatar and their name.

Because Twitter don't provide its API to unauthorized public, I will use Github API instead. 
There's a [Github API](https://developer.github.com/v3/users/#get-all-users) for getting users with a `since` offset parameter.
You can check the working code by cloning this repo.

# Request and Response
Let's will start with the easiest feature: "On startup, load accounts data from the API and display 3 suggestions". This is simply about

1. Doing a request
2. Getting response
3. Rendering response data to UITableView

Doing a request is the most basic part in this project. 
We already know great library for request such as Alamofire, but let's think in Rx first. 
Consider that request's URL is a string, in this case `https://api.github.com/users`, then we can create our very first *Observable object*: `Observable<String>`
```Swift
let requestStream: Observable<String> = Observable.just("https://api.github.com/users")
```

This is a *stream* of URLs, in this case only one event (the URL string) will be emitted.

```
--a------|->

Where a is the string "https://api.github.com/users"
```

`requestStream` is just a stream of strings, doing no other operation, we need to make the "real" request happen when the event is emmited by *subscribing* to it
```Swift
requestStream.subscribeNext { url in 
  // Do the real request to Github API, get back a `User` model
  let responseStream: Observable<[User]> = UserModel().findUsers(url)
}
```

Note that `responseStream` is also an `Observable`. 
You can find the detail implement of `UserModel().findUsers(url)` later on this repo, but for now just conside it as a method which return a list of Users from Github response, then wrapped inside an `Observable` type.

So next step is rendering this list of Users to UITableView, which can be done with subcribing the `responseStream` again
```Swift
requestStream.subscribeNext { url in 
  let responseStream: Observable<[User]> = UserModel().findUsers(url)
  responseStream.subscribeNext { users in
    // ...
  }
}
```

If you were quick to notice, we have one `subscribeNext` call inside another, which is somewhat akin to callback hell. 
In Rx there are simple mechanisms for transforming and creating new streams out of others, and the corresponding method here is `map(f)`.

```Swift
let responseStream = requestStream.map { url in 
  return UserModel().findUsers(url)
}
```
We just created a beast called "metastream": a stream of streams. 
Don't panic yet. 
A metastream is a stream where each emitted value is yet another stream. 
You can think of it as [pointers](https://en.wikipedia.org/wiki/Pointer_(computer_programming)): each emitted value is a pointer to another stream. 
In our example, each request URL is mapped to a pointer to the stream containing the corresponding response.

![MetaStream](https://camo.githubusercontent.com/2a8a9cc75acd13443f588fd7f386bd7a6dcb271a/687474703a2f2f692e696d6775722e636f6d2f48486e6d6c61632e706e67)

A metastream looks confusing and we just want a simple stream of response where each emitted value is a directly `[User]`, not stream of `[User]`. 
Say hi to `flatMap(f)`, version of map() that "flattens" a metastream, by emitting on the "trunk" stream everything that will be emitted on "branch" streams. 
`flatmap` is not a "fix" and metastreams are not a bug, these are really the tools for dealing with asynchronous responses in Rx.

```Swift
let responseStream = requestStream.flatMap { url in 
  return UserModel().findUsers(url)
}
```

![flatMap](https://camo.githubusercontent.com/0b0ac4a249e1c15d7520c220957acfece1af3e95/687474703a2f2f692e696d6775722e636f6d2f4869337a4e7a4a2e706e67)

Nice. If we have more events happenning in `requestStream` (like continuous tapping a button or typing text), we will have the corresponding response results on `responseStream`, as expected:

```
requestStream:  --url-------url----------url------------|->
responseStream: -----[User]-----[User]-----[User]-------|->
```

Joining all the code until now, we have:
```Swift
let requestStream: Observable<String> = Observable.just("https://api.github.com/users")
let responseStream = requestStream.flatMap { url in 
  return UserModel().findUsers(url)
}
responseStream.subscribeNext { users in
  // users is a normal [User] list, here comes the UI Rendering part
}
```

# The refresh button
We will want a set of 3 new users every time when user tapped the "refresh" button. How to achieve this scenario?

We need 2 stream: a stream of tap event on the refresh button, and a stream of API URL transformed from that stream. 
In RxSwift, the stream of tap event can be created with method `rx_tap`
```Swift
let refreshStream = refresh.rx_tap
let requestStream: Observable<String> = refreshStream.map { _ in
  let random = Array(1...1000).random()
  return "https://api.github.com/users" + String(random)
}
```
*`refresh` is an outlet for Refresh button in our class, and random() is a custom extension*

Because I'm dumb and I don't have automated tests, I just broke one of our previously built features: a request doesn't happen anymore on startup, it happens only when the refresh button is tapped.
Urgh. I need both behaviors: a request when either refresh button is tapped or the UITableVIew  was just loaded.

We know how to make a separate stream for each one of those cases:
```Swift
let refreshStream = refresh.rx_tap
let requestStream: Observable<String> = refreshStream.map { _ in
  let random = Array(1...1000).random()
  return "https://api.github.com/users" + String(random)
}
let beginningStream: Observable<String> = Observable.just("https://api.github.com/users")
```

But how can we "merge" these two into one? Well, there's `merge()`. 
```
stream A: ---a--------e-----o----->
stream B: -----B---C-----D-------->
          vvvvvvvvv merge vvvvvvvvv
          ---a-B---C--e--D--o----->
```

In detail:
```Swift
let requestStream = Observable.of(refreshStream, beginningStream).merge()
```

And there is a cleaner way without the intermediate streamsm, by using `startWith(())`
```Swift
let refreshStream = refresh.rx_tap.startWith(())
let requestStream: Observable<String> = refreshStream.map { _ in
  let random = Array(1...1000).random()
  return "https://api.github.com/users" + String(random)
}
```

# 3 suggestions streams
As soons as we received users information from `responseStream`, we will want to show it immmediately on 3 UITableVIewCell. 
Let's think about Reactive mantra: "Everything is a stream"

![Mantra](https://camo.githubusercontent.com/e581baffb3db3e4f749350326af32de8d5ba4363/687474703a2f2f692e696d6775722e636f6d2f4149696d5138432e6a7067)

So let's create a seperated stream *for each cell*.
```Swift
// Inside func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
let userStream: Observable<User?> = responseStream.map { users in
  guard users.count > 0 else {return nil}
  return users.random()
}
```

With the refresh button we have a problem: as soon as user tap 'Refresh', the current 3 suggestions are not cleared. 
New suggestions come in only after a response has arrived, but to make the UI look nice, we need to clean out the current suggestions when taps happen on the refresh. 
We can do that by mapping Refresh tap to a nil stream, and merge to above `userStream` as such:
```Swift
let nilOnRefreshTapStream: Observable<User?> = refresh.rx_tap
  .map {_ in return nil}
let suggestionStream = Observable.of(userStream, nilOnRefreshTapStream)
  .merge()
```
And when rendering, we interpret `nil` as "no data", hence hiding cell's UI element:
```Swift
suggestionStream.subscribeNext{ op in
  guard let u = op else { return self.clearCell(cell) }
  return self.setCell(cell, user: u )
}.addDisposableTo(cell.disposeBagCell)
```
The big picture is now:
```
           refreshStream: ----------o--------o---->
           requestStream: -r--------r--------r---->
          responseStream: ----R---------R------R-->   
suggestionStream(Cell 1): ----s-----N---s----N-s-->
suggestionStream(Cell 2): ----q-----N---q----N-q-->
suggestionStream(Cell 3): ----t-----N---t----N-t-->
```
Where N stands for nil.
As a bonus, we can also render "empty" suggestions on startup. 
That is done by adding `.startWith(.None)` to the suggestion streams:
```Swift
let nilOnRefreshTapStream: Observable<User?> = refresh.rx_tap
  .map {_ in return nil}
let suggestionStream = Observable.of(userStream, nilOnRefreshTapStream)
  .merge()
  .startWith(.None)
```
Which results in:
```Swift
           refreshStream: ----------o--------o---->
           requestStream: -r--------r--------r---->
          responseStream: ----R---------R------R-->   
suggestionStream(Cell 1): -N--s-----N---s----N-s-->
suggestionStream(Cell 2): -N--q-----N---q----N-q-->
suggestionStream(Cell 3): -N--t-----N---t----N-t-->
```

# Closing a suggestion and using cached responses
There is one feature remaining to implement. 
Each suggestion should have its own 'x' button for closing it, and loading another in its place. 
At first thought, you could say it's enough to make a new request when any close button is tapped
```Swift
let closeStream = cell.cancel.rx_tap // "cancel" is outlet for cancel button
let requestStream = Observable.of(refreshStream, closeStream)
  .merge()
  .map { _ in
  let random = Array(1...1000).random()
  return "https://api.github.com/users" + String(random)
}
```
This will close and reload *all suggestion*, rather than just only the one user tapped on. 
There are a couple of different ways of solving this, and to keep it interesting, we will solve it by reusing previous responses. 
The API's response page size is 100 users while we were using just 3 of those, so there is plenty of fresh data available. 
No need to request more.

Again, let's think in streams. When a 'close' tap event happens, we want to use the most recently emitted (and cached) response on `responseStream` to get one random user from the list in the response. As such:

```Swift
   requestStream: --r--------------->
  responseStream: ------R----------->
closeClickStream: ------------c----->
suggestionStream: ------s-----s----->
```

In Rx* there is a combinator function called `combineLatest(f)` that seems to do what we need. 
It takes two streams A and B as inputs, and whenever either stream emits a value, combineLatest joins the two most recently emitted values a and b from both streams and outputs a value c = f(x,y), where f is a function you define. 
It is better explained with a diagram:

```Swift
stream A: --a-----------e--------i-------->
stream B: -----b----c--------d-------q---->
          vvvvvvvv combineLatest(f) vvvvvvv
          ----AB---AC--EC---ED--ID--IQ---->

where f is the uppercase function
```

We can apply combineLatest() on `closeStream` and `responseStream`, so that whenever the close button is tapped, we get the latest response emitted and produce a new value on `suggestionStream`. 
On the other hand, `combineLatest(f)` is symmetric: whenever a new response is emitted on `responseStream`, it will combine with the latest 'close' tap to produce a new suggestion. 

```Swift
let closeStream = cell.cancel.rx_tap
let userStream: Observable<User?> = Observable.combineLatest(closeStream, responseStream)
{ (_, users) in
  guard users.count > 0 else {return nil}
  return users.random()
}
let nilOnRefreshTapStream: Observable<User?> = refresh.rx_tap.map {_ in return nil}
let suggestionStream = Observable.of(userStream, nilOnRefreshTapStream)
  .merge()
  .startWith(.None)
```
One piece is still missing in the puzzle. 
The `combineLatest(f)` uses the most recent of the two sources, but if one of those sources hasn't emitted anything yet, `combineLatest(f)` cannot produce a data event on the output stream. 
If you look at the ASCII diagram above, you will see that the output has nothing when the first stream emitted value a. 
Only when the second stream emitted value b could it produce an output value.

There are different ways of solving this, and we will stay with the simplest one, which is simulating a tap to the 'close' button on startup:
```Swift
let closeStream = cell.cancel.rx_tap.startWith(())
```

# Wrapping up
We are done. The complete code is below
```Swift
let refreshStream = refresh.rx_tap.startWith(())
let requestStream: Observable<String> = refreshStream.map { _ in
  let random = Array(1...1000).random()
  return "https://api.github.com/users" + String(random)
}
let responseStream = requestStream.flatMap { url in 
  return UserModel().findUsers(url)
}

// Inside func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
let closeStream = cell.cancel.rx_tap.startWith(())
let userStream: Observable<User?> = Observable.combineLatest(closeStream, responseStream)
{ (_, users) in
  guard users.count > 0 else {return nil}
  return users.random()
}
let nilOnRefreshTapStream: Observable<User?> = refresh.rx_tap.map {_ in return nil}
let suggestionStream = Observable.of(userStream, nilOnRefreshTapStream)
  .merge()
  .startWith(.None)

suggestionStream.subscribeNext{ op in
  guard let u = op else { return self.clearCell(cell) }
  return self.setCell(cell, user: u )
}.addDisposableTo(cell.disposeBagCell)
```

You can see the working example on this repo.

That example is small but dense: it features management of multiple events with proper separation of concerns, and even caching of responses. 
The functional style made the code look more declarative than imperative: we are not giving a sequence of instructions to execute, we are just telling what something is by defining relationships between streams. 
For instance, with Rx we told the computer that `suggestionStream` is the 'close' stream combined with one user from the latest response, besides being nil when a refresh happens or program startup happened.

Notice also the impressive absence of control flow elements such as if, for, while, and the typical callback-based control flow that you expect from a Swift/IOS application. 
You can even get rid of the if and else in the `subscribeNext()` above by using `filter()` if you want (I'll leave the implementation details to you as an exercise). 
In Rx, we have stream functions such as map, filter, scan, merge, combineLatest, startWith, and many more to control the flow of an event-driven program. 
This toolset of functions gives you more power in less code.

# Where to go from here
If you think RxSwift will be your preferred library for IOS Programming, take a while to get acquainted with [RxSwift API](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/API.md) for transforming, combining, and creating Observables. 
If you want to understand those functions in diagrams of streams, take a look at [Marble diagrams](http://rxmarbles.com/). 
Whenever you get stuck trying to do something, draw those diagrams, think on them, look at the long list of functions, and think more. 
This workflow has been effective in my experience.

Once you start getting the hang of programming with RxSwift, you will need to get used to libraries which are using along such as `RxCocoa`, `Moya/RxSwift`, `RxDataSources` and then [Driver](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Units.md), etc. 
Finally, sharpen your skills further by learning real functional programming, and getting acquainted with issues such as side effects that affect Rx.

If this tutorial helped you, [tweet it forward](https://twitter.com/intent/tweet?original_referer=https:%2F%2Fgithub.com%2FDTVD%2FThe-introduction-to-RxSwift-you-have-been-missing&amp;text=The%20introduction%20to%20RxSwift%20you%27ve%20been%20missing&amp;tw_p=tweetbutton&amp;url=https:%2F%2Fgithub.com%2FDTVD%2FThe-introduction-to-RxSwift-you-have-been-missing&amp;via=dtvd88).

### Legal
This is primarily created by Andre Cesar de Souza Medeiros (alias "Andre Staltz"), 2014, and modified by Vu Nhat Minh (@Orakaro), 2016. 

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://licensebuttons.net/l/by-nc/4.0/88x31.png" /></a>

"Introduction to RxSwift you've been missing" by Vu Nhat Minh is licensed under a [Creative Commons Attribution-NonCommercial 4.0 International License]("Introduction to Reactive Programming you've been missing" by Andre Staltz is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.).
