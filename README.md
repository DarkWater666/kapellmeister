# Диспетчер HTTP-запросов

Этот шаблонизатор позволяет вам определять http-запросы к любым сторонним API с помощью упрощенного набора инструкций, включая анализатор маршрутов в формате yaml
## Использование

Добавьте kapellmeister в свой Gemfile:
На данный момент последняя версия 0.9.9.rc2 (Проект находится в стадии тестирования работоспособности, beta-test)
```ruby
gem 'kapellmeister', '~> 0.9.9.rc2'
```

### Добавьте новую конфигурацию для стороннего API:

    $ bin/rails g kapellmeister:add_service %<ThirdPartyName> %<options> --%<flags>

`ThirdPartyName` — Имя сервиса, может быть указан как КэмелКейсом (CamelCase) так и с нижним_подчёркиванием (under_scored)

`options` — Укажите ключи конфигурации, обычно это хост, ключ и версия

`flags` — Этот шаблонзатор пока что имеет один флаг.
Флаг `responder`, `false` — значение по-умолчанию.
Если вы установите для него значение `true`, то будет сгенерирован файл responder.rb используемый для анализа и парсинга ответа.

Все инструкции — это легковесные файлы в каталоге /lib вашего приложения.
Вот пример структуры:

``` Capfile
└── app
    └── lib
        └── third_party_service
            ├── client.rb
            ├── configuration.rb
            ├── responder.rb (опционально)
            └── routes.yml
        └── third_party_service.rb  
└── initializers
    └── third_party_service.rb
```

Если вы используете Rails, в вашем приложении есть папка `initializers`. Добавьте секретные ключи в файле-инициализаторе

    initializers/third_party_service.rb

Основной файл вашей интеграции, миксин, включающий Kapellmeister::Base

    app/lib/third_party_service.rb

Каталог, содержащий `routes scheme`, `client`, `configuration` и опциональный `responder`.

    app/lib/third_party_service



`routes.yml` — Маршруты к стороннему API во вложенном формате.

``` yaml
foo:                     => Обёртка для метода
  bar:                   => Наименование метода
    scheme:              => Описание схемы
      method: POST       => Тип запроса (* обязательный параметр!)
      wrappers:          => Обёрнуть ли имя метода и/или реальный путь для обеспечения уникальности. По умолчанию true для метода, и false для пути
        all: true        => Можно передать ключ all, который отработает и за обёртку метода и за обёртку пути с одним значением
        name: true       => Этот ключ отвечает за обёртку имени метода, приоритетней над all (по умолчанию true)
        path: false      => Этот ключ отвечает за обёртку пути, приоритетней над all (по умолчанию false)
      path: buz          => Настоящий путь (роут). Если параметра нет, то путь будет взят из наименования метода.
      body:              => Dry-scheme (из набора гемов DRY) для проверки параметров. Если параметра нет, то проверки не будет.
      query_params:      => Описание query-параметров. Если параметра нет, то подстановки параметров не будет.
      mock:              => Структура или путь к файлу mock для тестов. Если параметра нет, в среде разработки будет возвращён реальный ответ на запрос.

# Результат из примера выше:
# client = ThirdParty::Client.new
# client.foo_bar { a: 'b' } 
# => POST https://third_party.com/foo/buz DATA: { a: 'b' }
```
#### Пояснение к параметрам:

`body` — Вы можете использовать dry-scheme (из набора гемов DRY) для проверки параметров запроса.
Если этот ключ не существует, проверка будет пропущена.
Пример:

```yaml
body: DrySchema
```

`query_params` — Если для запроса требуется query-параметры.
Работают как массивы, так и руби-хэши.
Если этот ключ не существует, то подстановки параметров и их проверки не будет.
Пример:

```yaml
query_params:
  dbAct: getCities       => Пример использования известных и неизменяемых параметров
  optional:              => Пример использования опциональных параметров. Они будут подставлены при передачи их при запросе
    - city
    - state

# Результат из примера выше:
# /api?dbAct=getCities&city=Tokio
```
```yaml
query_params:
  - dbAct: getTarif
  - org                => Пример использования обязательных параметров.
  - dest
  - weight
  
# Результат из примера выше:
# /api?dbAct=getTarif&org=Tokio&dest=Beijing&weight=100
```

`mock` — Если вам нужно, чтобы реальные запросы не проходили во время тестирования,
вы можете заменить их на mocks.
Можно использовать как структуру yaml, так и путь к файлу yaml.
Например:

```yaml
mock: spec/mocks/http_clients/public/cities.yml
```

