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

License
-------

    Copyright (C) 2012  Peter Zotov <whitequark@whitequark.org>

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.