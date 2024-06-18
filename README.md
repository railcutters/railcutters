# Railcutters

[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/standardrb/standard)

After years developing Rails applications, you eventually get used to a certain patterns that are
not the default on the framework. As much as I love the defined opinions, good defaults and
guardrails for the most part, there's still some small nuisances that are left to personal taste.

This is partially true for every Rails developer who has touched more than a few codebases:
sometimes you end up carrying some patterns, helpers or settings from one project to another,
most of the time for the convenience, but also for the sake of consistency - individual or
team-wise.

Railcutters is a mix of patterns, features, libraries and preset settings that allowed me to
leverage the power of Rails while being able to keep some sanity while hopping between projects.

Yet, you don't need to go all in if you don't want/need to. It is made to be decoupled and
composable, and you can configure individual feature sets that you want.

It goes without saying that this is a work in progress, so expect things to change, but so far
everything is kept as simple as possible so you can review the code yourself and backed by a good
test suite.

## Breaking configuration

Some of the configuration will drastically change the way you write your code, so they are
classified as breaking changes. They are recommended for brand new projects or if you're willing to
change the existing code. In either case, you can disable these features individually or simply
disable all breaking changes by setting `config.railcutters.set_safe_defaults!` in your
configuration.

## Requirements

This gem is officially meant to be supported by Rails **7.1+**. It may work on older versions, but
it is not guaranteed, as it is not tested against them.

## Install

Add this to your `Gemfile`:

```ruby
gem "railcutters", git: "https://github.com/railcutters/railcutters.git", branch: "main"
```

At this point in time, this is an alpha project, so until `v1`, expect things to change.

## Features

### ActionController::Base\#params.rename()

Allow controller parameters to be renamed with an easy-to-use syntax:

```ruby
def user_id_params
  params.rename("user.id" => "user_id").permit(:user_id)
end
```

Disable it setting `config.railcutters.use_params_renamer = false` in your configuration.

### ActionController::Metal\#paginate() [alpha]

Paginate a collection with an easy-to-use syntax:

```ruby
class UsersController < ApplicationController
  def index
    @users = paginate(User.where(customer_id: params[:customer_id]))
  end
end
```

This will automatically paginate the collection using the `page` and `per_page` parameters sent
from the frontend. It also allows you to customize the pagination options by passing a hash as the
second argument:

```ruby
class UsersController < ApplicationController
  def index
    @users = paginate(User.where(customer_id: params[:customer_id]), page: 4, per_page: 10)
  end
end
```

It outputs a `Pagination` header with the pagination information, so you can use it to render a
pagination component in your frontend:

Example header: `Pagination: page=1,per-page=30,total-records=100,total-pages=4`

Disable it setting `config.railcutters.use_pagination = false` in your configuration.

### Normalize controller parameters to use snake_case

It allows you to always rely that parameters sent from your frontend will have `snake_case` keys,
while converting them to `camelCase` before sending them back to the frontend. It allows you to use
the best of both worlds, while keeping the codebase consistent on both frontend and backend.

For converting keys to `camelCase`, you need to use `Jbuilder`.

Disable it setting `config.railcutters.normalize_payload_keys = false` in your configuration.

> This configuration is a breaking change if you are already counting on the case of the parameters
> in your application. This is recommended for new projects, and if you're not willing to change the
> existing code, you can disable this feature and any other breaking change by setting
> `config.railcutters.set_safe_defaults!` in your configuration.

### ActiveRecord::Enum defaults

#### Default behavior for arrays to be equivalent to hashes with key and value being the same

This helps keeping the database enum values consistent with the Ruby enum values, so it's easier to
read them in the database. It also prevents you from mistakenly add a new value to the enum array
without having the order in consideration, which can be a source of bugs.

```ruby
class User < ApplicationRecord
  enum status: %i[active inactive]
  # Is equivalent to:
  enum status: { active: "active", inactive: "inactive" }
end
```

Disable it setting `config.railcutters.use_enum_defaults = false` in your configuration.

> It goes without saying that this configuration is a breaking change if you are already using enums
> in your application. This is recommended for new projects, and if you're not willing to change the
> existing code, you can disable this feature and any other breaking change by setting
> `config.railcutters.set_safe_defaults!` in your configuration.

#### Default options when defining an enum

This helps you setting a default options to every enum you define, so you don't need to repeat them.
By default, it sets the `prefix` option to `true`, so you can avoid clashing names when using
different enums with the same value.

It also sets the `validate` option to `true`, a new option
available since Rails 7.1 that avoids invalid enums to fail with a `ArgumentError` exception and
instead adds a validation error to the model.

Set your own defaults with `config.railcutters.enum_defaults = { ... }` in your configuration.

> It goes without saying that this configuration is a breaking change if you are already using enums
> in your application. This is recommended for new projects, and if you're not willing to change the
> existing code, you can disable this feature and any other breaking change by setting
> `config.railcutters.set_safe_defaults!` in your configuration.

### Logger

#### KVTaggedLogger [beta]

This is a Rails logger that allows you to add tags in the format of a key-value to the log messages
instead of a plain string. It is useful for adding information that would otherwise be hard to parse
in your log aggregator such as Grafana Loki or Splunk, for example.

This is an opt-in feature, and to use it, you need to configure your logger like that:

```ruby
# Use a TID for request and job logs
config.log_tags = {tid: :request_id}
config.active_job.log_tags = {tid: :job_id}

# Log to STDOUT by default
config.logger = Railcutters::Logging::HashTaggedLogger.new(
  $stdout,
  formatter: Railcutters::Logging::LogfmtFormatter.new
)
```

We currently ship two log formatters: `LogfmtFormatter` and `HumanFriendlyFormatter`. The former is
the recommendation for production environments, and the latter is meant to be used in development
mode.

When enabled, you can add tags to your log messages like that:

```ruby
Rails.logger.tagged(user_id: 1) do
  Rails.logger.info("User created")
end
```

This will output the following log message, when using the `LogfmtFormatter`:

```
user_id=1 msg="User created"
```

By default, when enabled, it will also reduce the verbosity of request log messages, while also
converting many of Rails internal log messages to use the new format.
