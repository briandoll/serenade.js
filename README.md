# Monkey.js

Monkey.js is yet another MVC client side JavaScript framework. Why do we
indulge in recreating the wheel? We believe that Monkey.js more closely follows
the ideas of classical MVC than competing frameworks and has a number of other
advantages as well:

* Super pretty, powerful yet logic-less template language
* Data bindings keep your views up-to-date without any extra work
* Powerful caching and synchronization features
* Absolutely no dependencies, everything works without jQuery
* No need to inherit from base classes anywhere (though you can if you want)

## Architecture

In Monkey.js you define templates and render them, handing in a controller and
a model to the template. Monkey.js then handles getting values from the model
and updating them dynamically as the model changes, as well as dispatching
events to the controller when they occur. Templates are "logic-less" in that
they do not allow the execution of any code. Monkey.js is built around its
template engine, so unfortunately you do not have a choice as to the template
language.

Monkey.js also bundles a powerful abstraction for talking with RESTful
services, you can use Monkey.Model to persist and retrieve data, as well as
cache data in local storage.

## A simple example

Let us start off by creating a model and controller:

``` coffeescript
controller = { showAlert: -> alert('Alert!!!') }
model = { name: 'Jonas' }
```

As you can see, these are just normal JavaScript objects. Monkey.js does not
force you to use any kind of base object or class for models and controllers.

Let us now register a view, we are using Monkey.js's own template language here:

``` coffeescript
Monkey.registerView 'test', '''
  div[id="hello-world"]
    h1 name
    p
      a[event:click=showAlert href="#"] "Show the alert"
'''
```

Once we have a view registered, we can render it using `Monkey.render`, passing
in the model and controller we created before:

``` coffeescript
result = Monkey.render('test', model, controller)
```

The result we are getting back is just a regular DOM element. This element has
all events already attached, so you can just insert it into the DOM anywhere,
and you're good to go. Using standard DOM methods, we could do that like this:

``` coffeescript
window.onload = ->
  document.body.appendChild(result)
```

If you're using jQuery, you can use jQuery's `append` function to append the
element anywhere on the page.

``` coffeescript
$ -> $('body').append(result)
```

This example is written in CoffeeScript for easier readability, but there is
nothing stopping you from writing this in plain JavaScript as well.

## Dynamic properties

Unfortunately JavaScript does not make it possible to track changes to
arbitrary objects, so in order to update the view automatically as the model
changes, we will have to add some functionality to it. Thankfully this is quite
simple:

``` coffeescript
model = {}
Monkey.extend(model, Monkey.Properties)
model.property 'name'
```

Now we can set and get the name property using the `set` and `get` methods:

``` coffeescript
model.set('name', 'Peter')
model.get('name')
```

In browsers which support `Object.defineProperty`, we can even set and get this
property directly, like so:

``` coffeescript
model.name = 'Peter'
model.name
```

Note that Opera and IE8 and below do *not* support this, so you might want to
refrain from using this syntax. Further note that it is not strictly necessary
to call `model.property 'name'` unless you plan on using this feature, `get`
and `set` work fine without the property being declared.

If your model is a constructor, you might want to add the properties to its
prototype instead:

``` javascript
var MyModel = function(name) {
  this.set('name', name);
};
Monkey.extend(MyModel.prototype, Monkey.Properties)
```

Or in CoffeeScript:

``` coffeescript
class MyModel
  Monkey.extend(@prototype, Monkey.Properties)
```

## Template Language

The Monkey.js template language is inspired by Slim, Jade and HAML, but not
identical to any of these.

Any view in Monkey.js must have an element as its root node. Elements may have
any number of children. Elements can have attributes within square brackets.

This is a single element with no children and an id attribute:

``` slim
div[id="monkey"]
```

Indentation is significant and is used to nest elements:

``` slim
div
  div[id="page"]
    div[id="child"]
  div[id="footer"]
```

Attributes may be bound to a model value by omitting the quotes:

``` slim
div[id=modelId]
```

Similarly text can be added to any element, this may be either
bound or unbound text or any mix thereof:

``` slim
div "Name: " name
```

## Events

Events are dispatched to the controller. The controller may choose to act on
these events in any way it chooses. The controller has a reference to both the
model, through `this.model`, and the view, through `this.view`.  These
properties will be set automatically by Monkey.js as the view is rendered. If
the view is a subview, the controller can also access its parent controller
through `this.parent`.