#### Объяснение сгенерированных файлов

`client.rb` — Унаследованный файл от главного диспетчера, и вы можете добавить некоторые методы настройки, пользовательские заголовки, параметры запросов, query-параметры.

`configuration.rb` — Добавляем путь к стороннему API, URL-адрес конфигурации и логгер.

`responder.rb` — По умолчанию используется стандартный обработчик ответов, обработанный в формате json. Но вы можете написать свой собственный.



---
### english

# HTTP requests dispatcher

This template-service allows you to define http requests to a third party through a lightweight set of instructions, including a route parser in yaml format

## Usage

Add kapellmeister to your Gemfile:
At the moment, the latest version is 0.9.9.rc2 (The project is in the stage of performance testing, beta-test)
```ruby
gem 'kapellmeister', '~> 0.9.9.rc2'
```

### Add a new configuration for the third-party API:

    $ bin/rails g kapellmeister:add_service %<ThirdPartyName> %<options> --%<flags>

`ThirdPartyName` — The name of the service, can be specified either CamelCased or under_scored

`options` — Specify the configuration keys, usually `host`, `key` and `version`

`flags` — This generator has only one flag so far.
The `responder` flag, `false` is the default value.
If you set it to `true`, the responder.rb file will be generated, which is used for analyzing and parsing the response.

All instructions are lightweight files in the /lib directory of your application.
Here is an example of the structure:

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

If you are using Rails gem, there is a `initializers` folder in your application. Add the secret keys in the initializer file.

    app/lib/third_party_service.rb

The main file of your integration, a mixin that includes Kapellmeister::Base

    app/lib/third_party_service

A directory containing `routes scheme`, `client`, `configuration` and an optional `responder`.

`routes.yml` — Routes to a third-party API in a nested format.

``` yaml
foo:                     => Wrapper of the method
  bar:                   => Name of the method
    scheme:              => Description of the scheme
      method: POST       => Request type (* required)
      wrappers:          => Whether to wrap the method name and/or the actual path to ensure uniqueness. By default, true for the method, and false for the path
        all: true        => You can pass the 'all' key, which will work for both the method wrapper and the path wrapper with one value
        name: true       => This key is responsible for wrapping the method name, which takes precedence over 'all' key (true by default)
        path: false      => This key is responsible for wrapping the path, taking precedence over 'all' key (false by default)
      path: buz          => The real path (route). If there is no parameter, the path will be taken from the method name.
      body:              => Dry-scheme (from the set of DRY gems) to check the parameters. If there is no parameter, then there'll be no verification.
      query_params:      => Description of the query parameters. If there is no parameter, then there'll be no parameter substitution.
      mock:              => The structure or path to the mock file for the tests. If there is no parameter, the actual response to the request will be returned in the development environment.

# The result from the example above:
# client = ThirdParty::Client.new
# client.foo_bar { a: 'b' } 
# => POST https://third_party.com/foo/buz DATA: { a: 'b' }
```
#### Explanation of the parameters:

`body` — You can use the dry-scheme (from the set of DRY gems) to check the request parameters.
If this key doesn't exist, the verification will be skipped.
Example:

```yaml
body: DrySchema
```

`query_params` — If the request requires query parameters.
Both arrays and ruby-hashes work.
If this key doesn't exist, then there'll be no parameter substitution and validation.
Example:

```yaml
query_params:
  dbAct: getCities       => Example of using known and immutable parameters
  optional:              => An example of using optional parameters. They'll be substituted when they are transmitted during the request
    - city
    - state

# The result from the example above:
# /api?dbAct=getCities&city=Tokio
```
```yaml
query_params:
  - dbAct: getTarif
  - org                => Example of using required parameters.
  - dest
  - weight

# The result from the example above:
# /api?dbAct=getTarif&org=Tokio&dest=Beijing&weight=100
```

`mock` —  If you need real requests not to pass during testing,
you can replace them with mocks.
You can use both the yaml structure and the path to the yaml-file.
Example:

```yaml
mock: spec/mocks/http_clients/public/cities.yml
```

#### Explanation of the generated files

`client.rb` — An inherited file from the main dispatcher, and you can add some configuration methods, custom headers, request parameters, query-parameters.

`configuration.rb` — Add the path to the third-party API, the configuration URL and the logger.

`responder.rb` —  By default, a standard response handler is used, parsed in json format. But you can write your own.

## Contributing

Pull requests welcome: fork, make a topic branch, commit (squash when possible) *with tests* and I'll happily consider.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Copyright

Copyright (c) 2024 Denis Arushanov aka DarkWater
