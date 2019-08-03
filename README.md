# detransport_ternopil_telegram

Source code for <https://t.me/DetransportTernopilBot>

## Installation

### Requirements

- Crystal
- PostgreSQL

Clone repository:

```console
git clone https://github.com/mamantoha/detransport_tenopil_telegram.git
```

### Setup Telegram

Copy `.env.example` to `.env` and set variables

### Setup Database

Copy `db/database.yml.example` to `db/database.yml` and set PostgreSQL variables

```console
crystal sam.cr -- db:setup
crystal sam.cr -- db:migrate
```

### Run

```console
shards build --release
./bin/detransport_telegram
```

## Deployment

### Linux with systemd

Create `/etc/systemd/system/detransport_ternopil_telegram.service`

```ini
[Unit]
Description=Detransport Ternopil Telegram service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=user
WorkingDirectory=/path/to/detransport_tenopil_telegram
ExecStart=/path/to/detransport_ternopil_telegram/bin/detransport_telegram &>/dev/null &
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
```

```console
sudo systemctl enable detransport_tenopil_telegram
```

```console
sudo systemctl start detransport_ternopil_telegram
```

## Contributing

1. Fork it (<https://github.com/mamantoha/detransport_telegram/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer