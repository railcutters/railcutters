# Railcutters

[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/standardrb/standard)

After years developing Rails applications, one eventually get used to a certain patterns that are
not the default on the framework. As much as we love the defined opinions, good defaults and
guardrails for the most part, there's still some small nuisances that are left to personal taste.

This is partially true for every Rails developer who has touched more than a few codebases:
sometimes you end up carrying some patterns, snippets, helpers or settings from one project to
another, most of the time for the convenience, but also for the sake of consistency - individual or
team-wise.

Railcutters is a mix of patterns, features, libraries and preset settings that allowed me to
leverage the power of Rails while being able to keep some sanity while hopping between projects.

Yet, you don't need to go all in if you don't want/need to. It is made to be decoupled and
composable, and you can configure individual specific features that you want.

It goes without saying that this is a work in progress, so expect things to change, but so far
everything is kept as simple as possible so you can review the code yourself and it's also backed by
a good test suite.

## Breaking configuration

Some of the configuration will dramatically change the way you write your code, so they are
classified as breaking configurations. They are recommended for brand new projects or if you're
willing to change the existing code.

In either case, you can disable these features individually or simply disable all breaking changes
by setting `config.railcutters.use_safe_defaults!` in your configuration.

## Requirements

This gem is officially meant to be supported by Rails **7.1+**. It may work on older versions, but
it is not guaranteed, as it is not tested against them.

## Install

Add this to your `Gemfile`:

```ruby
gem "railcutters", git: "https://github.com/railcutters/railcutters.git", branch: "main"
```

At this point in time, this is an alpha project, so until `v1`, expect things to change.

## Feature list

Here's a table with all available features we offer through this gem. You can disable them
individually by setting the corresponding configuration option `config.railcutters.<configuration>`
to **`false`** in your configuration.

Read the `Breaking` column as it will tell you if it will break your code on an existing project,
meaning that you will need to change your code to make it work again. These settings are recommended
for new projects or if you're willing to change the existing code.

### Rails

Things that affects to the entire framework behavior.

<table>
  <tbody>
    <tr>
      <th align="left">Feature</th>
      <th align="left">Summary</th>
      <th align="left">Breaking</th>
      <th align="left">Configuration</th>
    </tr>
    <tr>
      <td><strong><code>KVTaggedLogger</code></strong></td>
      <td>Allow logging using Key-Valued structures for better tagging and observability</td>
      <td>:white_check_mark: No</td>
      <td><code>hashed_tagged_logging</code></td>
    </tr>
    <tr>
      <td><strong><code>Configure disabled components</code></strong></td>
      <td>Allow configuring disabled frameworks such as <code>active_job</code> or
        <code>action_mailer</code>, even if they're disabled (commented out on
        <code>config/application.rb</code>)
      </td>
      <td>:white_check_mark: No</td>
      <td><code>mock_settings_for_disabled_frameworks</code></td>
    </tr>
    <tr>
      <td><strong><code>Dotenv</code></strong></td>
      <td>Allows loading <code>.env</code> files.
      </td>
      <td>:white_check_mark: No</td>
      <td>N/A</td>
    </tr>
  </tbody>
</table>

### ActionController

Features that affect the behavior of Controllers.

<table>
  <tbody>
    <tr>
      <th align="left">Feature</th>
      <th align="left">Summary</th>
      <th align="left">Breaking</th>
      <th align="left">Configuration</th>
    </tr>
    <tr>
      <td><strong><code>params#rename()</code></strong></td>
      <td>Allows you to rename parameters coming to a route</td>
      <td>:white_check_mark: No</td>
      <td><code>params_renamer</code></td>
    </tr>
    <tr>
      <td><strong><code>#paginate()</code></strong></td>
      <td>Easily paginates an AR query for API endpoints</td>
      <td>:white_check_mark: No</td>
      <td><code>pagination</code></td>
    </tr>
    <tr>
      <td><strong><code>snake_case controller parameters</code></strong></td>
      <td>Converts all controller parameters to snake_case</td>
      <td>:x: Yes</td>
      <td><code>normalized_payload</code></td>
    </tr>
  </tbody>
