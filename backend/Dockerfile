FROM elixir:latest

WORKDIR /app

# Install build dependencies, curl for healthchecks, and inotify-tools for code reloading
RUN apt-get update && \
    apt-get install -y build-essential curl inotify-tools && \
    rm -rf /var/lib/apt/lists/*

# Copy only mix.exs first for layer caching
COPY mix.exs ./

# Setup Elixir and get dependencies
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

# Copy rest of the code
COPY . .

EXPOSE 4000

CMD ["mix", "phx.server"]
