FROM ghcr.io/gleam-lang/gleam:v1.7.0-erlang
RUN apt-get update && apt-get install --yes build-essential

# Add project code
COPY . /build/

# Compile the project
RUN cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
