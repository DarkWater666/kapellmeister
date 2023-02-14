# HTTP requests dispatcher

This template-service allows you to define http requests to a third party through a lightweight set of instructions, including a route parser in yaml format

## Usage

Add kapellmeister to your Gemfile:

```ruby
gem 'kapellmeister', '~> 0.9.6'
```

### Add new third party configuration:

    $ bin/rails g kapellmeister:add_service %<ThirdPartyName> %<options> --%<flags>

`ThirdPartyName` — Pass the lib name, either CamelCased or under_scored

`options` — Pass the configuration keys, usually host, key and version

`flags` — This generator have one flag.
This flag is `responder`, default is `false`.
If you set it to `true` will be generated responder.rb used for parsing response.

All the instructions are lightweight files in your /lib folder.
Here's the example of structure:

``` Capfile
└── app
    └── lib
        └── third_party_service
            ├── client.rb
            ├── configuration.rb
            ├── responder.rb
            └── routes.yml
        └── third_party_service.rb  
└── initializers
    └── third_party_service.rb
```

    initializers/third_party_service.rb

If you use the Rails gem you have the `initializers` folder in your application. Add the secret keys to config.

    app/lib/third_party_service.rb

Main file of your integration. Make it module and include the Kapellmeister::Base

    app/lib/third_party_service

Folder contains `routes scheme`, `client`, `configuration` and optional `responder`.

`routes.yml` — Routes to third party in nested format.

``` yaml
foo:                     => Wrapper for method
  bar:                   => Method name
    scheme:              => Scheme description
      method: POST       => Request type (* required)
      use_wrapper: true  => Wrap method for uniqueness. Default true
      path: buz          => Real path
      body:              => Dry schema for checking parameters. If key doesn't exist nothing happens
      query_params:      => Query params. If key doesn't exist nothing happens
      mock:              => Structure or Path to mock file for tests. If key doesn't exist nothing happens

# ThirdParty::Client.foo_bar { a: 'b' } => POST https://third_party.com/foo/buz DATA: { a: 'b' }
```
#### Parameters explanation:

`body` — You can use dry-schema for validate request parameters.
If this key doesn't exist validation will be skipped.
For example:

```yaml
body: CreateSchema
```

`query_params` — If request needs a query string.
Both arrays and hashes work.
If this key doesn't exist validation will be skipped.
For example:

```yaml
query_params:
  dbAct: getCities       => For known and unchangeable parameters
  optional:              => For optional parameters
    - city
    - state

# /api?dbAct=getCities&city=Tokio
```
```yaml
query_params:
  - dbAct: getTarif
  - org                => For required parameters
  - dest
  - weight
  
# /api?dbAct=getTarif&org=Tokio&dest=Beijing&weight=100
```

`mock` — If you need real requests don't pass during the testing,
then you can replace them with mocks.
Both yaml structure or path to yaml file can be used.
For example:

```yaml
mock: spec/mocks/http_clients/public/cities.yml
```

#### Generated files explanation

`client.rb` — Nested from main dispatcher and you can add some configuration methods, custom headers and requests options.

`configuration.rb` — Add path to third party, config url and logger

`responder.rb` — By default uses standard responders parsed response in json. But you can write your own.

## Contributing

Pull requests welcome: fork, make a topic branch, commit (squash when possible) *with tests* and I'll happily consider.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Copyright

Copyright (c) 2022 Denis Arushanov aka DarkWater