</table>

### ActiveRecord

Features affecting the behavior of Models

<table>
  <tbody>
    <tr>
      <th align="left">Feature</th>
      <th align="left">Summary</th>
      <th align="left">Breaking</th>
      <th align="left">Configuration</th>
    </tr>
    <tr>
      <td><strong><code>#paginate()</code></strong></td>
      <td>Paginates an AR query and return its metadata</td>
      <td>:white_check_mark: No</td>
      <td><code>pagination</code></td>
    </tr>
    <tr>
      <td><strong><code>#safe_sort()</code></strong></td>
      <td>Sorts a query while validating the allowed fields</td>
      <td>:white_check_mark: No</td>
      <td><code>safe_sort</code></td>
    </tr>
    <tr>
      <td><strong><code>ActiveRecord Migration defaults</code></strong></td>
      <td>Sets database timestamps to created_at and updated_at fields, and makes null fields visible</td>
      <td>:white_check_mark: No</td>
      <td><code>ar_migration_defaults</code></td>
    </tr>
    <tr>
      <td><strong><code>Enum defaults</code></strong></td>
      <td>Sets sensible and configurable defaults to <code>enum</code> on ActiveRecord</td>
      <td>:x: Yes</td>
      <td><code>ar_enum_defaults</code></td>
    </tr>
    <tr>
      <td><strong><code>Enum string values</code></strong></td>
      <td>Treats all <code>enums</code> values as strings on ActiveRecord</td>
      <td>:x: Yes</td>
      <td><code>ar_enum_string_values</code></td>
    </tr>
  </tbody>
</table>

### SQLite3

Features to enhance the behavior of SQLite3

<table>
  <tbody>
    <tr>
      <th align="left">Feature</th>
      <th align="left">Summary</th>
      <th align="left">Breaking</th>
      <th align="left">Configuration</th>
    </tr>
    <tr>
      <td><strong><code>SQLite3 performance optimization</code></strong></td>
      <td>Configures SQLite3 for the best web server performance. Requires sqlite3 &gt;= 2.0</td>
      <td>:white_check_mark: No</td>
      <td><code>sqlite_tuning</code></td>
    </tr>
    <tr>
      <td><strong><code>SQLite3 STRICT tables</code></strong></td>
      <td>Use SQLite rigid typing system for tables</td>
      <td>:x: Yes</td>
      <td><code>sqlite_strictness</code></td>
    </tr>
  </tbody>
</table>

## Feature documentation

### KVTaggedLogger

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

> [!TIP]
> Disable it setting `config.railcutters.hashed_tagged_logging = false` in your configuration.

---

### Configure disabled components

A common practice when working with Rails as API is to disable the components that you're not using
by commenting them out on `config/application.rb`. However, if you simply comment them out, you
will get an immediate error because they are probably being configured on your
`config/environments/*.rb` files, so you would need to remove or comment them there as well.

This feature allow you to keep these settings of disabled frameworks such as **active_job** or
**action_mailer**, even if they're disabled (commented out on _config/application.rb_) so you can
easily enable them if or when you change your mind and you need that component in the future.

> [!TIP]
> Disable it setting `config.railcutters.mock_settings_for_disabled_frameworks = false` in your
> configuration.

---

### Dotenv loading

This feature allows you to load `.env` files in your Rails application. It is useful for development
and testing, as it allows you to set environment variables in a file instead of setting them
manually.

This is an opt-in feature, and to use it, you need to add this code below to your
`config/application.rb`, right after the `require_relative "boot"` section.

```ruby
# Load .env files automatically for test and development environments
require "railcutters/dotenv/load" if Rails.env.test? || Rails.env.development?
```

> [!TIP]
> Alternatively, create a new file named `config/dotenv.rb` and add the code above to it. Then, add
> `require_relative "dotenv"` to your `config/application.rb` file. This will make your application
> file cleaner and easier to read.

---

