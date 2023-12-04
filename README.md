# Railcutters

[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

After years developing Rails applications, you eventually get used to a certain patterns that are
not the default on the framework. As much as I love the defined opinions, good defaults and
guardrails for the most part, there's still some small nuisances that are left to personal taste.

This is partially true for every Rails developer who has touched more than a few codebases:
sometimes you end up carrying some patterns, helpers or settings from one project to another,
most of the time for the convenience, but also for the sake of consistency - individual or
team-wise.

Railcutters is a mix of patterns, features, libraries and settings that allowed me to leverage the
power of Rails while being able to keep some sanity while hopping between projects. Think of it as a
gem that does something similar to [suspenders](https://github.com/thoughtbot/suspenders).

Yet, you don't need to go all in if you don't want/need to. It is made to be decoupled and
composable, and you can configure individual feature sets that you want.

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
