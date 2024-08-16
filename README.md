# HasPrivateAttributes 🔒

This Ruby gem provides a simple and elegant way to define private attributes in your classes. It allows you to create static, lazy-evaluated, and argument-based private attributes with automatic caching and freezing of the returned values, all in a thread-safe manner.

## Features 🌟

- **Static Attributes**: Define private attributes with a fixed, immutable value.
- **Lazy Attributes**: Define private attributes that are lazily evaluated and cached.
- **Argument-based Attributes**: Define private attributes that depend on arguments and cache the results.
- **Inheritance**: Private attributes can be inherited from parent classes.
- **Freezing**: All returned values are automatically deep-frozen to prevent modification.
- **Thread Safety**: All operations are thread-safe, allowing for use in multi-threaded environments.

## Installation 📥

Add this line to your application's Gemfile:

```ruby
gem 'has_private_attributes'
```

And then execute:

```bash
bundle install
```

## Usage 🚀

Here's a simple example of how to use the `HasPrivateAttributes` gem:

```ruby
class MyClass
  include HasPrivateAttributes

  # definition of private attributes

  private_attribute :static_servers, [
    { ip: '1.1.1.1', location: 'US' },
    { ip: '8.8.8.8', location: 'US' }
  ]

  private_attribute :lazy_servers do
    [
      { ip: '2.2.2.2', location: 'EU' },
      { ip: '3.3.3.3', location: 'EU' }
    ]
  end

  private_attribute :servers_by_region do |region|
    case region
    when 'us'
      [
        { ip: '1.1.1.1', location: 'US' },
        { ip: '8.8.8.8', location: 'US' }
      ]
    when 'eu'
      [
        { ip: '2.2.2.2', location: 'EU' }
      ]
    end
  end

  # usage of private attributes

  def get_static_servers
    static_servers
  end

  def get_lazy_servers
    lazy_servers
  end

  def get_servers_by_region(region)
    servers_by_region(region)
  end
end

instance = MyClass.new

puts instance.get_static_servers
# Output:
# [
#   { ip: '1.1.1.1', location: 'US' },
#   { ip: '8.8.8.8', location: 'US' }
# ]

puts instance.get_lazy_servers
# Output:
# [
#   { ip: '2.2.2.2', location: 'EU' },
#   { ip: '3.3.3.3', location: 'EU' }
# ]

puts instance.get_servers_by_region('us')
# Output:
# [
#   { ip: '1.1.1.1', location: 'US' },
#   { ip: '8.8.8.8', location: 'US' }
# ]

puts instance.get_servers_by_region('eu')
# Output:
# [
#   { ip: '2.2.2.2', location: 'EU' }
# ]
```

## Examples 💡

Here are some more examples of using the `HasPrivateAttributes` gem:

### Static Attributes 🗄️

```ruby
instance.static_servers # => [{ ip: '1.1.1.1', location: 'US' }, { ip: '8.8.8.8', location: 'US' }]
instance.static_servers.frozen? # => true
```

### Lazy Attributes 🐢

```ruby
instance.lazy_servers # => [{ ip: '2.2.2.2', location: 'EU' }, { ip: '3.3.3.3', location: 'EU' }]
instance.lazy_servers.object_id # => 12345678
instance.lazy_servers.object_id # => 12345678 (same object)
```

### Argument-based Attributes 🔍

```ruby
instance.servers_by_region('us') # => [{ ip: '1.1.1.1', location: 'US' }, { ip: '8.8.8.8', location: 'US' }]
instance.servers_by_region('eu') # => [{ ip: '2.2.2.2', location: 'EU' }]
```

## Thread Safety 🔒

All operations in HasPrivateAttributes are thread-safe. This means you can safely use private attributes in multi-threaded environments without worrying about race conditions or data inconsistencies. The gem uses Ruby's `Monitor` and `Mutex` classes to ensure proper synchronization.

For example, you can safely access private attributes from multiple threads:

```ruby
threads = []
10.times do
  threads << Thread.new do
    puts instance.get_lazy_servers
  end
end
threads.each(&:join)
```

This will safely initialize and return the lazy servers, even if multiple threads try to access it simultaneously.

## Contributing 🤝

Bug reports and pull requests are welcome on GitHub at https://github.com/sebyx07/has_private_attributes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/sebyx07/has_private_attributes/blob/master/CODE_OF_CONDUCT.md).

## License 📄

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct 🤵

Everyone interacting in the HasPrivateAttributes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sebyx07/has_private_attributes/blob/master/CODE_OF_CONDUCT.md).