### ActionController::Base\#params.rename()

Allow controller parameters to be renamed with an easy-to-use syntax:

```ruby
def user_id_params
  params.rename("user.id" => "user_id").permit(:user_id)
end
```

> [!TIP]
> Disable it setting `config.railcutters.params_renamer = false` in your configuration.

---

### ActionController::Metal\#paginate()

Paginate a collection with an easy-to-use syntax, useful for APIs, as it returns the pagination
metadata on a header.

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

**Example header:** `Pagination: page=1,per-page=30,total-records=100,total-pages=4`

> [!TIP]
> Disable it setting `config.railcutters.pagination = false` in your configuration.

---

### Normalize controller parameters to use snake_case

It allows you to always rely that parameters sent from your frontend will have `snake_case` keys,
while converting them to `camelCase` before sending them back to the frontend. It allows you to use
the best of both worlds, while keeping the codebase consistent on both frontend and backend.

For converting keys to `camelCase`, you need to use `Jbuilder`.

Disable it setting `config.railcutters.normalized_payload = false` in your configuration.

> [!TIP]
> Disable it setting `config.railcutters.safe_sort = false` in your configuration.

> [!CAUTION]
> **This is a breaking configuration** if you are already counting on the casing of the parameters
> in your application. This is recommended for new projects, and if you're not willing to change the
> existing code, you can disable this feature and any other breaking change by setting
> `config.railcutters.use_safe_defaults!` in your configuration.

---

### ActiveRecord::Base\#paginate()

Paginates your query with an easy-to-use syntax. It works together with the `pagination` method
available on the controller:

```ruby
users = User.where(customer_id: params[:customer_id]).paginate(page: 4, per_page: 10)
puts users.pagination # => #<Hash @page=4, @per_page=10, @total=100, @pages=10>
```

> [!TIP]
> Disable it setting `config.railcutters.pagination = false` in your configuration.

---

### ActiveRecord::Base\#safe_sort()

This is a safe way to sort your queries, as it prevents database enumeration and potential DoS by
limiting which columns can be sorted.

You will need to first define the default sortable columns in your model:

```ruby
class User < ApplicationRecord
  safe_sortable_columns :id, :name, :email
end
```

Then you can call `safe_sort` in your queries:

```ruby
User.safe_sort(params[:sort], params[:order])
```

If you try to sort by a column that is not defined, it can either ignore the sorting at all, or you
can define a fallback column:

```ruby
User.safe_sort(params[:sort], params[:order], default: :name, default_order: :asc)
```

You can also define the allowed columns on the method call:

```ruby
User.safe_sort(params[:sort], params[:order], only_columns: %i[name age])
```

> [!TIP]
> Disable it setting `config.railcutters.safe_sort = false` in your configuration.

---

### ActiveRecord Migration Defaults

This sets the following defaults to your migrations:

  1. Sets `CURRENT_TIMESTAMP` as the default value for `timestamps` fields. It will make these
     fields also work outside of Rails.
  1. Explicitly sets the current `null` value for fields declared on migration files. It makes
     the code more explicit and easier to read.
  1. Sets all foreign key constraints to deferred, so they are not checked on every write within a
     transaction. This allows you to write to the database in any order, and foreign keys will only
     be checked at the end of the transaction. Only supported on PostgreSQL and SQLite on Rails 7.2+

> [!TIP]
> Disable it setting `config.railcutters.ar_migration_defaults = false` in your configuration.

---

### ActiveRecord::Enum with sensible defaults

This helps you setting a default options to every enum you define, so you don't need to repeat them.
By default, it sets the `prefix` option to `true`, so you can avoid clashing names when using
different enums with the same value.

It also sets the `validate` option to `true`, a new option
available since Rails 7.1 that avoids invalid enums to fail with a `ArgumentError` exception and
instead adds a validation error to the model.

> [!TIP]
> Set your own defaults with `config.railcutters.ar_enum_defaults = { ... }` in your configuration. Set
> it to a blank hash to disable it completely.

