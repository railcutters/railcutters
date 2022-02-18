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