While you *can* access the view and thus dynamically change it from the
controller through standard DOM manipulation, you should generally avoid doing
this as much as possible. Ideally your controller should only change properties
on models, and those changes should then be dynamically reflected in the view.
This is the essence of the classical MVC pattern.

Events are bound by using the `event:name=bidning` syntax for an element's
attributes like so:

``` slim
div
  h3 "Post"
  a[href="#" event:click=like] "Like this post"
```

You can use any DOM event, such as `submit`, `mouseover`, `blur`, `keydown`,
etc. This will now look up the property `like` on your controller and call it
as a function. You could implement this as follows:

``` coffeescript
controller =
  like: -> @model.set('liked', true)
```

Note that we do not have to set `@model` ourselves, Monkey.js does this for
you.

In this example, if we have scrolled down a bit, we would jump to the start of
the page, since the link points to the `#` anchor. In many JavaScript
frameworks such as jQuery, we could fix this by returning `false` from the
event handler. In Monkey.js, returning false does nothing. Thankfully the event
object is passed into the function call on the controller, so we can use the
`preventDefault` function to stop the link being followed:

``` coffeescript
controller =
  like: (event) ->
    @model.set('liked', true)
    event.preventDefault()
```

You can use `event` for any number of things here, such as attaching the same
event to multiple targets and then figuring out which triggered the event
through `event.target`.

Preventing the default action of an event is really, really common, so having
to call `preventDefault` everywhere gets old very fast. For this reason,
Monkey.js has a special syntax in its templates to prevent the default action
without having to do any additional work in the controller. Just append an
exclamation mark after the event binding:

``` slim
div
  h3 "Post"
  a[href="#" event:click=like!] "Like this post"
```

## Binding styles

We can change the style of an element by binding its class attribute to a model
property. If possible, this is what you should do, since it separates styling
from behaviour. Sometimes however, its necessary to bind a style attribute
directly. Consider for example if you have a progress bar, whose width should
be changed based on the `progress` property of a model object.

You can use the special `style:name=value` syntax to dynamically bind styles to
elements like so:

``` slim
div[class="progress" style:width=progress]
```

Style names should be camelCased, like in JavaScript, not dash-cased, like in
CSS. That means you should write `style:backgroundColor=color`, not
`style:background-color=color`.

## Collections

Oftentimes you will want to render a collection of objects in your views.
Monkey has special syntax for collections built into its template language.
Assuming you have a model like this:

``` coffeescript
post =
  comments: [{ body: 'Hello'}, {body: 'Awesome!'}]
```

You could output the list of comments like this:

``` slim
ul[id="comments"]
  - collection comments
    li body
```

This should output one li element for each comment.

If `comments` is an instance of `Monkey.Collection`, Monkey.js will dynamically
update this collection as comments are added, removed or changed:

``` coffeescript
post =
  comments: new Monkey.Collection([{ body: 'Hello'}, {body: 'Awesome!'}])
```

## Views

It can be convenient to split parts of view into subviews. The `view` instruction
does just that:

``` slim
div
  h3 "Most recent comment"
  - view post
```

Assuming that there is a post view registered with `Monkey.registerView('post',
'...')` that view will now be rendered.

It will often be useful to use the `view` and `collection` instructions
together:

``` slim
div
  h3 "Comments"
  ul
    - collection comments
      - view comment
```

By default, the subviews will use the same controller as their parent view.
This can be quite inconvenient in a lot of cases, and we would really like to
use a specific controller for this new view.

If your controller can be instantiated with JavaScript's `new` operator, you
can use `registerController` to tell Monkey.js which controller to use for your
view. Any constructor function in JavaScript and any CoffeeScript class can be
used here. For example:

``` javascript
var CommentController = function() {};
Monkey.registerController 'comment', CommentController
```

Or in CoffeeScript:

``` coffeescript
class CommentController
Monkey.registerController 'comment', CommentController
```

Monkey.js will now infer that you want to use a `CommentController` with the
`comment` view.

## Monkey.Model

It can be quite convenient to use any old JavaScript object as a model, but
sometimes we require more powerful abstractions. Monkey offers a base for
building objects which is quite powerful. You can use it like this:

``` coffeescript
class MyModel extends Monkey.Model
```

You can use the same property declarations in these models:

``` javascript
MyModel.property('name')
```
