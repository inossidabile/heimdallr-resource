Heimdallr Resource
==================

Heimdallr Resource is a gem which provides CanCan-like interface for writing secure
controllers on top of [Heimdallr](http://github.com/roundlake/heimdallr)-protected
models.

``` ruby
class CricketController < ApplicationController
  include Heimdallr::Resource

  load_and_authorize_resource

  # or set the name explicitly:
  #
  # load_and_authorize_resource :resource => :cricket

  # if nested:
  #
  # routes.rb:
  #   resources :categories do
  #     resources :crickets
  #   end
  #
  # load_and_authorize_resource :through => :category

  def index
    # @crickets is loaded and secured here
  end
end
```

Overview
--------

API of Heimdallr Resource basically consists of two methods, `load_resource` and `authorize_resource`.
Both work by adding a filter in standard Rails filter chain and obey the `:only` and `:except` options.

`load_resource` loads a record or scope and wraps it in a Heimadllr proxy. For `index` action, a scope is
loaded. For `show`, `new`, `create`, `edit`, `update` and `destroy` a record is loaded. No further action
is performed by Heimdallr Resource.

`authorize_resource` verifies if the current security context allows for creating or updating the records.
The checks are performed for `new`, `create`, `edit` and `update` actions.

Credits
-------

Peter Zotov ([@whitequark](http://twitter.com/#!/whitequark))
Boris Staal ([@_inossidabile](http://twitter.com/#!/_inossidabile))

()[!roundlake.ru/assets/logo.png]

LICENSE
-------

It is free software, and may be redistributed under the terms specified in the LICENSE file.