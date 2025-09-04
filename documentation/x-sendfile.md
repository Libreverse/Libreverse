# X-Accel-Redirect / X-Sendfile setup

Production uses Passenger + NGINX. Rails is configured to use NGINX acceleration via:

- `config/environments/production.rb`: `config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"`
- `docker/webapp.conf`: sets `passenger_env_var X-Accel-Mapping` and defines internal locations

Internal NGINX locations (internal-only):

- `/_internal/storage/` -> `alias /home/app/webapp/storage/`
- `/_internal/private/` -> `alias /home/app/webapp/private/`

`X-Accel-Mapping` tells Rack::Sendfile how to translate filesystem paths to those internal URIs. Multiple mappings are comma-separated and must end in `/`.

## Using in controllers

Include the concern and call the helper:

```ruby
class DownloadsController < ApplicationController
  include AcceleratedSendfile

  def show
    record = Document.find(params[:id])
    accelerated_send_file(record.absolute_path,
      filename: record.filename,
      disposition: (record.inline? ? 'inline' : 'attachment'))
  end
end
```

The helper validates the path is absolute and under an allowed accelerated root (`storage/` or `private/`).

## Notes

- In development/test, Rack::Sendfile may be disabled; Rails will stream from Ruby instead.
- If you add more accelerated roots, extend `X-Accel-Mapping` in `webapp.conf` and the whitelist in the concern.
- For Active Storage public URLs you likely do not need this; this is for app-managed files outside Active Storage.
