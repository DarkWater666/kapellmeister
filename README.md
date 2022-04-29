# HTTP requests dispatcher

This template-service allows you to define http requests to a third party through a lightweight set of instructions, including a route parser in yaml format

## Usage

Add kapellmeister to your Gemfile:

```ruby
gem 'kapellmeister', '~> 0.4.1'
```

### Add new third party configuration:

    $ bin/rails g kapellmeister:add_service %<ThirdPartyName> %<options> --%<flags>

`ThirdPartyName` — Pass the lib name, either CamelCased or under_scored
`options` — Pass the configuration keys, usually host, key and version
`flags` — This generator have one flag. This flag is `responder`, default is `false`. If you set to `true` will be generated responder.rb used for parsing response.

All the instructions are lightweight files in your /lib folder. Here's the example of structure:

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
      method: POST       => Request type
      use_wrapper: true  => Default true
      path: buz          => Real path
      mock:              => Mock for development
        token: blablabla

# ThirdParty::Client.foo_bar { a: 'b' } => POST https://third_party.com/foo/buz DATA: { a: 'b' }
```

`client.rb` — Nested from main dispatcher and you can add some configuration methods, custom headers and requests options.

`configuration.rb` — Add path to third party, config url and logger

`responder.rb` — By default uses standard responders parsed response in json. But you can write your own.

## Contributing

Pull requests welcome: fork, make a topic branch, commit (squash when possible) *with tests* and I'll happily consider.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Copyright

Copyright (c) 2022 Denis Arushanov aka DarkWater