> [!CAUTION]
> **This is a breaking configuration** if you are already using enums in your application. This is
> recommended for new projects, and if you're not willing to change the existing code, you can
> disable this feature and any other breaking change by setting
> `config.railcutters.use_safe_defaults!` in your configuration.

---

### ActiveRecord::Enum string values

Sets the default behavior for array values to be equivalent to hashes with identical key and values.

This helps keeping the database enum values consistent with the Ruby enum values, so it's easier to
read them in the database. It also prevents you from mistakenly add a new value to the enum array
without having the order in consideration, which can be a source of bugs.

```ruby
class User < ApplicationRecord
  enum :status, %i[active inactive]
  # Is equivalent to:
  enum :status, { active: "active", inactive: "inactive" }
end
```

> [!TIP]
> Disable it setting `config.railcutters.ar_enum_string_values = false` in your configuration.

> [!CAUTION]
> **This is a breaking configuration** if you are already using enums in your application. This is
> recommended for new projects, and if you're not willing to change the existing code, you can
> disable this feature and any other breaking change by setting
> `config.railcutters.use_safe_defaults!` in your configuration.

---

### SQLite3 performance tuning

SQLite is a great database for many use cases, but it is not without its quirks. One of the most
common issues is that whiel very good at parallelism and handling concurrent writes, it is not
configured correctly out of the box to take advantage of this due to legacy reasons.

This gem ships with a set of performance tuning options that makes it work better in most cases.
Many of these options have already been merged into Rails 7.1, while others will only be available
for Rails 8.0+, but you can use them today.

See: https://kerkour.com/sqlite-for-servers

Additionally, two features are also available which will help you customizing your database:

  1. Enable loading extensions on `database.yml`
  1. Enable setting `PRAGMA`'s settings through `database.yml`

> [!IMPORTANT]
> While this is a safe configuration, you will need to install `sqlite2` >= `2.0` to use it.

> [!TIP]
> Disable it setting `config.railcutters.sqlite_tuning = false` in your configuration.

#### Using `PRAGMAS` to set database options

In your `database.yml`, you can set `pragmas` to a hash of `PRAGMA` settings that will be set when
the database is connected. To do so, you can use the following syntax:

```yaml
development:
  adapter: sqlite3
  database: storage/development.sqlite3
  pragmas:
    synchronous: 1
    journal_mode: DELETE
```

See: https://www.sqlite.org/pragma.html

#### Loading SQLite3 extensions

In your `database.yml`, you can set `extensions` to an array of extension paths that will be loaded
when the database is connected. To do so, you can use the following syntax:

```yaml
development:
  adapter: sqlite3
  database: storage/development.sqlite3
  extensions:
    - /path/to/extension.so
```

> [!NOTE]
> Ensure that the extension exists and is compatible with your version of SQLite and OS/platform.

---

### SQLite3 STRICT tables

This is [a feature available](https://sqlite.org/stricttables.html) since SQLite 3.37.0 (2021-11-27)
that allows you to define tables with a more rigid type system, as found in all other SQL databases
and in the SQL standard.

When enabled, it will enforce the following rules:

  1. The minimum version of SQLite is 3.37.0
  1. All migrations that create tables will create them as `STRICT` by default
  1. All field conversions will be done considering the available types in SQLite `STRICT` mode.

Because this is enabled on a per-table basis, you need to migrate existing tables to use this.

> [!TIP]
> Disable it setting `config.railcutters.sqlite_strictness = false` in your configuration.

> [!CAUTION]
> **This is a breaking configuration** and will affect the way your database works. This is
> recommended for new projects, and if you're not willing to change the existing code, you can
> disable this feature and any other breaking change by setting
> `config.railcutters.use_safe_defaults!` in your configuration.

---

## Recommendations

Aside from using the features above, there are some other recommendations that you can follow to
have a more maintainable and consistent application.

### SQLite maintainance

If you're using SQLite, you should run the following commands periodically to keep your database in
good shape:

```sql
PRAGMA optimize;
VACUUM;
```
