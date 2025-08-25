# server-interview

To start your Phoenix server:

- Install PostgreSQL locally
- Create `.env` from `.env.example` file

```
DATABASE_HOSTNAME=
DATABASE_NAME=
DATABASE_PASSWORD=
DATABASE_POOL_SIZE=
DATABASE_PORT=
DATABASE_USERNAME=
```

- Run the following commands to install language dependencies

```bash
$ brew install asdf
$ asdf plugin add erlang
$ asdf plugin add elixir
$ asdf install
$ asdf set erlang x.x.x # get version from .tool-versions
$ asdf set elixir x.x.x # get version from .tool-versions
```

- Run `mix setup` to install and setup dependencies
- Run `mix run priv/repo/seeds.exs` to seed the local database
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

- Visit `localhost:4000/graphiql` for GraphQL IDE
- Visit `localhost:4000/dev/dashboard` for Phoenix Dashboard

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
