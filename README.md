Heimdallr Resource
==================

Heimdallr Resource is a gem which provides CanCan-like interface for writing secure
controllers on top of [Heimdallr](http://github.com/roundlake/heimdallr)-protected
models.

Overview
--------

API of Heimdallr Resource basically consists of two methods, `load_resource` and `load_and_authorize_resource`.
Both work by adding a filter in standard Rails filter chain and obey the `:only` and `:except` options.

`load_resource` loads a record or scope and wraps it in a Heimadllr proxy. For `index` action, a scope is loaded. For `show`, `new`, `create`, `edit`, `update` and `destroy` a record is loaded. No further action is performed by Heimdallr Resource.

`load_and_authorize_resource` loads a record and verifies if the current security context allows for creating, updating or destroying the records. The checks are performed for `new`, `create`, `edit`, `update` and `destroy` actions. `index` and `show` will simply follow the defined `:fetch` scope.

```ruby
class CricketController < ApplicationController
  include Heimdallr::Resource

  load_and_authorize_resource

  def index
    # @crickets is loaded and secured here
  end
  
  def show
    # @cricket is loaded by .find(params[:id]) and secured here
  end
  
  def create
    # @cricket is created, filled with params[:cricket] and secured here
  end

  def update
    # @cricket is loaded by .find(params[:id]) and secured here.
    # Fields from params[:cricket] won't be applied automatically!
  end

  def show
    # @cricket is loaded by .find(params[:id]) and secured here.
  end

  def destroy
    # @cricket is loaded by .find(params[:id]) and secured here.
  end
end
```

Custom entity
-------------

To explicitly specify which class should be used as a Heimdallr model you can use the following option:

```ruby
# This will use the Entity class
load_and_authorize :resource => :'entity'
# This will use the Namespace::OtherEntity class
load_and_authorize :resource => :'namespace/other_entity' 
```

Namespaces
----------
By default Heimdallr Resource will seek for the namespace just like it does with the class. So for `Foo::Bars` controller it will try to bind to `Foo::Bar` model.

Custom methods (besides CRUD)
-----------------------------

By default Heimdallr Resource will consider non-CRUD methods a `:record` methods (like `show`). So it will try to find entity using `params[:id]`. To modify this behavior to make it work like `index` or `create`, you can explicitly define the way it should handle the methods.

```ruby
load_and_authorize :collection => [:search], :new_record => [:special_create]
```

Inlined resources
-----------------
If you have inlined resource with such routing:

```ruby
resources :foos do
  resources :bars do
    resources :bazs
  end
end
```

Rails will provide `params[:foo_id]` and `params[:bar_id]` inside `BazsController`. To make Heimdallr search through and assign the parent entities you can use this syntax:

```ruby
load_and_authorize_resource :through => :foo
# or even
load_and_authorize_resource :through => [:foo, :bar]
```

If the whole path or some if its parts are optional, you can specify the `:shallow` option.

```ruby
load_and_authorize_resource :through => [:foo, :bar], :shallow => true
```

In the latter case it will work from any route, the direct or inlined one.

Credits
-------

<img src="http://roundlake.ru/assets/logo.png" align="right" />

* Peter Zotov ([@whitequark](http://twitter.com/#!/whitequark))
* Boris Staal ([@_inossidabile](http://twitter.com/#!/_inossidabile))
* Alexander Pavlenko ([@Alerticus](http://twitter.com/#!/Alerticus))

LICENSE
-------

It is free software, and may be redistributed under the terms of MIT license.
